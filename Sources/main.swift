import Cocoa
import SwiftUI
import UserNotifications
import AVFoundation

// MARK: - Timer Manager

class TimerManager: ObservableObject {
    static let shared = TimerManager()

    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var selectedPreset: Int = 25
    @Published var customMinutes: String = ""

    private var timer: Timer?
    weak var statusItem: NSStatusItem?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var timeString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    func start(minutes: Int) {
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
        updateMenuBar()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func resume() {
        guard remainingSeconds > 0 else { return }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remainingSeconds = 0
        totalSeconds = 0
        statusItem?.button?.attributedTitle = NSAttributedString(string: "🍅")
    }

    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            updateMenuBar()
        } else {
            timer?.invalidate()
            timer = nil
            isRunning = false
            statusItem?.button?.attributedTitle = NSAttributedString(string: "🍅")
            sendNotification()
            playAlertSound()
        }
    }

    private func updateMenuBar() {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        let timeStr = String(format: "%d:%02d", m, s)

        let full = NSMutableAttributedString()
        full.append(NSAttributedString(string: "🍅 "))
        let timeAttr = NSAttributedString(
            string: timeStr,
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            ]
        )
        full.append(timeAttr)
        statusItem?.button?.attributedTitle = full
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Complete!"
        content.body = "Great focus session! Time for a break. 🎉"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func playAlertSound() {
        // Play system alert sound
        if let sound = NSSound(named: "Glass") {
            sound.play()
        } else {
            NSSound.beep()
        }

        // Play again after a short delay for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let sound = NSSound(named: "Hero") {
                sound.play()
            }
        }
    }
}

// MARK: - SwiftUI Timer View

struct TimerView: View {
    @ObservedObject var manager = TimerManager.shared

    let presets = [15, 25, 45]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Pomodoro")
                .font(.system(size: 18, weight: .bold))
                .padding(.top, 8)

            // Timer display
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                // Progress ring
                Circle()
                    .trim(from: 0, to: manager.progress)
                    .stroke(
                        Color.red,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: manager.progress)

                // Time text
                VStack(spacing: 4) {
                    Text(manager.totalSeconds > 0 ? manager.timeString : "\(manager.selectedPreset):00")
                        .font(.system(size: 36, weight: .light, design: .monospaced))

                    if manager.isRunning {
                        Text("focusing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 160, height: 160)
            .padding(.vertical, 4)

            // Preset buttons
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { mins in
                    Button(action: { manager.selectedPreset = mins }) {
                        Text("\(mins)m")
                            .font(.system(size: 13, weight: manager.selectedPreset == mins ? .bold : .regular))
                            .frame(width: 50, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(manager.selectedPreset == mins ? Color.red.opacity(0.15) : Color.gray.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(manager.isRunning)
                }

                // Custom input
                HStack(spacing: 2) {
                    TextField("min", text: $manager.customMinutes)
                        .textFieldStyle(.plain)
                        .frame(width: 32)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .onSubmit {
                            if let val = Int(manager.customMinutes), val > 0, val <= 180 {
                                manager.selectedPreset = val
                            }
                        }
                    Text("m")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(width: 50, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                )
                .disabled(manager.isRunning)
            }

            // Control buttons
            HStack(spacing: 12) {
                if manager.isRunning {
                    Button(action: { manager.pause() }) {
                        Label("Pause", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else if manager.remainingSeconds > 0 && manager.totalSeconds > 0 {
                    Button(action: { manager.resume() }) {
                        Label("Resume", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button(action: {
                        let mins: Int
                        if let custom = Int(manager.customMinutes), custom > 0, custom <= 180 {
                            mins = custom
                            manager.selectedPreset = custom
                        } else {
                            mins = manager.selectedPreset
                        }
                        manager.start(minutes: mins)
                    }) {
                        Label("Start", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }

                if manager.totalSeconds > 0 {
                    Button(action: { manager.reset() }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .frame(height: 32)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 4)

            Divider()

            // Quit button
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Text("Quit Pomodoro")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .frame(width: 280)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permission
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("Notification permission granted")
            }
        }

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.attributedTitle = NSAttributedString(string: "🍅")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Connect manager to status item
        TimerManager.shared.statusItem = statusItem

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 380)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: TimerView())
    }

    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // Show notifications even when app is foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - Main Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Hide from Dock (menu bar only)
NSApp.setActivationPolicy(.accessory)

app.run()
