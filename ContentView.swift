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
    let cadence: Int
    let lastContactDate: Date

    var urgency: Int {
        let today = Date()
        let daysSinceLastContact = Calendar.current.dateComponents([.day], from: lastContactDate, to: today).day ?? 0
        return daysSinceLastContact - cadence
    }

    var touchpointStatus: String {
        if urgency < 0 {
            let daysRemaining = -urgency
            if daysRemaining == 1 {
                return "Due tomorrow"
            } else {
                return "Due in \(daysRemaining) days"
            }
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
    @State private var contacts = [
        Contact(name: "John Doe", cadence: 2, lastContactDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
        Contact(name: "Jane Smith", cadence: 1, lastContactDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
        Contact(name: "Alice Johnson", cadence: 1, lastContactDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!),
        Contact(name: "Robert Brown", cadence: 7, lastContactDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
        Contact(name: "Emily Davis", cadence: 30, lastContactDate: Calendar.current.date(byAdding: .day, value: -25, to: Date())!),
        Contact(name: "Chris Wilson", cadence: 14, lastContactDate: Calendar.current.date(byAdding: .day, value: -20, to: Date())!)
    ]

    var body: some View {
        NavigationSplitView {
            List {
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
                            Circle()
                                .fill(contact.statusColor)
                                .frame(width: 12, height: 12)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .toolbar {
                // Toolbar Items
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    // Debugging function (must be declared outside 'body')
    private func debugContacts() {
        for contact in contacts {
            let daysSinceLastContact = Calendar.current.dateComponents([.day], from: contact.lastContactDate, to: Date()).day ?? 0
            print("\(contact.name): daysSinceLastContact = \(daysSinceLastContact), cadence = \(contact.cadence), urgency = \(contact.urgency)")
        }
    }

    // Placeholder function for adding items
    private func addItem() {
        print("Add item functionality not implemented yet.")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
