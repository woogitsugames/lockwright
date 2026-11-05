import AVFoundation
import SwiftUI
import UIKit

/// Measurement app for the owner (D-33): a step-by-step wizard following spikes/measure/SPEC.md.
@main
struct LWMeasureApp: App {
    @StateObject private var wizard = Wizard()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(wizard)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Palette (warm dark, no green/red: verdicts rely on words and shapes)

enum Palette {
    static let bg = Color(red: 0x1A / 255, green: 0x18 / 255, blue: 0x16 / 255)
    static let surface = Color(red: 0x27 / 255, green: 0x23 / 255, blue: 0x1F / 255)
    static let text = Color(red: 0xF0 / 255, green: 0xEB / 255, blue: 0xE1 / 255)
    static let muted = Color(red: 0xB8 / 255, green: 0xAF / 255, blue: 0xA2 / 255)
    static let accent = Color(red: 0xE3 / 255, green: 0xD5 / 255, blue: 0xB8 / 255)
    static let accentPressed = Color(red: 0xC9 / 255, green: 0xBB / 255, blue: 0x9E / 255)
    static let line = Color(red: 0x4A / 255, green: 0x43 / 255, blue: 0x3B / 255)
    static let ochre = Color(red: 0xD9 / 255, green: 0xA4 / 255, blue: 0x41 / 255)
    static let clay = Color(red: 0xC7 / 255, green: 0x89 / 255, blue: 0x5E / 255)
    static let taupe = Color(red: 0x8F / 255, green: 0x87 / 255, blue: 0x7C / 255)
}

extension Verdict {
    var word: String {
        switch self {
        case .pass: return L.t("verdict_pass")
        case .border: return L.t("verdict_border")
        case .fail: return L.t("verdict_fail")
        case .noData: return L.t("verdict_no_data")
        }
    }

    var symbol: String {
        switch self {
        case .pass: return "checkmark.circle"
        case .border: return "exclamationmark.triangle"
        case .fail: return "xmark.octagon"
        case .noData: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .pass: return Palette.accent
        case .border: return Palette.ochre
        case .fail: return Palette.clay
        case .noData: return Palette.taupe
        }
    }
}

struct ResultRow: Identifiable {
    let id: String
    let title: String
    let detail: String
    let verdict: Verdict?   // nil = informational metric without a threshold
}

// MARK: - Wizard state machine

@MainActor
final class Wizard: ObservableObject {
    enum Step { case start, prep, haptic, continuous, audio, taps, analyzing, results }

    static let hapticTrials = 30
    static let audioTrials = 30
    static let tapTrials = 20
    static let continuousSeconds = 4

    @Published var step: Step = .start
    @Published var deviceClass: String
    @Published var running = false
    @Published var waitingHands = false
    @Published var progress = 0
    @Published var total = 0
    @Published var flash = false
    @Published var notice: String?
    @Published var rows: [ResultRow] = []
    @Published var fileURL: URL?

    let detectedClass: String
    let model: String
    let haptics = HapticCore()
    let accel = AccelRecorder()
    let audio = AudioProbe()
    let thresholds = Thresholds.load()

    private var hapticCalls: [Double] = []
    private var continuousWindow: (Double, Double)?
    private var audioCalls: [Double] = []
    private var taps: [TapEvent] = []
    private var micGranted = false
    private var lastTap = 0.0
    private var extraNotes: [String] = []

    init() {
        let m = DeviceInfo.modelIdentifier()
        let c = DeviceInfo.detectClass(m)
        model = m
        detectedClass = c
        deviceClass = c
    }

    var classLabel: String { L.t(deviceClass == "iphone_se" ? "class_iphone_se" : "class_iphone_new") }

    private func after(_ seconds: Double, _ work: @escaping @MainActor () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            MainActor.assumeIsolated { work() }
        }
    }

    func begin() { step = .prep }

    func prepDone() {
        UIApplication.shared.isIdleTimerDisabled = true
        accel.start()
        if haptics.supported {
            step = .haptic
        } else {
            notice = L.t("no_haptics")
            extraNotes.append("Core Haptics niedostępne (H0): kroki 2-3 pominięte")
            step = .audio
        }
    }

    /// Short pause after pressing Start so the finger leaves the phone before the measurement.
    private func startRunning(total: Int, then work: @escaping @MainActor () -> Void) {
        running = true
        waitingHands = true
        progress = 0
        self.total = total
        after(1.5) {
            self.waitingHands = false
            work()
        }
    }

    func runHaptic() {
        hapticCalls.removeAll()
        startRunning(total: Wizard.hapticTrials) {
            for i in 0..<Wizard.hapticTrials {
                self.after(0.4 * Double(i)) {
                    let (call, _) = self.haptics.transient(intensity: 1.0, sharpness: 0.8)
                    self.hapticCalls.append(call)
                    self.progress = i + 1
                }
            }
            self.after(0.4 * Double(Wizard.hapticTrials) + 0.3) {
                self.running = false
                self.step = .continuous
            }
        }
    }

    func runContinuous() {
        startRunning(total: Wizard.continuousSeconds) {
            let start = CACurrentMediaTime()
            self.haptics.continuousStart()
            self.haptics.continuousUpdate(intensity: 1.0, sharpness: 0.3)
            for s in 1...Wizard.continuousSeconds {
                self.after(Double(s - 1)) { self.progress = s }
            }
            self.after(Double(Wizard.continuousSeconds)) {
                self.haptics.continuousStop()
                self.continuousWindow = (start, CACurrentMediaTime())
                self.after(0.6) {
                    self.running = false
                    self.step = .audio
                }
            }
        }
    }

    func runAudio() {
        running = true
        waitingHands = true
        AVAudioApplication.requestRecordPermission { granted in
            Task { @MainActor in
                self.audioPermission(granted)
            }
        }
    }

    private func audioPermission(_ granted: Bool) {
        micGranted = false
        if granted {
            do {
                try audio.start()
                micGranted = true
            } catch {
                notice = L.t("mic_error")
                extraNotes.append("mikrofon: nie udało się uruchomić AVAudioEngine (\(error.localizedDescription))")
            }
        } else {
            notice = L.t("mic_denied")
            extraNotes.append("mikrofon: brak zgody, pomiary dźwięku pominięte")
        }
        guard micGranted else {
            running = false
            step = .taps
            progress = 0
            total = Wizard.tapTrials
            return
        }
        audio.mic.clear()
        audioCalls.removeAll()
        startRunning(total: Wizard.audioTrials) {
            for i in 0..<Wizard.audioTrials {
                self.after(0.4 * Double(i)) {
                    if let t = self.audio.playClick() { self.audioCalls.append(t) }
                    self.progress = i + 1
                }
            }
            self.after(0.4 * Double(Wizard.audioTrials) + 0.4) {
                self.running = false
                self.progress = 0
                self.total = Wizard.tapTrials
                self.step = .taps
            }
        }
    }

    /// Called from the touch view with UITouch.timestamp (uptime clock, same as CACurrentMediaTime).
    func tapped(at touchTime: TimeInterval) {
        guard step == .taps, progress < Wizard.tapTrials else { return }
        if touchTime - lastTap < 0.5 { return }   // too fast: the previous vibration may still ring
        lastTap = touchTime
        let h: Double? = haptics.supported ? haptics.transient(intensity: 1.0, sharpness: 0.8).0 : nil
        let a: Double? = micGranted ? audio.playClick() : nil
        taps.append(TapEvent(touch: touchTime, haptic: h, audio: a))
        progress += 1
        flash = true
        after(0.15) { self.flash = false }
        if progress == Wizard.tapTrials {
            after(0.8) { self.analyze() }
        }
    }

    private func analyze() {
        step = .analyzing
        // Let the "calculating" screen render first; the analysis itself takes well under a second.
        after(0.1) { self.finishAnalysis() }
    }

    private func finishAnalysis() {
        let acc = accel.snapshot()
        let mic: MicTrack? = micGranted ? audio.mic.snapshot() : nil
        let audioInfo: [String: Any]? = micGranted ? audio.sessionInfo() : nil
        let inputLatency = AVAudioSession.sharedInstance().inputLatency * 1000
        let data = RunData(deviceClass: deviceClass, hapticCalls: hapticCalls, continuousWindow: continuousWindow,
                           audioCalls: audioCalls, taps: taps, accel: acc.samples, accelDeliveryLagMs: acc.meanDeliveryLagMs,
                           mic: mic, micInvalidHostTimes: audio.mic.invalidHostTimes,
                           inputLatencyMs: micGranted ? inputLatency : nil)
        let outcome = Analysis.run(data)
        let verdicts = Report.verdicts(outcome, thresholds: thresholds, deviceClass: deviceClass)

        var notes = extraNotes
        if thresholds == nil { notes.append("brak thresholds.json w pakiecie aplikacji: werdykty = no_data") }
        if deviceClass != detectedClass { notes.append("klasa telefonu zmieniona ręcznie (wykryto \(detectedClass))") }
        notes.append("Core Haptics: resety silnika \(haptics.resets), zatrzymania \(haptics.stops)")

        if let built = Report.build(outcome: outcome, verdicts: verdicts, deviceClass: deviceClass, model: model,
                                           osVersion: UIDevice.current.systemVersion,
                                           hapticTier: haptics.supported ? "H3" : "H0", audioInfo: audioInfo,
                                           extraNotes: notes, date: Date()) {
            fileURL = Report.save(built.0, name: built.1)
        }
        rows = makeRows(outcome, verdicts)

        accel.stop()
        audio.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        step = .results
    }

    private func detail(_ m: Metric?) -> String {
        guard let m, let p50 = m.p50, let p95 = m.p95 else { return L.t("detail_none") }
        return L.f("detail", String(format: "%.1f", p50), String(format: "%.1f", p95), m.n, m.rejected)
    }

    private func makeRows(_ o: Outcome, _ v: [String: Verdict]) -> [ResultRow] {
        let gap = o.continuousMaxGapMs.map { L.f("detail_single", String(format: "%.1f", $0)) } ?? L.t("detail_none")
        return [
            ResultRow(id: "haptic_tap", title: L.t("m_haptic_tap"), detail: detail(o.metrics["haptic_tap"]), verdict: v["haptic_tap_p95_ms"] ?? .noData),
            ResultRow(id: "audio_tap", title: L.t("m_audio_tap"), detail: detail(o.metrics["audio_tap"]), verdict: v["audio_tap_p95_ms"] ?? .noData),
            ResultRow(id: "haptic_call", title: L.t("m_haptic_call"), detail: detail(o.metrics["haptic_call"]), verdict: v["haptic_call_p95_ms"] ?? .noData),
            ResultRow(id: "sync", title: L.t("m_sync"), detail: detail(o.metrics["audio_haptic_sync"]), verdict: v["audio_haptic_sync_ms"] ?? .noData),
            ResultRow(id: "cont", title: L.t("m_cont"), detail: gap, verdict: v["continuous_max_gap_ms"] ?? .noData),
            ResultRow(id: "audio_call_fast", title: L.t("m_audio_call_fast"), detail: detail(o.metrics["audio_call_fast"]), verdict: nil),
        ]
    }

    func repeatAll() {
        hapticCalls.removeAll()
        continuousWindow = nil
        audioCalls.removeAll()
        taps.removeAll()
        extraNotes.removeAll()
        notice = nil
        rows = []
        fileURL = nil
        lastTap = 0
        progress = 0
        running = false
        accel.clear()
        audio.mic.clear()
        step = .prep
    }
}

// MARK: - Views

struct WarmButtonStyle: ButtonStyle {
    var primary = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundColor(primary ? Palette.bg : Palette.text)
            .background(primary ? (configuration.isPressed ? Palette.accentPressed : Palette.accent) : Palette.surface)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(primary ? Color.clear : Palette.accent, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct StepPage<Content: View>: View {
    let title: String
    let text: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title).font(.system(.largeTitle, design: .serif))
                Text(text).font(.body).fixedSize(horizontal: false, vertical: true)
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var w: Wizard

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            content
        }
        .foregroundColor(Palette.text)
    }

    @ViewBuilder private var content: some View {
        switch w.step {
        case .start: StartView()
        case .prep:
            StepPage(title: L.t("prep_title"), text: L.t("prep_body")) {
                Button(L.t("done")) { w.prepDone() }.buttonStyle(WarmButtonStyle())
            }
        case .haptic:
            AutoStepView(title: L.t("haptic_title"), text: L.t("haptic_body"), progressKey: "progress") { w.runHaptic() }
        case .continuous:
            AutoStepView(title: L.t("cont_title"), text: L.t("cont_body"), progressKey: "seconds") { w.runContinuous() }
        case .audio:
            AutoStepView(title: L.t("audio_title"), text: L.t("audio_body"), progressKey: "progress") { w.runAudio() }
        case .taps: TapStepView()
        case .analyzing:
            VStack(spacing: 16) {
                ProgressView().tint(Palette.accent)
                Text(L.t("analyzing")).font(.system(.title2, design: .serif))
            }
        case .results: ResultsView()
        }
    }
}

struct StartView: View {
    @EnvironmentObject var w: Wizard
    @State private var picking = false

    var body: some View {
        StepPage(title: L.t("app_title"), text: L.t("start_body")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L.t("class_label")).font(.subheadline).foregroundColor(Palette.muted)
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(w.classLabel).font(.headline)
                        Text(L.t(w.deviceClass == w.detectedClass ? "class_auto" : "class_manual") + " · " + w.model)
                            .font(.footnote).foregroundColor(Palette.muted)
                    }
                    Spacer()
                    Button(L.t("change")) { picking = true }
                        .buttonStyle(WarmButtonStyle(primary: false))
                        .frame(width: 110)
                }
                .padding(12)
                .background(Palette.surface)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.line, lineWidth: 2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Button(L.t("start_btn")) { w.begin() }.buttonStyle(WarmButtonStyle())
            Text(L.t("footnote")).font(.footnote).foregroundColor(Palette.muted)
        }
        .confirmationDialog(L.t("class_pick_title"), isPresented: $picking, titleVisibility: .visible) {
            Button(L.t("class_iphone_new")) { w.deviceClass = "iphone_new" }
            Button(L.t("class_iphone_se")) { w.deviceClass = "iphone_se" }
            Button(L.t("cancel"), role: .cancel) {}
        }
    }
}

struct AutoStepView: View {
    @EnvironmentObject var w: Wizard
    let title: String
    let text: String
    let progressKey: String
    let action: @MainActor () -> Void

    var body: some View {
        StepPage(title: title, text: text) {
            if let n = w.notice {
                Text(n).font(.callout).foregroundColor(Palette.ochre).fixedSize(horizontal: false, vertical: true)
            }
            if w.running {
                VStack(alignment: .leading, spacing: 12) {
                    if w.waitingHands {
                        Text(L.t("wait_hands")).font(.title3)
                    } else {
                        Text(L.f(progressKey, w.progress, w.total)).font(.title3).monospacedDigit()
                    }
                    ProgressView(value: Double(w.progress), total: Double(max(w.total, 1))).tint(Palette.accent)
                }
            } else {
                Button(L.t("begin")) { action() }.buttonStyle(WarmButtonStyle())
            }
        }
    }
}

/// UIKit view: UITouch.timestamp is on the same clock as CACurrentMediaTime (system uptime).
final class TouchView: UIView {
    var onTouch: (@MainActor (TimeInterval) -> Void)?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let u = touches.first else { return }
        onTouch?(u.timestamp)
    }
}

struct TouchArea: UIViewRepresentable {
    let onTouch: @MainActor (TimeInterval) -> Void
    func makeUIView(context: Context) -> TouchView {
        let v = TouchView()
        v.backgroundColor = .clear
        v.onTouch = onTouch
        return v
    }
    func updateUIView(_ v: TouchView, context: Context) { v.onTouch = onTouch }
}

struct TapStepView: View {
    @EnvironmentObject var w: Wizard

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L.t("tap_title")).font(.system(.largeTitle, design: .serif))
            Text(L.t("tap_body")).font(.body).fixedSize(horizontal: false, vertical: true)
            if let n = w.notice {
                Text(n).font(.callout).foregroundColor(Palette.ochre).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .fill(w.flash ? Palette.accent : Palette.surface)
                Circle()
                    .stroke(Palette.accent, lineWidth: 3)
                Text(L.f("tap_count", w.progress, Wizard.tapTrials))
                    .font(.title3).monospacedDigit()
                    .foregroundColor(w.flash ? Palette.bg : Palette.text)
                TouchArea { t in w.tapped(at: t) }
                    .clipShape(Circle())
            }
            .frame(width: 220, height: 220)
            .frame(maxWidth: .infinity)
            .animation(.easeOut(duration: 0.12), value: w.flash)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }
}

struct ResultsView: View {
    @EnvironmentObject var w: Wizard

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L.t("results_title")).font(.system(.largeTitle, design: .serif))
                Text(L.t("results_hint")).font(.body).fixedSize(horizontal: false, vertical: true)
                ForEach(w.rows) { row in
                    ResultRowView(row: row)
                    Rectangle().fill(Palette.line).frame(height: 2)
                }
                if let url = w.fileURL {
                    ShareLink(item: url) {
                        Label(L.t("share"), systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(WarmButtonStyle())
                    Text(L.f("saved", url.lastPathComponent)).font(.footnote).foregroundColor(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button(L.t("repeat")) { w.repeatAll() }.buttonStyle(WarmButtonStyle(primary: false))
                Text(L.t("footnote")).font(.footnote).foregroundColor(Palette.muted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
    }
}

struct ResultRowView: View {
    let row: ResultRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.verdict?.symbol ?? "info.circle")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(row.verdict?.color ?? Palette.muted)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(row.title).font(.headline)
                Text(row.verdict?.word ?? L.t("verdict_info"))
                    .font(.body.weight(.semibold))
                    .foregroundColor(row.verdict?.color ?? Palette.muted)
                Text(row.detail).font(.subheadline).foregroundColor(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
