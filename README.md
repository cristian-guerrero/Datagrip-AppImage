# DataGrip AppImage

This project provides a GitHub Actions workflow to build an AppImage for JetBrains DataGrip.

## How it works

The CI workflow:
1.  Downloads the latest version of DataGrip from JetBrains.
2.  Prepares an `AppDir` with the necessary metadata.
3.  Uses `appimagetool` to generate the AppImage.
4.  Uploads the resulting AppImage as a release asset.

## Usage

Push a tag or run the workflow manually to trigger a build.
