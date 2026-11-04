import CoreHaptics
import QuartzCore

/// Spike 1 measurement core (docs/TECH.md §2.1, §4). H3 Core Haptics: a looping continuous player with
/// dynamic intensity/sharpness (sendParameters, <= 60 Hz) and transients in a SEPARATE player, so the
/// dynamic intensity of the continuous channel does not rescale the clicks (TECH §2.1 note).
/// The Godot module (godot-ios/haptics_probe_ios.mm) implements the same calls in Objective-C++.
final class HapticCore {
    private(set) var engine: CHHapticEngine?
    private var continuous: CHHapticAdvancedPatternPlayer?
    private(set) var resets = 0
    private(set) var stops = 0
    private(set) var lastResetMs = 0.0
    let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    init() { start() }

    private func start() {
        guard supported else { return }
        do {
            let e = try CHHapticEngine()
            e.playsHapticsOnly = true
            e.isAutoShutdownEnabled = false
            e.stoppedHandler = { [weak self] _ in self?.stops += 1 }
            e.resetHandler = { [weak self] in
                guard let self else { return }
                let t0 = CACurrentMediaTime()
                try? self.engine?.start()
                self.continuous = nil
                self.makeContinuous()
                self.resets += 1
                self.lastResetMs = (CACurrentMediaTime() - t0) * 1000
            }
            try e.start()
            engine = e
            makeContinuous()
        } catch {
            engine = nil
        }
    }

    private func makeContinuous() {
        guard let e = engine else { return }
        let ev = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)], relativeTime: 0, duration: 30)
        if let p = try? CHHapticPattern(events: [ev], parameters: []), let pl = try? e.makeAdvancedPlayer(with: p) {
            pl.loopEnabled = true
            continuous = pl
        }
    }

    /// Returns (call, return) in CACurrentMediaTime seconds (same clock as UITouch.timestamp: uptime).
    @discardableResult
    func transient(intensity: Float, sharpness: Float) -> (Double, Double) {
        let t0 = CACurrentMediaTime()
        guard let e = engine else { return (t0, t0) }
        let ev = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)], relativeTime: 0)
        if let p = try? CHHapticPattern(events: [ev], parameters: []), let pl = try? e.makePlayer(with: p) {
            try? pl.start(atTime: CHHapticTimeImmediate)
        }
        return (t0, CACurrentMediaTime())
    }

    func continuousStart() { try? continuous?.start(atTime: CHHapticTimeImmediate) }

    @discardableResult
    func continuousUpdate(intensity: Float, sharpness: Float) -> Double {
        let t0 = CACurrentMediaTime()
        try? continuous?.sendParameters([
            CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0),
            CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharpness - 0.3, relativeTime: 0)],
            atTime: CHHapticTimeImmediate)
        return t0
    }

    func continuousStop() { try? continuous?.stop(atTime: CHHapticTimeImmediate) }
}
