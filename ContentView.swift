//
//  ContentView.swift
//  Tchpnt
//
//  Created by Tanner Briggs on 1/3/25.
//

import SwiftUI
import SwiftData

// Define the Contact struct for stack rank data
struct Contact: Identifiable {
    let id = UUID()
    let name: String
    let phoneNumber: String // Store phone number for actual contact linkage
    let cadence: Int
    var lastContactDate: Date // Mutable for resetting
    let preferredAction: String // "Text", "Call", or "Meet Up"

    var urgency: Int {
        let today = Date()
        let daysSinceLastContact = Calendar.current.dateComponents([.day], from: lastContactDate, to: today).day ?? 0
        return daysSinceLastContact - cadence
    }

    var touchpointStatus: String {
        if urgency < 0 {
            let daysRemaining = -urgency
            return daysRemaining == 1 ? "Due tomorrow" : "Due in \(daysRemaining) days"
        } else if urgency == 0 {
            return "Due today"
        } else {
            return "Overdue by \(urgency) days"
        }
    }

    var statusColor: Color {
        if urgency > 0 {
            return .red
        } else if urgency == 0 {
            return .blue
        } else if urgency == -1 {
            return .yellow
        } else {
            return .green
        }
    }
}

struct ContentView: View {
    @State private var contacts: [Contact] = [
        Contact(name: "John Doe", phoneNumber: "123-456-7890", cadence: 2, lastContactDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, preferredAction: "Text"),
        Contact(name: "Jane Smith", phoneNumber: "987-654-3210", cadence: 1, lastContactDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, preferredAction: "Call"),
        Contact(name: "Alice Johnson", phoneNumber: "555-123-4567", cadence: 1, lastContactDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, preferredAction: "Meet Up"),
        Contact(name: "Robert Brown", phoneNumber: "111-222-3333", cadence: 7, lastContactDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, preferredAction: "Text"),
        Contact(name: "Emily Davis", phoneNumber: "444-555-6666", cadence: 30, lastContactDate: Calendar.current.date(byAdding: .day, value: -25, to: Date())!, preferredAction: "Call"),
        Contact(name: "Chris Wilson", phoneNumber: "777-888-9999", cadence: 14, lastContactDate: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, preferredAction: "Meet Up")
    ]

    @State private var showResetAlert = false
    @State private var selectedContact: Contact?

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
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contact.name)
                                        .font(.headline)
                                    Text(contact.touchpointStatus)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Button(action: { handleAction(for: contact) }) {
                                    Image(systemName: iconName(for: contact.preferredAction))
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                Circle()
                                    .fill(contact.statusColor)
                                    .frame(width: 12, height: 12)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .toolbar {
                // Toolbar Items
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NewTouchpointView(
                        saveTouchpoint: { newContact in
                            contacts.append(newContact)
                        },
                        existingContacts: contacts // Pass existing contacts to check for duplicates
                    )) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Reset Touchpoint"),
                message: Text("Do you want to reset \(selectedContact?.name ?? "")'s touchpoint?"),
                primaryButton: .default(Text("Yes"), action: {
                    if let contact = selectedContact {
                        resetTouchpoint(for: contact)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
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
        switch contact.preferredAction {
        case "Text":
            openMessages(for: contact)
        case "Call":
            makeCall(to: contact)
        case "Meet Up":
            promptReset(for: contact)
        default:
            break
        }
    }

    private func openMessages(for contact: Contact) {
        guard let url = URL(string: "sms:\(contact.phoneNumber)") else { return }
        UIApplication.shared.open(url)
        promptReset(for: contact)
    }

    private func makeCall(to contact: Contact) {
        guard let url = URL(string: "tel://\(contact.phoneNumber)") else { return }
        UIApplication.shared.open(url)
        promptReset(for: contact)
    }

    private func promptReset(for contact: Contact) {
        selectedContact = contact
        showResetAlert = true
    }

    private func resetTouchpoint(for contact: Contact) {
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index].lastContactDate = Date()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
