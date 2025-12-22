# Blog Writer App

A Flutter Android app for writing blog posts in Markdown format with GitHub integration.

## Features

- Write blog posts with title, date, and Markdown content
- Automatically generates filename from title
- Saves posts directly to GitHub repository
- Maintains posts.json for blog metadata
- Settings page to configure GitHub repo and token
- Syncs with GitHub on app start

## Setup

1. Create a GitHub Personal Access Token with `repo` permissions
2. In the app's Settings page, enter:
   - GitHub Access Token
   - Repository Owner (e.g., a1kundu)
   - Repository Name (e.g., a1kundu.github.io)
   - Branch (e.g., main)

## Usage

1. Configure settings with your GitHub details
2. Switch to Writer tab
3. Enter the blog post title
4. Select the publication date
5. Write the content in Markdown format
6. Tap "Save Post" to commit and push to GitHub

Posts are saved to `src/assets/blogs/` in your repository.

## Permissions

The app requires internet access to communicate with GitHub API.

## Building

To build the APK:

```bash
flutter build apk
```

The APK will be in `build/app/outputs/flutter-apk/app-release.apk`
