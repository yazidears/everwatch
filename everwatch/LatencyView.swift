import SwiftUI

struct PingLatencyView: View {
    @Binding var websites: [Website] // Pass websites as a binding

    var body: some View {
        NavigationView {
            List {
                ForEach(websites) { website in
                    Section(header: Text(website.name)) { // Group by website name
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
            .navigationTitle("Ping & Latency")
        }
    }
}

