import Foundation

/// Builds the result file in the schema of spikes/measure/SPEC.md ("lockwright.measure/1").
enum Report {
    /// Verdict key in thresholds.json -> how to get its value from the outcome.
    static let verdictKeys = ["haptic_call_p95_ms", "haptic_tap_p95_ms", "audio_tap_p95_ms",
                              "continuous_max_gap_ms", "audio_haptic_sync_ms"]

    static func value(for key: String, _ o: Outcome) -> Double? {
        switch key {
        case "haptic_call_p95_ms": return o.metrics["haptic_call"]?.p95
        case "haptic_tap_p95_ms": return o.metrics["haptic_tap"]?.p95
        case "audio_tap_p95_ms": return o.metrics["audio_tap"]?.p95
        case "continuous_max_gap_ms": return o.continuousMaxGapMs
        case "audio_haptic_sync_ms": return o.metrics["audio_haptic_sync"]?.p95
        default: return nil
        }
    }

    static func verdicts(_ o: Outcome, thresholds: Thresholds?, deviceClass: String) -> [String: Verdict] {
        var v: [String: Verdict] = [:]
        for k in verdictKeys {
            v[k] = thresholds?.verdict(k, deviceClass: deviceClass, value: value(for: k, o)) ?? .noData
        }
        return v
    }

    static func metricJSON(_ m: Metric) -> [String: Any] {
        [
            "n": m.n,
            "rejected": m.rejected,
            "p50_ms": m.p50.map { round2($0) as Any } ?? NSNull(),
            "p95_ms": m.p95.map { round2($0) as Any } ?? NSNull(),
            "samples_ms": m.samples.map { round2($0) },
        ]
    }

    static func build(outcome o: Outcome, verdicts: [String: Verdict], deviceClass: String, model: String, osVersion: String,
                      hapticTier: String, audioInfo: [String: Any]?, extraNotes: [String], date: Date) -> (Data, String)? {
        var metrics: [String: Any] = [:]
        for (k, m) in o.metrics { metrics[k] = metricJSON(m) }
        if let gap = o.continuousMaxGapMs { metrics["continuous_max_gap_ms"] = gap }

        var device: [String: Any] = [
            "platform": "ios",
            "manufacturer": "Apple",
            "model": model,
            "os": osVersion,
            "class": deviceClass,
            "haptic_tier": hapticTier,
            "accel_hz": o.accelHz.map { $0 as Any } ?? NSNull(),
        ]
        if let a = audioInfo { device["audio"] = a }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        iso.timeZone = TimeZone(identifier: "UTC")
        let root: [String: Any] = [
            "schema": "lockwright.measure/1",
            "app": "ios-native",
            "app_version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.2.0",
            "created_utc": iso.string(from: date),
            "device": device,
            "metrics": metrics,
            "verdicts": verdicts.mapValues { $0.rawValue },
            "notes": extraNotes + o.notes,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        else { return nil }

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "yyyyMMdd-HHmm"
        let safeModel = model.map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
        return (data, "lockwright-pomiar-ios-\(safeModel)-\(fmt.string(from: date)).json")
    }

    static func save(_ data: Data, name: String) -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let url = dir.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
