//
//  TestEngine.swift
//  HTMLConsoleApp
//
//  Created by Collin Pieper on 9/11/25.
//

import Foundation

// Test/Demo engine with image placement and echo functionality
class TestEngine: Engine {
    private var inputCount: Int = 0
    private var availableImages: [String] = []
    private var imagesPath: String?

    override init(controller: ConsoleController, moduleBundle: ModuleBundle? = nil) {
        super.init(controller: controller, moduleBundle: moduleBundle)

        if let moduleBundle = moduleBundle {
            print("TestEngine: Initializing with module bundle: \(moduleBundle.info.name)")
            print("TestEngine: Bundle path: \(moduleBundle.bundlePath)")
            // Load images from module bundle
            self.imagesPath = moduleBundle.bundlePath + "/images"
            self.availableImages = discoverImagesFromModule()
        } else {
            print("TestEngine: No module bundle provided, using fallback")
            // Fallback: load images from main bundle (for backward compatibility)
            self.availableImages = discoverAvailableImages()
        }

        print("TestEngine: Initialized with \(availableImages.count) images")
    }
    
    // Discover images from module bundle
    private func discoverImagesFromModule() -> [String] {
        guard let moduleBundle = moduleBundle else {
            print("TestEngine: No module bundle available")
            return []
        }

        // Find the bundle in the app's Resources directory
        let bundleName = URL(fileURLWithPath: moduleBundle.bundlePath).lastPathComponent
        guard let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: nil),
              let nestedBundle = Bundle(url: bundleURL) else {
            print("TestEngine: Could not find bundle \(bundleName) in app resources")
            return []
        }

        // Look for images in the bundle's images directory
        guard let imagesURL = nestedBundle.url(forResource: "images", withExtension: nil) else {
            print("TestEngine: No images directory found in bundle")
            return []
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(at: imagesURL, includingPropertiesForKeys: nil)
            let imageFiles = contents
                .compactMap { $0.lastPathComponent }
                .filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".gif") }
                .sorted()

            print("TestEngine: Discovered \(imageFiles.count) images from bundle: \(imageFiles.prefix(5))")
            return imageFiles
        } catch {
            print("TestEngine: Error reading images from bundle: \(error)")
            return []
        }
    }

    // Fallback: discover images from main bundle (backward compatibility)
    private func discoverAvailableImages() -> [String] {
        guard let bundlePath = Bundle.main.resourcePath else {
            return []
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
            let imageFiles = contents
                .filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".gif") }
                .sorted()

            print("TestEngine: Discovered \(imageFiles.count) images from main bundle (fallback)")
            return imageFiles
        } catch {
            return []
        }
    }

    // Get the image path/URL that WebKit can access
    private func getImagePath(for imageName: String) -> String? {
        let fileNameWithoutExtension = imageName.components(separatedBy: ".").first ?? imageName
        let fileExtension = imageName.components(separatedBy: ".").last ?? "png"

        if let moduleBundle = moduleBundle {
            // Try to find the image in the nested bundle structure within app bundle
            let bundleName = URL(fileURLWithPath: moduleBundle.bundlePath).lastPathComponent
            if let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: nil),
               let nestedBundle = Bundle(url: bundleURL),
               let imagesURL = nestedBundle.url(forResource: "images", withExtension: nil) {

                // Construct the image URL within the images directory
                let imageURL = imagesURL.appendingPathComponent(imageName)

                // Verify the file exists
                if FileManager.default.fileExists(atPath: imageURL.path) {
                    print("TestEngine: Found image at \(imageURL.absoluteString)")
                    return imageURL.absoluteString
                } else {
                    print("TestEngine: Image \(imageName) not found at \(imageURL.path)")
                }
            }

            // Fallback: try to access directly in main bundle Resources
            if let imageURL = Bundle.main.url(forResource: fileNameWithoutExtension, withExtension: fileExtension) {
                print("TestEngine: Using fallback image from main bundle: \(imageURL.absoluteString)")
                return imageURL.absoluteString
            }

            print("TestEngine: Could not find image \(imageName) in any location")
            return nil
        } else {
            // Fallback to main bundle resources (these should work)
            if let bundleURL = Bundle.main.url(forResource: fileNameWithoutExtension, withExtension: fileExtension) {
                return bundleURL.absoluteString
            }
            return nil
        }
    }
    
    override func configureStatusBar() {
        statusBar?.setLineCount(1)

        // Register named fields
        statusBar?.registerField(name: "module_name", line: 0, alignment: .center)
        statusBar?.registerField(name: "input_count", line: 0, alignment: .left)
        statusBar?.registerField(name: "image_count", line: 0, alignment: .right)

        // Set initial field values
        let moduleName = moduleBundle?.info.name ?? "Test Engine"
        statusBar?.updateField(name: "module_name", text: moduleName)
        statusBar?.updateField(name: "input_count", text: "Inputs: 0")
        statusBar?.updateField(name: "image_count", text: "Images: \(availableImages.count)")
    }
    
    override func start() {
        statusBar?.show()
        showWelcomeMessage()
        controller?.showPrompt()
    }
    
    override internal func showWelcomeMessage() {
        if let moduleBundle = moduleBundle {
            addContent(text: "Welcome to \(moduleBundle.info.name) v\(moduleBundle.info.version)")
            if let description = moduleBundle.info.description {
                addContent(text: description)
            }
            addContent(text: "Module loaded with \(availableImages.count) images available.")
        } else {
            addContent(text: "Welcome to HTMLConsole Test Mode")
        }
        addContent(text: "Type something and press Enter to see responsive content layout...")
    }
    
    override func processInput(_ input: String) {
        incrementInputCount()
        
        // Add user input as text content
        addContent(text: "\n" + input)
        
        // Occasionally add content with a random image (50% chance)
        if !availableImages.isEmpty && Int.random(in: 1...2) == 1 {
            addRandomContent()
        }
        
        controller?.showPrompt()
    }
    
    
    private func addRandomContent() {
        guard let randomImageName = availableImages.randomElement(),
              let imagePath = getImagePath(for: randomImageName) else { return }

        // Randomly decide whether to add a caption (50% chance)
        let caption = Int.random(in: 1...2) == 1 ? randomImageName : ""

        // Decide what type of content to add
        let contentType = Int.random(in: 1...4)

        switch contentType {
        case 1:
            // Text only
            addContent(text: "Some interesting text content about the current topic.")
        case 2:
            // Image only
            addContent(image: imagePath, caption: caption)
        case 3:
            // Text with image
            addContent(text: "Here's some descriptive text that goes with this image.",
                      image: imagePath,
                      caption: caption)
        case 4:
            // Just an image with caption
            addContent(image: imagePath, caption: caption.isEmpty ? "A random image" : caption)
        default:
            break
        }

        print("DEBUG: CONTENT - Added content with image: \(randomImageName) -> \(imagePath), caption: \(caption.isEmpty ? "none" : caption)")
    }
    
    func incrementInputCount() {
        inputCount += 1
        
        // Update input count in status bar
        statusBar?.updateField(name: "input_count", text: "Inputs: \(inputCount)")
    }
}
