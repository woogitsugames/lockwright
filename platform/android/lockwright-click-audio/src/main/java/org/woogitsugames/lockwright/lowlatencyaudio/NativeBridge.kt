package org.woogitsugames.lockwright.lowlatencyaudio

/** JNI entry points of liblwaudio.so (Oboe click engine). */
internal object NativeBridge {
    init {
        System.loadLibrary("lwaudio")
    }

    @JvmStatic external fun nativeStart(): Boolean
    @JvmStatic external fun nativeStop()
    @JvmStatic external fun nativeLoadSample(id: Int, pcm: ByteArray, rate: Int): Boolean
    @JvmStatic external fun nativePlay(id: Int, gain: Float, pitch: Float): Boolean
    @JvmStatic external fun nativeStatsInt(): LongArray
    @JvmStatic external fun nativeStatsReal(): DoubleArray
    @JvmStatic external fun nativeError(): String
}
