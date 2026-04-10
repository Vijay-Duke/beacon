import SwiftUI

struct PreferencesView: View {
    @ObservedObject var prefs: PreferencesManager
    @State private var hotkeyCode: UInt16 = 56

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }
            styleTab
                .tabItem { Label("Styles", systemImage: "paintbrush") }
        }
        .frame(width: 500, height: 380)
        .onAppear {
            hotkeyCode = prefs.hotkeyKeyCode
        }
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Hotkey") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Activation Key:")
                        Spacer()
                        HotkeyRecorderView(keyCode: $hotkeyCode)
                            .onChange(of: hotkeyCode) { _, newValue in
                                prefs.hotkeyKeyCode = newValue
                            }
                    }
                    Text("Double-tap and hold to activate the laser pointer.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(4)
            }

            GroupBox("Appearance") {
                VStack(spacing: 10) {
                    HStack {
                        Text("Style:")
                            .frame(width: 60, alignment: .trailing)
                        Picker("", selection: Binding(
                            get: { prefs.laserStyle },
                            set: { prefs.laserStyle = $0 }
                        )) {
                            ForEach(LaserStyle.allCases, id: \.self) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        .labelsHidden()
                    }

                    HStack {
                        Text("Color:")
                            .frame(width: 60, alignment: .trailing)
                        Picker("", selection: Binding(
                            get: { prefs.laserColor },
                            set: { prefs.laserColor = $0 }
                        )) {
                            ForEach(LaserColor.allCases, id: \.self) { color in
                                Text(color.rawValue.capitalized).tag(color)
                            }
                        }
                        .labelsHidden()
                    }

                    HStack {
                        Text("Size:")
                            .frame(width: 60, alignment: .trailing)
                        Slider(value: Binding(
                            get: { prefs.laserSize },
                            set: { prefs.laserSize = $0 }
                        ), in: 10...60, step: 2)
                        Text("\(Int(prefs.laserSize))pt")
                            .frame(width: 36, alignment: .trailing)
                            .monospacedDigit()
                    }
                }
                .padding(4)
            }

            Spacer()
        }
        .padding()
    }

    private var styleTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Classic Dot — Trail") {
                VStack(spacing: 10) {
                    HStack {
                        Toggle("Enable Trail", isOn: Binding(
                            get: { prefs.trailEnabled },
                            set: { prefs.trailEnabled = $0 }
                        ))
                        Spacer()
                    }
                    HStack {
                        Text("Trail Length:")
                            .frame(width: 100, alignment: .trailing)
                        Slider(value: Binding(
                            get: { Double(prefs.trailLength) },
                            set: { prefs.trailLength = Int($0) }
                        ), in: 10...50, step: 1)
                        Text("\(prefs.trailLength)")
                            .frame(width: 30, alignment: .trailing)
                            .monospacedDigit()
                    }
                }
                .padding(4)
            }

            GroupBox("Spotlight") {
                HStack {
                    Text("Dim Opacity:")
                        .frame(width: 100, alignment: .trailing)
                    Slider(value: Binding(
                        get: { prefs.spotlightDimOpacity },
                        set: { prefs.spotlightDimOpacity = $0 }
                    ), in: 0.4...0.8, step: 0.05)
                    Text("\(Int(prefs.spotlightDimOpacity * 100))%")
                        .frame(width: 36, alignment: .trailing)
                        .monospacedDigit()
                }
                .padding(4)
            }

            GroupBox("Glowing Halo") {
                HStack {
                    Text("Pulse Speed:")
                        .frame(width: 100, alignment: .trailing)
                    Slider(value: Binding(
                        get: { prefs.haloPulseSpeed },
                        set: { prefs.haloPulseSpeed = $0 }
                    ), in: 0.5...3.0, step: 0.1)
                    Text(String(format: "%.1fs", prefs.haloPulseSpeed))
                        .frame(width: 36, alignment: .trailing)
                        .monospacedDigit()
                }
                .padding(4)
            }

            GroupBox("Crosshair") {
                HStack {
                    Text("Line Thickness:")
                        .frame(width: 100, alignment: .trailing)
                    Slider(value: Binding(
                        get: { prefs.crosshairThickness },
                        set: { prefs.crosshairThickness = $0 }
                    ), in: 0.5...4.0, step: 0.5)
                    Text(String(format: "%.1fpt", prefs.crosshairThickness))
                        .frame(width: 46, alignment: .trailing)
                        .monospacedDigit()
                }
                .padding(4)
            }

            Spacer()
        }
        .padding()
    }
}
