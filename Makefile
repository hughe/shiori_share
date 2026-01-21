# Shiori Share - Build Makefile

.PHONY: all build build-ios build-macos clean test open help

# Default target
all: build-sim

# Build all platforms (iOS only - macOS requires additional work for share extension)
build: build-sim

# Build for iOS
build-ios:
	xcodebuild -project ShioriShare.xcodeproj \
		-scheme ShioriShare \
		-destination 'generic/platform=iOS' \
		-configuration Debug \
		build

# Build for macOS
build-macos:
	xcodebuild -project ShioriShare.xcodeproj \
		-scheme ShioriShare \
		-destination 'platform=macOS' \
		-configuration Debug \
		build

# Build for iOS Simulator
build-sim:
	xcodebuild -project ShioriShare.xcodeproj \
		-scheme ShioriShare \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-configuration Debug \
		build

# Clean build artifacts
clean:
	xcodebuild -project ShioriShare.xcodeproj -alltargets clean
	rm -rf build/
	rm -rf ~/Library/Developer/Xcode/DerivedData/ShioriShare-*

# Run tests
test:
	xcodebuild -project ShioriShare.xcodeproj \
		-scheme ShioriShare \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		test

# Open project in Xcode
open:
	open ShioriShare.xcodeproj

# Archive for release
archive:
	xcodebuild -project ShioriShare.xcodeproj \
		-scheme ShioriShare \
		-destination 'generic/platform=iOS' \
		-configuration Release \
		-archivePath build/ShioriShare.xcarchive \
		archive

# Help
help:
	@echo "Shiori Share Build Targets:"
	@echo "  make build      - Build for iOS and macOS"
	@echo "  make build-ios  - Build for iOS (device)"
	@echo "  make build-macos - Build for macOS"
	@echo "  make build-sim  - Build for iOS Simulator"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make test       - Run tests on iOS Simulator"
	@echo "  make open       - Open project in Xcode"
	@echo "  make archive    - Create release archive"
