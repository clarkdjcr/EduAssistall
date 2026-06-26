import Foundation

struct StudentGrade: Codable, Identifiable {
    var id: String              // equals assignmentId (weeklyAssignment.id)
    var assignmentId: String
    var studentId: String
    var teacherId: String
    var score: Double           // 0–100 percentage
    var feedback: String
    var gradedAt: Date
    var assignmentTitle: String

    var letterGrade: String {
        switch score {
        case 90...:   return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default:      return "F"
        }
    }

    init(id: String, assignmentId: String, studentId: String, teacherId: String,
         score: Double, feedback: String, gradedAt: Date, assignmentTitle: String) {
        self.id = id
        self.assignmentId = assignmentId
        self.studentId = studentId
        self.teacherId = teacherId
        self.score = score
        self.feedback = feedback
        self.gradedAt = gradedAt
        self.assignmentTitle = assignmentTitle
    }
}
