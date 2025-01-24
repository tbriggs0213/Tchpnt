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

    var statusColor: Color {
        if urgency > 0 {
            return .red
        } else if urgency == 0 {
            return .blue
        } else {
            return .green
        }
    }
}

struct ContentView: View {
    @State private var contacts: [Contact] = []
    @State private var showResetAlert = false
    @State private var selectedContact: Contact?
    @State private var expandedContactId: UUID?

    var body: some View {
        NavigationSplitView {
            List {
                if contacts.isEmpty {
                    Text("No touchpoints available. Add a new one!")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    Section(header: Text("Touchpoints")) {
                        ForEach(contacts.sorted(by: { $0.lastContactDate < $1.lastContactDate })) { contact in
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
                                .contentShape(Rectangle()) // Ensure the entire row is tappable
                                .onTapGesture {
                                    if expandedContactId == contact.id {
                                        expandedContactId = nil
                                    } else {
                                        expandedContactId = contact.id
                                    }
                                }
                                
                                if expandedContactId == contact.id {
                                    HStack {
                                        Button(action: { openMessages(for: contact) }) {
                                            Image(systemName: "message")
                                            Text("Text")
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button(action: { makeCall(to: contact) }) {
                                            Image(systemName: "phone")
                                            Text("Call")
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button(action: { promptReset(for: contact) }) {
                                            Image(systemName: "person")
                                            Text("Meet Up")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    .padding(.top, 5)
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
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

    private func promptReset(for contact: Contact) {
        selectedContact = contact
        showResetAlert = true
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
