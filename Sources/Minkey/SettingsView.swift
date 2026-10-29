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
            window = newWindow
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
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
                    "Records which app, where minkey edited and how many characters, never what you typed. Turns itself off after 24 hours."
                )
            }
        }
        .formStyle(.grouped)
        .onAppear { diagnosticsOn = state.diagnostics.isEnabled }
    }
}

struct ShortcutRecorder: View {
    @Binding var shortcut: Shortcut
    @State private var monitor: Any?

    var body: some View {
        Button(monitor == nil ? Self.describe(shortcut) : String(localized: "Press a shortcut…")) {
            monitor == nil ? start() : stop()
        }
    }

    private func start() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection([.shift, .control, .option, .command])
            if !modifiers.isEmpty {
                shortcut = Shortcut(keyCode: event.keyCode, modifiers: UInt(modifiers.rawValue))
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
        49: "Space", 0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H", 34: "I", 38: "J", 40: "K",
        37: "L", 46: "M", 45: "N", 31: "O", 35: "P", 12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 13: "W",
        7: "X", 16: "Y", 6: "Z",
    ]

    static func describe(_ shortcut: Shortcut) -> String {
        let symbols: [(UInt, String)] = [
            (Shortcut.control, "⌃"), (Shortcut.option, "⌥"), (Shortcut.shift, "⇧"), (Shortcut.command, "⌘"),
        ]
        let prefix = symbols.filter { shortcut.modifiers & $0.0 != 0 }.map(\.1).joined()
        return prefix + (keyNames[shortcut.keyCode] ?? "#\(shortcut.keyCode)")
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

    var body: some View {
        Form {
            Section {
                Toggle("Also expand in English mode", isOn: $state.settings.macros.inEnglishMode)
                Table($rows, selection: $selection) {
                    TableColumn("Shorthand") { $row in TextField("", text: $row.short) }
                    TableColumn("Expands to") { $row in TextField("", text: $row.expansion) }
                }
                .frame(minHeight: 160)
                .overlay {
                    if rows.isEmpty {
                        Text("Add shorthand such as btw → by the way.").foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Button("+") { rows.append(MacroRow(short: "", expansion: "")) }
                    Button("−") { rows.removeAll { $0.id == selection } }
                        .disabled(selection == nil)
                    Spacer()
                    Button("Import…", action: importMacros)
                    Button("Export…", action: exportMacros)
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
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url),
            let macros = try? Macros(importing: data)
        else { return }
        state.settings.macros = macros
        load()
    }

    private func exportMacros() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "minkey-macros.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? state.settings.macros.exported().write(to: url, options: .atomic)
    }
}

struct AppsView: View {
    @EnvironmentObject private var state: AppState

    private struct AppRow: Identifiable {
        let id: String
    }

    private var apps: [AppRow] {
        Set(state.settings.languages.chosen.keys).union(state.settings.overrides.keys).sorted().map(AppRow.init)
    }

    var body: some View {
        Form {
            Section {
                Table(apps) {
                    TableColumn("App") { app in Text(app.id) }
                    TableColumn("Language") { app in
                        Picker("", selection: language(app.id)) {
                            Text("Vietnamese").tag(Language.vietnamese)
                            Text("English").tag(Language.english)
                        }
                        .labelsHidden()
                    }
                    TableColumn("Typing mode") { app in
                        Picker("", selection: override(app.id)) {
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
                Text("Free and open source under the MIT licence.").foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

@ViewBuilder private func helpText(_ text: LocalizedStringKey) -> some View {
    Text(text).font(.caption).foregroundStyle(.secondary)
}
