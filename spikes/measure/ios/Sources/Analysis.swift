import Foundation

/// A measured quantity: one sample per successful trial (ms) plus the number of rejected trials.
struct Metric {
    var samples: [Double] = []
    var rejected = 0
    var n: Int { samples.count }
    var p50: Double? { Stats.percentile(samples, 50) }
    var p95: Double? { Stats.percentile(samples, 95) }
}

enum Stats {
    /// Nearest-rank percentile.
    static func percentile(_ v: [Double], _ p: Double) -> Double? {
        guard !v.isEmpty else { return nil }
        let s = v.sorted()
        let rank = Int((p / 100 * Double(s.count)).rounded(.up))
        return s[max(0, min(s.count - 1, rank - 1))]
    }

    static func median(_ v: [Double]) -> Double? { percentile(v, 50) }
}

/// A sampled signal seen through closures, so the accelerometer (irregular timestamps) and the microphone
/// (buffers with host times) share one onset detector.
struct Track {
    let count: Int
    let time: (Int) -> Double
    let value: (Int) -> Double
    /// First index whose time is >= t (count when none).
    let index: (Double) -> Int
}

struct TapEvent {
    let touch: Double
    let haptic: Double?
    let audio: Double?
}

/// Everything recorded during one run (times in seconds of uptime).
struct RunData {
    var deviceClass: String
    var hapticCalls: [Double]
    var continuousWindow: (Double, Double)?
    var audioCalls: [Double]
    var taps: [TapEvent]
    var accel: [AccelSample]
    var accelDeliveryLagMs: Double?
    var mic: MicTrack?
    var micInvalidHostTimes: Int
    var inputLatencyMs: Double?
}

struct Outcome {
    var metrics: [String: Metric] = [:]
    var continuousMaxGapMs: Double?
    var accelHz: Double?
    var notes: [String] = []
}

enum Verdict: String {
    case pass, border, fail
    case noData = "no_data"
}

/// thresholds.json (bundled from spikes/measure/thresholds.json).
struct Thresholds {
    let root: [String: Any]

    static func load() -> Thresholds? {
        guard let url = Bundle.main.url(forResource: "thresholds", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return Thresholds(root: obj)
    }

    func rule(_ key: String, deviceClass: String) -> (pass: Double, fail: Double?)? {
        guard let node = root[key] as? [String: Any] else { return nil }
        let r = (node[deviceClass] as? [String: Any]) ?? node
        guard let pass = (r["pass"] as? NSNumber)?.doubleValue else { return nil }
        return (pass, (r["fail"] as? NSNumber)?.doubleValue)
    }

    /// SPEC.md: value <= pass -> pass; <= (fail ?? pass*1.25) -> border; otherwise fail.
    func verdict(_ key: String, deviceClass: String, value: Double?) -> Verdict {
        guard let v = value, let r = rule(key, deviceClass: deviceClass) else { return .noData }
        if v <= r.pass { return .pass }
        if v <= (r.fail ?? r.pass * 1.25) { return .border }
        return .fail
    }
}

enum Analysis {
    // MARK: - signal helpers

    static func lowerBound(_ a: [Double], _ x: Double) -> Int {
        var lo = 0, hi = a.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if a[mid] < x { lo = mid + 1 } else { hi = mid }
        }
        return lo
    }

    /// |acceleration| in m/s^2 minus its trailing 50 ms moving average (removes gravity), absolute value.
    static func accelTrack(_ s: [AccelSample]) -> Track {
        var t = [Double](), v = [Double]()
        t.reserveCapacity(s.count)
        v.reserveCapacity(s.count)
        let mags = s.map { ($0.x * $0.x + $0.y * $0.y + $0.z * $0.z).squareRoot() * 9.80665 }
        var start = 0
        var sum = 0.0
        for i in 0..<s.count {
            while start < i && s[start].t < s[i].t - 0.05 {
                sum -= mags[start]
                start += 1
            }
            let count = i - start
            let avg = count > 0 ? sum / Double(count) : mags[i]
            t.append(s[i].t)
            v.append(abs(mags[i] - avg))
            sum += mags[i]
        }
        return Track(count: t.count, time: { t[$0] }, value: { v[$0] }, index: { lowerBound(t, $0) })
    }

    /// Trailing moving average of |x| over `w` samples.
    static func envelope(_ x: [Float], w: Int) -> [Float] {
        var out = [Float](repeating: 0, count: x.count)
        var sum = 0.0
        for i in 0..<x.count {
            sum += Double(abs(x[i]))
            if i >= w { sum -= Double(abs(x[i - w])) }
            out[i] = Float(sum / Double(min(i + 1, w)))
        }
        return out
    }

    /// RBJ biquad high-pass (Q = 0.707). Used to find the 3 kHz click under the low-frequency knock of a tap.
    static func highpass(_ x: [Float], sampleRate: Double, cutoff: Double = 2000) -> [Float] {
        let w0 = 2 * Double.pi * cutoff / sampleRate
        let cw = cos(w0), alpha = sin(w0) / (2 * 0.7071)
        let a0 = 1 + alpha
        let b0 = (1 + cw) / 2 / a0, b1 = -(1 + cw) / a0, b2 = (1 + cw) / 2 / a0
        let a1 = -2 * cw / a0, a2 = (1 - alpha) / a0
        var y = [Float](repeating: 0, count: x.count)
        var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0
        for i in 0..<x.count {
            let x0 = Double(x[i])
            let y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            y[i] = Float(y0)
            x2 = x1; x1 = x0; y2 = y1; y1 = y0
        }
        return y
    }

    static func micTrack(_ m: MicTrack, values: [Float]) -> Track {
        Track(count: values.count, time: { m.time(at: $0) }, value: { Double(values[$0]) }, index: { m.index(at: $0) })
    }

    /// Threshold = median(noise window) * factor (at least minThr and extraThr); onset = first sample above it
    /// inside the search window. Returns (index, threshold).
    static func onset(_ tr: Track, noise: (Double, Double), search: (Double, Double),
                      factor: Double, minThr: Double, extraThr: Double = 0) -> (index: Int, thr: Double)? {
        guard tr.count > 0 else { return nil }
        let n0 = tr.index(noise.0), n1 = tr.index(noise.1)
        guard n1 - n0 >= 3 else { return nil }
        guard let med = Stats.median((n0..<n1).map(tr.value)) else { return nil }
        let thr = max(med * factor, minThr, extraThr)
        var i = tr.index(search.0)
        let end = tr.index(search.1)
        while i < end {
            if tr.value(i) > thr { return (index: i, thr: thr) }
            i += 1
        }
        return nil
    }

    static func maxValue(_ tr: Track, from a: Double, to b: Double) -> Double {
        var m = 0.0
        var i = tr.index(a)
        let end = tr.index(b)
        while i < end {
            m = max(m, tr.value(i))
            i += 1
        }
        return m
    }

    // MARK: - run

    static func run(_ d: RunData) -> Outcome {
        var out = Outcome()
        let acc = accelTrack(d.accel)

        // Achieved accelerometer rate from the median sample interval.
        var dt = 0.01
        if d.accel.count > 10 {
            var diffs = [Double]()
            diffs.reserveCapacity(d.accel.count)
            for i in 1..<d.accel.count { diffs.append(d.accel[i].t - d.accel[i - 1].t) }
            if let m = Stats.median(diffs.filter { $0 > 0 }), m > 0 {
                dt = m
                out.accelHz = (1 / m * 10).rounded() / 10
            }
        }
        if let hz = out.accelHz {
            out.notes.append(String(format: "akcelerometr: żądane 1000 Hz (interval 0.001 s), osiągnięte %.1f Hz; rozdzielczość czasu ok. %.0f ms (±%.0f ms) — haptic_call, haptic_tap, continuous_max_gap_ms i audio_haptic_sync są orientacyjne", hz, dt * 1000, dt * 500))
            if dt > 0.0025 {
                out.notes.append("akcelerometr wolniejszy niż 400 Hz: warunek 'energia >= 100 Hz przez >= 5 ms' przy rozdzielaniu stuknięcia i wibracji pominięty (niewykonalny); wibracja = pierwszy onset po wygaśnięciu stuknięcia i po wywołaniu API")
                out.notes.append("akcelerometr iPhone'a ma filtr dolnoprzepustowy przed próbkowaniem; drgania Taptic Engine mogą być słabo widoczne, stąd możliwe odrzucone próby")
            }
        } else {
            out.notes.append("akcelerometr: brak danych")
        }
        if let lag = d.accelDeliveryLagMs {
            out.notes.append(String(format: "zegar akcelerometru: średnio %.1f ms od CMAccelerometerData.timestamp do dostarczenia (CACurrentMediaTime) — wspólny zegar uptime", lag))
        }

        // Step 2: haptic_call = API call -> vibration onset (accelerometer).
        var hapticCall = Metric()
        for t0 in d.hapticCalls {
            if let o = onset(acc, noise: (t0 - 0.25, t0 - 0.01), search: (t0, t0 + 0.15), factor: 6, minThr: 0.02) {
                hapticCall.samples.append((acc.time(o.index) - t0) * 1000)
            } else {
                hapticCall.rejected += 1
            }
        }
        out.metrics["haptic_call"] = hapticCall

        // Step 3: longest gap in continuous vibration.
        if let win = d.continuousWindow, acc.count > 0 {
            let s = win.0, e = win.1
            let n0 = acc.index(s - 0.5), n1 = acc.index(s - 0.02)
            let a = acc.index(s + 0.15), b = acc.index(e - 0.05)
            if n1 - n0 >= 3, b - a >= 3, let med = Stats.median((n0..<n1).map(acc.value)) {
                let thr = max(med * 6, 0.02)
                var above = 0, run = 0, maxRun = 0
                for i in a..<b {
                    // Envelope over +-1 sample: at ~100 Hz the vibration is aliased and single samples can hit zero.
                    let env = max(acc.value(max(i - 1, 0)), acc.value(i), acc.value(min(i + 1, acc.count - 1)))
                    if env > thr {
                        above += 1
                        run = 0
                    } else {
                        run += 1
                        maxRun = max(maxRun, run)
                    }
                }
                if above > 0 {
                    out.continuousMaxGapMs = round2(Double(maxRun) * dt * 1000)
                }
                out.notes.append(String(format: "opór ciągły: drgania widoczne w %.0f%% próbek akcelerometru (obwiednia ±1 próbka)", Double(above) / Double(b - a) * 100))
            }
        }
        if out.continuousMaxGapMs == nil && d.continuousWindow != nil {
            out.notes.append("opór ciągły: drgań nie wykryto w akcelerometrze")
        }

        // Microphone tracks: broadband envelope (knock) and 2 kHz high-passed envelope (click).
        var audioCall = Metric()
        var audioTap = Metric()
        var hapticTap = Metric()
        var sync = Metric()
        var broad: Track?
        var high: Track?
        if let m = d.mic, !m.samples.isEmpty {
            let w = max(1, Int((m.sampleRate * 0.0005).rounded()))
            broad = micTrack(m, values: envelope(m.samples, w: w))
            high = micTrack(m, values: envelope(highpass(m.samples, sampleRate: m.sampleRate), w: w))
        }

        // Step 4: audio_call_fast = AVAudioPlayerNode schedule call -> click onset in the microphone.
        if let hp = high {
            for t0 in d.audioCalls {
                if let o = onset(hp, noise: (t0 - 0.25, t0 - 0.01), search: (t0, t0 + 0.3), factor: 8, minThr: 0.01) {
                    audioCall.samples.append((hp.time(o.index) - t0) * 1000)
                } else {
                    audioCall.rejected += 1
                }
            }
        } else {
            audioCall.rejected = d.audioCalls.count
        }

        // Step 5: taps.
        for ev in d.taps {
            var vibration: Double?
            if let hT = ev.haptic {
                var tapOnset: Double?
                if let o = onset(acc, noise: (ev.touch - 0.4, ev.touch - 0.1), search: (ev.touch - 0.1, ev.touch + 0.03),
                                 factor: 6, minThr: 0.02) {
                    let i = o.index, thr = o.thr
                    tapOnset = acc.time(i)
                    let limit = acc.index(hT + 0.15)
                    var j = i + 1
                    while j < limit && acc.value(j) > thr { j += 1 }   // wait for the tap to die down
                    var k = max(j, acc.index(max(acc.time(i) + 0.003, hT)))
                    while k < limit {
                        if acc.value(k) > thr {
                            vibration = acc.time(k)
                            break
                        }
                        k += 1
                    }
                }
                if let a = tapOnset, let v = vibration {
                    hapticTap.samples.append((v - a) * 1000)
                } else {
                    hapticTap.rejected += 1
                }
            }
            if let aT = ev.audio, let br = broad, let hp = high {
                var knock: Double?
                var clickOnset: Double?
                if let o = onset(br, noise: (ev.touch - 0.4, ev.touch - 0.1), search: (ev.touch - 0.1, ev.touch + 0.03),
                                 factor: 8, minThr: 0.01) {
                    let i = o.index
                    knock = br.time(i)
                    // The knock may still ring in the high band when the click is scheduled: raise the threshold.
                    let local = 3 * maxValue(hp, from: aT - 0.005, to: aT)
                    if let c = onset(hp, noise: (ev.touch - 0.4, ev.touch - 0.1),
                                     search: (max(br.time(i) + 0.003, aT), aT + 0.2),
                                     factor: 8, minThr: 0.01, extraThr: local) {
                        clickOnset = hp.time(c.index)
                    }
                }
                if let k = knock, let c = clickOnset {
                    audioTap.samples.append((c - k) * 1000)
                } else {
                    audioTap.rejected += 1
                }
                if let c = clickOnset, let v = vibration {
                    sync.samples.append(abs(c - v) * 1000)
                } else {
                    sync.rejected += 1
                }
            }
        }

        out.metrics["audio_call_fast"] = audioCall
        out.metrics["haptic_tap"] = hapticTap
        out.metrics["audio_tap"] = audioTap
        out.metrics["audio_haptic_sync"] = sync

        if d.mic != nil {
            let lat = d.inputLatencyMs.map { String(format: "%.1f", $0) } ?? "?"
            out.notes.append("mikrofon: czas próbki = AVAudioTime.hostTime bufora (AVAudioTime.seconds(forHostTime:), zegar jak CACurrentMediaTime), bez korekty o inputLatency (\(lat) ms); jeśli system nie wlicza jej w znacznik, audio_call_fast i audio_haptic_sync mogą być zawyżone o tę wartość; audio_tap (oba onsety w mikrofonie) nie zależy od tego")
            if d.micInvalidHostTimes > 0 {
                out.notes.append("mikrofon: \(d.micInvalidHostTimes) buforów bez ważnego hostTime — czas przybliżony z chwili dostarczenia")
            }
        }
        out.notes.append("iOS: audio_call_engine i audio_oboe_gain_ms nie dotyczą (jedna ścieżka: AVAudioEngine)")
        return out
    }
}
