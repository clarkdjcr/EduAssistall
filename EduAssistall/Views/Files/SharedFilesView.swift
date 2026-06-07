import SwiftUI

struct SharedFilesView: View {
    let profile: UserProfile
    var groupId: String? = nil
    var groupMemberIds: [String] = []

    @State private var individualFiles: [SharedFile] = []
    @State private var groupFiles: [SharedFile] = []
    @State private var selectedScope: FileScope = .individual
    @State private var isLoading = true
    @State private var isUploading = false
    @State private var errorMessage: String?

    #if os(iOS)
    @State private var showImagePicker = false
    #endif

    private var displayedFiles: [SharedFile] {
        selectedScope == .individual ? individualFiles : groupFiles
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Scope", selection: $selectedScope) {
                    Text("My Files").tag(FileScope.individual)
                    Text("Group").tag(FileScope.group)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if displayedFiles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: selectedScope == .individual ? "folder" : "person.3")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text(selectedScope == .individual ? "No personal files yet." : "No group files yet.")
                            .font(.headline)
                        Text(selectedScope == .individual
                             ? "Upload files here to keep them accessible and share with your teacher."
                             : "Files shared with your group appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(displayedFiles) { file in
                            SharedFileRow(file: file)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if file.uploadedBy == profile.id {
                                        Button(role: .destructive) {
                                            Task { await delete(file) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #else
                    .listStyle(.inset)
                    #endif
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Files")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        #if os(iOS)
                        showImagePicker = true
                        #endif
                    } label: {
                        if isUploading {
                            ProgressView().tint(.blue)
                        } else {
                            Image(systemName: "plus")
                        }
                    }
                    .disabled(isUploading)
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showImagePicker) {
                ImageAttachmentPicker { data, filename, mime in
                    Task { await upload(data: data, filename: filename, mimeType: mime) }
                }
            }
            #endif
            .task { await load() }
            .onChange(of: selectedScope) { _, _ in Task { await load() } }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        async let indFetch = FirestoreService.shared.fetchIndividualFiles(studentId: profile.id)
        async let grpFetch: [SharedFile] = {
            if let gid = groupId {
                return (try? await FirestoreService.shared.fetchGroupFiles(groupMemberId: gid)) ?? []
            }
            return (try? await FirestoreService.shared.fetchGroupFiles(groupMemberId: profile.id)) ?? []
        }()
        individualFiles = (try? await indFetch) ?? []
        groupFiles = await grpFetch
        isLoading = false
    }

    private func upload(data: Data, filename: String, mimeType: String) async {
        isUploading = true
        errorMessage = nil
        let scope = selectedScope
        let ownerId = scope == .individual ? profile.id : (groupId ?? profile.id)
        let path = scope == .individual
            ? StorageService.individualFilePath(studentId: profile.id, filename: filename)
            : StorageService.groupFilePath(groupId: ownerId, filename: filename)

        do {
            let (ref, url) = try await StorageService.shared.upload(data: data, path: path, mimeType: mimeType)
            let file = SharedFile(
                name: filename,
                storageRef: ref,
                downloadURL: url,
                uploadedBy: profile.id,
                uploaderName: profile.displayName,
                mimeType: mimeType,
                sizeBytes: data.count,
                scope: scope,
                ownerId: ownerId,
                groupMemberIds: scope == .group ? groupMemberIds : []
            )
            try await FirestoreService.shared.saveSharedFile(file)
            if scope == .individual { individualFiles.insert(file, at: 0) }
            else { groupFiles.insert(file, at: 0) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isUploading = false
    }

    private func delete(_ file: SharedFile) async {
        try? await StorageService.shared.delete(path: file.storageRef)
        try? await FirestoreService.shared.deleteSharedFile(file)
        if file.scope == .individual {
            individualFiles.removeAll { $0.id == file.id }
        } else {
            groupFiles.removeAll { $0.id == file.id }
        }
    }
}

// MARK: - File Row

private struct SharedFileRow: View {
    let file: SharedFile

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: file.typeIcon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(file.sizeLabel)
                    Text("·")
                    Text(file.uploaderName)
                    Text("·")
                    Text(file.createdAt, style: .relative)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if let url = URL(string: file.downloadURL) {
                Link(destination: url) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
