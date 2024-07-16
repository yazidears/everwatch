import SwiftUI

struct WebsiteStatsView: View {
    @Binding var websites: [Website]

    var body: some View {
        NavigationView {
            VStack {
                Text("Overall Website Statistics")
                    .font(.headline)
                    .padding()

                HStack {
                    Text("Total Websites:")
                    Spacer()
                    Text("\(websites.count)")
                }
                .padding()

                HStack {
                    Text("Currently Online:")
                    Spacer()
                    Text("\(websites.filter { $0.status == "200" }.count)")
                }
                .padding()

                HStack {
                    Text("Currently Offline:")
                    Spacer()
                    Text("\(websites.filter { $0.status != "200" }.count)")
                }
                .padding()

                HStack {
                    Text("Average Ping Time:")
                    Spacer()
                    if let avgPing = calculateAveragePing(websites: websites) {
                        Text("\(String(format: "%.2f", avgPing * 1000)) ms")
                    } else {
                        Text("N/A")
                    }
                }
                .padding()

                // New Statistics
                HStack {
                    Text("Fastest Ping:")
                    Spacer()
                    if let fastestPing = calculateFastestPing(websites: websites) {
                        Text("\(String(format: "%.2f", fastestPing * 1000)) ms")
                    } else {
                        Text("N/A")
                    }
                }
                .padding()

                HStack {
                    Text("Slowest Ping:")
                    Spacer()
                    if let slowestPing = calculateSlowestPing(websites: websites) {
                        Text("\(String(format: "%.2f", slowestPing * 1000)) ms")
                    } else {
                        Text("N/A")
                    }
                }
                .padding()

                HStack {
                    Text("Most Common Status Code:")
                    Spacer()
                    Text("\(mostFrequentStatusCode(websites: websites) ?? "N/A")")
                }
                .padding()
            }
            .navigationTitle("Website Stats")
        }
    }

    func calculateAveragePing(websites: [Website]) -> TimeInterval? {
            let totalPingTime = websites.flatMap { $0.history.compactMap { $0.pingTime } }.reduce(0, +)
            let totalPings = websites.flatMap { $0.history.compactMap { $0.pingTime } }.count
            return totalPings > 0 ? totalPingTime / Double(totalPings) : nil
        }
    }
    // Calculate fastest ping
    func calculateFastestPing(websites: [Website]) -> TimeInterval? {
        let allPings = websites.flatMap { $0.history.compactMap { $0.pingTime } }
        return allPings.min()
    }

    // Calculate slowest ping
    func calculateSlowestPing(websites: [Website]) -> TimeInterval? {
        let allPings = websites.flatMap { $0.history.compactMap { $0.pingTime } }
        return allPings.max()
    }

    // Find most frequent status code
func mostFrequentStatusCode(websites: [Website]) -> String? {
    let allStatusCodes = websites.flatMap { $0.history.compactMap { $0.statusCode } }

    let statusCodeCounts = allStatusCodes.reduce(into: [Int: Int]()) { counts, statusCode in
        counts[statusCode, default: 0] += 1
    }
    
    if let mostFrequent = statusCodeCounts.max(by: { $0.value < $1.value }) {
        return String(mostFrequent.key)
    } else {
        return nil
    }
}
