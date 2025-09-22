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
    
    // Font controls - separate floating buttons
    private var fontButton: NSView!
    private var fontSizeButton: NSView!
    private var fontLabel: NSTextField!
    private var fontSizeLabel: NSTextField!
    
    // Width constraints for dynamic sizing
    private var fontButtonWidthConstraint: NSLayoutConstraint!
    private var fontSizeButtonWidthConstraint: NSLayoutConstraint!
    
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
        createFontControls()
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
    
    private func createFontControls() {
        // Create font button - displays current font name
        fontButton = createFloatingButton()
        fontLabel = NSTextField(labelWithString: "Arial")
        setupFontLabel()
        fontButton.addSubview(fontLabel)
        
        // Add click gesture for font selection
        let fontClickGesture = NSClickGestureRecognizer(target: self, action: #selector(showFontMenu))
        fontButton.addGestureRecognizer(fontClickGesture)
        
        // Create font size button - displays current size
        fontSizeButton = createFloatingButton()
        fontSizeLabel = NSTextField(labelWithString: "11")
        setupFontSizeLabel()
        fontSizeButton.addSubview(fontSizeLabel)
        
        // Add click gesture for font size selection
        let sizeClickGesture = NSClickGestureRecognizer(target: self, action: #selector(showFontSizeMenu))
        fontSizeButton.addGestureRecognizer(sizeClickGesture)
        
        view.addSubview(fontButton)
        view.addSubview(fontSizeButton)
    }
    
    private func createFloatingButton() -> NSView {
        let button = NSView()
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.white.cgColor
        button.layer?.cornerRadius = 12
        button.layer?.shadowColor = NSColor.black.cgColor
        button.layer?.shadowOpacity = 0.1
        button.layer?.shadowOffset = NSSize(width: 0, height: 2)
        button.layer?.shadowRadius = 4
        
        // Subtle border for definition
        button.layer?.borderWidth = 0.5
        button.layer?.borderColor = NSColor(white: 0.9, alpha: 1.0).cgColor
        
        return button
    }
    
    private func setupFontLabel() {
        fontLabel.font = NSFont.systemFont(ofSize: 9, weight: .medium) // Smaller font for 70px width
        fontLabel.textColor = NSColor(white: 0.2, alpha: 1.0)
        fontLabel.backgroundColor = NSColor.clear
        fontLabel.isBezeled = false
        fontLabel.isEditable = false
        fontLabel.alignment = .center
        fontLabel.maximumNumberOfLines = 1
        fontLabel.lineBreakMode = .byTruncatingTail
    }
    
    private func setupFontSizeLabel() {
        fontSizeLabel.font = NSFont.systemFont(ofSize: 9, weight: .medium) // Match font label size
        fontSizeLabel.textColor = NSColor(white: 0.2, alpha: 1.0)
        fontSizeLabel.backgroundColor = NSColor.clear
        fontSizeLabel.isBezeled = false
        fontSizeLabel.isEditable = false
        fontSizeLabel.alignment = .center
    }
    
    private func calculateOptimalWidth(for text: String, font: NSFont, minWidth: CGFloat = 40, maxWidth: CGFloat = 120) -> CGFloat {
        let textSize = text.size(withAttributes: [.font: font])
        let padding: CGFloat = 16 // 8px on each side to match constraint padding (4px each side + some buffer)
        let calculatedWidth = textSize.width + padding
        return max(minWidth, min(maxWidth, calculatedWidth))
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
        
        // Font controls
        fontButton.translatesAutoresizingMaskIntoConstraints = false
        fontSizeButton.translatesAutoresizingMaskIntoConstraints = false
        fontLabel.translatesAutoresizingMaskIntoConstraints = false
        fontSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        // Add font controls constraints - separate floating buttons
        NSLayoutConstraint.activate([
            // Font button - leftmost (dynamic width)
            fontButton.trailingAnchor.constraint(equalTo: fontSizeButton.leadingAnchor, constant: -15),
            fontButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            fontButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Font label inside font button
            fontLabel.centerXAnchor.constraint(equalTo: fontButton.centerXAnchor),
            fontLabel.centerYAnchor.constraint(equalTo: fontButton.centerYAnchor),
            fontLabel.leadingAnchor.constraint(equalTo: fontButton.leadingAnchor, constant: 4),
            fontLabel.trailingAnchor.constraint(equalTo: fontButton.trailingAnchor, constant: -4),
            
            // Font size button - middle (compact width)
            fontSizeButton.trailingAnchor.constraint(equalTo: zoomContainer?.leadingAnchor ?? view.trailingAnchor, constant: -15),
            fontSizeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            fontSizeButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Font size label inside font size button
            fontSizeLabel.centerXAnchor.constraint(equalTo: fontSizeButton.centerXAnchor),
            fontSizeLabel.centerYAnchor.constraint(equalTo: fontSizeButton.centerYAnchor)
        ])
        
        // Create and store width constraints for dynamic sizing
        fontButtonWidthConstraint = fontButton.widthAnchor.constraint(equalToConstant: 70)
        fontSizeButtonWidthConstraint = fontSizeButton.widthAnchor.constraint(equalToConstant: 50)
        
        NSLayoutConstraint.activate([
            fontButtonWidthConstraint,
            fontSizeButtonWidthConstraint
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
        
        // Monitor selection changes to update font controls
        NotificationCenter.default.addObserver(
            forName: NSTextView.didChangeSelectionNotification,
            object: textView,
            queue: .main
        ) { [weak self] _ in
            self?.updateFontControls()
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
        
        // Store current text content, selection, and typing attributes
        let currentText = textView.string
        let currentSelection = textView.selectedRange()
        let currentTypingAttributes = textView.typingAttributes
        
        // Update text view size and configuration
        textView.frame = NSRect(x: 0, y: 0, width: paperSize.width, height: paperSize.height)
        
        // Update text view properties WITHOUT destroying text storage connection
        updateTextViewLayout(paperSize: paperSize, zoomLevel: zoomLevel)
        
        // Restore text if it was lost
        if textView.string.isEmpty && !currentText.isEmpty {
            textView.string = currentText
        }
        
        // Update existing text formatting while preserving user's font choices
        if let textStorage = textView.textStorage, textStorage.length > 0 {
            // Only update zoom scaling for existing fonts, don't override font choices
            textStorage.enumerateAttribute(.font, in: NSRange(location: 0, length: textStorage.length)) { (value, range, stop) in
                if let currentFont = value as? NSFont {
                    // Scale the existing font to match new zoom level
                    let originalSize = currentFont.pointSize / self.zoomLevel // Get original size
                    let newScaledSize = originalSize * zoomLevel
                    if let newFont = NSFont(name: currentFont.fontName, size: newScaledSize) {
                        textStorage.addAttribute(.font, value: newFont, range: range)
                    }
                }
            }
        }
        
        // Restore typing attributes (preserves user's font/size choice)
        textView.typingAttributes = currentTypingAttributes
        
        // Restore selection
        textView.selectedRange = currentSelection
        
        // Update font controls to show the preserved settings
        DispatchQueue.main.async { [weak self] in
            self?.updateFontControls()
        }
        
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
        // Store current typing attributes to preserve user's font choice
        let currentTypingAttributes = textView.typingAttributes
        
        // Use the centralized layout setup for consistency
        DocumentLayout.setupTextView(textView, paperSize: paperSize, zoomLevel: zoomLevel)
        
        // Restore user's typing attributes (font/size choice)
        if let userFont = currentTypingAttributes[.font] as? NSFont {
            // Update the user's chosen font with the correct zoom scaling
            let originalSize = userFont.pointSize / zoomLevel // Get original size
            let newScaledSize = originalSize * zoomLevel
            if let scaledFont = NSFont(name: userFont.fontName, size: newScaledSize) {
                var preservedAttributes = currentTypingAttributes
                preservedAttributes[.font] = scaledFont
                textView.typingAttributes = preservedAttributes
            } else {
                textView.typingAttributes = currentTypingAttributes
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func textDidChange() {
        document?.updateChangeCount(.changeDone)
        updateStatusBar()
        updateFontControls()
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
    
    @objc private func showFontMenu() {
        let menu = NSMenu()
        
        let basicFonts = [
            "Arial",
            "Times New Roman", 
            "Helvetica",
            "Georgia",
            "Courier New",
            "Verdana",
            "Trebuchet MS",
            "Comic Sans MS"
        ]
        
        for fontName in basicFonts {
            let menuItem = NSMenuItem(title: fontName, action: #selector(selectFont(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = fontName
            
            // Check current font (no checkmark if mixed selection)
            if let currentFontName = getCurrentFontName(), fontName == currentFontName {
                menuItem.state = .on
            }
            
            menu.addItem(menuItem)
        }
        
        // Show menu below the font button
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: -5), in: fontButton)
    }
    
    @objc private func showFontSizeMenu() {
        let menu = NSMenu()
        
        let commonSizes = ["8", "9", "10", "11", "12", "14", "16", "18", "20", "24", "28", "32", "36", "48", "72"]
        
        for sizeString in commonSizes {
            let menuItem = NSMenuItem(title: sizeString, action: #selector(selectFontSize(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = sizeString
            
            // Check current size (no checkmark if mixed selection)
            if let currentSize = getCurrentFontSize(), CGFloat(Double(sizeString) ?? 0) == currentSize {
                menuItem.state = .on
            }
            
            menu.addItem(menuItem)
        }
        
        // Show menu below the font size button
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: -5), in: fontSizeButton)
    }
    
    @objc private func selectFont(_ sender: NSMenuItem) {
        guard let fontName = sender.representedObject as? String else { return }
        
        let currentSize = getCurrentFontSize() ?? 11.0
        print("Applying font change: \(fontName) at size \(currentSize)")
        applyFontChange(fontName: fontName, fontSize: currentSize)
    }
    
    @objc private func selectFontSize(_ sender: NSMenuItem) {
        guard let sizeString = sender.representedObject as? String,
              let fontSize = Double(sizeString) else { return }
        
        let currentFont = getCurrentFontName() ?? "Arial"
        print("Applying size change: \(currentFont) at size \(fontSize)")
        applyFontChange(fontName: currentFont, fontSize: CGFloat(fontSize))
    }
    
    private func getCurrentFontName() -> String? {
        guard let textView = textView, let textStorage = textView.textStorage else { 
            return fontLabel?.stringValue ?? "Arial" 
        }
        
        let selectedRange = textView.selectedRange()
        
        if selectedRange.length > 0 {
            // Check if selection has mixed fonts
            var mixedFonts = false
            var firstFont: NSFont?
            
            textStorage.enumerateAttribute(.font, in: selectedRange) { (value, range, stop) in
                if let font = value as? NSFont {
                    if let first = firstFont {
                        if first.familyName != font.familyName {
                            mixedFonts = true
                            stop.pointee = true
                        }
                    } else {
                        firstFont = font
                    }
                }
            }
            
            if mixedFonts {
                return nil // Mixed selection - return nil for blank display
            } else if let font = firstFont {
                return font.familyName ?? "Arial"
            }
        } else {
            // No selection - use typing attributes or cursor position
            if let font = textView.typingAttributes[.font] as? NSFont {
                return font.familyName ?? "Arial"
            } else if selectedRange.location > 0 {
                let cursorLocation = max(0, selectedRange.location - 1)
                if let font = textStorage.attribute(.font, at: cursorLocation, effectiveRange: nil) as? NSFont {
                    return font.familyName ?? "Arial"
                }
            }
        }
        
        return "Arial"
    }
    
    private func getCurrentFontSize() -> CGFloat? {
        guard let textView = textView, let textStorage = textView.textStorage else { 
            return CGFloat(Double(fontSizeLabel?.stringValue ?? "11") ?? 11.0)
        }
        
        let selectedRange = textView.selectedRange()
        
        if selectedRange.length > 0 {
            // Check if selection has mixed font sizes
            var mixedSizes = false
            var firstSize: CGFloat?
            
            textStorage.enumerateAttribute(.font, in: selectedRange) { (value, range, stop) in
                if let font = value as? NSFont {
                    let size = font.pointSize / zoomLevel // Adjust for zoom
                    if let first = firstSize {
                        if abs(first - size) > 0.1 { // Allow small rounding differences
                            mixedSizes = true
                            stop.pointee = true
                        }
                    } else {
                        firstSize = size
                    }
                }
            }
            
            if mixedSizes {
                return nil // Mixed selection - return nil for blank display
            } else if let size = firstSize {
                return size
            }
        } else {
            // No selection - use typing attributes or cursor position
            if let font = textView.typingAttributes[.font] as? NSFont {
                return font.pointSize / zoomLevel
            } else if selectedRange.location > 0 {
                let cursorLocation = max(0, selectedRange.location - 1)
                if let font = textStorage.attribute(.font, at: cursorLocation, effectiveRange: nil) as? NSFont {
                    return font.pointSize / zoomLevel
                }
            }
        }
        
        return 11.0
    }
    
    private func applyFontChange(fontName: String, fontSize: CGFloat) {
        guard let textView = textView else { return }
        
        // Calculate actual font size considering zoom
        let actualFontSize = fontSize * zoomLevel
        
        // Try to create font with the family name
        var newFont: NSFont?
        if let font = NSFont(name: fontName, size: actualFontSize) {
            newFont = font
        } else {
            // Fallback: try with family name and default traits
            newFont = NSFont(descriptor: NSFontDescriptor(fontAttributes: [
                .family: fontName,
                .size: actualFontSize
            ]), size: actualFontSize)
        }
        
        // Final fallback to system font if needed
        let font = newFont ?? NSFont.systemFont(ofSize: actualFontSize)
        
        let selectedRange = textView.selectedRange()
        
        if selectedRange.length > 0 {
            // Apply to selection
            textView.textStorage?.addAttribute(.font, value: font, range: selectedRange)
        }
        
        // ALWAYS update typing attributes for future text
        var typingAttributes = textView.typingAttributes
        typingAttributes[.font] = font
        textView.typingAttributes = typingAttributes
        
        // Update UI to reflect current settings
        DispatchQueue.main.async { [weak self] in
            self?.updateFontControls()
        }
        
        // Mark document as changed
        document?.updateChangeCount(.changeDone)
    }
    
    private func updateFontControls() {
        let currentFontName = getCurrentFontName()
        let currentFontSize = getCurrentFontSize()
        
        // Handle mixed selections with blank display (like Google Docs)
        let displayName = currentFontName ?? ""
        let sizeString = currentFontSize != nil ? String(format: "%.0f", currentFontSize!) : ""
        
        // Update the readable labels
        fontLabel?.stringValue = displayName
        fontSizeLabel?.stringValue = sizeString
        
        // Calculate optimal widths and animate the change
        if let labelFont = fontLabel?.font {
            let textToMeasure = displayName.isEmpty ? "Arial" : displayName // Use Arial as base measurement for empty
            let fontWidth = calculateOptimalWidth(for: textToMeasure, font: labelFont, minWidth: 60, maxWidth: 300)
            animateWidthChange(constraint: fontButtonWidthConstraint, to: fontWidth)
        }
        
        if let sizeFont = fontSizeLabel?.font {
            let textToMeasure = sizeString.isEmpty ? "11" : sizeString // Use "11" as base measurement for empty
            let sizeWidth = calculateOptimalWidth(for: textToMeasure, font: sizeFont, minWidth: 35, maxWidth: 60)
            animateWidthChange(constraint: fontSizeButtonWidthConstraint, to: sizeWidth)
        }
    }
    
    private func animateWidthChange(constraint: NSLayoutConstraint, to newWidth: CGFloat) {
        constraint.constant = newWidth
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.allowsImplicitAnimation = true
            view.layoutSubtreeIfNeeded()
        }
    }
    
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
