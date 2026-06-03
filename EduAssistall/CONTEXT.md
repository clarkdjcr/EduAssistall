# App Source Context

## Purpose
Store the EduAssist SwiftUI application source, app configuration, platform entitlements, assets, models, services, and views.

## Contents
- SwiftUI app entry points and root views.
- Models, services, view models, utilities, and feature views.
- App assets, privacy manifest, Firebase plist, entitlements, and Info.plist.

## Conventions
- Keep platform-specific behavior behind existing extension helpers when possible.
- Use existing Firebase service wrappers and async/await patterns.
- Preserve role-based navigation in `Views/Main/MainTabView.swift`.
- Log app source additions or edits in `EduAssistall/LOG.md`.
