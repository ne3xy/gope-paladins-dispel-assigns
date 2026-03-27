#!/usr/bin/env bash

set -e

# Get latest tag (fallback to v0.0.0 if none exist)
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")

echo "Latest tag: $LATEST_TAG"

# Strip leading 'v' if present
VERSION=${LATEST_TAG#v}

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# Increment patch version
PATCH=$((PATCH + 1))

NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"

echo "New tag: $NEW_TAG"

# Ensure we're on a clean working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is not clean. Commit or stash changes first."
  exit 1
fi

# Create and push tag
git tag "$NEW_TAG"
git push origin "$NEW_TAG"

echo "Tag $NEW_TAG created and pushed successfully."