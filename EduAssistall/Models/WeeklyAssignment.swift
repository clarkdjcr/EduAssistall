import Foundation

struct WeeklyAssignment: Codable, Identifiable {
    var id: String
    var studentId: String
    var teacherId: String
    var teacherName: String
    var weekOf: Date           // Monday 00:00 local for the assigned week
    var dayNumber: Int         // 1 = Monday … 5 = Friday
    var title: String
    var lessonPlanText: String
    var archived: Bool
    var assignedAt: Date
    var recommendationId: String?

    var dayLabel: String {
        switch dayNumber {
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        case 5: return "Friday"
        default: return "Day \(dayNumber)"
        }
    }

    var scheduledDate: Date {
        Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: weekOf) ?? weekOf
    }

    var isPast: Bool {
        scheduledDate < Calendar.current.startOfDay(for: Date())
    }

    init(id: String, studentId: String, teacherId: String, teacherName: String,
         weekOf: Date, dayNumber: Int, title: String, lessonPlanText: String,
         archived: Bool, assignedAt: Date, recommendationId: String? = nil) {
        self.id = id
        self.studentId = studentId
        self.teacherId = teacherId
        self.teacherName = teacherName
        self.weekOf = weekOf
        self.dayNumber = dayNumber
        self.title = title
        self.lessonPlanText = lessonPlanText
        self.archived = archived
        self.assignedAt = assignedAt
        self.recommendationId = recommendationId
    }

    static func mondayOf(week containing: Date) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: containing)
        return cal.date(from: components) ?? containing
    }
}
