// SettingsView.swift
import SwiftUI
import Swift
struct SettingsView: View {
    @AppStorage("checkInterval") var checkInterval: TimeInterval = 300
    @AppStorage("enableBackgroundChecks") var enableBackgroundChecks: Bool = true
    @AppStorage("notifyWhenWebsiteDown") var notifyWhenWebsiteDown: Bool = true
    @AppStorage("notifyWhenWebsiteBackUp") var notifyWhenWebsiteBackUp: Bool = true

    var body: some View {
            // Use a custom List style to remove the extra top padding
            List {
                Section(header: Text("Monitoring")) {
                    HStack {
                        Text("Check every")
                        Spacer()
                        Text("\(Int(checkInterval / 60)) minutes")
                    }
                    Slider(value: $checkInterval, in: 30...3600, step: 30) {
                        Text("Check Interval")
                    }
                    Toggle("Enable Background Checks", isOn: $enableBackgroundChecks)
                }

                Section(header: Text("Notifications")) {
                    Toggle("Notify when website goes down", isOn: $notifyWhenWebsiteDown)
                    Toggle("Notify when website is back up", isOn: $notifyWhenWebsiteBackUp)
                }
            }
            .listStyle(.plain) // Use plain list style to minimize padding
            .navigationTitle("Settings")
        
    }
}
