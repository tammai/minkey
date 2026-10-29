import AppKit
import MinkeyEngine
import MinkeyKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor enum SettingsWindow {
    private static var window: NSWindow?

    static func show() {
        if window == nil {
            let controller = NSHostingController(rootView: SettingsView().environmentObject(AppState.shared))
            let newWindow = NSWindow(contentViewController: controller)
            newWindow.title = String(localized: "minkey Settings")
            newWindow.styleMask = [.titled, .closable]
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            window = newWindow
            installMainMenu()
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    /// minkey has no Dock icon and so no menu bar of its own; without these, Cmd-C, Cmd-V and Cmd-W do nothing.
    private static func installMainMenu() {
        let edit = NSMenu(title: String(localized: "Edit"))
        edit.addItem(withTitle: String(localized: "Undo"), action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: String(localized: "Redo"), action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: String(localized: "Cut"), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: String(localized: "Copy"), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: String(localized: "Paste"), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(
            withTitle: String(localized: "Select All"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        let file = NSMenu(title: String(localized: "Window"))
        file.addItem(
            withTitle: String(localized: "Close"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        let main = NSMenu()
        for submenu in [file, edit] {
            let item = NSMenuItem()
            item.submenu = submenu
            main.addItem(item)
        }
        NSApp.mainMenu = main
    }
}

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralView().tabItem { Text("General") }
            MacrosView().tabItem { Text("Macros") }
            AppsView().tabItem { Text("Apps") }
            AboutView().tabItem { Text("About") }
        }
        .frame(width: 520, height: 400)
        .safeAreaInset(edge: .bottom) { SaveStatus() }
    }
}

private struct SaveStatus: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        if state.saveFailed {
            errorText("Settings couldn't be saved and will be lost when minkey restarts.").padding(8)
        }
    }
}

struct GeneralView: View {
    @EnvironmentObject private var state: AppState
    @State private var diagnosticsOn = false

    var body: some View {
        Form {
            Section {
                Picker("Tone placement", selection: $state.settings.toneStyle) {
                    Text("New style (hoà, thuý)").tag(ToneStyle.new)
                    Text("Old style (hòa, thúy)").tag(ToneStyle.old)
                }
                Toggle("Spell check", isOn: $state.settings.spellCheck)
                helpText("Words that can't be Vietnamese go back to the keys you typed.")
                LabeledContent("Vietnamese/English shortcut") {
                    ShortcutRecorder(shortcut: $state.settings.toggleShortcut)
                }
            }
            Section {
                Toggle("Diagnostic log", isOn: $diagnosticsOn)
                    .onChange(of: diagnosticsOn) { on in
                        on ? state.diagnostics.enable() : state.diagnostics.disable()
                    }
                helpText(
                    "Records which app, where minkey edited and how many characters, never what you typed. Turns itself off after 24 hours. Saved in ~/Library/Logs/minkey-diagnostics.log."
                )
            }
        }
        .formStyle(.grouped)
        .onAppear { diagnosticsOn = state.diagnostics.isEnabled }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            if diagnosticsOn, !state.diagnostics.isEnabled { diagnosticsOn = false }
        }
    }
}

struct ShortcutRecorder: View {
    @Binding var shortcut: Shortcut
    @State private var monitor: Any?
    @State private var rejected = false

    var body: some View {
        VStack(alignment: .trailing) {
            Button(monitor == nil ? Self.describe(shortcut) : String(localized: "Press a shortcut…")) {
                monitor == nil ? start() : stop()
            }
            if rejected {
                errorText("Use Control, Option or Command, and not a shortcut macOS uses to switch input sources.")
            }
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        rejected = false
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection([.shift, .control, .option, .command])
            let candidate = Shortcut(keyCode: event.keyCode, modifiers: UInt(modifiers.rawValue))
            if candidate.isAllowedToggle {
                shortcut = candidate
            } else {
                rejected = true
            }
            stop()
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    private static let keyNames: [UInt16: String] = [
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H", 34: "I", 38: "J", 40: "K",
        37: "L", 46: "M", 45: "N", 31: "O", 35: "P", 12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 13: "W",
        7: "X", 16: "Y", 6: "Z", 29: "0", 18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8",
        25: "9",
    ]

    static func describe(_ shortcut: Shortcut) -> String {
        let symbols: [(UInt, String)] = [
            (Shortcut.control, "⌃"), (Shortcut.option, "⌥"), (Shortcut.shift, "⇧"), (Shortcut.command, "⌘"),
        ]
        let prefix = symbols.filter { shortcut.modifiers & $0.0 != 0 }.map(\.1).joined()
        let key =
            shortcut.keyCode == 49
            ? String(localized: "Space")
            : keyNames[shortcut.keyCode] ?? String(localized: "Key \(Int(shortcut.keyCode))")
        return prefix + key
    }
}

private struct MacroRow: Identifiable {
    let id = UUID()
    var short: String
    var expansion: String
}

struct MacrosView: View {
    @EnvironmentObject private var state: AppState
    @State private var rows: [MacroRow] = []
    @State private var selection: MacroRow.ID?
    @State private var fileError: LocalizedStringKey?

    var body: some View {
        Form {
            Section {
                Toggle("Also expand in English mode", isOn: $state.settings.macros.inEnglishMode)
                Table($rows, selection: $selection) {
                    TableColumn("Shorthand") { $row in TextField("Shorthand", text: $row.short).labelsHidden() }
                    TableColumn("Expands to") { $row in TextField("Expands to", text: $row.expansion).labelsHidden() }
                }
                .frame(minHeight: 160)
                .overlay {
                    if rows.isEmpty {
                        Text("Add shorthand such as btw → by the way.").foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Button {
                        rows.append(MacroRow(short: "", expansion: ""))
                    } label: {
                        Label("Add shorthand", systemImage: "plus")
                    }
                    Button {
                        rows.removeAll { $0.id == selection }
                    } label: {
                        Label("Remove shorthand", systemImage: "minus")
                    }
                    .disabled(selection == nil)
                    Spacer()
                    Button("Import…", action: importMacros)
                    Button("Export…", action: exportMacros)
                }
                .labelStyle(.iconOnly)
                if rows.contains(where: { $0.short.isEmpty != $0.expansion.isEmpty }) {
                    helpText("Rows need both a shorthand and its expansion to be saved.")
                }
                let named = rows.map { $0.short.lowercased() }.filter { !$0.isEmpty }
                if Set(named).count < named.count {
                    helpText("Shorthand ignores case, so only the last of two matching rows is kept.")
                }
                if let fileError {
                    errorText(fileError)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: load)
        .onChange(of: rows.map { [$0.short, $0.expansion] }) { _ in save() }
    }

    private func load() {
        rows = state.settings.macros.entries.sorted { $0.key < $1.key }.map {
            MacroRow(short: $0.key, expansion: $0.value)
        }
    }

    private func save() {
        let entries = rows.filter { !$0.short.isEmpty && !$0.expansion.isEmpty }.map {
            ($0.short.lowercased(), $0.expansion)
        }
        state.settings.macros.entries = Dictionary(entries, uniquingKeysWith: { _, last in last })
    }

    private func importMacros() {
        fileError = nil
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = try? Data(contentsOf: url), let macros = try? Macros(importing: data) else {
            fileError = "That file isn't a minkey macro export."
            return
        }
        state.settings.macros.entries.merge(macros.entries) { _, imported in imported }
        load()
    }

    private func exportMacros() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "minkey-macros.json"
        fileError = nil
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try state.settings.macros.exported().write(to: url, options: .atomic)
        } catch {
            fileError = "The macros couldn't be saved to that file."
        }
    }
}

struct AppsView: View {
    @EnvironmentObject private var state: AppState

    @State private var selection: String?

    private struct AppRow: Identifiable {
        let id: String

        var name: String {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return id }
            return FileManager.default.displayName(atPath: url.path)
        }
    }

    private var apps: [AppRow] {
        Set(state.settings.languages.chosen.keys).union(state.settings.overrides.keys).sorted().map(AppRow.init)
    }

    var body: some View {
        Form {
            Section {
                Table(apps, selection: $selection) {
                    TableColumn("App") { app in Text(app.name).help(app.id) }
                    TableColumn("Language") { app in
                        Picker("Language", selection: language(app.id)) {
                            Text("Vietnamese").tag(Language.vietnamese)
                            Text("English").tag(Language.english)
                        }
                        .labelsHidden()
                    }
                    TableColumn("Typing mode") { app in
                        Picker("Typing mode", selection: override(app.id)) {
                            Text("Automatic").tag(DeliveryMode?.none)
                            Text("Direct").tag(DeliveryMode?.some(.direct))
                            Text("Underlined").tag(DeliveryMode?.some(.marked))
                        }
                        .labelsHidden()
                    }
                }
                .frame(minHeight: 200)
                .overlay {
                    if apps.isEmpty {
                        Text("Apps appear here once you switch language in them.").foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Button {
                        if let selection {
                            state.settings.languages.chosen[selection] = nil
                            state.settings.overrides[selection] = nil
                        }
                        selection = nil
                    } label: {
                        Label("Remove app", systemImage: "minus")
                    }
                    .labelStyle(.iconOnly)
                    .disabled(selection == nil)
                    Spacer()
                }
                helpText("Underlined mode is for apps where direct typing doesn't work, such as some terminals.")
            }
        }
        .formStyle(.grouped)
    }

    private func language(_ app: String) -> Binding<Language> {
        Binding(
            get: { state.settings.languages.language(for: app) },
            set: { state.settings.languages.chosen[app] = $0 }
        )
    }

    private func override(_ app: String) -> Binding<DeliveryMode?> {
        Binding(
            get: { state.settings.overrides[app] },
            set: { state.settings.overrides[app] = $0 }
        )
    }
}

struct AboutView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Version", value: version)
                Text("minkey never stores or sends what you type. It only goes online to check for updates.")
                Text("Free and open source under the MIT license.").foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

@ViewBuilder private func helpText(_ text: LocalizedStringKey) -> some View {
    Text(text).font(.caption).foregroundStyle(.secondary)
}

@ViewBuilder private func errorText(_ text: LocalizedStringKey) -> some View {
    Text(text).font(.caption).foregroundStyle(.red)
}
