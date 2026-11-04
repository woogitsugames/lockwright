import SwiftUI
import UIKit

/// Native control app for spike 1: same effect as the Godot probe, no engine in between.
/// Tap = transient; horizontal drag = continuous resistance (intensity = x / width * 0.55).
@main
struct LWHapticsNativeApp: App {
    var body: some Scene { WindowGroup { ProbeView().ignoresSafeArea() } }
}

final class Probe: ObservableObject {
    let core = HapticCore()
    @Published var text = ""
    @Published var flash = false
    private var lat: [Double] = []
    private var lastUpdate = 0.0
    private let pl = Locale.current.language.languageCode?.identifier == "pl"

    func down(touchTime: TimeInterval, x: CGFloat, width: CGFloat) {
        let (call, _) = core.transient(intensity: 0.9, sharpness: 0.85)
        lat.append((call - touchTime) * 1000)
        core.continuousStart()
        core.continuousUpdate(intensity: Float(x / width) * 0.55, sharpness: 0.3)
        flash = true
        refresh()
    }

    func move(x: CGFloat, width: CGFloat) {
        let now = CACurrentMediaTime()
        if now - lastUpdate < 1.0 / 60.0 { return }   // TECH §2.1: sendParameters at most 60 Hz
        lastUpdate = now
        core.continuousUpdate(intensity: Float(x / width) * 0.55, sharpness: 0.3)
    }

    func up() {
        core.continuousStop()
        flash = false
    }

    func refresh() {
        let s = lat.sorted()
        let p50 = s.isEmpty ? 0 : s[s.count / 2]
        let p95 = s.isEmpty ? 0 : s[min(s.count - 1, s.count * 95 / 100)]
        text = (pl ? "Natywna aplikacja kontrolna (narzędzie testowe, nie gra)\n" : "Native control app (test tool, not a game)\n")
            + "Core Haptics: \(core.supported ? "H3" : "H0 (no haptics)"), resets \(core.resets), stops \(core.stops)\n"
            + String(format: "%@ %d: touch -> CH call p50 %.2f / p95 %.2f ms\n", pl ? "dotknięcia" : "taps", lat.count, p50, p95)
            + (pl ? "przesuń w poziomie: opór ciągły" : "drag horizontally: continuous resistance")
        NSLog("LWHapticsNative tap touch_to_call_ms=%.3f", lat.last ?? 0)
    }
}

/// UIKit view: UITouch.timestamp is on the same clock as CACurrentMediaTime (system uptime).
final class TouchView: UIView {
    var probe: Probe?
    override func touchesBegan(_ t: Set<UITouch>, with e: UIEvent?) {
        guard let u = t.first else { return }
        probe?.down(touchTime: u.timestamp, x: u.location(in: self).x, width: bounds.width)
    }
    override func touchesMoved(_ t: Set<UITouch>, with e: UIEvent?) {
        guard let u = t.first else { return }
        probe?.move(x: u.location(in: self).x, width: bounds.width)
    }
    override func touchesEnded(_ t: Set<UITouch>, with e: UIEvent?) { probe?.up() }
    override func touchesCancelled(_ t: Set<UITouch>, with e: UIEvent?) { probe?.up() }
}

struct TouchArea: UIViewRepresentable {
    let probe: Probe
    func makeUIView(context: Context) -> TouchView { let v = TouchView(); v.probe = probe; v.backgroundColor = .clear; return v }
    func updateUIView(_ v: TouchView, context: Context) {}
}

struct ProbeView: View {
    @StateObject var probe = Probe()
    var body: some View {
        ZStack(alignment: .topLeading) {
            (probe.flash ? Color(red: 0.92, green: 0.90, blue: 0.85) : Color(red: 0.10, green: 0.094, blue: 0.086))
            Text(probe.text).font(.system(size: 15)).foregroundColor(Color(red: 0.94, green: 0.92, blue: 0.88))
                .padding(.top, 60).padding(.horizontal, 16)
            TouchArea(probe: probe)
        }
        .onAppear { probe.refresh() }
    }
}
