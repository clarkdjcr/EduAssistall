import SwiftUI

// Phase 2: Avatar customization screen
struct AvatarCustomizationView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    @State private var avatarConfig: AvatarConfig
    @State private var selectedTab = 0
    
    init() {
        // Initialize with default config
        _avatarConfig = State(initialValue: AvatarConfig())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Avatar preview
                AvatarPreviewView(config: avatarConfig)
                    .frame(height: 200)
                    .background(Color.appSecondaryGroupedBackground)
                
                // Customization tabs
                Picker("Category", selection: $selectedTab) {
                    Text("Body").tag(0)
                    Text("Hair").tag(1)
                    Text("Accessories").tag(2)
                    Text("Background").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Customization options
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case 0:
                            bodyOptions
                        case 1:
                            hairOptions
                        case 2:
                            accessoryOptions
                        case 3:
                            backgroundOptions
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                // Save button
                Button {
                    saveAvatar()
                } label: {
                    Text("Save Avatar")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .buttonStyle(.plain)
            }
            .navigationTitle("Customize Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                loadCurrentAvatar()
            }
        }
    }
    
    private var bodyOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Body Type")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(BodyType.allCases, id: \.self) { type in
                    Button {
                        avatarConfig.bodyType = type
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "figure.stand")
                                .font(.title2)
                                .foregroundStyle(avatarConfig.bodyType == type ? .blue : .secondary)
                            Text(type.displayName)
                                .font(.caption)
                                .foregroundStyle(avatarConfig.bodyType == type ? .blue : .secondary)
                        }
                        .padding()
                        .background(avatarConfig.bodyType == type ? Color.blue.opacity(0.1) : Color.appSecondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("Skin Tone")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(SkinTone.allCases, id: \.self) { tone in
                    Button {
                        avatarConfig.skinTone = tone
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(tone.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(avatarConfig.skinTone == tone ? Color.blue : Color.clear, lineWidth: 3)
                                )
                            Text(tone.displayName)
                                .font(.caption)
                                .foregroundStyle(avatarConfig.skinTone == tone ? .blue : .secondary)
                        }
                        .padding()
                        .background(avatarConfig.skinTone == tone ? Color.blue.opacity(0.1) : Color.appSecondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var hairOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hair Style")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(HairStyle.allCases, id: \.self) { style in
                    Button {
                        avatarConfig.hairStyle = style
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                                .foregroundStyle(avatarConfig.hairStyle == style ? .blue : .secondary)
                            Text(style.displayName)
                                .font(.caption)
                                .foregroundStyle(avatarConfig.hairStyle == style ? .blue : .secondary)
                        }
                        .padding()
                        .background(avatarConfig.hairStyle == style ? Color.blue.opacity(0.1) : Color.appSecondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("Hair Color")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(HairColor.allCases, id: \.self) { color in
                    Button {
                        avatarConfig.hairColor = color
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(avatarConfig.hairColor == color ? Color.blue : Color.clear, lineWidth: 3)
                                )
                            Text(color.displayName)
                                .font(.caption)
                                .foregroundStyle(avatarConfig.hairColor == color ? .blue : .secondary)
                        }
                        .padding()
                        .background(avatarConfig.hairColor == color ? Color.blue.opacity(0.1) : Color.appSecondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var accessoryOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accessories")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AvatarAccessory.allCases, id: \.self) { accessory in
                    Button {
                        if avatarConfig.accessories.contains(accessory) {
                            avatarConfig.accessories.removeAll { $0 == accessory }
                        } else {
                            avatarConfig.accessories.append(accessory)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: accessory.icon)
                                .font(.title2)
                                .foregroundStyle(avatarConfig.accessories.contains(accessory) ? .blue : .secondary)
                            Text(accessory.displayName)
                                .font(.caption)
                                .foregroundStyle(avatarConfig.accessories.contains(accessory) ? .blue : .secondary)
                            
                            if let unlockLevel = accessory.unlockLevel {
                                if let profile = authVM.currentProfile, profile.level < unlockLevel {
                                    Text("Unlocks at Lvl \(unlockLevel)")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .padding()
                        .background(avatarConfig.accessories.contains(accessory) ? Color.blue.opacity(0.1) : Color.appSecondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(isAccessoryLocked(accessory))
                }
            }
        }
    }
    
    private var backgroundOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Background")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AvatarBackground.allCases, id: \.self) { background in
                    Button {
                        avatarConfig.background = background
                    } label: {
                        VStack(spacing: 8) {
                            Rectangle()
                                .fill(background.color)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(avatarConfig.background == background ? Color.blue : Color.clear, lineWidth: 3)
                                )
                            Text(background.displayName)
                                .font(.caption)
                                .foregroundStyle(avatarConfig.background == background ? .blue : .secondary)
                        }
                        .padding()
                        .background(avatarConfig.background == background ? Color.blue.opacity(0.1) : Color.appSecondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func isAccessoryLocked(_ accessory: AvatarAccessory) -> Bool {
        guard let unlockLevel = accessory.unlockLevel else { return false }
        guard let profile = authVM.currentProfile else { return true }
        return profile.level < unlockLevel
    }
    
    private func loadCurrentAvatar() {
        if let profile = authVM.currentProfile, let config = profile.avatarConfig {
            avatarConfig = config
        }
    }
    
    private func saveAvatar() {
        Task {
            if let profile = authVM.currentProfile {
                var updatedProfile = profile
                updatedProfile.avatarConfig = avatarConfig
                try? await FirestoreService.shared.updateUserProfile(updatedProfile)
            }
            dismiss()
        }
    }
}

// Phase 2: Avatar preview component
struct AvatarPreviewView: View {
    let config: AvatarConfig
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(config.background.color.opacity(0.3))
                .frame(width: 150, height: 150)
            
            // Avatar body (simplified representation)
            VStack(spacing: 8) {
                // Head
                Circle()
                    .fill(config.skinTone.color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        // Hair
                        Circle()
                            .fill(config.hairColor.color)
                            .frame(width: 65, height: 65)
                            .offset(y: -10)
                            .opacity(config.hairStyle == .bald ? 0 : 1)
                    )
                
                // Body
                RoundedRectangle(cornerRadius: 20)
                    .fill(config.skinTone.color)
                    .frame(width: 40, height: 50)
            }
            
            // Accessories
            if config.accessories.contains(.glasses) {
                Image(systemName: "eyeglasses")
                    .font(.title3)
                    .offset(y: -5)
            }
            
            if config.accessories.contains(.hatBaseball) {
                Image(systemName: "cap.fill")
                    .font(.title3)
                    .offset(y: -40)
            }
            
            if config.accessories.contains(.hatBeanie) {
                Image(systemName: "hat.fill")
                    .font(.title3)
                    .offset(y: -40)
            }
            
            if config.accessories.contains(.headphones) {
                Image(systemName: "headphones")
                    .font(.title3)
                    .offset(y: -5)
            }
        }
        .padding()
    }
}
