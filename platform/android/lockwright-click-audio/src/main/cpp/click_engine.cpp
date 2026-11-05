#include "click_engine.h"

#include <android/log.h>
#include <time.h>

#include <algorithm>
#include <cmath>

#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "LWAudio", __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, "LWAudio", __VA_ARGS__)

namespace lwaudio {

static int64_t now_ns() {
  timespec ts{};
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return static_cast<int64_t>(ts.tv_sec) * 1000000000LL + ts.tv_nsec;
}

// Cubic-free, allocation-at-load-time resampler (linear is enough for 1-3 ms clicks at 44.1/48 kHz).
static std::vector<float> convert(const std::vector<int16_t>& in, int32_t src_rate, int32_t dst_rate) {
  if (in.empty() || src_rate <= 0 || dst_rate <= 0) return {};
  const double ratio = static_cast<double>(src_rate) / dst_rate;
  const auto n = static_cast<size_t>(std::floor((in.size() - 1) / ratio)) + 1;
  std::vector<float> out(n);
  for (size_t i = 0; i < n; ++i) {
    const double p = i * ratio;
    const auto k = static_cast<size_t>(p);
    const double f = p - k;
    const float a = in[k] / 32768.f, b = in[std::min(k + 1, in.size() - 1)] / 32768.f;
    out[i] = static_cast<float>(a + (b - a) * f);
  }
  return out;
}

bool ClickEngine::open_stream(oboe::SharingMode mode) {
  oboe::AudioStreamBuilder b;
  b.setDirection(oboe::Direction::Output)
      ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
      ->setSharingMode(mode)
      ->setFormat(oboe::AudioFormat::Float)
      ->setChannelCount(oboe::ChannelCount::Mono)
      ->setUsage(oboe::Usage::Game)
      ->setContentType(oboe::ContentType::Sonification)
      ->setDataCallback(this)
      ->setErrorCallback(this);
  // No sample rate requested: the device's native rate avoids a resampler in the path.
  oboe::Result r = b.openStream(stream_);
  if (r != oboe::Result::OK) {
    error_ = std::string("openStream: ") + oboe::convertToText(r);
    LOGW("%s (sharing %d)", error_.c_str(), static_cast<int>(mode));
    return false;
  }
  // Two bursts: the usual lowest glitch-free setting; the callback adapts on xruns.
  stream_->setBufferSizeInFrames(stream_->getFramesPerBurst() * 2);
  const int32_t rate = stream_->getSampleRate();
  if (rate != rate_.load()) {
    rate_ = rate;
    for (int i = 0; i < kMaxSamples; ++i) {  // stream is not started yet: safe to rebuild the bank
      if (!src_pcm_[i].empty()) bank_[i] = convert(src_pcm_[i], src_rate_[i], rate);
    }
  }
  r = stream_->requestStart();
  if (r != oboe::Result::OK) {
    error_ = std::string("requestStart: ") + oboe::convertToText(r);
    stream_->close();
    stream_.reset();
    return false;
  }
  opens_++;
  LOGI("stream open: api %d, sharing %d, perf %d, rate %d, burst %d, buffer %d/%d",
       static_cast<int>(stream_->getAudioApi()), static_cast<int>(stream_->getSharingMode()),
       static_cast<int>(stream_->getPerformanceMode()), rate, stream_->getFramesPerBurst(),
       stream_->getBufferSizeInFrames(), stream_->getBufferCapacityInFrames());
  return true;
}

bool ClickEngine::start() {
  std::lock_guard<std::mutex> lock(open_mutex_);
  if (stream_) return true;
  // Exclusive first (lowest latency on AAudio MMAP devices), then shared.
  return open_stream(oboe::SharingMode::Exclusive) || open_stream(oboe::SharingMode::Shared);
}

void ClickEngine::stop() {
  std::lock_guard<std::mutex> lock(open_mutex_);
  if (stream_) {
    stream_->stop();
    stream_->close();
    stream_.reset();
  }
}

bool ClickEngine::load_sample(int32_t id, const int16_t* pcm, size_t frames, int32_t rate) {
  if (id < 0 || id >= kMaxSamples || pcm == nullptr || frames == 0) return false;
  std::lock_guard<std::mutex> lock(open_mutex_);
  ready_[id].store(false, std::memory_order_release);
  // A voice may still read the old buffer: silence it by waiting one burst cycle is overkill for a
  // spike; samples are loaded once at start before any play().
  src_pcm_[id].assign(pcm, pcm + frames);
  src_rate_[id] = rate;
  bank_[id] = convert(src_pcm_[id], rate, rate_.load());
  ready_[id].store(true, std::memory_order_release);
  return true;
}

bool ClickEngine::play(int32_t id, float gain, float pitch) {
  if (id < 0 || id >= kMaxSamples || !ready_[id].load(std::memory_order_acquire)) return false;
  Trigger t{id, gain, pitch, now_ns()};
  plays_++;
  if (!queue_.push(t)) {
    dropped_++;
    return false;
  }
  return true;
}

oboe::DataCallbackResult ClickEngine::onAudioReady(oboe::AudioStream* s, void* data, int32_t frames) {
  const int64_t t0 = now_ns();
  auto* out = static_cast<float*>(data);
  std::fill(out, out + frames, 0.f);
  Trigger t;
  while (queue_.pop(t)) {
    // Steal the voice closest to its end when all are busy.
    int slot = -1;
    double best = -1.0;
    for (int v = 0; v < kMaxVoices; ++v) {
      if (voices_[v].sample < 0) {
        slot = v;
        break;
      }
      const double left = bank_[voices_[v].sample].size() - voices_[v].pos;
      if (slot < 0 || left < best) {
        slot = v;
        best = left;
      }
    }
    if (voices_[slot].sample >= 0) stolen_++;
    voices_[slot] = Voice{t.sample, 0.0, t.gain, t.pitch};
    const uint32_t k = c2m_count_.fetch_add(1) % call_to_mix_ms_.size();
    call_to_mix_ms_[k] = static_cast<float>((t0 - t.t_call_ns) / 1e6);
  }
  for (auto& v : voices_) {
    if (v.sample < 0) continue;
    const std::vector<float>& b = bank_[v.sample];
    const double end = static_cast<double>(b.size() - 1);
    for (int32_t i = 0; i < frames; ++i) {
      if (v.pos >= end) {
        v.sample = -1;
        break;
      }
      const auto k = static_cast<size_t>(v.pos);
      const float f = static_cast<float>(v.pos - k);
      out[i] += (b[k] + (b[k + 1] - b[k]) * f) * v.gain;
      v.pos += v.step;
    }
  }
  for (int32_t i = 0; i < frames; ++i) out[i] = std::clamp(out[i], -1.f, 1.f);
  // Grow the buffer by one burst after an underrun (Oboe's recommended latency tuner, simplified).
  static int32_t last_xruns = 0;
  auto xr = s->getXRunCount();
  if (xr && xr.value() > last_xruns) {
    last_xruns = xr.value();
    const int32_t want = s->getBufferSizeInFrames() + s->getFramesPerBurst();
    if (want <= s->getBufferCapacityInFrames()) s->setBufferSizeInFrames(want);
  }
  const uint32_t k = cb_count_.fetch_add(1) % cb_us_.size();
  cb_us_[k] = static_cast<float>((now_ns() - t0) / 1e3);
  return oboe::DataCallbackResult::Continue;
}

void ClickEngine::onErrorAfterClose(oboe::AudioStream*, oboe::Result error) {
  // Headphones plugged, route change, another app took the exclusive stream: reopen.
  LOGW("stream closed: %s, reopening", oboe::convertToText(error));
  std::lock_guard<std::mutex> lock(open_mutex_);
  stream_.reset();
  for (auto& v : voices_) v.sample = -1;
  if (!open_stream(oboe::SharingMode::Exclusive)) open_stream(oboe::SharingMode::Shared);
}

static double pct(std::vector<float> v, double p) {
  if (v.empty()) return 0.0;
  std::sort(v.begin(), v.end());
  return v[static_cast<size_t>(p * (v.size() - 1))];
}

Stats ClickEngine::stats() {
  std::lock_guard<std::mutex> lock(open_mutex_);
  Stats s;
  if (stream_) {
    s.sample_rate = stream_->getSampleRate();
    s.frames_per_burst = stream_->getFramesPerBurst();
    s.buffer_size = stream_->getBufferSizeInFrames();
    s.buffer_capacity = stream_->getBufferCapacityInFrames();
    s.channels = stream_->getChannelCount();
    s.performance_mode = static_cast<int32_t>(stream_->getPerformanceMode());
    s.sharing_mode = static_cast<int32_t>(stream_->getSharingMode());
    s.audio_api = static_cast<int32_t>(stream_->getAudioApi());
    auto xr = stream_->getXRunCount();
    s.xruns = xr ? xr.value() : -1;
    auto lat = stream_->calculateLatencyMillis();
    s.latency_ms = lat ? lat.value() : -1.0;
  }
  const uint32_t n1 = std::min<uint32_t>(c2m_count_.load(), call_to_mix_ms_.size());
  std::vector<float> c2m(call_to_mix_ms_.begin(), call_to_mix_ms_.begin() + n1);
  s.call_to_mix_p50_ms = pct(c2m, 0.5);
  s.call_to_mix_p95_ms = pct(c2m, 0.95);
  const uint32_t n2 = std::min<uint32_t>(cb_count_.load(), cb_us_.size());
  s.callback_p95_us = pct(std::vector<float>(cb_us_.begin(), cb_us_.begin() + n2), 0.95);
  s.opens = opens_;
  s.dropped_triggers = dropped_;
  s.voices_stolen = stolen_;
  s.plays = plays_;
  s.error = error_;
  return s;
}

}  // namespace lwaudio
