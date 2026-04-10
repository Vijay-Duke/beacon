import SwiftUI
import AppKit

struct HotkeyRecorderView: View {
    @Binding var keyCode: UInt16
    @State private var isRecording = false

    var body: some View {
        Button(action: { isRecording.toggle() }) {
            Text(isRecording ? "Press a key..." : keyName(for: keyCode))
                .frame(minWidth: 120)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isRecording ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .background(
            KeyRecorderRepresentable(isRecording: $isRecording, keyCode: $keyCode)
                .frame(width: 0, height: 0)
        )
    }

    private func keyName(for code: UInt16) -> String {
        let knownKeys: [UInt16: String] = [
            62: "Right Control", 59: "Left Control",
            58: "Left Option", 61: "Right Option",
            56: "Left Shift", 60: "Right Shift",
            55: "Left Command", 54: "Right Command",
            49: "Space", 36: "Return", 53: "Escape",
            48: "Tab",
        ]
        return knownKeys[code] ?? "Key \(code)"
    }
}

struct KeyRecorderRepresentable: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var keyCode: UInt16

    func makeNSView(context: Context) -> KeyRecorderNSView {
        let view = KeyRecorderNSView()
        view.onKeyRecorded = { code in
            keyCode = code
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: KeyRecorderNSView, context: Context) {
        nsView.isRecordingActive = isRecording
        if isRecording {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

class KeyRecorderNSView: NSView {
    var onKeyRecorded: ((UInt16) -> Void)?
    var isRecordingActive = false

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if isRecordingActive {
            onKeyRecorded?(event.keyCode)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        if isRecordingActive {
            onKeyRecorded?(event.keyCode)
        }
    }
}
