// Low-latency click engine for spike 3 (docs/TECH.md §1.6, §4): Oboe/AAudio output, preallocated
// PCM samples, triggers from the game thread through a lock-free queue, mixing in the callback.
#pragma once

#include <oboe/Oboe.h>

#include <array>
#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace lwaudio {

// Single-producer / single-consumer ring of fixed-size commands. No allocation, no locks.
template <typename T, size_t N>
class SpscRing {
 public:
  bool push(const T& v) {
    const size_t h = head_.load(std::memory_order_relaxed);
    const size_t n = (h + 1) % N;
    if (n == tail_.load(std::memory_order_acquire)) return false;
    buf_[h] = v;
    head_.store(n, std::memory_order_release);
    return true;
  }
  bool pop(T& v) {
    const size_t t = tail_.load(std::memory_order_relaxed);
    if (t == head_.load(std::memory_order_acquire)) return false;
    v = buf_[t];
    tail_.store((t + 1) % N, std::memory_order_release);
    return true;
  }

 private:
  std::array<T, N> buf_{};
  std::atomic<size_t> head_{0}, tail_{0};
};

struct Trigger {
  int32_t sample = -1;
  float gain = 1.f;
  float pitch = 1.f;
  int64_t t_call_ns = 0;  // CLOCK_MONOTONIC when play() was called
};

struct Voice {
  int32_t sample = -1;
  double pos = 0.0;
  float gain = 1.f;
  float step = 1.f;
};

struct Stats {
  int32_t sample_rate = 0, frames_per_burst = 0, buffer_size = 0, buffer_capacity = 0, channels = 0;
  int32_t performance_mode = 0, sharing_mode = 0, audio_api = 0;  // oboe enums
  int32_t xruns = 0, opens = 0, dropped_triggers = 0, voices_stolen = 0;
  double latency_ms = -1.0;          // oboe calculateLatencyMillis (AAudio timestamps)
  double call_to_mix_p50_ms = 0.0;   // play() -> first callback that mixes the voice
  double call_to_mix_p95_ms = 0.0;
  double callback_p95_us = 0.0;      // time spent in the callback
  int64_t plays = 0;
  std::string error;
};

class ClickEngine : public oboe::AudioStreamDataCallback, public oboe::AudioStreamErrorCallback {
 public:
  static constexpr int kMaxSamples = 32;
  static constexpr int kMaxVoices = 16;

  bool start();
  void stop();
  // Called on a loading thread: converts int16 PCM at `rate` to float at the stream rate.
  bool load_sample(int32_t id, const int16_t* pcm, size_t frames, int32_t rate);
  // Real-time safe from the game thread: no allocation, no lock.
  bool play(int32_t id, float gain, float pitch);
  Stats stats();

  oboe::DataCallbackResult onAudioReady(oboe::AudioStream* s, void* data, int32_t frames) override;
  void onErrorAfterClose(oboe::AudioStream* s, oboe::Result error) override;

 private:
  bool open_stream(oboe::SharingMode mode);

  std::shared_ptr<oboe::AudioStream> stream_;
  std::mutex open_mutex_;
  std::atomic<int32_t> rate_{48000};
  // Sample bank: written only before the slot is published (ready flag), read in the callback.
  std::array<std::vector<float>, kMaxSamples> bank_;
  std::array<std::atomic<bool>, kMaxSamples> ready_{};
  std::array<int32_t, kMaxSamples> src_rate_{};
  std::array<std::vector<int16_t>, kMaxSamples> src_pcm_;  // kept to re-convert after a rate change
  SpscRing<Trigger, 256> queue_;
  std::array<Voice, kMaxVoices> voices_{};
  // Statistics written by the callback, read by stats() (approximate, lock-free).
  std::array<float, 512> call_to_mix_ms_{};
  std::atomic<uint32_t> c2m_count_{0};
  std::array<float, 512> cb_us_{};
  std::atomic<uint32_t> cb_count_{0};
  std::atomic<int32_t> dropped_{0}, stolen_{0}, opens_{0};
  std::atomic<int64_t> plays_{0};
  std::string error_;
};

}  // namespace lwaudio
