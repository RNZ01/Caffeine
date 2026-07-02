import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var caffeinate: Process?
    private var timer: Timer?
    private var endDate: Date?
    private var currentDuration: Int?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        start(savedDuration)
    }

    func applicationWillTerminate(_ notification: Notification) {
        caffeinate?.terminationHandler = nil
        caffeinate?.terminate()
    }

    @objc private func toggle() {
        isActive ? stop() : start(nil)
    }

    @objc private func startDuration(_ item: NSMenuItem) {
        start(item.representedObject as? Int)
    }

    @objc private func toggleStartAtLogin() {
        do {
            try setStartAtLogin(!isStartAtLoginEnabled)
            updateMenu()
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private var isActive: Bool {
        caffeinate?.isRunning == true
    }

    private var savedDuration: Int? {
        UserDefaults.standard.object(forKey: "duration") as? Int
    }

    private func start(_ seconds: Int?) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-dimsu"] + (seconds.map { ["-t", String($0)] } ?? [])
        process.terminationHandler = { [weak self] process in
            DispatchQueue.main.async {
                if self?.caffeinate === process { self?.finish() }
            }
        }

        do {
            try process.run()
            let oldProcess = caffeinate
            oldProcess?.terminationHandler = nil
            caffeinate = process
            currentDuration = seconds
            UserDefaults.standard.set(seconds, forKey: "duration")
            endDate = seconds.map { Date().addingTimeInterval(TimeInterval($0)) }
            restartTimer(seconds: seconds)
            oldProcess?.terminate()
            updateMenu()
        } catch {
            NSAlert(error: error).runModal()
            updateMenu()
        }
    }

    private func stop() {
        let process = caffeinate
        process?.terminationHandler = nil
        finish()
        process?.terminate()
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        caffeinate = nil
        endDate = nil
        currentDuration = nil
        updateMenu()
    }

    private func restartTimer(seconds: Int?) {
        timer?.invalidate()
        timer = seconds == nil ? nil : Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard isActive else { finish(); return }
        if let endDate, endDate <= Date() { stop() }
        else { updateStatusItem() }
    }

    private func updateMenu() {
        updateStatusItem()
        let active = isActive
        let menu = NSMenu()
        menu.addItem(menuItem(active ? "Turn Off" : "Turn On Forever", #selector(toggle)))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: active ? "Status: Enabled (\(remainingText()))" : "Status: Disabled", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        addDurationItems(to: menu, active: active)
        menu.addItem(.separator())
        let startAtLogin = menuItem("Start at Login", #selector(toggleStartAtLogin))
        startAtLogin.state = isStartAtLoginEnabled ? .on : .off
        menu.addItem(startAtLogin)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Caffeine", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        statusItem.menu = menu
    }

    private func updateStatusItem() {
        let active = isActive
        let image = NSImage(named: "MenuBarIcon") ?? NSImage(systemSymbolName: "cup.and.saucer", accessibilityDescription: "Caffeine")
        image?.size = NSSize(width: 20, height: 20)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.title = active ? remainingText() : ""
    }

    private func addDurationItems(to menu: NSMenu, active: Bool) {
        [("15 minutes", 15 * 60), ("30 minutes", 30 * 60), ("1 hour", 60 * 60), ("2 hours", 120 * 60)].forEach { title, seconds in
            let item = menuItem(title, #selector(startDuration(_:)))
            item.representedObject = seconds
            item.state = active && currentDuration == seconds ? .on : .off
            menu.addItem(item)
        }

        let forever = menuItem("Forever", #selector(startDuration(_:)))
        forever.image = NSImage(systemSymbolName: "infinity", accessibilityDescription: "Forever")
        forever.state = active && currentDuration == nil ? .on : .off
        menu.addItem(forever)
    }

    private var isStartAtLoginEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled || FileManager.default.fileExists(atPath: launchAgentURL.path)
        }
        return FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    private var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/local.caffeine.plist")
    }

    private func setStartAtLogin(_ enabled: Bool) throws {
        try? FileManager.default.removeItem(at: launchAgentURL)

        if #available(macOS 13.0, *) {
            enabled ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister()
        } else if enabled {
            try setLegacyStartAtLogin()
        }
    }

    private func setLegacyStartAtLogin() throws {
        guard let executablePath = Bundle.main.executablePath else {
            throw NSError(domain: "Caffeine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find app executable path."])
        }

        try FileManager.default.createDirectory(
            at: launchAgentURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let plist: [String: Any] = [
            "Label": Bundle.main.bundleIdentifier ?? "local.caffeine",
            "ProgramArguments": [executablePath],
            "RunAtLoad": true
        ]
        if !(plist as NSDictionary).write(to: launchAgentURL, atomically: true) {
            throw NSError(domain: "Caffeine", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not write login item."])
        }
    }

    private func menuItem(_ title: String, _ action: Selector?, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func remainingText() -> String {
        guard let endDate else { return "∞" }
        let seconds = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        return seconds >= 60 ? "\((seconds + 59) / 60)m" : "\(seconds)s"
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
