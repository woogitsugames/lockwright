import AVFoundation
import CoreMotion
import QuartzCore
import UIKit

/// One accelerometer sample. `t` is CMLogItem.timestamp (seconds of system uptime, the same clock as
/// CACurrentMediaTime and UITouch.timestamp); x/y/z in g.
struct AccelSample {
    let t: Double
    let x: Double
    let y: Double
    let z: Double
}

/// Records the accelerometer at the fastest rate Core Motion gives (requested 1 kHz; iPhones usually deliver ~100 Hz).
final class AccelRecorder {
    private let manager = CMMotionManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .userInteractive
        return q
    }()
    private let lock = NSLock()
    private var samples: [AccelSample] = []
    private var deliveryLagSum = 0.0
    private var deliveryLagCount = 0

    var available: Bool { manager.isAccelerometerAvailable }

    func start() {
        guard manager.isAccelerometerAvailable, !manager.isAccelerometerActive else { return }
        manager.accelerometerUpdateInterval = 0.001
        manager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let self, let d = data else { return }
            let now = CACurrentMediaTime()
            self.lock.lock()
            self.samples.append(AccelSample(t: d.timestamp, x: d.acceleration.x, y: d.acceleration.y, z: d.acceleration.z))
            self.deliveryLagSum += now - d.timestamp
            self.deliveryLagCount += 1
            self.lock.unlock()
        }
    }

    func stop() {
        if manager.isAccelerometerActive { manager.stopAccelerometerUpdates() }
    }

    func clear() {
        lock.lock()
        samples.removeAll()
        deliveryLagSum = 0
        deliveryLagCount = 0
        lock.unlock()
    }

    /// Samples sorted by time plus the mean delivery lag in ms (CACurrentMediaTime at delivery - sample timestamp).
    func snapshot() -> (samples: [AccelSample], meanDeliveryLagMs: Double?) {
        lock.lock()
        let s = samples
        let lag = deliveryLagCount > 0 ? deliveryLagSum / Double(deliveryLagCount) * 1000 : nil
        lock.unlock()
        return (s.sorted { $0.t < $1.t }, lag)
    }
}

/// Microphone samples (channel 0) with the uptime time of each buffer's first frame.
struct MicTrack {
    let sampleRate: Double
    let samples: [Float]
    /// (index of the first sample of a buffer, its time in seconds of uptime), sorted.
    let chunkIndex: [Int]
    let chunkTime: [Double]

    /// Last chunk whose first index <= i.
    private func chunk(forIndex i: Int) -> Int {
        var lo = 0, hi = chunkIndex.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if chunkIndex[mid] <= i { lo = mid } else { hi = mid - 1 }
        }
        return lo
    }

    func time(at i: Int) -> Double {
        guard !chunkIndex.isEmpty else { return 0 }
        let c = chunk(forIndex: i)
        return chunkTime[c] + Double(i - chunkIndex[c]) / sampleRate
    }

    /// First sample index whose time is >= t (clamped to 0...count).
    func index(at t: Double) -> Int {
        guard !chunkTime.isEmpty else { return 0 }
        if t <= chunkTime[0] { return 0 }
        var lo = 0, hi = chunkTime.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if chunkTime[mid] <= t { lo = mid } else { hi = mid - 1 }
        }
        let end = lo + 1 < chunkIndex.count ? chunkIndex[lo + 1] : samples.count
        let i = chunkIndex[lo] + Int(((t - chunkTime[lo]) * sampleRate).rounded(.up))
        return min(i, end)
    }
}

final class MicRecorder {
    private let lock = NSLock()
    private var samples: [Float] = []
    private var chunkIndex: [Int] = []
    private var chunkTime: [Double] = []
    private var sampleRate = 48000.0
    private(set) var invalidHostTimes = 0

    func append(time: Double, sampleRate sr: Double, data: [Float], hostTimeValid: Bool) {
        lock.lock()
        sampleRate = sr
        chunkIndex.append(samples.count)
        chunkTime.append(time)
        samples.append(contentsOf: data)
        if !hostTimeValid { invalidHostTimes += 1 }
        lock.unlock()
    }

    func clear() {
        lock.lock()
        samples.removeAll()
        chunkIndex.removeAll()
        chunkTime.removeAll()
        invalidHostTimes = 0
        lock.unlock()
    }

    func snapshot() -> MicTrack {
        lock.lock()
        let m = MicTrack(sampleRate: sampleRate, samples: samples, chunkIndex: chunkIndex, chunkTime: chunkTime)
        lock.unlock()
        return m
    }
}

/// "Fast path" audio on iOS: AVAudioEngine with a player node for the click and an input tap for the microphone.
final class AudioProbe {
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let mic = MicRecorder()
    private var click: AVAudioPCMBuffer?
    private var attached = false
    private(set) var running = false

    func start() throws {
        if running { return }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try? session.setPreferredIOBufferDuration(0.005)
        // Without this, iOS mutes haptics while the microphone is recording (needed for the tap step).
        try? session.setAllowHapticsAndSystemSoundsDuringRecording(true)
        try session.setActive(true)

        let input = engine.inputNode
        let inFormat = input.outputFormat(forBus: 0)
        guard inFormat.sampleRate > 0, inFormat.channelCount > 0 else {
            throw NSError(domain: "LWMeasure", code: 1, userInfo: [NSLocalizedDescriptionKey: "no input format"])
        }
        let sr = session.sampleRate > 0 ? session.sampleRate : 48000
        guard let monoFormat = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1) else {
            throw NSError(domain: "LWMeasure", code: 2, userInfo: [NSLocalizedDescriptionKey: "no output format"])
        }
        if !attached {
            engine.attach(player)
            attached = true
        }
        engine.connect(player, to: engine.mainMixerNode, format: monoFormat)
        click = AudioProbe.makeClick(format: monoFormat)

        input.installTap(onBus: 0, bufferSize: 256, format: inFormat) { [weak self] buffer, when in
            guard let self, let channels = buffer.floatChannelData else { return }
            let n = Int(buffer.frameLength)
            guard n > 0 else { return }
            let data = Array(UnsafeBufferPointer(start: channels[0], count: n))
            let rate = buffer.format.sampleRate
            let valid = when.isHostTimeValid
            // AVAudioTime.seconds(forHostTime:) is on the mach_absolute_time clock = CACurrentMediaTime.
            let t = valid ? AVAudioTime.seconds(forHostTime: when.hostTime) : CACurrentMediaTime() - Double(n) / rate
            self.mic.append(time: t, sampleRate: rate, data: data, hostTimeValid: valid)
        }
        engine.prepare()
        try engine.start()
        player.play()
        running = true
    }

    func stop() {
        guard running else { return }
        player.stop()
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        running = false
    }

    /// Schedules the click to play immediately. Returns the call time (CACurrentMediaTime) or nil.
    func playClick() -> Double? {
        guard running, let b = click else { return nil }
        let t0 = CACurrentMediaTime()
        player.scheduleBuffer(b, completionHandler: nil)
        return t0
    }

    func sessionInfo() -> [String: Any] {
        let s = AVAudioSession.sharedInstance()
        let sr = s.sampleRate
        return [
            "sample_rate": Int(sr.rounded()),
            "frames_per_burst": Int((s.ioBufferDuration * sr).rounded()),
            "io_buffer_duration_ms": round2(s.ioBufferDuration * 1000),
            "output_latency_ms": round2(s.outputLatency * 1000),
            "input_latency_ms": round2(s.inputLatency * 1000),
            "estimated_output_latency_ms": round2((s.outputLatency + s.ioBufferDuration) * 1000),
            "path": "AVAudioEngine (playAndRecord, measurement, defaultToSpeaker)",
        ]
    }

    /// 1 ms 3 kHz burst (raised-cosine attack, then hold) followed by a ~5 ms exponential decay.
    static func makeClick(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sr = format.sampleRate
        let frames = AVAudioFrameCount(sr * 0.006)
        guard let b = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames), let ch = b.floatChannelData else { return nil }
        b.frameLength = frames
        let attack = 0.0003, burst = 0.001, tau = 0.001
        for i in 0..<Int(frames) {
            let t = Double(i) / sr
            let env: Double
            if t < attack {
                env = 0.5 - 0.5 * cos(Double.pi * t / attack)
            } else if t < burst {
                env = 1.0
            } else {
                env = exp(-(t - burst) / tau)
            }
            ch[0][i] = Float(0.8 * env * sin(2 * Double.pi * 3000 * t))
        }
        return b
    }
}

enum DeviceInfo {
    /// e.g. "iPhone14,6". On the simulator the simulated model is used.
    static func modelIdentifier() -> String {
        if let sim = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return sim }
        var u = utsname()
        uname(&u)
        let mirror = Mirror(reflecting: u.machine)
        var id = ""
        for child in mirror.children {
            guard let v = child.value as? Int8, v != 0 else { continue }
            id.append(Character(UnicodeScalar(UInt8(bitPattern: v))))
        }
        return id
    }

    /// iPhone SE 2 (iPhone12,8) / SE 3 (iPhone14,6), or any 750x1334 screen -> iphone_se; else iphone_new.
    @MainActor
    static func detectClass(_ model: String) -> String {
        if ["iPhone12,8", "iPhone14,6"].contains(model) { return "iphone_se" }
        let nb = UIScreen.main.nativeBounds
        if Int(max(nb.width, nb.height)) == 1334 { return "iphone_se" }
        return "iphone_new"
    }
}

func round2(_ x: Double) -> Double { (x * 100).rounded() / 100 }
