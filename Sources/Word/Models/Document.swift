import Cocoa
import UniformTypeIdentifiers
import CoreText

// Associated object keys for text view references
private struct AssociatedKeys {
    static var wordLabel = 0
    static var document = 1
}

// Custom text view that forces black text and updates word count
class TypewriterTextView: NSTextView {
    
    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        super.insertText(insertString, replacementRange: replacementRange)
        
        // FORCE black text after every character insertion
        forceBlackText()
        updateWordCount()
    }
    
    override func didChangeText() {
        super.didChangeText()
        
        // FORCE black text after any text change
        forceBlackText()
        updateWordCount()
    }
    
    private func forceBlackText() {
        // Get the courier font
        let courierFont = NSFont(name: "Courier", size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        
        // Force styling on the entire text storage - using RED to make it VERY visible
        if let textStorage = self.textStorage, textStorage.length > 0 {
            let fullRange = NSRange(location: 0, length: textStorage.length)
            
            // Remove any existing background color that might be causing issues
            textStorage.removeAttribute(.backgroundColor, range: fullRange)
            
            // Add only font and foreground color
            textStorage.addAttributes([
                .font: courierFont,
                .foregroundColor: NSColor.red  // Using RED to make absolutely sure it's visible
            ], range: fullRange)
        }
        
        // Ensure typing attributes are correct - RED text
        typingAttributes = [
            .font: courierFont,
            .foregroundColor: NSColor.red  // RED for maximum visibility
            // NO backgroundColor in typing attributes
        ]
        
        // Force text view properties
        textColor = NSColor.red  // RED for maximum visibility
        insertionPointColor = NSColor.red
        backgroundColor = NSColor.yellow  // YELLOW background for contrast
    }
    
    private func updateWordCount() {
        // Update word count
        if let wordLabel = objc_getAssociatedObject(self, &AssociatedKeys.wordLabel) as? NSTextField,
           let document = objc_getAssociatedObject(self, &AssociatedKeys.document) as? Document {
            
            let stats = document.getDocumentStatistics()
            DispatchQueue.main.async {
                wordLabel.stringValue = "Words: \(stats.words) | Characters: \(stats.characters)"
            }
        }
    }
}

// Create a custom text view that handles automatic page breaks
class AutoPageTextView: NSTextView {
    var paperHeight: CGFloat = 0
    var marginSize: CGFloat = 72
    var pageSpacing: CGFloat = 30  // Space between pages
    
    override func insertText(_ string: Any, replacementRange: NSRange) {
        super.insertText(string, replacementRange: replacementRange)
        checkForPageBreak()
    }
    
    override func insertNewline(_ sender: Any?) {
        super.insertNewline(sender)
        checkForPageBreak()
    }
    
    private func checkForPageBreak() {
        guard paperHeight > 0 else { return }
        
        // Calculate how much vertical space we have for text on each page
        let usablePageHeight = paperHeight - (marginSize * 2)  // Remove top and bottom margins
        
        // Use proper font metrics for line height calculation (WYSIWYG standard)
        let font = self.font ?? NSFont.systemFont(ofSize: 11)
        let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        let ascent = CTFontGetAscent(ctFont)
        let descent = CTFontGetDescent(ctFont)
        let leading = CTFontGetLeading(ctFont)
        let lineHeight = (ascent + descent + leading) * 1.15  // Google Docs 1.15x spacing
        
        // Calculate how many lines can fit on a page
        let maxLinesPerPage = Int(usablePageHeight / lineHeight)
        
        // Count current lines of text
        let text = string
        let currentLines = text.components(separatedBy: .newlines).count
        
        // If we exceed the page capacity, add a new page
        if currentLines > maxLinesPerPage {
            createNewPage()
        }
    }
    
    private func createNewPage() {
        // Increase the text container height to accommodate a new page
        let newHeight = paperHeight + pageSpacing + paperHeight
        
        // Update text container size
        textContainer?.size.height = newHeight
        
        // Update the text view frame
        frame.size.height = newHeight
    }
}

class Document: NSDocument {
    
    // MARK: - Properties
    
    /// The main text content of the document
    var textStorage = NSTextStorage()
    
    /// Current font settings - Always Courier for typewriter feel
    var defaultFont: NSFont = NSFont(name: "Courier", size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    
    /// Zoom level for the document (1.0 = 100%, 1.5 = 150%, etc.)
    private var zoomLevel: CGFloat = 1.0
    
    /// Store references for zoom updates
    private var currentWindow: NSWindow?
    private var currentTextView: NSTextView?
    private var currentPaperView: NSView?
    private var currentPaperContainer: NSView?
    private var currentScrollView: NSScrollView?
    
    /// Document metadata
    var wordCount: Int {
        return textStorage.string.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
    
    var characterCount: Int {
        return textStorage.length
    }
    
    // MARK: - Document Lifecycle
    
    override init() {
        super.init()
        setupDocument()
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }
    
    override func makeWindowControllers() {
        // Create a simple window with a text view
        // Create window sized to show the paper nicely
        let windowWidth: CGFloat = 900   // Wide enough to show paper + margins
        let windowHeight: CGFloat = 700  // Tall enough for paper + interface
        
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = displayName.isEmpty ? "Untitled" : displayName
        window.minSize = NSSize(width: 700, height: 500)  // Minimum size to see paper
        
        // Define the workspace gray color (like Word 2007)
        let workspaceGray = NSColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
        
        // Force light appearance (no dark mode)
        window.appearance = NSAppearance(named: .aqua)
        window.backgroundColor = workspaceGray
        
        // Create the main workspace view with light gray background (like Word 2007)
        let mainView = NSView()
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = workspaceGray.cgColor
        
        // Create the paper container view
        let paperContainer = NSView()
        paperContainer.wantsLayer = true
        
        // Create the "paper" view with white background and subtle shadow (like Word 2007)
        let paperView = NSView()
        paperView.wantsLayer = true
        paperView.layer?.backgroundColor = NSColor.white.cgColor
        paperView.layer?.cornerRadius = 0  // Sharp corners like real paper
        
        // Subtle shadow like in Word 2007
        paperView.layer?.shadowColor = NSColor.black.cgColor
        paperView.layer?.shadowOpacity = 0.2
        paperView.layer?.shadowOffset = NSSize(width: 2, height: -2)  // Right and down shadow
        paperView.layer?.shadowRadius = 3
        
        // Very subtle border
        paperView.layer?.borderWidth = 0.5
        paperView.layer?.borderColor = NSColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0).cgColor
        
        let initialWindowSize = NSSize(width: windowWidth, height: windowHeight)
        let paperDimensions = calculateResponsivePaperSize(for: initialWindowSize, zoomLevel: zoomLevel)
        var paperWidth = paperDimensions.width
        var paperHeight = paperDimensions.height
        let marginSize: CGFloat = 72    // 1 inch margins at 72 DPI (true inch measurement)
        
        // Position the text view within the paper with proper margins
        let textView = AutoPageTextView()
        
        // Configure the custom text view with paper dimensions
        textView.paperHeight = paperHeight
        textView.marginSize = marginSize
        
        // WORKING settings - keep these!
        textView.backgroundColor = NSColor.clear  // Transparent so we see the paper
        textView.textColor = NSColor.black
        textView.insertionPointColor = NSColor.black
        
        // Use Arial 11pt to match Google Docs default (gives ~65 chars per line)
        let googleDocsFont = NSFont(name: "Arial", size: 11) ?? NSFont.systemFont(ofSize: 11)
        textView.font = googleDocsFont
        
        // Calculate proper line spacing using real font metrics (WYSIWYG industry standard)
        let lineHeight = calculateLineHeight(font: googleDocsFont, lineSpacing: 1.15)
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Google Docs formatting standards
        paragraphStyle.alignment = .left           // Left-aligned (Google Docs default)
        paragraphStyle.firstLineHeadIndent = 0     // No first line indent
        paragraphStyle.headIndent = 0              // No left indent  
        paragraphStyle.tailIndent = 0              // No right indent
        paragraphStyle.paragraphSpacing = 0        // No paragraph spacing
        paragraphStyle.paragraphSpacingBefore = 0  // No spacing before
        
        // Line spacing (1.15 ratio - Google Docs standard)
        paragraphStyle.lineSpacing = 0             // Use natural spacing
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.lineHeightMultiple = 1.15   // Google Docs 1.15 line spacing
        
        // Tab stops every 0.5" (Google Docs standard)
        var tabStops: [NSTextTab] = []
        for i in 1...20 {  // Add 20 tab stops
            let location = CGFloat(i) * 36  // 0.5" = 36pt
            tabStops.append(NSTextTab(textAlignment: .left, location: location))
        }
        paragraphStyle.tabStops = tabStops
        
        // Set typing attributes with Google Docs standards
        textView.typingAttributes = [
            .font: googleDocsFont,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        // Text settings for typewriter experience
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.allowsUndo = true
        textView.isRichText = false
        
        // Set proper margins (1 inch all around) FIRST
        textView.textContainerInset = NSSize(width: marginSize, height: marginSize)
        
        // Configure text container for RESPONSIVE GOOGLE DOCS WIDTH COMPATIBILITY
        if let textContainer = textView.textContainer {
            // Calculate usable width based on actual paper size (maintains Google Docs proportions)
            let usableWidth = paperWidth - (marginSize * 2)
            
            textContainer.widthTracksTextView = false  // Don't track view width
            textContainer.heightTracksTextView = false
            textContainer.size = NSSize(width: usableWidth, height: paperHeight - (marginSize * 2))
            textContainer.lineFragmentPadding = 0  // Remove extra padding
            
        }
        
        // Ensure text view uses top-left origin (not flipped)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        // Force layout to ensure proper positioning
        textView.textContainer?.lineFragmentPadding = 0
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        
        // Set our document to use the text view's text storage
        if let textViewStorage = textView.textStorage {
            textStorage = textViewStorage
            
            // Apply Google Docs styling to the entire text storage
            let fullRange = NSRange(location: 0, length: textViewStorage.length)
            textViewStorage.addAttributes([
                .font: googleDocsFont,
                .foregroundColor: NSColor.black,
                .paragraphStyle: paragraphStyle
            ], range: fullRange)
        }
        
        // Ensure cursor starts at the beginning and text view gets focus
        textView.selectedRange = NSRange(location: 0, length: 0)  // Cursor at start
        
        // Fix cursor positioning to start at top-left
        DispatchQueue.main.async {
            // Clear any existing text first
            textView.string = ""
            
            // Set cursor at the very beginning
            textView.selectedRange = NSRange(location: 0, length: 0)
            
            // Make text view first responder AFTER setting cursor position
            textView.window?.makeFirstResponder(textView)
            
            // Force scroll to top-left corner of the text view
            let topLeftPoint = NSPoint(x: 0, y: 0)
            textView.scroll(topLeftPoint)
            
            // Ensure the text view is visible and properly positioned
            if let scrollView = textView.enclosingScrollView {
                scrollView.reflectScrolledClipView(scrollView.contentView)
                // Scroll to show the top of the document
                scrollView.contentView.scroll(to: NSPoint(x: 0, y: 0))
            }
        }
        
        // Create scroll view for the paper
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false  // Show scrollers for better UX
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = workspaceGray  // Match workspace color exactly
        scrollView.drawsBackground = true
        
        // Create a container view to center the paper
        let paperContainerView = NSView()
        
        // Make container adapt to scroll view size for perfect centering
        func setupPaperLayout() {
            let scrollViewSize = scrollView.frame.size
            
            // Container should be at least as big as the scroll view for centering
            let containerWidth = max(paperWidth + 100, scrollViewSize.width)
            let containerHeight = max(paperHeight + 100, scrollViewSize.height)
            
            paperContainerView.frame = NSRect(x: 0, y: 0, width: containerWidth, height: containerHeight)
            
            // Center the paper in the container
            let paperX = (containerWidth - paperWidth) / 2
            let paperY = (containerHeight - paperHeight) / 2
            
            paperView.frame = NSRect(x: paperX, y: paperY, width: paperWidth, height: paperHeight)
            textView.frame = NSRect(x: 0, y: 0, width: paperWidth, height: paperHeight)
        }
        
        // Initial setup (will be called again after scroll view is configured)
        let paperX = paperWidth / 2  // Temporary positioning
        let paperY = paperHeight / 2
        
        paperView.frame = NSRect(x: paperX, y: paperY, width: paperWidth, height: paperHeight)
        textView.frame = NSRect(x: 0, y: 0, width: paperWidth, height: paperHeight)
        
        // Build the view hierarchy: container -> paper -> text view
        paperView.addSubview(textView)
        paperContainerView.addSubview(paperView)
        
        // Set up the scroll view with the container as document view
        scrollView.documentView = paperContainerView
        
        // Configure the scroll view's clip view
        let clipView = scrollView.contentView
        clipView.drawsBackground = true
        clipView.backgroundColor = workspaceGray  // Match workspace color exactly
        clipView.automaticallyAdjustsContentInsets = false
        
        // Call proper layout setup after scroll view is configured
        DispatchQueue.main.async {
            setupPaperLayout()
        }
        
        // Create status bar with white background
        let statusBar = NSView()
        statusBar.wantsLayer = true
        statusBar.layer?.backgroundColor = NSColor.white.cgColor
        
        let wordLabel = NSTextField(labelWithString: "Words: 0")
        wordLabel.textColor = NSColor.black
        statusBar.addSubview(wordLabel)
        
        // Set up word count updates using notification instead of custom class
        NotificationCenter.default.addObserver(forName: NSText.didChangeNotification, object: textView, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            let stats = self.getDocumentStatistics()
            wordLabel.stringValue = "Words: \(stats.words) | Characters: \(stats.characters)"
        }
        
        // Initialize word count
        let stats = getDocumentStatistics()
        wordLabel.stringValue = "Words: \(stats.words) | Characters: \(stats.characters)"
        
        // Add scroll view and status bar to main view
        mainView.addSubview(scrollView)
        mainView.addSubview(statusBar)
        
        // Set up Auto Layout for proper resizing
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        statusBar.translatesAutoresizingMaskIntoConstraints = false
        wordLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll view fills most of the window with workspace padding
            scrollView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: statusBar.topAnchor, constant: -10),
            
            // Status bar at bottom
            statusBar.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: mainView.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 30),
            
            // Word label in status bar
            wordLabel.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor, constant: 20),
            wordLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor)
        ])
        
        window.contentView = mainView
        window.center()
        
        // Store references for zoom functionality
        currentWindow = window
        currentTextView = textView
        currentPaperView = paperView
        currentPaperContainer = paperContainerView
        currentScrollView = scrollView
        
        // Add keyboard shortcuts for zoom
        setupZoomKeyboardShortcuts(for: window)
        
        // Add observer to resize paper when window resizes - FULL RESPONSIVENESS
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // Recalculate paper size for new window size
                let newWindowSize = window.frame.size
                let newDimensions = self.calculateResponsivePaperSize(for: newWindowSize)
                paperWidth = newDimensions.width
                paperHeight = newDimensions.height
                
                // Update custom text view properties (textView is already AutoPageTextView)
                textView.paperHeight = paperHeight
                textView.marginSize = marginSize
                
                // Update text container size - MAINTAIN GOOGLE DOCS PROPORTIONAL WIDTH
                if let textContainer = textView.textContainer {
                    let usableWidth = paperWidth - (marginSize * 2)
                    textContainer.size = NSSize(width: usableWidth, height: paperHeight - (marginSize * 2))
                }
                
                // Re-layout everything with new sizes
                setupPaperLayout()
                
                // Force refresh
                scrollView.needsDisplay = true
                paperContainerView.needsDisplay = true
            }
        }
        
        let windowController = NSWindowController(window: window)
        addWindowController(windowController)
    }
    
    // MARK: - Paper Sizing
    
    // MARK: - Font Metrics (WYSIWYG Industry Standards)
    
    // Get precise font metrics using CoreText (like Google Docs/MS Word)
    private func getFontMetrics(font: NSFont) -> (ascent: CGFloat, descent: CGFloat, leading: CGFloat, unitsPerEm: CGFloat) {
        let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        
        let ascent = CTFontGetAscent(ctFont)
        let descent = CTFontGetDescent(ctFont)
        let leading = CTFontGetLeading(ctFont)
        let unitsPerEm = CGFloat(CTFontGetUnitsPerEm(ctFont))
        
        return (ascent, descent, leading, unitsPerEm)
    }
    
    // Calculate exact glyph advance width using CoreText (industry standard)
    private func getGlyphAdvanceWidth(for character: Character, font: NSFont) -> CGFloat {
        let string = String(character)
        let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        
        // Get glyph for character
        var glyph: CGGlyph = 0
        let characters = Array(string.utf16)
        CTFontGetGlyphsForCharacters(ctFont, characters, &glyph, 1)
        
        // Get advance width
        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(ctFont, .default, &glyph, &advance, 1)
        
        return advance.width
    }
    
    // Calculate average character width using real font metrics (for layout estimation)
    private func calculateAverageCharacterWidth(font: NSFont) -> CGFloat {
        // Use a representative sample of English text for average
        let sampleChars: [Character] = ["a", "e", "i", "o", "u", "n", "r", "t", "l", "s", "h", "d", "c", "f", "m", "p", "g", "y", "w", "v", "b", "k", "x", "j", "q", "z", " "]
        
        let totalWidth = sampleChars.reduce(0.0) { sum, char in
            sum + getGlyphAdvanceWidth(for: char, font: font)
        }
        
        return totalWidth / CGFloat(sampleChars.count)
    }
    
    // Calculate proper line height using font metrics (industry standard)
    private func calculateLineHeight(font: NSFont, lineSpacing: CGFloat = 1.15) -> CGFloat {
        let metrics = getFontMetrics(font: font)
        let naturalLineHeight = metrics.ascent + metrics.descent + metrics.leading
        return naturalLineHeight * lineSpacing
    }
    
    // Calculate exact paper width needed for specific character count using real font metrics
    private func calculateFixedPaperWidth(charactersPerLine: Int, font: NSFont, margins: CGFloat) -> CGFloat {
        let avgCharWidth = calculateAverageCharacterWidth(font: font)
        let textWidth = CGFloat(charactersPerLine) * avgCharWidth
        return textWidth + (margins * 2)  // Add left + right margins
    }
    
    // Calculate text container width (without margins) using real font metrics
    private func calculateTextContainerWidth(charactersPerLine: Int, font: NSFont) -> CGFloat {
        let avgCharWidth = calculateAverageCharacterWidth(font: font)
        return CGFloat(charactersPerLine) * avgCharWidth
    }
    
    // MARK: - WYSIWYG Text Measurement (Industry Standard)
    
    // Measure exact width of a text string using CoreText (like Google Docs/MS Word)
    private func measureTextWidth(text: String, font: NSFont) -> CGFloat {
        let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [.font: ctFont]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        let line = CTLineCreateWithAttributedString(attributedString)
        return CTLineGetTypographicBounds(line, nil, nil, nil)
    }
    
    // Calculate how many characters fit in a given width (proper word-wrapping simulation)
    private func calculateCharactersPerLine(width: CGFloat, font: NSFont) -> Int {
        // Test with a representative line of text
        let testText = "The quick brown fox jumps over the lazy dog. This is a test of character width calculation using real font metrics and CoreText for WYSIWYG accuracy like Google Docs and Microsoft Word."
        
        var charactersOnLine = 0
        var currentWidth: CGFloat = 0
        
        for char in testText {
            let charWidth = getGlyphAdvanceWidth(for: char, font: font)
            if currentWidth + charWidth > width {
                break
            }
            currentWidth += charWidth
            charactersOnLine += 1
        }
        
        return charactersOnLine
    }
    
    // Fixed character width sizing - always gives exactly 80 characters per line
    private func calculateResponsivePaperSize(for windowSize: NSSize, zoomLevel: CGFloat = 1.0) -> (width: CGFloat, height: CGFloat) {
        let marginSize: CGFloat = 72  // 1 inch margins
        
        // Calculate exact width needed for the 84-character Google Docs test string
        let font = NSFont(name: "Arial", size: 11) ?? NSFont.systemFont(ofSize: 11)
        let googleDocsTestString = "sadasdasdmasdajsdaushdasdkhashdkahsjdkhaskjdhakjshdkjashdkjahsdkjashdkjhajksdhskajdh"
        let exactStringWidth = measureTextWidth(text: googleDocsTestString, font: font)
        
        // Add a tiny buffer to ensure perfect fit (Google Docs seems to have slightly more space)
        let googleDocsUsableWidth = exactStringWidth + 2.0  // Add 2pt buffer for perfect match
        let logicalPaperWidth = googleDocsUsableWidth + (marginSize * 2)
        
        Swift.print("🎯 PERFECT GOOGLE DOCS MATCH:")
        Swift.print("   Test string: \(googleDocsTestString.count) chars")
        Swift.print("   Exact width needed: \(exactStringWidth)pt")
        Swift.print("   Google Docs width: \(googleDocsUsableWidth)pt")
        Swift.print("   Paper width: \(logicalPaperWidth)pt")
        
        
        // Use standard US Letter height ratio (11/8.5 = 1.294)
        let logicalPaperHeight = logicalPaperWidth * 1.294
        
        // Apply zoom for visual scaling only (character count stays the same)
        let visualPaperWidth = logicalPaperWidth * zoomLevel
        let visualPaperHeight = logicalPaperHeight * zoomLevel
        
        // Never scale down - this compromises character count
        // Instead, always use the logical size needed for 80 characters
        return (visualPaperWidth, visualPaperHeight)
    }
    
    // MARK: - Zoom Functionality
    
    private func setupZoomKeyboardShortcuts(for window: NSWindow) {
        // Create a local event monitor for keyboard shortcuts
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            // Check for Cmd+Plus (zoom in)
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "=" {
                self.zoomIn()
                return nil // Consume the event
            }
            
            // Check for Cmd+Minus (zoom out)
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "-" {
                self.zoomOut()
                return nil // Consume the event
            }
            
            // Check for Cmd+0 (reset zoom)
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "0" {
                self.resetZoom()
                return nil // Consume the event
            }
            
            return event
        }
    }
    
    @objc private func zoomIn() {
        let newZoomLevel = min(zoomLevel * 1.2, 3.0)  // Max 300% zoom
        setZoomLevel(newZoomLevel)
    }
    
    @objc private func zoomOut() {
        let newZoomLevel = max(zoomLevel / 1.2, 0.5)  // Min 50% zoom
        setZoomLevel(newZoomLevel)
    }
    
    @objc private func resetZoom() {
        setZoomLevel(1.0)
    }
    
    private func setZoomLevel(_ newZoomLevel: CGFloat) {
        zoomLevel = newZoomLevel
        updatePaperSizeForCurrentZoom()
    }
    
    private func updatePaperSizeForCurrentZoom() {
        guard let window = currentWindow,
              let textView = currentTextView,
              let paperView = currentPaperView,
              let paperContainer = currentPaperContainer,
              let scrollView = currentScrollView else { return }
        
        // GOOGLE DOCS STANDARDS - Base values that scale proportionally
        let baseFontSize: CGFloat = 11      // Arial 11pt (Google Docs default)
        let baseMarginSize: CGFloat = 72    // 1 inch margins (Google Docs standard)
        let lineSpacingRatio: CGFloat = 1.15 // 1.15 line spacing (Google Docs default)
        
        // Calculate scaled values while maintaining Google Docs proportions
        let scaledFontSize = baseFontSize * zoomLevel
        let scaledMarginSize = baseMarginSize * zoomLevel
        let scaledFont = NSFont(name: "Arial", size: scaledFontSize) ?? NSFont.systemFont(ofSize: scaledFontSize)
        
        // Recalculate paper size with new zoom level
        let windowSize = window.frame.size
        let newDimensions = calculateResponsivePaperSize(for: windowSize, zoomLevel: zoomLevel)
        let newPaperWidth = newDimensions.width
        let newPaperHeight = newDimensions.height
        
        // Update text view properties with scaled values
        if let autoPageTextView = textView as? AutoPageTextView {
            autoPageTextView.paperHeight = newPaperWidth / zoomLevel * 1.294  // Use logical height
            autoPageTextView.marginSize = baseMarginSize  // Keep logical margin size
        }
        
        // Update font and text attributes to match zoom level
        textView.font = scaledFont
        
        // Calculate proper line height maintaining Google Docs 1.15 ratio
        let lineHeight = calculateLineHeight(font: scaledFont, lineSpacing: lineSpacingRatio)
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Google Docs formatting standards
        paragraphStyle.alignment = .left           // Left-aligned (Google Docs default)
        paragraphStyle.firstLineHeadIndent = 0     // No first line indent
        paragraphStyle.headIndent = 0              // No left indent  
        paragraphStyle.tailIndent = 0              // No right indent
        paragraphStyle.paragraphSpacing = 0        // No paragraph spacing
        paragraphStyle.paragraphSpacingBefore = 0  // No spacing before
        
        // Line spacing (maintain 1.15 ratio regardless of zoom)
        paragraphStyle.lineSpacing = 0             // Use natural spacing
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.lineHeightMultiple = lineSpacingRatio  // Key: maintain 1.15 ratio
        
        // Tab stops every 0.5" (Google Docs standard)
        let tabStopWidth = 36 * zoomLevel  // 0.5" = 36pt, scaled with zoom
        var tabStops: [NSTextTab] = []
        for i in 1...20 {  // Add 20 tab stops
            let location = CGFloat(i) * tabStopWidth
            tabStops.append(NSTextTab(textAlignment: .left, location: location))
        }
        paragraphStyle.tabStops = tabStops
        
        // Update typing attributes with Google Docs standards
        textView.typingAttributes = [
            .font: scaledFont,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        // Apply scaled font and formatting to existing text
        if let textStorage = textView.textStorage {
            let range = NSRange(location: 0, length: textStorage.length)
            textStorage.addAttribute(.font, value: scaledFont, range: range)
            textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        }
        
        // Update text container size maintaining Google Docs proportional width
        if let textContainer = textView.textContainer {
            // Calculate usable width based on actual paper size (maintains proportions)
            let usableWidth = newPaperWidth - (scaledMarginSize * 2)
            textContainer.size = NSSize(width: usableWidth, height: newPaperHeight - (scaledMarginSize * 2))
            
        }
        
        // Update text container inset with scaled margins (maintain 1" logical margins)
        textView.textContainerInset = NSSize(width: scaledMarginSize, height: scaledMarginSize)
        
        // Update paper view size
        paperView.frame = NSRect(x: 0, y: 0, width: newPaperWidth, height: newPaperHeight)
        textView.frame = NSRect(x: 0, y: 0, width: newPaperWidth, height: newPaperHeight)
        
        // Update container and layout
        let containerWidth = max(newPaperWidth + 100, scrollView.frame.size.width)
        let containerHeight = max(newPaperHeight + 100, scrollView.frame.size.height)
        
        paperContainer.frame = NSRect(x: 0, y: 0, width: containerWidth, height: containerHeight)
        
        // Center the paper in the container
        let paperX = (containerWidth - newPaperWidth) / 2
        let paperY = (containerHeight - newPaperHeight) / 2
        paperView.frame = NSRect(x: paperX, y: paperY, width: newPaperWidth, height: newPaperHeight)
        
        // Force refresh
        scrollView.needsDisplay = true
        paperContainer.needsDisplay = true
    }
    
    // MARK: - Document Setup
    
    private func setupDocument() {
        // Set up default text attributes - force black text on white background
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: defaultFont,
            .foregroundColor: NSColor.black,
            .backgroundColor: NSColor.white
        ]
        
        // If the document is empty, add default attributes
        if textStorage.length == 0 {
            textStorage.append(NSAttributedString(string: "", attributes: defaultAttributes))
        }
    }
    
    // MARK: - Reading and Writing
    
    override func data(ofType typeName: String) throws -> Data {
        switch typeName {
        case "public.plain-text":
            return textStorage.string.data(using: .utf8) ?? Data()
        case "public.rtf":
            let range = NSRange(location: 0, length: textStorage.length)
            return textStorage.rtf(from: range, documentAttributes: [:]) ?? Data()
        default:
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        switch typeName {
        case "public.plain-text":
            if let string = String(data: data, encoding: .utf8) {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: defaultFont,
                    .foregroundColor: NSColor.textColor
                ]
                textStorage.setAttributedString(NSAttributedString(string: string, attributes: attributes))
            } else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
            }
        case "public.rtf":
            var attributes: NSDictionary?
            if let attributedString = NSAttributedString(rtf: data, documentAttributes: &attributes) {
                textStorage.setAttributedString(attributedString)
            } else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
            }
        default:
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
    }
    
    // MARK: - Document Types
    
    override class func canConcurrentlyReadDocuments(ofType: String) -> Bool {
        return true
    }
    
    override func writableTypes(for saveOperation: NSDocument.SaveOperationType) -> [String] {
        switch saveOperation {
        case .saveOperation, .saveAsOperation, .saveToOperation:
            return ["public.plain-text", "public.rtf"]
        case .autosaveInPlaceOperation, .autosaveElsewhereOperation, .autosaveAsOperation:
            return ["public.plain-text", "public.rtf"]
        @unknown default:
            return ["public.plain-text"]
        }
    }
    
    override class var readableTypes: [String] {
        return ["public.plain-text", "public.rtf"]
    }
    
    override class var writableTypes: [String] {
        return ["public.plain-text", "public.rtf"]
    }
    
    override func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
        switch typeName {
        case "public.plain-text":
            return "txt"
        case "public.rtf":
            return "rtf"
        default:
            return super.fileNameExtension(forType: typeName, saveOperation: saveOperation)
        }
    }
    
    // MARK: - Text Formatting Methods
    
    func applyFont(_ font: NSFont, to range: NSRange? = nil) {
        let targetRange = range ?? NSRange(location: 0, length: textStorage.length)
        textStorage.addAttribute(.font, value: font, range: targetRange)
        updateChangeCount(.changeDone)
    }
    
    func applyBold(to range: NSRange? = nil) {
        let targetRange = range ?? NSRange(location: 0, length: textStorage.length)
        textStorage.enumerateAttribute(.font, in: targetRange) { (value, range, _) in
            if let font = value as? NSFont {
                let boldFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                textStorage.addAttribute(.font, value: boldFont, range: range)
            }
        }
        updateChangeCount(.changeDone)
    }
    
    func applyItalic(to range: NSRange? = nil) {
        let targetRange = range ?? NSRange(location: 0, length: textStorage.length)
        textStorage.enumerateAttribute(.font, in: targetRange) { (value, range, _) in
            if let font = value as? NSFont {
                let italicFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                textStorage.addAttribute(.font, value: italicFont, range: range)
            }
        }
        updateChangeCount(.changeDone)
    }
    
    func applyUnderline(to range: NSRange? = nil) {
        let targetRange = range ?? NSRange(location: 0, length: textStorage.length)
        textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: targetRange)
        updateChangeCount(.changeDone)
    }
    
    func applyTextColor(_ color: NSColor, to range: NSRange? = nil) {
        let targetRange = range ?? NSRange(location: 0, length: textStorage.length)
        textStorage.addAttribute(.foregroundColor, value: color, range: targetRange)
        updateChangeCount(.changeDone)
    }
    
    // MARK: - Text Statistics
    
    func getDocumentStatistics() -> (words: Int, characters: Int, lines: Int) {
        let text = textStorage.string
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let characters = text.count
        let lines = text.components(separatedBy: .newlines).count
        
        return (words: words, characters: characters, lines: lines)
    }
}
