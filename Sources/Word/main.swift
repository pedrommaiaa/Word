import Cocoa

// Set up the application
let app = NSApplication.shared

// CRITICAL: Initialize custom DocumentController BEFORE setting delegate
// This ensures our DocumentController becomes the shared instance
_ = DocumentController()

let delegate = AppDelegate()
app.delegate = delegate

// Configure the application to behave as a regular app
app.setActivationPolicy(.regular)

// Start the main event loop
app.run()
