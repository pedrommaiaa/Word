import Cocoa

// Set up the application
let app = NSApplication.shared

// Initialize custom DocumentController
_ = DocumentController()

// Set up app delegate
let delegate = AppDelegate()
app.delegate = delegate

// Configure as regular app
app.setActivationPolicy(.regular)

// Start the main event loop
app.run()
