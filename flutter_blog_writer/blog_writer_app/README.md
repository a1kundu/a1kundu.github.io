# Blog Writer App

A Flutter Android app for writing blog posts in Markdown format with GitHub integration.

## Features

- **Setup Required**: App requires GitHub configuration on first launch
- **Posts List**: View all existing blog posts from your repository
- **Add New Posts**: Floating action button opens dialog to write new posts
- **Direct GitHub Integration**: Saves posts directly to your GitHub repo
- **Automatic Commits**: Each post creates commits for posts.json and .md file

## Setup

1. Create a GitHub Personal Access Token with `repo` permissions
2. On first launch, enter:
   - GitHub Access Token
   - Repository Owner (e.g., a1kundu)
   - Repository Name (e.g., a1kundu.github.io)
   - Branch (e.g., main)

## Usage

1. **First Time**: Configure GitHub settings (required)
2. **View Posts**: Main screen shows list of existing posts sorted by date
3. **Add Post**: Tap the + button to open the post writer dialog
4. **Write**: Enter title, select date, write Markdown content
5. **Save**: Post is committed directly to your GitHub repository

## Permissions

The app requires internet access to communicate with GitHub API.

## Building

To build the APK:

```bash
flutter build apk
```

The APK will be in `build/app/outputs/flutter-apk/app-release.apk`
