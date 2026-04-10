import SwiftUI

struct PreferencesView: View {
    @ObservedObject var prefs: PreferencesManager
    @State private var hotkeyCode: UInt16 = 62

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }
            styleTab
                .tabItem { Label("Styles", systemImage: "paintbrush") }
        }
        .frame(width: 450, height: 350)
        .onAppear {
            hotkeyCode = prefs.hotkeyKeyCode
        }
    }

    private var generalTab: some View {
        Form {
            Section("Hotkey") {
                HStack {
                    Text("Activation Key:")
                    Spacer()
                    HotkeyRecorderView(keyCode: $hotkeyCode)
                        .onChange(of: hotkeyCode) { _, newValue in
                            prefs.hotkeyKeyCode = newValue
                        }
                }
            }

            Section("Appearance") {
                HStack {
                    Text("Style:")
                    Spacer()
                    Picker("", selection: Binding(
                        get: { prefs.laserStyle },
                        set: { prefs.laserStyle = $0 }
                    )) {
                        ForEach(LaserStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .frame(width: 160)
                }

                HStack {
                    Text("Color:")
                    Spacer()
                    Picker("", selection: Binding(
                        get: { prefs.laserColor },
                        set: { prefs.laserColor = $0 }
                    )) {
                        ForEach(LaserColor.allCases, id: \.self) { color in
                            Text(color.rawValue.capitalized).tag(color)
                        }
                    }
                    .frame(width: 160)
                }

                HStack {
                    Text("Size:")
                    Slider(value: Binding(
                        get: { prefs.laserSize },
                        set: { prefs.laserSize = $0 }
                    ), in: 10...60, step: 2)
                    Text("\(Int(prefs.laserSize))pt")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("General") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { prefs.launchAtLogin },
                    set: { prefs.launchAtLogin = $0 }
                ))
            }
        }
        .padding()
    }

    private var styleTab: some View {
        Form {
            Section("Classic Dot — Trail") {
                Toggle("Enable Trail", isOn: Binding(
                    get: { prefs.trailEnabled },
                    set: { prefs.trailEnabled = $0 }
                ))
                HStack {
                    Text("Trail Length:")
                    Slider(value: Binding(
                        get: { Double(prefs.trailLength) },
                        set: { prefs.trailLength = Int($0) }
                    ), in: 10...50, step: 1)
                    Text("\(prefs.trailLength)")
                        .frame(width: 30, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("Spotlight") {
                HStack {
                    Text("Dim Opacity:")
                    Slider(value: Binding(
                        get: { prefs.spotlightDimOpacity },
                        set: { prefs.spotlightDimOpacity = $0 }
                    ), in: 0.4...0.8, step: 0.05)
                    Text("\(Int(prefs.spotlightDimOpacity * 100))%")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("Glowing Halo") {
                HStack {
                    Text("Pulse Speed:")
                    Slider(value: Binding(
                        get: { prefs.haloPulseSpeed },
                        set: { prefs.haloPulseSpeed = $0 }
                    ), in: 0.5...3.0, step: 0.1)
                    Text(String(format: "%.1fs", prefs.haloPulseSpeed))
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("Crosshair") {
                HStack {
                    Text("Line Thickness:")
                    Slider(value: Binding(
                        get: { prefs.crosshairThickness },
                        set: { prefs.crosshairThickness = $0 }
                    ), in: 0.5...4.0, step: 0.5)
                    Text(String(format: "%.1fpt", prefs.crosshairThickness))
                        .frame(width: 50, alignment: .trailing)
                        .monospacedDigit()
                }
            }
        }
        .padding()
    }
}
