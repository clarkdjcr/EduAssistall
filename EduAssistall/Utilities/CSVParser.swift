import Foundation

struct ParsedCSV {
    let headers: [String]
    let rows: [[String]]

    var isEmpty: Bool { rows.isEmpty }

    func value(row: [String], header: String) -> String {
        guard let idx = headers.firstIndex(where: { $0.caseInsensitiveCompare(header) == .orderedSame }),
              idx < row.count else { return "" }
        return row[idx]
    }
}

enum CSVParser {
    static func parse(_ content: String) -> ParsedCSV {
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n")
                                .replacingOccurrences(of: "\r", with: "\n")
        var lines = normalized.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !lines.isEmpty else { return ParsedCSV(headers: [], rows: []) }
        let headers = parseRow(lines.removeFirst()).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let rows = lines.map { parseRow($0) }
        return ParsedCSV(headers: headers, rows: rows)
    }

    // RFC 4180-compliant parser: handles quoted fields, escaped quotes (""), commas inside quotes.
    private static func parseRow(_ row: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = row.startIndex

        while i < row.endIndex {
            let ch = row[i]
            if inQuotes {
                if ch == "\"" {
                    let next = row.index(after: i)
                    if next < row.endIndex && row[next] == "\"" {
                        current.append("\"")
                        i = row.index(after: next)
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(ch)
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                } else if ch == "," {
                    fields.append(current.trimmingCharacters(in: .whitespaces))
                    current = ""
                } else {
                    current.append(ch)
                }
            }
            i = row.index(after: i)
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }
}

// MARK: - Column auto-detection

struct ColumnMap {
    var studentFirstName: Int?
    var studentLastName: Int?
    var studentEmail: Int?
    var grade: Int?
    var parentEmail: Int?
    var parentFirstName: Int?
    var parentLastName: Int?

    /// Returns a display name built from the mapped first/last columns (or email as fallback).
    func studentName(from row: [String]) -> String {
        let first = studentFirstName.flatMap { $0 < row.count ? row[$0] : nil } ?? ""
        let last  = studentLastName.flatMap  { $0 < row.count ? row[$0] : nil } ?? ""
        if !first.isEmpty || !last.isEmpty { return "\(first) \(last)".trimmingCharacters(in: .whitespaces) }
        return studentEmail.flatMap { $0 < row.count ? row[$0] : nil } ?? ""
    }

    func parentName(from row: [String]) -> String {
        let first = parentFirstName.flatMap { $0 < row.count ? row[$0] : nil } ?? ""
        let last  = parentLastName.flatMap  { $0 < row.count ? row[$0] : nil } ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
}

extension CSVParser {
    /// Attempts to auto-detect column positions from common header names exported by school SIS systems.
    static func autoDetectColumns(headers: [String]) -> ColumnMap {
        var map = ColumnMap()
        for (i, h) in headers.enumerated() {
            let l = h.lowercased()
            if l.contains("first") && (l.contains("student") || !l.contains("parent")) && !l.contains("parent") {
                map.studentFirstName = i
            } else if l.contains("last") && !l.contains("parent") {
                map.studentLastName = i
            } else if (l.contains("email") || l.contains("e-mail")) && !l.contains("parent") && !l.contains("guardian") {
                map.studentEmail = i
            } else if l.contains("grade") || l.contains("year") || l.hasPrefix("gr") {
                map.grade = i
            } else if (l.contains("email") || l.contains("e-mail")) && (l.contains("parent") || l.contains("guardian")) {
                map.parentEmail = i
            } else if l.contains("first") && (l.contains("parent") || l.contains("guardian")) {
                map.parentFirstName = i
            } else if l.contains("last") && (l.contains("parent") || l.contains("guardian")) {
                map.parentLastName = i
            } else if l == "name" || l == "student name" || l == "student" {
                // Single "Name" column — treat as first name
                map.studentFirstName = i
            } else if l.contains("parent") && l.contains("name") {
                map.parentFirstName = i
            }
        }
        return map
    }
}

// MARK: - Import record

struct StudentImportRecord: Identifiable {
    let id = UUID()
    let studentName: String
    let studentEmail: String
    let grade: String
    let parentEmail: String
    let parentName: String

    var isValid: Bool {
        !studentName.trimmingCharacters(in: .whitespaces).isEmpty &&
        studentEmail.contains("@") && studentEmail.contains(".")
    }

    var validationError: String? {
        if studentName.trimmingCharacters(in: .whitespaces).isEmpty { return "Missing name" }
        if !studentEmail.contains("@") { return "Invalid email" }
        return nil
    }
}
