//
//  RemindersTool.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/17/25.
//

@preconcurrency import EventKit
import Foundation
import FoundationModels
import FoundationModelsKit

/// A tool for managing reminders using EventKit.
///
/// Use `RemindersTool` for create, read, update, complete, and delete operations
/// for reminders. It integrates with the system Reminders app.
///
/// The following actions are supported:
/// - `create`: Create a new reminder
/// - `query`: Query reminders with optional filters
/// - `complete`: Mark a reminder as completed
/// - `update`: Update an existing reminder
/// - `delete`: Delete a reminder
///
/// Query filters include: `all`, `incomplete`, `completed`, `today`, and `overdue`.
///
/// ```swift
/// let session = LanguageModelSession(tools: [RemindersTool()])
/// let response = try await session.respond(to: "Remind me to buy groceries tomorrow")
/// ```
///
/// - Important: Requires Reminders entitlement, `NSRemindersUsageDescription` in Info.plist,
///   and user permission at runtime.
public struct RemindersTool: Tool {

  /// The name of the tool, used for identification.
  public let name = "manageReminders"
  /// A brief description of the tool's functionality.
  public let description =
    "Create, read, update, complete, and query reminders from the Reminders app"

  /// Arguments for reminder operations.
  @Generable
  public struct Arguments: RuntimeCompatibleGenerable {
    /// The action to perform: "create", "query", "complete", "update", "delete"
    @Guide(description: "The action to perform: 'create', 'query', 'complete', 'update', 'delete'")
    public var action: String

    /// Title of the reminder
    @Guide(description: "Title of the reminder")
    public var title: String?

    /// Notes for the reminder
    @Guide(description: "Notes for the reminder")
    public var notes: String?

    /// Due date in format YYYY-MM-DD HH:mm:ss (24-hour format). Examples: '2025-01-15 17:00:00' for tomorrow at 5 PM
    @Guide(
      description:
        "Due date in format YYYY-MM-DD HH:mm:ss (24-hour format). Examples: '2025-01-15 17:00:00' for tomorrow at 5 PM"
    )
    public var dueDate: String?

    /// Priority level: "none", "low", "medium", "high"
    @Guide(description: "Priority level: 'none', 'low', 'medium', 'high'")
    public var priority: String?

    /// List name (defaults to default reminders list)
    @Guide(description: "List name (defaults to default reminders list)")
    public var listName: String?

    /// Reminder identifier for updating/completing
    @Guide(description: "Reminder identifier for updating/completing")
    public var reminderId: String?

    /// Filter for querying: "all", "incomplete", "completed", "today", "overdue"
    @Guide(description: "Filter for querying: 'all', 'incomplete', 'completed', 'today', 'overdue'")
    public var filter: String?

    public init(
      action: String = "",
      title: String? = nil,
      notes: String? = nil,
      dueDate: String? = nil,
      priority: String? = nil,
      listName: String? = nil,
      reminderId: String? = nil,
      filter: String? = nil
    ) {
      self.action = action
      self.title = title
      self.notes = notes
      self.dueDate = dueDate
      self.priority = priority
      self.listName = listName
      self.reminderId = reminderId
      self.filter = filter
    }
  }

  nonisolated(unsafe) private let eventStore = EKEventStore()

  public init() {}

  public func call(arguments: Arguments) async throws -> some PromptRepresentable {
    // Request access if needed
    let authorized = await requestAccess()
    guard authorized else {
      return createErrorOutput(error: RemindersError.accessDenied)
    }

    switch arguments.action.lowercased() {
    case "create":
      return try createReminder(arguments: arguments)
    case "query":
      return await queryReminders(arguments: arguments)
    case "complete":
      return try completeReminder(reminderId: arguments.reminderId)
    case "update":
      return try updateReminder(arguments: arguments)
    case "delete":
      return try deleteReminder(reminderId: arguments.reminderId)
    default:
      return createErrorOutput(error: RemindersError.invalidAction)
    }
  }

  private func requestAccess() async -> Bool {
    do {
      if #available(macOS 14.0, iOS 17.0, *) {
        return try await eventStore.requestFullAccessToReminders()
      } else {
        return try await eventStore.requestAccess(to: .reminder)
      }
    } catch {
      return false
    }
  }

  private func createReminder(arguments: Arguments) throws -> GeneratedContent {
    guard let title = arguments.title, !title.isEmpty else {
      return createErrorOutput(error: RemindersError.missingTitle)
    }

    let reminder = EKReminder(eventStore: eventStore)
    reminder.title = title

    if let notes = arguments.notes {
      reminder.notes = notes
    }

    if let dueDateString = arguments.dueDate,
      let dueDate = parseDate(dueDateString) {
      reminder.dueDateComponents = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: dueDate
      )
    }

    // Set priority
    if let priorityString = arguments.priority {
      switch priorityString.lowercased() {
      case "high":
        reminder.priority = 1
      case "medium":
        reminder.priority = 5
      case "low":
        reminder.priority = 9
      default:
        reminder.priority = 0  // none
      }
    }

    // Set calendar (list)
    if let listName = arguments.listName {
      let calendars = eventStore.calendars(for: .reminder)
      if let calendar = calendars.first(where: { $0.title == listName }) {
        reminder.calendar = calendar
      } else {
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
      }
    } else {
      reminder.calendar = eventStore.defaultCalendarForNewReminders()
    }

    do {
      try eventStore.save(reminder, commit: true)

      return GeneratedContent(properties: [
        "status": "success",
        "message": "Reminder created successfully",
        "reminderId": reminder.calendarItemIdentifier,
        "title": reminder.title ?? "",
        "list": reminder.calendar?.title ?? "",
        "dueDate": formatDateComponents(reminder.dueDateComponents),
        "priority": getPriorityString(reminder.priority)
      ])
    } catch {
      return createErrorOutput(error: error)
    }
  }

  private func queryReminders(arguments: Arguments) async -> GeneratedContent {
    let calendars = eventStore.calendars(for: .reminder)
    var predicate: NSPredicate

    let filter = arguments.filter?.lowercased() ?? "incomplete"

    switch filter {
    case "all":
      predicate = eventStore.predicateForReminders(in: calendars)
    case "completed":
      predicate = eventStore.predicateForCompletedReminders(
        withCompletionDateStarting: nil, ending: nil, calendars: calendars)
    case "today":
      let startOfDay = Calendar.current.startOfDay(for: Date())
      let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
      predicate = eventStore.predicateForIncompleteReminders(
        withDueDateStarting: startOfDay, ending: endOfDay, calendars: calendars)
    case "overdue":
      predicate = eventStore.predicateForIncompleteReminders(
        withDueDateStarting: nil, ending: Date(), calendars: calendars)
    default:  // "incomplete"
      predicate = eventStore.predicateForIncompleteReminders(
        withDueDateStarting: nil, ending: nil, calendars: calendars)
    }

    var reminders = await fetchReminders(matching: predicate)

    // Sort reminders
    reminders.sort { reminder1, reminder2 in
      // First by completion status
      if reminder1.isCompleted != reminder2.isCompleted {
        return !reminder1.isCompleted
      }

      // Then by due date
      if let date1 = reminder1.dueDate,
        let date2 = reminder2.dueDate {
        return date1 < date2
      }

      // Reminders with due dates come before those without
      if reminder1.dueDate != nil && reminder2.dueDate == nil {
        return true
      }

      return false
    }

    var remindersDescription = ""

    for (index, reminder) in reminders.enumerated() {
      let completed = reminder.isCompleted ? "[x]" : "[ ]"
      let priority = getPriorityString(reminder.priority)
      let dueDate = formatReminderDueDate(reminder.dueDate)

      remindersDescription += "\(index + 1). \(completed) \(reminder.title)\n"
      remindersDescription += "   List: \(reminder.listName)\n"
      if !dueDate.isEmpty {
        remindersDescription += "   Due: \(dueDate)\n"
      }
      if priority != "None" {
        remindersDescription += "   Priority: \(priority)\n"
      }
      if let notes = reminder.notes, !notes.isEmpty {
        remindersDescription += "   Notes: \(notes.prefix(50))...\n"
      }
      remindersDescription += "\n"
    }

    if remindersDescription.isEmpty {
      remindersDescription = "No reminders found with filter '\(filter)'"
    }

    return GeneratedContent(properties: [
      "status": "success",
      "filter": filter,
      "count": reminders.count,
      "reminders": remindersDescription.trimmingCharacters(in: .whitespacesAndNewlines),
      "message": "Found \(reminders.count) reminder(s)"
    ])
  }

  private func fetchReminders(matching predicate: NSPredicate) async -> [ReminderSnapshot] {
    await withCheckedContinuation { continuation in
      eventStore.fetchReminders(matching: predicate) { fetchedReminders in
        let snapshots = fetchedReminders?.map(ReminderSnapshot.init) ?? []
        continuation.resume(returning: snapshots)
      }
    }
  }

  private func completeReminder(reminderId: String?) throws -> GeneratedContent {
    guard let id = reminderId else {
      return createErrorOutput(error: RemindersError.missingReminderId)
    }

    guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
      return createErrorOutput(error: RemindersError.reminderNotFound)
    }

    reminder.isCompleted = true
    reminder.completionDate = Date()

    do {
      try eventStore.save(reminder, commit: true)

      return GeneratedContent(properties: [
        "status": "success",
        "message": "Reminder completed successfully",
        "reminderId": reminder.calendarItemIdentifier,
        "title": reminder.title ?? "",
        "completedAt": formatDate(Date())
      ])
    } catch {
      return createErrorOutput(error: error)
    }
  }

  private func updateReminder(arguments: Arguments) throws -> GeneratedContent {
    guard let reminderId = arguments.reminderId else {
      return createErrorOutput(error: RemindersError.missingReminderId)
    }

    guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
      return createErrorOutput(error: RemindersError.reminderNotFound)
    }

    // Update fields if provided
    if let title = arguments.title {
      reminder.title = title
    }

    if let notes = arguments.notes {
      reminder.notes = notes
    }

    if let dueDateString = arguments.dueDate {
      if let dueDate = parseDate(dueDateString) {
        reminder.dueDateComponents = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute],
          from: dueDate
        )
      } else if dueDateString.lowercased() == "none" {
        reminder.dueDateComponents = nil
      }
    }

    if let priorityString = arguments.priority {
      switch priorityString.lowercased() {
      case "high":
        reminder.priority = 1
      case "medium":
        reminder.priority = 5
      case "low":
        reminder.priority = 9
      default:
        reminder.priority = 0
      }
    }

    do {
      try eventStore.save(reminder, commit: true)

      return GeneratedContent(properties: [
        "status": "success",
        "message": "Reminder updated successfully",
        "reminderId": reminder.calendarItemIdentifier,
        "title": reminder.title ?? "",
        "list": reminder.calendar?.title ?? "",
        "dueDate": formatDateComponents(reminder.dueDateComponents),
        "priority": getPriorityString(reminder.priority)
      ])
    } catch {
      return createErrorOutput(error: error)
    }
  }

  private func deleteReminder(reminderId: String?) throws -> GeneratedContent {
    guard let id = reminderId else {
      return createErrorOutput(error: RemindersError.missingReminderId)
    }

    guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
      return createErrorOutput(error: RemindersError.reminderNotFound)
    }

    let title = reminder.title ?? "Untitled"

    do {
      try eventStore.remove(reminder, commit: true)

      return GeneratedContent(properties: [
        "status": "success",
        "message": "Reminder deleted successfully",
        "deletedTitle": title
      ])
    } catch {
      return createErrorOutput(error: error)
    }
  }

  private func parseDate(_ dateString: String) -> Date? {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone.current

    // Try multiple date formats to be more flexible
    let formats = [
      "yyyy-MM-dd HH:mm:ss",  // Primary format: 2025-01-15 17:00:00
      "yyyy-MM-dd HH:mm",  // Without seconds: 2025-01-15 17:00
      "yyyy-MM-dd",  // Date only: 2025-01-15 (defaults to start of day)
      "MM/dd/yyyy HH:mm:ss",  // US format: 01/15/2025 17:00:00
      "MM/dd/yyyy HH:mm",  // US format without seconds: 01/15/2025 17:00
      "MM/dd/yyyy"  // US date only: 01/15/2025
    ]

    for format in formats {
      formatter.dateFormat = format
      if let date = formatter.date(from: dateString) {
        return date
      }
    }

    // If no format worked, try ISO 8601 formatter as fallback
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.timeZone = TimeZone.current
    return isoFormatter.date(from: dateString)
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.timeZone = TimeZone.current
    return formatter.string(from: date)
  }

  private func formatDateComponents(_ components: DateComponents?) -> String {
    guard let components = components,
      let date = Calendar.current.date(from: components)
    else {
      return ""
    }

    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private func formatReminderDueDate(_ date: Date?) -> String {
    guard let date else { return "" }

    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private func getPriorityString(_ priority: Int) -> String {
    switch priority {
    case 1...3:
      return "High"
    case 4...6:
      return "Medium"
    case 7...9:
      return "Low"
    default:
      return "None"
    }
  }

  private func createErrorOutput(error: Error) -> GeneratedContent {
    return GeneratedContent(properties: [
      "status": "error",
      "error": error.localizedDescription,
      "message": "Failed to perform reminder operation"
    ])
  }
}

private struct ReminderSnapshot: Sendable {
  let title: String
  let listName: String
  let dueDate: Date?
  let priority: Int
  let notes: String?
  let isCompleted: Bool

  init(reminder: EKReminder) {
    self.title = reminder.title ?? "Untitled"
    self.listName = reminder.calendar?.title ?? "Unknown List"
    self.dueDate = reminder.dueDateComponents?.date
    self.priority = reminder.priority
    self.notes = reminder.notes
    self.isCompleted = reminder.isCompleted
  }
}

enum RemindersError: Error, LocalizedError {
  case accessDenied
  case invalidAction
  case missingTitle
  case missingReminderId
  case reminderNotFound

  var errorDescription: String? {
    switch self {
    case .accessDenied:
      return "Access to reminders denied. Please grant permission in Settings."
    case .invalidAction:
      return "Invalid action. Use 'create', 'query', 'complete', 'update', or 'delete'."
    case .missingTitle:
      return "Title is required to create a reminder."
    case .missingReminderId:
      return "Reminder ID is required."
    case .reminderNotFound:
      return "Reminder not found with the provided ID."
    }
  }
}
