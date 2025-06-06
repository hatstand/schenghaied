#!/bin/bash
# Helper script to build, test and create releases

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Show help
show_help() {
  echo -e "${BLUE}Schengen Tracker Build Helper${NC}"
  echo
  echo "Usage: ./build.sh [command]"
  echo
  echo "Commands:"
  echo "  test              Run flutter tests"
  echo "  build             Build release APK"
  echo "  release [version] Create a new version tag and push to GitHub"
  echo "  clean             Clean up build artifacts"
  echo "  help              Show this help message"
}

# Run tests
run_tests() {
  echo -e "${YELLOW}Running Flutter tests...${NC}"
  flutter test
  echo -e "${GREEN}Tests completed!${NC}"
}

# Build release APK
build_release() {
  echo -e "${YELLOW}Building release APK...${NC}"
  flutter build apk --release
  echo -e "${GREEN}APK built successfully at build/app/outputs/flutter-apk/app-release.apk${NC}"
}

# Create a release
create_release() {
  if [ -z "$1" ]; then
    echo -e "${RED}Error: Version number is required for release${NC}"
    echo "Usage: ./build.sh release v1.0.0"
    exit 1
  fi

  VERSION=$1
  
  if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo -e "${RED}Error: Version must follow format v0.0.0${NC}"
    exit 1
  fi
  
  echo -e "${YELLOW}Creating release $VERSION...${NC}"
  
  # Make sure we have latest changes
  git pull --ff-only

  # Make sure repo is clean
  if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}Error: Working directory is not clean. Please commit or stash changes.${NC}"
    exit 1
  fi
  
  # Update version in pubspec.yaml
  VERSION_NO_V="${VERSION#v}"
  sed -i "s/^version: .*/version: $VERSION_NO_V/g" pubspec.yaml

  # Commit version change
  git add pubspec.yaml
  git commit -m "Bump version to $VERSION"
  
  # Create tag
  git tag -a "$VERSION" -m "Release $VERSION"
  
  # Push changes
  echo -e "${YELLOW}Pushing changes and tag to origin...${NC}"
  git push && git push origin "$VERSION"
  
  echo -e "${GREEN}Release $VERSION created successfully!${NC}"
  echo "GitHub Action will automatically build and publish the release."
}

# Clean up
clean_project() {
  echo -e "${YELLOW}Cleaning up project...${NC}"
  flutter clean
  echo -e "${GREEN}Cleaned!${NC}"
}

# Main command handler
case "$1" in
  test)
    run_tests
    ;;
  build)
    build_release
    ;;
  release)
    create_release "$2"
    ;;
  clean)
    clean_project
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    show_help
    ;;
esac
