#include "lockcore/lockfile.hpp"

#include <limits>

namespace lockcore {

using json::Value;

namespace field {

bool get_int(const Value& obj, std::string_view key, std::int64_t lo, std::int64_t hi, std::int64_t& out,
             std::vector<SpecError>& errors, const std::string& path) {
  const Value* v = obj.find(key);
  const std::string p = path + "." + std::string(key);
  if (v == nullptr) {
    errors.push_back({p, "missing"});
    return false;
  }
  if (!v->is_int() || v->uint_only()) {
    errors.push_back({p, "expected integer"});
    return false;
  }
  if (v->as_int() < lo || v->as_int() > hi) {
    errors.push_back({p, "out of range [" + std::to_string(lo) + ", " + std::to_string(hi) + "]"});
    return false;
  }
  out = v->as_int();
  return true;
}

bool get_bool(const Value& obj, std::string_view key, bool& out, std::vector<SpecError>& errors,
              const std::string& path) {
  const Value* v = obj.find(key);
  const std::string p = path + "." + std::string(key);
  if (v == nullptr || !v->is_bool()) {
    errors.push_back({p, v == nullptr ? "missing" : "expected boolean"});
    return false;
  }
  out = v->as_bool();
  return true;
}

// Seeds are 64-bit; JSON consumers that read numbers as doubles (Godot, JS) would
// lose precision, so seeds are written as decimal strings.
bool parse_u64(const std::string& s, std::uint64_t& out) {
  if (s.empty() || s.size() > 20) return false;
  std::uint64_t v = 0;
  for (char c : s) {
    if (c < '0' || c > '9') return false;
    const auto d = static_cast<std::uint64_t>(c - '0');
    if (v > (std::numeric_limits<std::uint64_t>::max() - d) / 10) return false;
    v = v * 10 + d;
  }
  out = v;
  return true;
}

}  // namespace field

namespace {

bool get_string(const Value& obj, std::string_view key, std::string& out, std::vector<SpecError>& errors,
                const std::string& path) {
  const Value* v = obj.find(key);
  if (v == nullptr || !v->is_string()) {
    errors.push_back({path + "." + std::string(key), v == nullptr ? "missing" : "expected string"});
    return false;
  }
  out = v->as_string();
  return true;
}

bool material_from_name(std::string_view n, MaterialId& out) {
  for (int i = 0; i <= static_cast<int>(MaterialId::steel); ++i) {
    if (material_name(static_cast<MaterialId>(i)) == n) {
      out = static_cast<MaterialId>(i);
      return true;
    }
  }
  return false;
}

}  // namespace

Value difficulty_to_json(const DifficultyVector& d) {
  Value o = Value::object();
  o.set("tier", Value::integer(d.tier));
  o.set("n_min", Value::integer(d.n_min));
  o.set("n_max", Value::integer(d.n_max));
  o.set("sec_min", Value::integer(d.sec_min));
  o.set("sec_max", Value::integer(d.sec_max));
  o.set("win_shear_q16", Value::integer(d.win_shear));
  o.set("tension_band_q16", Value::integer(d.tension_band));
  o.set("overset_margin_q16", Value::integer(d.overset_margin));
  o.set("noise_q16", Value::integer(d.noise));
  o.set("bind_spread_q16", Value::integer(d.bind_spread));
  o.set("multi_bind_p_q16", Value::integer(d.multi_bind_p));
  o.set("drop_grace_ms", Value::integer(d.drop_grace_ms));
  o.set("s_max_q16", Value::integer(d.s_max));
  o.set("time_limit_s", Value::integer(d.time_limit_s));
  return o;
}

bool difficulty_from_json(const Value& v, DifficultyVector& d, std::vector<SpecError>& errors,
                          const std::string& path) {
  if (!v.is_object()) {
    errors.push_back({path, "expected object"});
    return false;
  }
  const std::size_t before = errors.size();
  std::int64_t x = 0;
  auto i32 = [&](std::string_view k, std::int64_t lo, std::int64_t hi, std::int32_t& out) {
    if (field::get_int(v, k, lo, hi, x, errors, path)) out = static_cast<std::int32_t>(x);
  };
  i32("tier", 0, 10, d.tier);
  i32("n_min", 1, 64, d.n_min);
  i32("n_max", 1, 64, d.n_max);
  i32("sec_min", 0, 64, d.sec_min);
  i32("sec_max", 0, 64, d.sec_max);
  i32("win_shear_q16", 0, Q16_ONE, d.win_shear);
  i32("tension_band_q16", 0, Q16_ONE, d.tension_band);
  i32("overset_margin_q16", 0, Q16_ONE, d.overset_margin);
  i32("noise_q16", 0, Q16_ONE, d.noise);
  i32("bind_spread_q16", 0, Q16_ONE, d.bind_spread);
  i32("multi_bind_p_q16", 0, Q16_ONE, d.multi_bind_p);
  i32("drop_grace_ms", 0, 10000, d.drop_grace_ms);
  i32("s_max_q16", 1, 64 * Q16_ONE, d.s_max);
  i32("time_limit_s", 1, 3600, d.time_limit_s);
  if (errors.size() == before && (d.n_min > d.n_max || d.sec_min > d.sec_max))
    errors.push_back({path, "min > max"});
  return errors.size() == before;
}

Value lock_to_value(const LockSpec& spec, const FamilyModule& family) {
  Value o = Value::object();
  o.set("schema", Value::string(std::string(LOCK_SCHEMA)));
  o.set("family", Value::string(spec.family));
  o.set("rules_version", Value::integer(spec.rules_version));
  o.set("id", Value::string(spec.id));
  o.set("source", Value::string(spec.source));
  o.set("seed", Value::string(std::to_string(spec.seed)));
  o.set("difficulty", difficulty_to_json(spec.difficulty));
  o.set("spec", spec.params ? family.params_to_json(*spec.params) : Value::object());
  Value pres = Value::object();
  pres.set("material", Value::string(std::string(material_name(spec.material))));
  o.set("presentation", std::move(pres));
  return o;
}

std::string lock_to_json(const LockSpec& spec, const FamilyModule& family) {
  return json::write(lock_to_value(spec, family));
}

LockParse lock_from_json(std::string_view text, const FamilyRegistry& registry) {
  LockParse r;
  json::ParseResult pr = json::parse(text);
  if (!pr.ok) {
    r.errors.push_back({"", pr.error});
    return r;
  }
  const Value& v = pr.value;
  if (!v.is_object()) {
    r.errors.push_back({"", "expected object"});
    return r;
  }
  std::string schema;
  if (get_string(v, "schema", schema, r.errors, "") && schema != LOCK_SCHEMA)
    r.errors.push_back({".schema", "unsupported schema '" + schema + "'"});
  get_string(v, "family", r.spec.family, r.errors, "");
  std::int64_t x = 0;
  if (field::get_int(v, "rules_version", 0, 1000000, x, r.errors, "")) r.spec.rules_version = static_cast<std::int32_t>(x);
  get_string(v, "id", r.spec.id, r.errors, "");
  get_string(v, "source", r.spec.source, r.errors, "");
  std::string seed;
  if (get_string(v, "seed", seed, r.errors, "") && !field::parse_u64(seed, r.spec.seed))
    r.errors.push_back({".seed", "expected decimal uint64 string"});
  if (const Value* d = v.find("difficulty")) {
    difficulty_from_json(*d, r.spec.difficulty, r.errors, ".difficulty");
  } else {
    r.errors.push_back({".difficulty", "missing"});
  }
  if (const Value* p = v.find("presentation"); p != nullptr && p->is_object()) {
    std::string m;
    if (get_string(*p, "material", m, r.errors, ".presentation") && !material_from_name(m, r.spec.material))
      r.errors.push_back({".presentation.material", "unknown material"});
  }
  const FamilyModule* fam = registry.find(r.spec.family);
  if (fam == nullptr) {
    r.errors.push_back({".family", "unknown family '" + r.spec.family + "'"});
    return r;
  }
  if (r.spec.rules_version != fam->rules_version())
    r.errors.push_back({".rules_version", "module implements rules_version " + std::to_string(fam->rules_version())});
  const Value* ps = v.find("spec");
  if (ps == nullptr || !ps->is_object()) {
    r.errors.push_back({".spec", "missing"});
    return r;
  }
  r.spec.params = fam->params_from_json(*ps, r.errors);
  if (r.errors.empty()) {
    for (auto& e : fam->validate(r.spec)) r.errors.push_back(std::move(e));
  }
  r.ok = r.errors.empty();
  return r;
}

}  // namespace lockcore
