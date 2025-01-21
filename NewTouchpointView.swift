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
    @State private var phoneNumber: String = "" // Store the contact’s phone number
    @State private var cadence: Int = 7 // Default to weekly
    @State private var customCadence: String = "" // Custom cadence starts blank
    @State private var preferredAction: String = "Text"
    @State private var showContactPicker = false // State for showing contact picker
    @State private var showDuplicateAlert = false // Alert for duplicate contacts

    let saveTouchpoint: (Contact) -> Void
    let existingContacts: [Contact] // List of existing contacts to check for duplicates

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact")) {
                    Button(action: {
                        showContactPicker = true // Show the Contact Picker
                    }) {
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
                        TextField("Enter custom days (1–365)", text: $customCadence)
                            .keyboardType(.numberPad)
                            .onChange(of: customCadence) {
                                if let value = Int(customCadence), value < 1 {
                                    customCadence = "1"
                                } else if let value = Int(customCadence), value > 365 {
                                    customCadence = "365"
                                }
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
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView { selectedName, selectedPhone in
                    contactName = selectedName
                    phoneNumber = selectedPhone
                }
            }
            .alert(isPresented: $showDuplicateAlert) {
                Alert(
                    title: Text("Duplicate Contact"),
                    message: Text("\(contactName) is already in your touchpoints."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func save() {
        guard !contactName.isEmpty, !phoneNumber.isEmpty else { return }

        // Check for duplicate phone numbers
        if existingContacts.contains(where: { $0.phoneNumber == phoneNumber }) {
            showDuplicateAlert = true
            return
        }

        let effectiveCadence: Int
        if cadence == 0, let customValue = Int(customCadence), customValue >= 1, customValue <= 365 {
            effectiveCadence = customValue
        } else {
            effectiveCadence = cadence
        }

        let newTouchpoint = Contact(
            name: contactName,
            phoneNumber: phoneNumber,
            cadence: effectiveCadence,
            lastContactDate: Date(),
            preferredAction: preferredAction
        )
        
        saveTouchpoint(newTouchpoint)
        presentationMode.wrappedValue.dismiss()
    }
}

struct ContactPickerView: UIViewControllerRepresentable {
    let onSelect: (String, String) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(onSelect: onSelect)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: (String, String) -> Void

        init(onSelect: @escaping (String, String) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let fullName = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ") // Get full name of contact

            let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? "Unknown" // Extract phone number
            onSelect(fullName, phoneNumber)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            // Handle cancel action (optional)
        }
    }
}

#Preview {
    NewTouchpointView(
        saveTouchpoint: { _ in },
        existingContacts: []
    )
}
