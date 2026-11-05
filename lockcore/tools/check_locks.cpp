// check_locks: verifier for authored lock files (lockwright.lock/1), e.g. the
// practice set in lockcore/practice/. Per file: parse (lock_from_json, which
// validates), oracle, scripted bot (hard gate, half the time limit), clumsy bot and
// feeling bot over N bot seeds (soft metrics, full time limit), plus the share of
// feeling runs that met false_set / counter_rotate / overset / drop / stress /
// detector_trip (does the lesson show its event?). Exit 1 if any file
// fails to parse, carries a key the parser ignores (or a value that does not read back
// the same), or the scripted bot fails.
//
//   check_locks [--feel N] [--csv FILE] <lock.json>...
#include <algorithm>
#include <cstdio>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include "lockcore/lockcore.hpp"

using namespace lockcore;

namespace {

std::string read_file(const std::string& path, bool& ok) {
  std::ifstream f(path, std::ios::binary);
  ok = static_cast<bool>(f);
  std::stringstream ss;
  ss << f.rdbuf();
  return ss.str();
}

std::int64_t median(std::vector<std::int64_t> v) {
  if (v.empty()) return 0;
  std::sort(v.begin(), v.end());
  return v[v.size() / 2];
}

// Steps as seconds with one decimal ("12.3").
std::string secs(std::int64_t steps) {
  char b[32];
  std::snprintf(b, sizeof b, "%lld.%lld", static_cast<long long>(steps / SIM_HZ),
                static_cast<long long>((steps % SIM_HZ) * 10 / SIM_HZ));
  return b;
}

// Keys of `file` that the parser did not take over into `canon` (ignored, i.e. a typo
// or an unknown field), and values that changed on the way (T20 format check).
void diff_spec(const json::Value& file, const json::Value& canon, const std::string& path, std::vector<std::string>& out) {
  if (file.is_object() && canon.is_object()) {
    for (const auto& [k, v] : file.members()) {
      const json::Value* c = canon.find(k);
      if (c == nullptr) out.push_back(path + "." + k + " ignored by the parser");
      else diff_spec(v, *c, path + "." + k, out);
    }
    return;
  }
  if (file.is_array() && canon.is_array()) {
    if (file.items().size() != canon.items().size()) {
      out.push_back(path + " length changed");
      return;
    }
    for (std::size_t i = 0; i < file.items().size(); ++i)
      diff_spec(file.items()[i], canon.items()[i], path + "[" + std::to_string(i) + "]", out);
    return;
  }
  if (json::write(file) != json::write(canon)) out.push_back(path + " reads back as " + json::write(canon));
}

// Events reported as "share of feeling-bot runs that met it" (lesson coverage).
struct Watch {
  EventKind kind;
  const char* tag;
};
const std::vector<Watch> kWatch = {{EventKind::false_set, "fs"},      {EventKind::counter_rotate, "cr"},
                                   {EventKind::overset, "ov"},        {EventKind::drop, "dr"},
                                   {EventKind::stress, "st"},         {EventKind::detector_trip, "dt"}};

}  // namespace

int main(int argc, char** argv) {
  std::uint64_t n_feel = 200;
  std::string csv_path;
  std::vector<std::string> files;
  for (int i = 1; i < argc; ++i) {
    const std::string a = argv[i];
    if ((a == "--feel" || a == "--csv") && i + 1 >= argc) {
      std::fprintf(stderr, "missing value for %s\n", a.c_str());
      return 2;
    }
    if (a == "--feel") {
      if (!field::parse_u64(argv[++i], n_feel) || n_feel == 0 || n_feel > 100000) {
        std::fprintf(stderr, "--feel needs 1..100000\n");
        return 2;
      }
    } else if (a == "--csv") {
      csv_path = argv[++i];
    } else {
      files.push_back(a);
    }
  }
  if (files.empty()) {
    std::fprintf(stderr, "usage: check_locks [--feel N] [--csv FILE] <lock.json>...\n");
    return 2;
  }
  std::ofstream csv;
  if (!csv_path.empty()) {
    csv.open(csv_path);
    if (!csv) {
      std::fprintf(stderr, "cannot open %s for writing\n", csv_path.c_str());
      return 2;
    }
    csv << "file,id,family,tier,parse,scripted_ok,scripted_steps,clumsy_ok_x1000,feel_runs,feel_ok_x1000,feel_p50_steps,"
           "time_limit_s,error,events_seen\n";
  }
  const FamilyRegistry& reg = FamilyRegistry::builtin();
  int bad = 0;
  std::printf("%-28s %-14s %4s %5s %8s %8s %7s %8s  %s\n", "id", "family", "tier", "parse", "scripted", "clumsy",
              "feel", "feel p50", "note");
  for (const std::string& path : files) {
    bool readable = false;
    const std::string text = read_file(path, readable);
    const LockParse lp = readable ? lock_from_json(text, reg) : LockParse{};
    std::string error;
    if (!readable) error = "cannot read file";
    else if (!lp.ok) error = lp.errors.empty() ? "parse error" : lp.errors.front().path + ": " + lp.errors.front().message;
    if (!error.empty()) {
      ++bad;
      std::printf("%-28s %-14s %4s %5s %8s %8s %7s %8s  %s\n", path.c_str(), "-", "-", "FAIL", "-", "-", "-", "-",
                  error.c_str());
      if (csv.is_open()) csv << path << ",,,," << 0 << ",0,0,0,0,0,0,0,\"" << error << "\"\n";
      continue;
    }
    const LockSpec& spec = lp.spec;
    {
      // Everything outside presentation must survive a parse / write round trip.
      std::vector<std::string> d;
      const json::Value file = json::parse(text).value;
      const json::Value canon = lock_to_value(spec, *reg.find(spec.family));
      for (const auto& [k, v] : file.members()) {
        if (k == "presentation") continue;
        const json::Value* c = canon.find(k);
        if (c == nullptr) d.push_back("." + k + " ignored by the parser");
        else diff_spec(v, *c, "." + k, d);
      }
      if (!d.empty()) {
        ++bad;
        std::printf("%-28s %-14s %4d %5s  %s\n", spec.id.c_str(), spec.family.c_str(), spec.difficulty.tier, "FAIL",
                    d.front().c_str());
        for (std::size_t i = 1; i < d.size(); ++i) std::printf("    %s\n", d[i].c_str());
        if (csv.is_open()) csv << path << "," << spec.id << "," << spec.family << "," << spec.difficulty.tier << ",0,0,0,0,0,0,0,0,\"" << d.front() << "\"\n";
        continue;
      }
    }
    const FamilyModule& fam = *reg.find(spec.family);
    const ToolSet tools = fam.required_tools(spec);
    const SolveReport s = fam.solver(spec, tools);
    std::int64_t c_ok = 0, f_ok = 0;
    std::vector<std::int64_t> seen_runs(kWatch.size(), 0);
    std::vector<std::int64_t> f_steps;
    std::string feel_fail;
    for (std::uint64_t k = 0; k < n_feel; ++k) {
      SolveOptions o;
      o.bot_seed = 1000 + k;
      const SolveReport c = fam.run_bot(BotKind::clumsy, spec, tools, o);
      c_ok += c.ok ? 1 : 0;
      o.record_inputs = true;
      const SolveReport f = fam.run_bot(BotKind::feeling, spec, tools, o);
      {
        // Which lesson events this run met: replay its inputs (same hash as the bot).
        LockSession rs(fam, spec, tools);
        std::uint32_t seen = 0;
        for (const InputFrame& in : f.inputs) {
          if (rs.finished()) break;
          for (const LockEvent& e : rs.step(in).events) seen |= 1u << static_cast<unsigned>(e.kind);
        }
        for (std::size_t j = 0; j < kWatch.size(); ++j) seen_runs[j] += (seen >> static_cast<unsigned>(kWatch[j].kind)) & 1u;
      }
      if (f.ok) {
        ++f_ok;
        f_steps.push_back(f.steps);
      } else if (feel_fail.empty()) {
        feel_fail = f.reason;
      }
    }
    if (!s.ok) {
      ++bad;
      error = "scripted: " + s.reason;
    }
    const std::int64_t n = static_cast<std::int64_t>(n_feel);
    const std::int64_t c_x1000 = c_ok * 1000 / n, f_x1000 = f_ok * 1000 / n;
    char cbuf[48], fbuf[48];
    std::snprintf(cbuf, sizeof cbuf, "%lld.%lld%%", static_cast<long long>(c_x1000 / 10), static_cast<long long>(c_x1000 % 10));
    std::snprintf(fbuf, sizeof fbuf, "%lld.%lld%%", static_cast<long long>(f_x1000 / 10), static_cast<long long>(f_x1000 % 10));
    std::string events;
    for (std::size_t j = 0; j < kWatch.size(); ++j)
      if (seen_runs[j] > 0) {
        const std::int64_t pc = seen_runs[j] * 100 / n;
        events += std::string(events.empty() ? "" : " ") + kWatch[j].tag + " " + (pc == 0 ? "<1" : std::to_string(pc)) + "%";
      }
    const std::string note = !error.empty() ? error : (f_ok < n ? "feel e.g. " + feel_fail + "; " : "") + events;
    std::printf("%-28s %-14s %4d %5s %8s %8s %7s %8s  %s\n", spec.id.c_str(), spec.family.c_str(), spec.difficulty.tier,
                "ok", s.ok ? (secs(s.steps) + "s").c_str() : "FAIL", cbuf, fbuf, (secs(median(f_steps)) + "s").c_str(),
                note.c_str());
    if (csv.is_open()) {
      csv << path << "," << spec.id << "," << spec.family << "," << spec.difficulty.tier << ",1," << (s.ok ? 1 : 0) << ","
          << (s.ok ? s.steps : 0) << "," << c_x1000 << "," << n << "," << f_x1000 << "," << median(f_steps) << ","
          << spec.difficulty.time_limit_s << ",\"" << error << "\",\"" << events << "\"\n";
    }
  }
  std::printf("%d of %zu files failed\n", bad, files.size());
  return bad == 0 ? 0 : 1;
}
