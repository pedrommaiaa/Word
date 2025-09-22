import Cocoa

class DocumentViewController: NSViewController, NSWindowDelegate {
    
    // MARK: - UI Components
    
    private var scrollView: NSScrollView!
    private var paperContainer: NSView!
    private var paperView: NSView!
    private var textView: NSTextView!
    private var statusBar: NSView!
    private var statusLabel: NSTextField!
    private var zoomContainer: NSView?
    private var zoomInButton: NSView?
    private var zoomOutButton: NSView?
    private var zoomLabel: NSTextField?
    
    // MARK: - Properties
    
    var document: DocumentModel? {
        didSet {
            if isViewLoaded {
                setupDocument()
            }
        }
    }
    
    private var zoomLevel: CGFloat = 1.0
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        // Restore original workspace background
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0).cgColor
        setupUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        
        // Setup document if it was set before view loaded
        if document != nil {
            setupDocument()
        } else {
            updateStatusBar()
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // Set window delegate to handle zoom behavior
        view.window?.delegate = self
        
        // Always ensure cursor starts at top
        setCursorToTop()
    }
    
    private func setCursorToTop() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let textView = self.textView else { return }
            
            // Set cursor at the very beginning
            textView.selectedRange = NSRange(location: 0, length: 0)
            
            // Force scroll to absolute top of the text view
            textView.scroll(NSPoint.zero)
            
            // Position the main scroll view to show the paper properly
            if let mainScrollView = self.scrollView {
                // Calculate a position that shows the top of the paper with some margin
                let paperFrame = self.paperView.frame
                
                // Show the paper with a small margin from the top
                let targetY = paperFrame.maxY - mainScrollView.frame.height + 50 // 50px margin from top
                let scrollPoint = NSPoint(x: paperFrame.midX - mainScrollView.frame.width / 2, y: max(0, targetY))
                
                // Scroll to show the paper properly
                mainScrollView.contentView.scroll(to: scrollPoint)
                mainScrollView.reflectScrolledClipView(mainScrollView.contentView)
            }
            
            // Make text view first responder after positioning
            textView.window?.makeFirstResponder(textView)
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        createScrollView()
        createPaperViews()
        createTextView()
        createStatusBar()
        createZoomControl()
        setupConstraints()
        layoutPaper()
    }
    
    private func createScrollView() {
        scrollView = NSScrollView()
        GlassmorphismDesign.styleScrollView(scrollView)
        
        view.addSubview(scrollView)
    }
    
    private func createPaperViews() {
        // Container for centering the paper
        paperContainer = NSView()
        
        // Create floating paper with glassmorphism design
        let paperSize = DocumentLayout.calculatePaperSize(for: view.frame.size, zoomLevel: zoomLevel)
        paperView = GlassmorphismDesign.createFloatingPaper(size: paperSize)
        
        paperContainer.addSubview(paperView)
        scrollView.documentView = paperContainer
        
        // Add subtle fade-in animation
        paperView.layer?.add(GlassmorphismDesign.fadeInAnimation(), forKey: "fadeIn")
    }
    
    private func createTextView() {
        textView = NSTextView()
        let paperSize = DocumentLayout.calculatePaperSize(for: view.frame.size, zoomLevel: zoomLevel)
        DocumentLayout.setupTextView(textView, paperSize: paperSize, zoomLevel: zoomLevel)
        
        paperView.addSubview(textView)
        textView.frame = NSRect(x: 0, y: 0, width: paperSize.width, height: paperSize.height)
    }
    
    private func createStatusBar() {
        // Restore original status bar
        statusBar = NSView()
        statusBar.wantsLayer = true
        statusBar.layer?.backgroundColor = NSColor.white.cgColor
        
        // Create original status label with smaller font
        statusLabel = NSTextField(labelWithString: "Words: 0 | Characters: 0")
        statusLabel.font = NSFont.systemFont(ofSize: 10)
        statusLabel.textColor = NSColor.black
        statusBar.addSubview(statusLabel)
        
        view.addSubview(statusBar)
    }
    
    private func createZoomControl() {
        // Create container for zoom controls
        zoomContainer = NSView()
        guard let container = zoomContainer else { return }
        
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.white.cgColor
        container.layer?.cornerRadius = 12
        container.layer?.shadowColor = NSColor.black.cgColor
        container.layer?.shadowOpacity = 0.1
        container.layer?.shadowOffset = NSSize(width: 0, height: 2)
        container.layer?.shadowRadius = 4
        
        // Create zoom out button (-)
        zoomOutButton = createZoomButton(title: "−", action: #selector(zoomOut))
        
        // Create zoom percentage label
        zoomLabel = NSTextField(labelWithString: "100%")
        guard let label = zoomLabel else { return }
        
        label.font = NSFont.systemFont(ofSize: 8, weight: .medium)
        label.textColor = NSColor(white: 0.4, alpha: 1.0)
        label.backgroundColor = NSColor.clear
        label.isBezeled = false
        label.isEditable = false
        label.alignment = .center
        
        // Create zoom in button (+)
        zoomInButton = createZoomButton(title: "+", action: #selector(zoomIn))
        
        // Add all components to container
        if let outButton = zoomOutButton, let inButton = zoomInButton {
            container.addSubview(outButton)
            container.addSubview(label)
            container.addSubview(inButton)
        }
        
        view.addSubview(container)
    }
    
    private func createZoomButton(title: String, action: Selector) -> NSView {
        let button = NSView()
        button.wantsLayer = true
        
        // Create button label
        let buttonLabel = NSTextField(labelWithString: title)
        buttonLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        buttonLabel.textColor = NSColor(white: 0.3, alpha: 1.0)
        buttonLabel.backgroundColor = NSColor.clear
        buttonLabel.isBezeled = false
        buttonLabel.isEditable = false
        buttonLabel.alignment = .center
        
        button.addSubview(buttonLabel)
        
        // Add click gesture
        let clickGesture = NSClickGestureRecognizer(target: self, action: action)
        button.addGestureRecognizer(clickGesture)
        
        // Setup constraints for button label
        buttonLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonLabel.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            buttonLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        return button
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        statusBar.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        zoomContainer?.translatesAutoresizingMaskIntoConstraints = false
        zoomInButton?.translatesAutoresizingMaskIntoConstraints = false
        zoomOutButton?.translatesAutoresizingMaskIntoConstraints = false
        zoomLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll view with original workspace padding
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: statusBar.topAnchor, constant: -10),
            
            // Original status bar - full width at bottom, smaller height
            statusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 22),
            
            // Status label positioned like original
            statusLabel.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor, constant: 20),
            statusLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor)
        ])
        
        // Add zoom control constraints - compact top right corner
        if let container = zoomContainer,
           let outButton = zoomOutButton,
           let inButton = zoomInButton,
           let label = zoomLabel {
            
            NSLayoutConstraint.activate([
                // Position container in top-right corner
                container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
                container.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
                container.widthAnchor.constraint(equalToConstant: 70),
                container.heightAnchor.constraint(equalToConstant: 24),
                
                // Zoom out button on left
                outButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 2),
                outButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
                outButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2),
                outButton.widthAnchor.constraint(equalToConstant: 20),
                
                // Zoom label in center
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                label.widthAnchor.constraint(equalToConstant: 26),
                
                // Zoom in button on right
                inButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -2),
                inButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
                inButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2),
                inButton.widthAnchor.constraint(equalToConstant: 20)
            ])
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSText.didChangeNotification,
            object: textView,
            queue: .main
        ) { [weak self] _ in
            self?.textDidChange()
        }
        
    }
    
    private func setupDocument() {
        guard let document = document else { return }
        
        // Store current selection if any
        let currentSelection = textView?.selectedRange() ?? NSRange(location: 0, length: 0)
        
        // Connect the text storage safely
        if let textView = textView, textView.textStorage != nil {
            // Replace text storage while preserving text view state
            textView.layoutManager?.replaceTextStorage(document.textStorage)
            
            // Restore selection after text storage replacement
            DispatchQueue.main.async {
                textView.selectedRange = currentSelection
            }
        }
        
        // Ensure cursor starts at top after document setup
        DispatchQueue.main.async { [weak self] in
            self?.setCursorToTop()
        }
        
        updateStatusBar()
    }
    
    private func layoutPaper() {
        let paperSize = DocumentLayout.calculatePaperSize(for: view.frame.size, zoomLevel: zoomLevel)
        let containerSize = scrollView.frame.size
        
        // Make container larger than scroll view for centering
        let containerWidth = max(paperSize.width + 100, containerSize.width)
        let containerHeight = max(paperSize.height + 100, containerSize.height)
        
        paperContainer.frame = NSRect(x: 0, y: 0, width: containerWidth, height: containerHeight)
        DocumentLayout.centerPaper(paperView, in: paperContainer, paperSize: paperSize)
        
        // Update paper view size
        paperView.frame = NSRect(
            x: (containerWidth - paperSize.width) / 2,
            y: (containerHeight - paperSize.height) / 2,
            width: paperSize.width,
            height: paperSize.height
        )
        
        // Store current text content and selection
        let currentText = textView.string
        let currentSelection = textView.selectedRange()
        
        // Update text view size and configuration
        textView.frame = NSRect(x: 0, y: 0, width: paperSize.width, height: paperSize.height)
        
        // Update text view properties WITHOUT destroying text storage connection
        updateTextViewLayout(paperSize: paperSize, zoomLevel: zoomLevel)
        
        // Restore text if it was lost
        if textView.string.isEmpty && !currentText.isEmpty {
            textView.string = currentText
        }
        
        // Apply formatting to existing text while preserving content
        if let textStorage = textView.textStorage, textStorage.length > 0 {
            let range = NSRange(location: 0, length: textStorage.length)
            let baseFontSize: CGFloat = 11
            let scaledFontSize = baseFontSize * zoomLevel
            let font = NSFont(name: "Arial", size: scaledFontSize) ?? NSFont.systemFont(ofSize: scaledFontSize)
            
            textStorage.addAttribute(.font, value: font, range: range)
        }
        
        // Restore selection
        textView.selectedRange = currentSelection
        
        // Ensure proper scroll position after layout
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let textView = self.textView else { return }
            
            // If we're at the beginning of the document, scroll to top
            let currentRange = textView.selectedRange()
            if currentRange.location == 0 {
                self.setCursorToTop()
            } else {
                // Keep current selection visible
                textView.scrollRangeToVisible(currentRange)
            }
        }
    }
    
    // MARK: - Layout Helpers
    
    private func updateTextViewLayout(paperSize: NSSize, zoomLevel: CGFloat) {
        // Use the centralized layout setup for consistency
        DocumentLayout.setupTextView(textView, paperSize: paperSize, zoomLevel: zoomLevel)
    }
    
    // MARK: - Event Handlers
    
    private func textDidChange() {
        document?.updateChangeCount(.changeDone)
        updateStatusBar()
    }
    
    
    private func updateStatusBar() {
        guard let statusLabel = statusLabel else { return }
        
        if let document = document {
            let stats = document.getDocumentStatistics()
            statusLabel.stringValue = "Words: \(stats.words) | Characters: \(stats.characters)"
        } else {
            statusLabel.stringValue = "Words: 0 | Characters: 0"
        }
    }
    
    // MARK: - Zoom Support
    
    @objc func zoomIn() {
        zoomLevel = min(zoomLevel * 1.2, 3.0)
        DispatchQueue.main.async { [weak self] in
            self?.layoutPaper()
            self?.updateZoomDisplay()
        }
    }
    
    @objc func zoomOut() {
        zoomLevel = max(zoomLevel / 1.2, 0.5)
        DispatchQueue.main.async { [weak self] in
            self?.layoutPaper()
            self?.updateZoomDisplay()
        }
    }
    
    func zoomActualSize() {
        zoomLevel = 1.0
        DispatchQueue.main.async { [weak self] in
            self?.layoutPaper()
            self?.updateZoomDisplay()
        }
    }
    
    
    private func updateZoomDisplay() {
        guard let label = zoomLabel else { return }
        let percentage = Int(zoomLevel * 100)
        label.stringValue = "\(percentage)%"
    }
    
    // MARK: - NSWindowDelegate
    
    func windowShouldZoom(_ window: NSWindow, toFrame newFrame: NSRect) -> Bool {
        // Allow the native zoom behavior
        return true
    }
    
    func windowWillUseStandardFrame(_ window: NSWindow, defaultFrame: NSRect) -> NSRect {
        // Use the default frame for zoom behavior
        return defaultFrame
    }
    
    func windowDidResize(_ notification: Notification) {
        // Update layout when window resizes (including zoom/fullscreen)
        // Use a slight delay to ensure window operations complete first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.layoutPaper()
        }
    }
    
    func windowDidEnterFullScreen(_ notification: Notification) {
        // Adjust layout for fullscreen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.layoutPaper()
        }
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        // Adjust layout when exiting fullscreen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.layoutPaper()
        }
    }
}

extension DocumentViewController {
    // MARK: - Mouse Events for Title Bar Double-Click
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        // Handle double-click on title bar area
        if event.clickCount == 2 {
            let locationInView = view.convert(event.locationInWindow, from: nil)
            
            // Check if click is in the top area (title bar region)
            if locationInView.y > view.bounds.height - 40 {
                // Trigger zoom/unzoom behavior
                view.window?.zoom(nil)
            }
        }
    }
}
