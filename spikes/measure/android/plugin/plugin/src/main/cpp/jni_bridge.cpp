// JNI surface used by LockwrightLowLatencyAudio.kt. One engine per process.
#include <jni.h>

#include "click_engine.h"

using lwaudio::ClickEngine;

static ClickEngine& engine() {
  static ClickEngine e;
  return e;
}

#define FN(name) Java_org_woogitsugames_lockwright_measure_ClickNative_##name

extern "C" {

JNIEXPORT jboolean JNICALL FN(nativeStart)(JNIEnv*, jclass) { return engine().start(); }

JNIEXPORT void JNICALL FN(nativeStop)(JNIEnv*, jclass) { engine().stop(); }

JNIEXPORT jboolean JNICALL FN(nativeLoadSample)(JNIEnv* env, jclass, jint id, jbyteArray pcm, jint rate) {
  const jsize bytes = env->GetArrayLength(pcm);
  jbyte* p = env->GetByteArrayElements(pcm, nullptr);
  const bool ok = engine().load_sample(id, reinterpret_cast<const int16_t*>(p), static_cast<size_t>(bytes) / 2, rate);
  env->ReleaseByteArrayElements(pcm, p, JNI_ABORT);
  return ok;
}

JNIEXPORT jboolean JNICALL FN(nativePlay)(JNIEnv*, jclass, jint id, jfloat gain, jfloat pitch) {
  return engine().play(id, gain, pitch);
}

// [rate, burst, buffer, capacity, channels, perfMode, sharing, api, xruns, opens, dropped, stolen, plays]
// + doubles [latency_ms, c2m_p50, c2m_p95, cb_p95_us]
JNIEXPORT jlongArray JNICALL FN(nativeStatsInt)(JNIEnv* env, jclass) {
  const lwaudio::Stats s = engine().stats();
  const jlong v[] = {s.sample_rate, s.frames_per_burst, s.buffer_size, s.buffer_capacity, s.channels,
                     s.performance_mode, s.sharing_mode, s.audio_api, s.xruns, s.opens, s.dropped_triggers,
                     s.voices_stolen, s.plays};
  jlongArray a = env->NewLongArray(sizeof(v) / sizeof(v[0]));
  env->SetLongArrayRegion(a, 0, sizeof(v) / sizeof(v[0]), v);
  return a;
}

JNIEXPORT jdoubleArray JNICALL FN(nativeStatsReal)(JNIEnv* env, jclass) {
  const lwaudio::Stats s = engine().stats();
  const jdouble v[] = {s.latency_ms, s.call_to_mix_p50_ms, s.call_to_mix_p95_ms, s.callback_p95_us};
  jdoubleArray a = env->NewDoubleArray(4);
  env->SetDoubleArrayRegion(a, 0, 4, v);
  return a;
}

JNIEXPORT jstring JNICALL FN(nativeError)(JNIEnv* env, jclass) {
  return env->NewStringUTF(engine().stats().error.c_str());
}
}
