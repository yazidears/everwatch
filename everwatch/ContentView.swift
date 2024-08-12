import SwiftUI
import Foundation
import UserNotifications
import BackgroundTasks

struct Website: Identifiable, Codable {
    let id = UUID()
    var name: String
    var url: String
    var status: String = "Checking..."
    var history: [WebsiteStatusRecord] = []
    
    // Per-website settings
    var isTimeSensitiveEnabled: Bool = true
    var skipTLSVerification: Bool = false
    var usualStatusCode: Int? = 200
}

struct WebsiteStatusRecord: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let statusCode: Int?
    let statusDescription: String?
    let pingTime: TimeInterval?
    let isCritical: Bool // Add a flag for critical alerts
}

struct WebsiteStatusPeriod: Identifiable {
    let id = UUID()
    let status: String
    let startTime: Date
    var endTime: Date? // endTime will be nil for the ongoing period

    var duration: String {
        if let endTime = endTime {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .abbreviated
            return formatter.string(from: startTime, to: endTime) ?? ""
        } else {
            return "Ongoing"
        }
    }
}
struct ContentView: View {
    @State private var websites: [Website] = []
    @AppStorage("savedWebsites") private var savedWebsites: Data = Data()
    @State private var isEditing = false // State variable for edit mode
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        sendNotification(title: "All set!", body: "everwatch is watchiiing :)")

        _websites = State(initialValue: (try? JSONDecoder().decode([Website].self, from: savedWebsites)) ?? [])
    }
    func deleteWebsite(at offsets: IndexSet) {
            websites.remove(atOffsets: offsets)
            if let encoded = try? JSONEncoder().encode(websites) {
                savedWebsites = encoded
            }
        }
    func statusIcon(for status: String) -> String {
            switch status {
            case "200": return "checkmark.circle.fill"
            case "Checking...": return "ellipsis.circle"
            default: return "xmark.circle.fill"
            }
        }

        func statusColor(for status: String) -> Color {
            switch status {
            case "200": return .green
            case "Checking...": return .yellow
            default: return .red
            }
        }
    var body: some View {
        TabView {
            NavigationView {
                List {
                    ForEach($websites) { $website in // Use $website to create a binding
                                            NavigationLink(destination: WebsiteDetailView(website: $website)) { 
                                            HStack {
                                                // Status Icon
                                                Image(systemName: statusIcon(for: website.status))
                                                    .foregroundColor(statusColor(for: website.status))

                                                VStack(alignment: .leading) {
                                                    Text(website.name)
                                                        .font(.headline) // Larger font for name
                                                    Text(website.url)
                                                        .font(.caption)  // Smaller font for URL
                                                }
                                            }
                                        }
                                    }
                    .onDelete(perform: deleteWebsite) // Add swipe-to-delete
                }
                .navigationTitle("Everwatch")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: AddWebsiteView(websites: $websites)) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .tabItem {
                Label("Websites", systemImage: "list.dash")
            }
            
            NavigationView {
                PingLatencyView(websites: $websites) // Pass websites as binding
            }
            .tabItem {
                Label("Ping", systemImage: "antenna.radiowaves.left.and.right")
            }
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            
            NavigationView {
                WebsiteStatsView(websites: $websites) // Pass the binding
            }
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
               .onReceive(timer) { _ in
                           for index in websites.indices {
                               Task {
                                   let (statusCode, description, pingTime) = await checkWebsiteStatus(urlString: websites[index].url)
                                   DispatchQueue.main.async {
                                       websites[index].status = description ?? "Unknown"

                                       // Determine if the status is critical
                                       let isCritical = (statusCode != nil && (statusCode! >= 400 || statusCode! < 100)) // 4xx and 5xx are critical, along with other error codes

                                       websites[index].history.append(WebsiteStatusRecord(timestamp: Date(), statusCode: statusCode, statusDescription: description, pingTime: pingTime, isCritical: isCritical))
                                   }
                               }
                           }

                           if let encoded = try? JSONEncoder().encode(websites) {
                               savedWebsites = encoded
                           }
                       }
               
            }
        }
    


struct WebsiteDetailView: View {
    @Binding var website: Website
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack { // HStack to align the name, URL, and gear icon
                    VStack(alignment: .leading) {
                        Text(website.name)
                            .font(.largeTitle)
                            .bold()
                        Text(website.url)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer() // Push the NavigationLink to the right
                    NavigationLink(destination: EditWebsiteView(website: $website)) {
                        Image(systemName: "gear")
                    }
                }
                
                Divider()
                
                Text("Current Status: \(website.status)")
                    .font(.title2)
                
                if website.status == "200" {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                }
                
                Divider()
                
                Text("History:")
                    .font(.title3)
                    .padding(.top)
                
                if website.history.isEmpty {
                    Text("No history yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(groupStatusPeriods(website.history)) { period in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(period.status)
                                .font(.headline)
                            HStack {
                                Text("\(period.startTime, style: .time) - \(period.endTime?.formatted(date: .omitted, time: .shortened) ?? "Now")")
                                    .font(.caption)
                                Text("(\(period.duration))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
    }
}



struct AddWebsiteView: View {
    @Binding var websites: [Website]
    @State private var name: String = ""
    @State private var urlee: String = ""
    @State private var showProtocolAlert = false  // State for alert

    var body: some View {
        NavigationView {
            Form {
                TextField("Website Name", text: $name)
                TextField("Website URL (e.g., example.com)", text: $urlee)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(.URL)
                
                Button("Add Website") {
                    var updatedURL = urlee.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Check and add protocol if missing
                    if !updatedURL.contains("://") {
                        updatedURL = "https://" + updatedURL
                        showProtocolAlert = true
                    }

                    if let url = URL(string: updatedURL) {
                        websites.append(Website(name: name, url: updatedURL))
                        name = ""
                        urlee = ""
                    } else {
                        // Handle invalid URL with an alert
                        showProtocolAlert = true
                    }
                }
            }
            .navigationTitle("Add Website")
            .alert("Protocol Added", isPresented: $showProtocolAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("HTTPS:// was added to the URL to ensure proper website monitoring.")
            }
        } // End of NavigationView
    }
}
struct EditWebsiteView: View {
    @Binding var website: Website
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            TextField("Name", text: $website.name)
            TextField("URL", text: $website.url)
            Toggle("Time Sensitive Notifications", isOn: $website.isTimeSensitiveEnabled)
            Toggle("Skip TLS Verification", isOn: $website.skipTLSVerification)
                .alert(isPresented: $website.skipTLSVerification) {
                    Alert(
                        title: Text("Warning"),
                        message: Text("Skipping TLS verification may expose you to security risks. Use with caution."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            TextField("Usual Status Code", value: $website.usualStatusCode, formatter: NumberFormatter())
        }
        .navigationTitle("Edit Website")
        // Add a Done button to dismiss the view
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
    }
}
func checkWebsiteStatus(urlString: String) async -> (Int?, String?, TimeInterval?) {
    guard let url = URL(string: urlString) else {
        return (nil, "Invalid URL", nil)
    }
    
    var websites = (try? JSONDecoder().decode([Website].self, from: UserDefaults.standard.data(forKey: "savedWebsites") ?? Data())) ?? []
    guard let website = websites.first(where: { $0.url == urlString }) else {
        return (nil, "Website not found", nil)
    }

    var statusCode: Int?
    var statusDescription: String?
    var pingTime: TimeInterval?

    do {
        let start = Date()
        let (data, response) = try await URLSession.shared.data(from: url)
        let end = Date()
        pingTime = end.timeIntervalSince(start)

        if let httpResponse = response as? HTTPURLResponse {
            statusCode = httpResponse.statusCode
            statusDescription = statusCode != nil ? String(statusCode!) : "Unknown"
        } else {
            statusDescription = "Unknown response"
        }
    } catch {
        statusDescription = error.localizedDescription
    }
    // Determine if the status is critical (corrected logic)
    let isCritical = (statusCode != nil && (statusCode! >= 400 || statusCode! < 100)) ||
                         (website.usualStatusCode != nil && statusCode != website.usualStatusCode)

        if let previousStatus = websites.first(where: { $0.url == urlString })?.status,
           statusDescription != previousStatus {
            let notificationType = website.isTimeSensitiveEnabled ? "Time Sensitive" : "Regular"
            sendNotification(title: "Website Status Changed (\(notificationType))", body: "\(urlString) is now \(statusDescription ?? "Unknown")", isCritical: isCritical)
        }else if let previousStatus = websites.first(where: { $0.url == urlString })?.status,
                   statusDescription != previousStatus { // Send normal notification if non-critical status change
           sendNotification(title: "Website Status Changed", body: "\(urlString) is now \(statusDescription ?? "Unknown")")
       }

       // Save updated website information back to UserDefaults
       if let index = websites.firstIndex(where: { $0.url == urlString }) {
           websites[index].status = statusDescription ?? "Unknown"
           websites[index].history.append(WebsiteStatusRecord(timestamp: Date(), statusCode: statusCode, statusDescription: statusDescription, pingTime: pingTime, isCritical: true))
           
           if let encoded = try? JSONEncoder().encode(websites) {
               UserDefaults.standard.set(encoded, forKey: "savedWebsites")
           }
       }

       return (statusCode, statusDescription, pingTime)
   }


// Helper function to group consecutive status records
func groupStatusPeriods(_ history: [WebsiteStatusRecord]) -> [WebsiteStatusPeriod] {
    guard !history.isEmpty else { return [] }

    var periods: [WebsiteStatusPeriod] = []
    var currentPeriod = WebsiteStatusPeriod(status: history[0].statusDescription ?? "Unknown", startTime: history[0].timestamp, endTime: nil)

    for record in history.dropFirst() {
        if record.statusDescription == currentPeriod.status {
            continue // Same status, extend the current period
        } else {
            currentPeriod.endTime = record.timestamp // End the current period
            periods.append(currentPeriod)
            currentPeriod = WebsiteStatusPeriod(status: record.statusDescription ?? "Unknown", startTime: record.timestamp, endTime: nil) // Start a new period
        }
    }
    
    // Append the last (potentially ongoing) period
    periods.append(currentPeriod)

    return periods.reversed() // Reverse the order
}
func sendNotification(title: String, body: String, isCritical: Bool = false) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    if #available(iOS 15.0, *) {
        content.interruptionLevel = isCritical ? .timeSensitive : .timeSensitive // Set interruption level
    }

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false) // Example trigger
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error sending notification: \(error.localizedDescription)")
        }
    }
}


// Background Task Identifier
let websiteCheckTaskIdentifier = "yzde.everwatch" // Replace with your actual identifier

func scheduleBackgroundCheck() {
    let request = BGProcessingTaskRequest(identifier: websiteCheckTaskIdentifier)
    request.requiresNetworkConnectivity = true // Require network for website checks
    request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // Start in 1 minute

    do {
        try BGTaskScheduler.shared.submit(request)
        print("Background task scheduled.")
    } catch {
        print("Could not schedule background task: \(error)")
    }
}

func handleBackgroundCheck(task: BGTask) {
    scheduleBackgroundCheck() // Reschedule the next check immediately
    
    // Load websites from UserDefaults
    var websites = (try? JSONDecoder().decode([Website].self, from: UserDefaults.standard.data(forKey: "savedWebsites") ?? Data())) ?? []
    
    // Check each website's status
    Task {
        for website in websites {
            let (statusCode, description, pingTime) = await checkWebsiteStatus(urlString: website.url)
            DispatchQueue.main.async {
                if let index = websites.firstIndex(where: { $0.url == website.url }) {
                    websites[index].status = description ?? "Unknown"
                    
                    // Determine if the status is critical
                    let isCritical = (statusCode != nil && (statusCode! >= 400 || statusCode! < 100))
                    
                    websites[index].history.append(WebsiteStatusRecord(timestamp: Date(), statusCode: statusCode, statusDescription: description, pingTime: pingTime, isCritical: isCritical))
                    
                    // Save updated websites back to UserDefaults
                    if let encoded = try? JSONEncoder().encode(websites) {
                        UserDefaults.standard.set(encoded, forKey: "savedWebsites")
                    }
                }
            }
        }
        task.setTaskCompleted(success: true)
    }
}
