#include "lockcore/replay.hpp"

#include "lockcore/lockfile.hpp"
#include "lockcore/session.hpp"

namespace lockcore {

using json::Value;

namespace {

constexpr std::int32_t kUnit = INPUT_QUANTUM;  // 1/256 in Q16

std::int64_t to_units(q16 v) { return v / kUnit; }

bool parse_hex64(const std::string& s, std::uint64_t& out) {
  if (s.size() != 16) return false;
  std::uint64_t v = 0;
  for (char c : s) {
    v <<= 4u;
    if (c >= '0' && c <= '9') v |= static_cast<std::uint64_t>(c - '0');
    else if (c >= 'a' && c <= 'f') v |= static_cast<std::uint64_t>(c - 'a' + 10);
    else return false;
  }
  out = v;
  return true;
}

}  // namespace

std::string hash_hex(std::uint64_t h) {
  static const char* hex = "0123456789abcdef";
  std::string s(16, '0');
  for (int i = 15; i >= 0; --i) {
    s[static_cast<std::size_t>(i)] = hex[h & 0xFu];
    h >>= 4u;
  }
  return s;
}

std::string replay_to_json(const Replay& r) {
  Value o = Value::object();
  o.set("schema", Value::string(std::string(REPLAY_SCHEMA)));
  o.set("family", Value::string(r.family));
  o.set("rules_version", Value::integer(r.rules_version));
  o.set("seed", Value::string(std::to_string(r.seed)));
  o.set("difficulty", difficulty_to_json(r.difficulty));
  o.set("input_unit", Value::string("1/256"));
  o.set("input_fields", [] {
    Value a = Value::array();
    for (const char* f : {"run", "tension", "pick_depth", "pick_lift", "rotate", "push", "tool"})
      a.push(Value::string(f));
    return a;
  }());
  // Run-length encoding: [run, tension, depth, lift, rotate, push, tool] per run.
  Value runs = Value::array();
  std::size_t i = 0;
  while (i < r.inputs.size()) {
    std::size_t j = i + 1;
    while (j < r.inputs.size() && r.inputs[j] == r.inputs[i]) ++j;
    const InputFrame& f = r.inputs[i];
    Value row = Value::array();
    row.push(Value::integer(static_cast<std::int64_t>(j - i)));
    row.push(Value::integer(to_units(f.tension)));
    row.push(Value::integer(to_units(f.pick_depth)));
    row.push(Value::integer(to_units(f.pick_lift)));
    row.push(Value::integer(to_units(f.rotate)));
    row.push(Value::integer(to_units(f.push)));
    row.push(Value::integer(f.tool));
    runs.push(std::move(row));
    i = j;
  }
  o.set("inputs", std::move(runs));
  Value exp = Value::object();
  exp.set("event_hash_fnv1a64", Value::string(hash_hex(r.expected_hash)));
  exp.set("steps", Value::integer(r.expected_steps));
  exp.set("open", Value::boolean(r.expected_open));
  o.set("expected", std::move(exp));
  return json::write(o);
}

bool replay_from_json(std::string_view text, Replay& out, std::string& error) {
  json::ParseResult pr = json::parse(text);
  if (!pr.ok) {
    error = pr.error;
    return false;
  }
  const Value& v = pr.value;
  std::vector<SpecError> errs;
  auto str = [&](std::string_view k) -> std::string {
    const Value* x = v.find(k);
    if (x == nullptr || !x->is_string()) {
      errs.push_back({std::string(k), "expected string"});
      return {};
    }
    return x->as_string();
  };
  if (str("schema") != REPLAY_SCHEMA) {
    error = "unsupported replay schema";
    return false;
  }
  out.family = str("family");
  std::int64_t x = 0;
  if (field::get_int(v, "rules_version", 0, 1000000, x, errs, "")) out.rules_version = static_cast<std::int32_t>(x);
  const std::string seed = str("seed");
  out.seed = 0;
  for (char c : seed) out.seed = out.seed * 10 + static_cast<std::uint64_t>(c - '0');
  if (const Value* d = v.find("difficulty")) difficulty_from_json(*d, out.difficulty, errs);
  const Value* runs = v.find("inputs");
  if (runs == nullptr || !runs->is_array()) {
    error = "inputs: expected array";
    return false;
  }
  out.inputs.clear();
  for (const Value& row : runs->items()) {
    if (!row.is_array() || row.items().size() != 7) {
      error = "inputs: each run needs 7 integers";
      return false;
    }
    for (const Value& c : row.items()) {
      if (!c.is_int() || c.uint_only()) {
        error = "inputs: expected integers";
        return false;
      }
    }
    const auto& it = row.items();
    const std::int64_t run = it[0].as_int();
    if (run <= 0 || run > 100000000) {
      error = "inputs: bad run length";
      return false;
    }
    InputFrame f;
    f.tension = static_cast<q16>(it[1].as_int() * kUnit);
    f.pick_depth = static_cast<q16>(it[2].as_int() * kUnit);
    f.pick_lift = static_cast<q16>(it[3].as_int() * kUnit);
    f.rotate = static_cast<q16>(it[4].as_int() * kUnit);
    f.push = static_cast<q16>(it[5].as_int() * kUnit);
    f.tool = static_cast<std::uint8_t>(it[6].as_int());
    out.inputs.insert(out.inputs.end(), static_cast<std::size_t>(run), f);
  }
  if (const Value* e = v.find("expected"); e != nullptr && e->is_object()) {
    if (const Value* h = e->find("event_hash_fnv1a64"); h != nullptr && h->is_string()) {
      if (!parse_hex64(h->as_string(), out.expected_hash)) errs.push_back({"expected.event_hash_fnv1a64", "bad hex"});
    }
    if (field::get_int(*e, "steps", 0, INT64_MAX, x, errs, "expected")) out.expected_steps = x;
    field::get_bool(*e, "open", out.expected_open, errs, "expected");
  }
  if (!errs.empty()) {
    error = errs.front().path + ": " + errs.front().message;
    return false;
  }
  return true;
}

ReplayResult run_replay(const FamilyRegistry& registry, const Replay& r) {
  ReplayResult res;
  const FamilyModule* fam = registry.find(r.family);
  if (fam == nullptr) {
    res.error = "unknown family " + r.family;
    return res;
  }
  if (fam->rules_version() != r.rules_version) {
    res.error = "replay recorded with rules_version " + std::to_string(r.rules_version) + ", module has " +
                std::to_string(fam->rules_version());
    return res;
  }
  LockSpec spec = fam->generate(r.seed, r.difficulty);
  LockSession s(*fam, spec);
  for (const InputFrame& f : r.inputs) {
    if (s.finished()) break;
    s.step(f);
  }
  res.ok = true;
  res.hash = s.event_hash();
  res.steps = s.t_step();
  res.open = s.is_open();
  res.failure = s.failure();
  return res;
}

}  // namespace lockcore
