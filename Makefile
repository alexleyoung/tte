.PHONY: build install clean help

# Project configuration
PROJECT_NAME = tte
SCHEME = tte
CONFIGURATION = Release
BUILD_DIR = build/Release
DERIVED_DATA_DIR = ~/Library/Developer/Xcode/DerivedData
INSTALL_DIR = /Applications

help:
	@echo "Available targets:"
	@echo "  make build    - Build the app in Release configuration"
	@echo "  make install  - Build and install the app to /Applications"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make help     - Show this help message"

build:
	@echo "Building $(PROJECT_NAME) in $(CONFIGURATION) mode..."
	xcodebuild -scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		clean build \
		-derivedDataPath $(BUILD_DIR)
	@echo "✅ Build completed successfully"

install: build
	@echo "Installing $(PROJECT_NAME).app to $(INSTALL_DIR)..."
	@echo "Note: This may require sudo permissions"
	@sudo rm -rf $(INSTALL_DIR)/$(PROJECT_NAME).app
	@sudo cp -R $(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(PROJECT_NAME).app $(INSTALL_DIR)/
	@echo "✅ $(PROJECT_NAME).app installed to $(INSTALL_DIR)"
	@echo ""
	@echo "To launch the app, run:"
	@echo "  open $(INSTALL_DIR)/$(PROJECT_NAME).app"

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@xcodebuild -scheme $(SCHEME) clean
	@echo "✅ Clean completed"
