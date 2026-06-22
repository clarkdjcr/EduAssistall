import Foundation

// Phase 3: Peer recognition (kudos) system
struct Kudos: Codable, Identifiable {
    var id: String
    var fromStudentId: String
    var toStudentId: String
    var reason: String
    var timestamp: Date
    
    init(fromStudentId: String, toStudentId: String, reason: String) {
        self.id = UUID().uuidString
        self.fromStudentId = fromStudentId
        self.toStudentId = toStudentId
        self.reason = reason
        self.timestamp = Date()
    }
}

// Phase 3: Kudos tracking for students
struct KudosStats: Codable {
    var studentId: String
    var receivedCount: Int
    var givenCount: Int
    var lastGivenDate: Date?
    var lastReceivedDate: Date?
    
    init(studentId: String) {
        self.studentId = studentId
        self.receivedCount = 0
        self.givenCount = 0
        self.lastGivenDate = nil
        self.lastReceivedDate = nil
    }
    
    // Check if student can give kudos (3 per day)
    func canGiveKudos() -> Bool {
        guard let lastGiven = lastGivenDate else { return true }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastGivenDay = calendar.startOfDay(for: lastGiven)
        return lastGivenDay < today || givenCount < 3
    }
    
    // Get remaining kudos for today
    func remainingKudosToday() -> Int {
        guard let lastGiven = lastGivenDate else { return 3 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastGivenDay = calendar.startOfDay(for: lastGiven)
        if lastGivenDay < today {
            return 3
        }
        return max(0, 3 - givenCount)
    }
}
