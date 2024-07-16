//
//  SettingsView.swift
//  everwatch
//
//  Created by Yazide Arsalan on 6/30/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("checkInterval") var checkInterval: TimeInterval = 60 // Default to 1 minute

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Check Frequency")) {
                    Picker("Check Every:", selection: $checkInterval) {
                        Text("1 Minute").tag(60)
                        Text("5 Minutes").tag(300)
                        Text("10 Minutes").tag(600)
                    }
                }

                // Add more settings here...
            }
            .navigationTitle("Settings")
        }
    }
}
