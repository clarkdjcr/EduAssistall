import Foundation

enum CurriculumBackend: String, Codable, CaseIterable, Identifiable {
    case firebase
    case sharePoint = "sharepoint"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .firebase: return "Firebase"
        case .sharePoint: return "SharePoint"
        }
    }
}

enum CurriculumScope: String, Codable, CaseIterable, Identifiable {
    case homeschool
    case district
    case state

    var id: String { rawValue }
}

enum CurriculumDocumentStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case active
    case archived

    var id: String { rawValue }
}

enum LessonPlanStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case approved
    case assigned
    case archived

    var id: String { rawValue }
}

enum DailyAssignmentStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case assigned
    case archived

    var id: String { rawValue }
}

struct CurriculumSource: Codable, Identifiable {
    var id: String
    var displayName: String
    var backend: CurriculumBackend
    var scope: CurriculumScope
    var districtId: String?
    var ownerId: String?
    var firebaseCollectionPath: String?
    var sharePointSiteId: String?
    var sharePointDriveId: String?
    var sharePointRootPath: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        displayName: String,
        backend: CurriculumBackend,
        scope: CurriculumScope,
        districtId: String? = nil,
        ownerId: String? = nil
    ) {
        self.id = UUID().uuidString
        self.displayName = displayName
        self.backend = backend
        self.scope = scope
        self.districtId = districtId
        self.ownerId = ownerId
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct CurriculumDocument: Codable, Identifiable {
    var id: String
    var sourceId: String
    var backend: CurriculumBackend
    var districtId: String?
    var title: String
    var subject: String
    var gradeLevel: String
    var course: String
    var standardCode: String
    var standards: [String]
    var summary: String
    var body: String
    var supportText: String
    var sourceFile: String?
    var sourceUrl: String?
    var sourceKind: String?
    var sourceStatus: String?
    var effectiveYear: Int?
    var contentHash: String?
    var approvalStatus: String?
    var parseStatus: String?
    var recordType: String?
    var sharePointItemId: String?
    var sharePointWebUrl: String?
    var storagePath: String?
    var status: CurriculumDocumentStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        sourceId: String,
        backend: CurriculumBackend,
        title: String,
        subject: String,
        gradeLevel: String,
        districtId: String? = nil
    ) {
        self.id = UUID().uuidString
        self.sourceId = sourceId
        self.backend = backend
        self.districtId = districtId
        self.title = title
        self.subject = subject
        self.gradeLevel = gradeLevel
        self.course = ""
        self.standardCode = ""
        self.standards = []
        self.summary = ""
        self.body = ""
        self.supportText = ""
        self.status = .draft
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct LessonPlan: Codable, Identifiable {
    var id: String
    var curriculumDocumentId: String?
    var sourceId: String?
    var districtId: String?
    var title: String
    var subject: String
    var gradeLevel: String
    var standards: [String]
    var objectives: [String]
    var materials: [String]
    var teacherNotes: String
    var aiDraft: String
    var status: LessonPlanStatus
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date

    init(title: String, subject: String, gradeLevel: String, createdBy: String) {
        self.id = UUID().uuidString
        self.title = title
        self.subject = subject
        self.gradeLevel = gradeLevel
        self.standards = []
        self.objectives = []
        self.materials = []
        self.teacherNotes = ""
        self.aiDraft = ""
        self.status = .draft
        self.createdBy = createdBy
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct DailyAssignment: Codable, Identifiable {
    var id: String
    var lessonPlanId: String
    var title: String
    var instructions: String
    var studentIds: [String]
    var contentItemIds: [String]
    var learningPathId: String?
    var dueDate: Date?
    var estimatedMinutes: Int
    var status: DailyAssignmentStatus
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date

    init(lessonPlanId: String, title: String, instructions: String, createdBy: String) {
        self.id = UUID().uuidString
        self.lessonPlanId = lessonPlanId
        self.title = title
        self.instructions = instructions
        self.studentIds = []
        self.contentItemIds = []
        self.estimatedMinutes = 30
        self.status = .draft
        self.createdBy = createdBy
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
