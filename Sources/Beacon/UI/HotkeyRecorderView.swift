import SwiftUI

struct HotkeyOption: Identifiable, Hashable {
    let id: UInt16
    let name: String
    let symbol: String
    let isModifier: Bool

    init(id: UInt16, name: String, symbol: String, isModifier: Bool = false) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.isModifier = isModifier
    }

    static let modifiers: [HotkeyOption] = [
        HotkeyOption(id: 56, name: "Left Shift", symbol: "⇧", isModifier: true),
        HotkeyOption(id: 60, name: "Right Shift", symbol: "⇧", isModifier: true),
        HotkeyOption(id: 59, name: "Left Control", symbol: "⌃", isModifier: true),
        HotkeyOption(id: 62, name: "Right Control", symbol: "⌃", isModifier: true),
        HotkeyOption(id: 58, name: "Left Option", symbol: "⌥", isModifier: true),
        HotkeyOption(id: 61, name: "Right Option", symbol: "⌥", isModifier: true),
        HotkeyOption(id: 55, name: "Left Command", symbol: "⌘", isModifier: true),
        HotkeyOption(id: 54, name: "Right Command", symbol: "⌘", isModifier: true),
        HotkeyOption(id: 63, name: "Fn", symbol: "fn", isModifier: true),
    ]

    static let functionKeys: [HotkeyOption] = [
        HotkeyOption(id: 122, name: "F1", symbol: "F1"),
        HotkeyOption(id: 120, name: "F2", symbol: "F2"),
        HotkeyOption(id: 99,  name: "F3", symbol: "F3"),
        HotkeyOption(id: 118, name: "F4", symbol: "F4"),
        HotkeyOption(id: 96,  name: "F5", symbol: "F5"),
        HotkeyOption(id: 97,  name: "F6", symbol: "F6"),
        HotkeyOption(id: 98,  name: "F7", symbol: "F7"),
        HotkeyOption(id: 100, name: "F8", symbol: "F8"),
        HotkeyOption(id: 101, name: "F9", symbol: "F9"),
        HotkeyOption(id: 109, name: "F10", symbol: "F10"),
        HotkeyOption(id: 103, name: "F11", symbol: "F11"),
        HotkeyOption(id: 111, name: "F12", symbol: "F12"),
    ]

    static let otherKeys: [HotkeyOption] = [
        HotkeyOption(id: 53,  name: "Escape", symbol: "⎋"),
        HotkeyOption(id: 49,  name: "Space", symbol: "␣"),
        HotkeyOption(id: 48,  name: "Tab", symbol: "⇥"),
        HotkeyOption(id: 51,  name: "Delete", symbol: "⌫"),
    ]

    static let allOptions: [HotkeyOption] = modifiers + functionKeys + otherKeys
}

struct HotkeyRecorderView: View {
    @Binding var keyCode: UInt16

    var body: some View {
        Picker("", selection: $keyCode) {
            Section("Modifier Keys") {
                ForEach(HotkeyOption.modifiers) { option in
                    Text("\(option.symbol) \(option.name)").tag(option.id)
                }
            }
            Section("Function Keys") {
                ForEach(HotkeyOption.functionKeys) { option in
                    Text(option.name).tag(option.id)
                }
            }
            Section("Other") {
                ForEach(HotkeyOption.otherKeys) { option in
                    Text("\(option.symbol) \(option.name)").tag(option.id)
                }
            }
        }
        .labelsHidden()
        .frame(width: 180)
    }
}
