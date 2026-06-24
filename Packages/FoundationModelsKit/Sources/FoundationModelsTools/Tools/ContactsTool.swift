//
//  ContactsTool.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/17/25.
//

@preconcurrency import Contacts
import Foundation
import FoundationModels
import FoundationModelsKit

/// A tool for managing contacts using the Contacts framework.
///
/// Use `ContactsTool` to search, read, and create contacts.
/// It integrates with the system Contacts app and requires appropriate permissions.
///
/// The following actions are supported:
/// - `search`: Search contacts by name, email, or phone number
/// - `read`: Read detailed information for a specific contact by ID
/// - `create`: Create a new contact with provided information
///
/// ```swift
/// let session = LanguageModelSession(tools: [ContactsTool()])
/// let response = try await session.respond(to: "Find John's phone number")
/// ```
///
/// - Important: Requires Contacts entitlement, `NSContactsUsageDescription` in Info.plist,
///   and user permission at runtime.
public struct ContactsTool: Tool {

    /// The name of the tool, used for identification.
    public let name = "manageContacts"
    /// A brief description of the tool's functionality.
    public let description = "Search, read, and create contacts from the Contacts app"

    /// Arguments for contact operations.
    @Generable
    public struct Arguments: RuntimeCompatibleGenerable {
        /// The action to perform: "search", "read", "create"
        @Guide(description: "The action to perform: 'search', 'read', 'create'")
        public var action: String

        /// Name to search for (for search action)
        @Guide(description: "Name to search for (for search action)")
        public var name: String?

        /// Contact identifier for reading
        @Guide(description: "Contact identifier for reading")
        public var contactId: String?

        /// First name for creating contact
        @Guide(description: "First name for creating contact")
        public var firstName: String?

        /// Last name for creating contact
        @Guide(description: "Last name for creating contact")
        public var lastName: String?

        /// Phone number for creating contact
        @Guide(description: "Phone number for creating contact")
        public var phoneNumber: String?

        /// Email address for creating contact
        @Guide(description: "Email address for creating contact")
        public var email: String?

        /// Organization for creating contact
        @Guide(description: "Organization for creating contact")
        public var organization: String?

        public init(
            action: String = "",
            name: String? = nil,
            contactId: String? = nil,
            firstName: String? = nil,
            lastName: String? = nil,
            phoneNumber: String? = nil,
            email: String? = nil,
            organization: String? = nil
        ) {
            self.action = action
            self.name = name
            self.contactId = contactId
            self.firstName = firstName
            self.lastName = lastName
            self.phoneNumber = phoneNumber
            self.email = email
            self.organization = organization
        }
    }

    private let store = CNContactStore()

    public init() {}

    public func call(arguments: Arguments) async throws -> GeneratedContent {
        // Request access if needed
        let authorized = await requestAccess()
        guard authorized else {
            return createErrorOutput(error: ContactsError.accessDenied)
        }

        switch arguments.action.lowercased() {
        case "search":
            return try searchContacts(query: arguments.name)
        case "read":
            return try readContact(contactId: arguments.contactId)
        case "create":
            return try createContact(arguments: arguments)
        default:
            return createErrorOutput(error: ContactsError.invalidAction)
        }
    }

    private func requestAccess() async -> Bool {
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            return false
        }
    }

    private func searchContacts(query: String?) throws -> GeneratedContent {
        guard let searchQuery = query, !searchQuery.isEmpty else {
            return createErrorOutput(error: ContactsError.missingQuery)
        }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor
        ]

        let predicate = CNContact.predicateForContacts(matchingName: searchQuery)

        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)

            if contacts.isEmpty {
                // Try searching by email or phone
                let allContacts = try store.unifiedContacts(
                    matching: NSPredicate(value: true),
                    keysToFetch: keysToFetch
                )

                let filteredContacts = allContacts.filter { contact in
                    // Check emails
                    for email in contact.emailAddresses where email.value.contains(searchQuery) {
                        return true
                    }
                    // Check phone numbers
                    for phone in contact.phoneNumbers where phone.value.stringValue.contains(searchQuery) {
                        return true
                    }
                    return false
                }

                return formatContactsOutput(contacts: filteredContacts, query: searchQuery)
            }

            return formatContactsOutput(contacts: contacts, query: searchQuery)
        } catch {
            return createErrorOutput(error: error)
        }
    }

    private func readContact(contactId: String?) throws -> GeneratedContent {
        guard let id = contactId else {
            return createErrorOutput(error: ContactsError.missingContactId)
        }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactNoteKey as CNKeyDescriptor
        ]

        do {
            let contact = try store.unifiedContact(withIdentifier: id, keysToFetch: keysToFetch)

            var addresses: [String] = []
            for address in contact.postalAddresses {
                let value = address.value
                let formatted = "\(value.street), \(value.city), \(value.state) \(value.postalCode)"
                addresses.append(formatted)
            }

            return GeneratedContent(properties: [
                "status": "success",
                "contactId": contact.identifier,
                "givenName": contact.givenName,
                "familyName": contact.familyName,
                "fullName": "\(contact.givenName) \(contact.familyName)".trimmingCharacters(
                    in: .whitespaces),
                "organization": contact.organizationName,
                "emails": contact.emailAddresses.map { $0.value as String },
                "phoneNumbers": contact.phoneNumbers.map { $0.value.stringValue },
                "addresses": addresses,
                "birthday": contact.birthday?.date?.description ?? "",
                "note": contact.note
            ])
        } catch {
            return createErrorOutput(error: error)
        }
    }

    private func createContact(arguments: Arguments) throws -> GeneratedContent {
        guard let firstName = arguments.firstName, !firstName.isEmpty else {
            return createErrorOutput(error: ContactsError.missingName)
        }

        let newContact = CNMutableContact()
        newContact.givenName = firstName

        if let lastName = arguments.lastName {
            newContact.familyName = lastName
        }

        if let email = arguments.email {
            newContact.emailAddresses = [
                CNLabeledValue(label: CNLabelHome, value: NSString(string: email))
            ]
        }

        if let phone = arguments.phoneNumber {
            newContact.phoneNumbers = [
                CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone))
            ]
        }

        if let org = arguments.organization {
            newContact.organizationName = org
        }

        let saveRequest = CNSaveRequest()
        saveRequest.add(newContact, toContainerWithIdentifier: nil)

        do {
            try store.execute(saveRequest)

            return GeneratedContent(properties: [
                "status": "success",
                "message": "Contact created successfully",
                "contactId": newContact.identifier,
                "givenName": newContact.givenName,
                "familyName": newContact.familyName,
                "fullName": "\(newContact.givenName) \(newContact.familyName)".trimmingCharacters(
                    in: .whitespaces),
                "email": arguments.email ?? "",
                "phoneNumber": arguments.phoneNumber ?? "",
                "organization": arguments.organization ?? ""
            ])

        } catch {
            return createErrorOutput(error: error)
        }
    }

    private func formatContactsOutput(contacts: [CNContact], query: String) -> GeneratedContent {
        var contactsDescription = ""

        for (index, contact) in contacts.enumerated() {
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            let email = contact.emailAddresses.first?.value as String? ?? "No email"
            let phone = contact.phoneNumbers.first?.value.stringValue ?? "No phone"
            let org = contact.organizationName.isEmpty ? "" : " (\(contact.organizationName))"

            contactsDescription += "\(index + 1). \(name)\(org) - Email: \(email), Phone: \(phone)\n"
        }

        if contactsDescription.isEmpty {
            contactsDescription = "No contacts found matching '\(query)'"
        }

        return GeneratedContent(properties: [
            "status": "success",
            "query": query,
            "count": contacts.count,
            "results": contactsDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            "message": "Found \(contacts.count) contact(s) matching '\(query)'"
        ])
    }

    private func createErrorOutput(error: Error) -> GeneratedContent {
        GeneratedContent(properties: [
            "status": "error",
            "error": error.localizedDescription,
            "message": "Failed to perform contact operation"
        ])
    }
}

enum ContactsError: Error, LocalizedError {
    case accessDenied
    case invalidAction
    case missingQuery
    case missingContactId
    case missingName

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to contacts denied. Please grant permission in Settings."
        case .invalidAction:
            return "Invalid action. Use 'search', 'read', or 'create'."
        case .missingQuery:
            return "Search query is required."
        case .missingContactId:
            return "Contact ID is required."
        case .missingName:
            return "Given name is required to create a contact."
        }
    }
}
