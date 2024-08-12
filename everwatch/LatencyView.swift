// SettingsView.swift

import SwiftUI

// MARK: - PingLatencyView (Improved UI)

struct PingLatencyView: View {
    @Binding var websites: [Website]

    var body: some View {
            List {
                ForEach(websites) { website in
                    Section(header: Text(website.name)) {
                        if let latestRecord = website.history.last, let pingTime = latestRecord.pingTime {
                            HStack {
                                Text("Latest Ping:")
                                Spacer()
                                Text("\(String(format: "%.2f", pingTime * 1000)) ms")
                            }
                        } else {
                            Text("No ping data available")
                        }
                    }
                }
            }
            .listStyle(.plain) // Use plain list style here as well
            .navigationTitle("Ping & Latency")
        }
    
}
