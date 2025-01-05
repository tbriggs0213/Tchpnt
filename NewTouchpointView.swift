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
    @State private var customCadence: Int = 7 // Custom cadence default
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
                        Text("Custom").tag(0) // Tag 0 for Custom
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if cadence == 0 { // Show input for custom cadence
                        TextField("Enter custom days (1–365)", value: $customCadence, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .onChange(of: customCadence) { newValue in
                                if newValue < 1 { customCadence = 1 }
                                if newValue > 365 { customCadence = 365 }
                            }
                    }
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
        let effectiveCadence = cadence == 0 ? customCadence : cadence
        let newTouchpoint = Contact(
            name: contactName,
            cadence: effectiveCadence,
            lastContactDate: Date(),
            preferredAction: preferredAction
        )
        saveTouchpoint(newTouchpoint)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    NewTouchpointView(saveTouchpoint: { _ in })
}

