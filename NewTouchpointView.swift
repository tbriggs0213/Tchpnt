//
//  NewTouchpointView.swift
//  Tchpnt
//
//  Created by Tanner Briggs on 1/4/25.
//

import SwiftUI
import ContactsUI

struct NewTouchpointView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var contactName: String = ""
    @State private var cadence: Int = 7 // Default to weekly
    @State private var preferredAction: String = "Text"

    let saveTouchpoint: (Contact) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact")) {
                    Button(action: showContactPicker) {
                        Text(contactName.isEmpty ? "Select Contact" : contactName)
                    }
                }

                Section(header: Text("Cadence")) {
                    Picker("Frequency", selection: $cadence) {
                        Text("Daily").tag(1)
                        Text("Weekly").tag(7)
                        Text("Monthly").tag(30)
                        Text("Custom (e.g., 14 days)").tag(14) // Add more options as needed
                    }
                    .pickerStyle(WheelPickerStyle())
                }

                Section(header: Text("Preferred Action")) {
                    Picker("Action", selection: $preferredAction) {
                        Text("Text").tag("Text")
                        Text("Call").tag("Call")
                        Text("Meet Up").tag("Meet Up")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section {
                    Button(action: save) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("New Touchpoint")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func showContactPicker() {
        // Placeholder for Contact Picker Integration
        print("Contact picker will be integrated here.")
    }

    private func save() {
        guard !contactName.isEmpty else { return }
        let newTouchpoint = Contact(
            name: contactName,
            cadence: cadence,
            lastContactDate: Date(), // Default to now
            preferredAction: preferredAction // Pass the preferred action here
        )
        saveTouchpoint(newTouchpoint)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    NewTouchpointView(saveTouchpoint: { _ in })
}
