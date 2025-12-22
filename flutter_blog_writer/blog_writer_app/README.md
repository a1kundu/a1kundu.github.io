# Blog Writer App

A Flutter Android app for writing blog posts in Markdown format.

## Features

- Write blog posts with title, date, and Markdown content
- Automatically generates filename from title
- Saves posts locally on device
- Maintains posts.json for blog metadata

## Usage

1. Enter the blog post title
2. Select the publication date
3. Write the content in Markdown format
4. Tap "Save Post" to save

Posts are saved to the device's documents directory under `blogs/` folder.

## Copying to Repository

After writing posts in the app, you can find the files in the app's storage. To add them to your GitHub Pages blog:

1. Locate the saved files (posts.json and .md files) in the app's storage
2. Copy them to your repository's `src/assets/blogs/` directory
3. Commit and push the changes

## Building

To build the APK:

```bash
flutter build apk
```

The APK will be in `build/app/outputs/flutter-apk/app-release.apk`
