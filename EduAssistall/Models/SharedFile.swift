import Foundation

enum FileScope: String, Codable {
    case individual
    case group
}

struct MessageAttachment: Codable, Identifiable {
    var id: String
    var filename: String
    var storageRef: String
    var downloadURL: String
    var mimeType: String
    var sizeBytes: Int

    init(filename: String, storageRef: String, downloadURL: String,
         mimeType: String, sizeBytes: Int) {
        self.id = UUID().uuidString
        self.filename = filename
        self.storageRef = storageRef
        self.downloadURL = downloadURL
        self.mimeType = mimeType
        self.sizeBytes = sizeBytes
    }

    var typeIcon: String {
        if mimeType.hasPrefix("image/") { return "photo.fill" }
        if mimeType == "application/pdf" { return "doc.richtext.fill" }
        if mimeType.hasPrefix("video/") { return "video.fill" }
        return "doc.fill"
    }

    var sizeLabel: String {
        let kb = Double(sizeBytes) / 1024
        if kb < 1024 { return String(format: "%.0f KB", kb) }
        return String(format: "%.1f MB", kb / 1024)
    }
}

struct SharedFile: Codable, Identifiable {
    var id: String
    var name: String
    var storageRef: String
    var downloadURL: String
    var uploadedBy: String
    var uploaderName: String
    var mimeType: String
    var sizeBytes: Int
    var createdAt: Date
    var scope: FileScope
    var ownerId: String          // studentId (individual) or groupId (group)
    var groupMemberIds: [String] // populated for group files

    init(name: String, storageRef: String, downloadURL: String,
         uploadedBy: String, uploaderName: String, mimeType: String,
         sizeBytes: Int, scope: FileScope, ownerId: String, groupMemberIds: [String] = []) {
        self.id = UUID().uuidString
        self.name = name
        self.storageRef = storageRef
        self.downloadURL = downloadURL
        self.uploadedBy = uploadedBy
        self.uploaderName = uploaderName
        self.mimeType = mimeType
        self.sizeBytes = sizeBytes
        self.createdAt = Date()
        self.scope = scope
        self.ownerId = ownerId
        self.groupMemberIds = groupMemberIds
    }

    var typeIcon: String {
        if mimeType.hasPrefix("image/") { return "photo.fill" }
        if mimeType == "application/pdf" { return "doc.richtext.fill" }
        if mimeType.hasPrefix("video/") { return "video.fill" }
        return "doc.fill"
    }

    var sizeLabel: String {
        let kb = Double(sizeBytes) / 1024
        if kb < 1024 { return String(format: "%.0f KB", kb) }
        return String(format: "%.1f MB", kb / 1024)
    }
}
