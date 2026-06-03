# Main Views Context

## Purpose
Store role-based app shell and main tab navigation views.

## Contents
- `MainTabView.swift` defines student, teacher, parent, and admin tab structures plus profile/settings navigation.

## Conventions
- Preserve role-based tab separation.
- Add settings links only for roles that are allowed to use the destination feature.
- Keep reusable feature screens in their own feature directories when practical.
- Log main navigation edits in `EduAssistall/Views/Main/LOG.md`.
