//  ContentView.swift
//  Tchpnt
//
//  Created by Tanner Briggs on 1/3/25.
//

import SwiftUI
import SwiftData

// ✅ Define the Contact model for SwiftData persistence
@Model
class Contact: Identifiable {
    var id: UUID
    var name: String
    var phoneNumber: String
    var cadence: Int
    var lastContactDate: Date
    var preferredAction: String // "Text", "Call", or "Meet Up"

    var urgency: Int {
        let today = Date()
        let daysSinceLastContact = Calendar.current.dateComponents([.day], from: lastContactDate, to: today).day ?? 0
        return daysSinceLastContact - cadence
    }

    var statusColor: Color {
        if urgency > 0 {
            return .red
        } else if urgency == 0 {
            return .blue
        } else {
            return .green
        }
    }

    init(name: String, phoneNumber: String, cadence: Int, lastContactDate: Date, preferredAction: String) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.cadence = cadence
        self.lastContactDate = lastContactDate
        self.preferredAction = preferredAction
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]

    enum ActiveAlert {
        case reset
        case delete
    }
    
    @State private var activeAlert: ActiveAlert?
    @State private var selectedContact: Contact?
    @State private var expandedContactId: UUID?
    @State private var refreshTrigger = false
    @State private var lastUpdateDate = Calendar.current.startOfDay(for: Date())
    @State private var contactToDelete: Contact?

    var body: some View {
        NavigationSplitView {
            List {
                if contacts.isEmpty {
                    Text("No touchpoints available. Add a new one!")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    Section(header: Text("Touchpoints")) {
                        ForEach(contacts.sorted(by: { $0.urgency > $1.urgency })) { contact in
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(contact.name)
                                            .font(.headline)
                                        Text(contactStatus(for: contact))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: {
                                        print("🔵 Quick action button tapped for \(contact.name)")
                                        handleAction(for: contact)
                                    }) {
                                        Image(systemName: iconName(for: contact.preferredAction))
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())

                                    Circle()
                                        .fill(contact.statusColor)
                                        .frame(width: 12, height: 12)
                                }
                                .padding(.vertical, 5)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if expandedContactId == contact.id {
                                        expandedContactId = nil
                                    } else {
                                        expandedContactId = contact.id
                                    }
                                }

                                if expandedContactId == contact.id {
                                    HStack {
                                        Button(action: {
                                            print("🔵 Text button tapped for \(contact.name)")
                                            openMessages(for: contact)
                                            print("📱 Messages opened")
                                            selectedContact = contact
                                            print("👤 Selected contact set to \(contact.name)")
                                            activeAlert = .reset
                                            print("🔔 Active alert set to reset")
                                        }) {
                                            Image(systemName: "message")
                                            Text("Text")
                                        }
                                        .buttonStyle(.bordered)

                                        Button(action: {
                                            print("🔵 Call button tapped for \(contact.name)")
                                            makeCall(to: contact)
                                            print("📞 Call initiated")
                                            selectedContact = contact
                                            print("👤 Selected contact set to \(contact.name)")
                                            activeAlert = .reset
                                            print("🔔 Active alert set to reset")
                                        }) {
                                            Image(systemName: "phone")
                                            Text("Call")
                                        }
                                        .buttonStyle(.bordered)

                                        Button(action: {
                                            print("🔵 Meet Up button tapped for \(contact.name)")
                                            selectedContact = contact
                                            print("👤 Selected contact set to \(contact.name)")
                                            activeAlert = .reset
                                            print("🔔 Active alert set to reset")
                                        }) {
                                            Image(systemName: "person")
                                            Text("Meet Up")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    .padding(.top, 5)
                                }
                            }
                        }
                        .onDelete { offsets in
                            let sortedContacts = contacts.sorted(by: { $0.urgency > $1.urgency })
                            for index in offsets {
                                contactToDelete = sortedContacts[index]
                                activeAlert = .delete
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NewTouchpointView(
                        saveTouchpoint: { newContact in
                            addContact(newContact)
                        },
                        existingContacts: contacts
                    )) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                print("📋 Contacts loaded: \(contacts.count)")
                for contact in contacts {
                    print("📌 Loaded Contact: \(contact.name), \(contact.phoneNumber)")
                }

                //moves timer to main thread so that it works even if app is backgrounded
                DispatchQueue.main.async {
                    // ⏰ Schedule timer to check for midnight refresh every 60 seconds
                    Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                        checkForMidnightRefresh()
                    }
                }
            }
            .onChange(of: refreshTrigger) {
                print("🔄 Refreshing UI due to new contact.")
            }
        } detail: {
            Text("Select an item")
        }
        .alert("Reset Touchpoint", isPresented: .init(
            get: { activeAlert == .reset },
            set: { if !$0 { activeAlert = nil } }
        )) {
            Button("Yes") {
                print("✅ Alert 'Yes' button tapped")
                if let contact = selectedContact {
                    resetTouchpoint(for: contact)
                }
                activeAlert = nil
            }
            Button("Cancel", role: .cancel) {
                print("❌ Alert cancelled")
                activeAlert = nil
            }
        } message: {
            Text("Do you want to reset \(selectedContact?.name ?? "")'s touchpoint?")
        }
        .alert("Delete Contact", isPresented: .init(
            get: { activeAlert == .delete },
            set: { if !$0 { activeAlert = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let contact = contactToDelete {
                    deleteContact(contact)
                }
                activeAlert = nil
            }
            Button("Cancel", role: .cancel) {
                activeAlert = nil
            }
        } message: {
            Text("Are you sure you want to delete \(contactToDelete?.name ?? "this contact")?")
        }
    }

    private func contactStatus(for contact: Contact) -> String {
        let daysSinceLastContact = Calendar.current.dateComponents([.day], from: contact.lastContactDate, to: Date()).day ?? 0
        let overdueDays = daysSinceLastContact - contact.cadence
        if overdueDays > 0 {
            return "Overdue by \(overdueDays) days"
        } else if overdueDays == 0 {
            return "Due today"
        } else {
            return "Due in \(-overdueDays) days"
        }
    }

    private func openMessages(for contact: Contact) {
        guard let url = URL(string: "sms:\(contact.phoneNumber)") else { return }
        UIApplication.shared.open(url)
    }

    private func makeCall(to contact: Contact) {
        guard let url = URL(string: "tel:\(contact.phoneNumber)") else { return }
        UIApplication.shared.open(url)
    }

    private func iconName(for action: String) -> String {
        switch action {
        case "Text":
            return "message"
        case "Call":
            return "phone"
        case "Meet Up":
            return "person"
        default:
            return "questionmark"
        }
    }

    private func handleAction(for contact: Contact) {
        print("🎯 handleAction called for \(contact.name)")
        switch contact.preferredAction {
        case "Text":
            openMessages(for: contact)
            print("📱 Messages opened")
            selectedContact = contact
            print("👤 Selected contact set to \(contact.name)")
            activeAlert = .reset
            print("🔔 Active alert set to reset")
        case "Call":
            makeCall(to: contact)
            print("📞 Call initiated")
            selectedContact = contact
            print("👤 Selected contact set to \(contact.name)")
            activeAlert = .reset
            print("🔔 Active alert set to reset")
        case "Meet Up":
            selectedContact = contact
            print("👤 Selected contact set to \(contact.name)")
            activeAlert = .reset
            print("🔔 Active alert set to reset")
        default:
            break
        }
    }

    private func addContact(_ contact: Contact) {
        print("🟡 Attempting to save contact: \(contact.name), \(contact.phoneNumber)")

        do {
            modelContext.insert(contact)
            try modelContext.save()  // ✅ Explicitly save to SwiftData
            print("✅ Contact successfully saved!")
            printAllContacts()  // 🔍 Debugging: Print all stored contacts
        } catch {
            print("❌ Failed to save contact: \(error.localizedDescription)")
        }

        refreshTrigger.toggle() // 🔄 Force UI refresh
    }

    private func printAllContacts() {
        let request = FetchDescriptor<Contact>()
        do {
            let savedContacts = try modelContext.fetch(request)
            print("📜 All saved contacts: \(savedContacts.map { "\($0.name), \($0.phoneNumber)" })")
        } catch {
            print("❌ Error fetching contacts: \(error.localizedDescription)")
        }
    }

    private func resetTouchpoint(for contact: Contact) {
        print("🔄 Starting reset for \(contact.name)")
        contact.lastContactDate = Date()
        print("📅 Updated lastContactDate to \(contact.lastContactDate)")

        do {
            try modelContext.save()
            print("💾 Changes saved to SwiftData")
            refreshTrigger.toggle()
            print("🔄 UI refresh triggered")
        } catch {
            print("❌ Failed to save reset touchpoint: \(error.localizedDescription)")
        }
    }

    private func deleteContact(_ contact: Contact) {
        modelContext.delete(contact)
        do {
            try modelContext.save()
            print("🗑️ Deleted contact: \(contact.name)")
        } catch {
            print("❌ Failed to delete contact: \(error.localizedDescription)")
        }
    }

    private func checkForMidnightRefresh() {
        let today = Calendar.current.startOfDay(for: Date())
        if today > lastUpdateDate {
            lastUpdateDate = today
            refreshTrigger.toggle()
            print("⏰ Midnight passed, refreshing UI!")
        } else {
            print("No refresh needed, Same day, but timer works.")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
