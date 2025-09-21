import Cocoa

class DocumentTextView: NSTextView {
    
    // MARK: - Properties
    
    weak var documentViewController: DocumentViewController?
    
    // MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTextView()
    }
    
    // MARK: - Setup
    
    private func setupTextView() {
        // Configure text view behavior
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isContinuousSpellCheckingEnabled = true
        isGrammarCheckingEnabled = true
        allowsUndo = true
        isRichText = true
        importsGraphics = false
        
        // Set up text container
        textContainer?.widthTracksTextView = true
        textContainer?.heightTracksTextView = false
        
        // Set up default typing attributes
        let defaultFont = NSFont.systemFont(ofSize: 12)
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: defaultFont,
            .foregroundColor: NSColor.textColor
        ]
        typingAttributes = defaultAttributes
        
        // Set up margins
        textContainerInset = NSSize(width: 20, height: 20)
        
        // Enable drag and drop
        registerForDraggedTypes([.fileURL, .string])
    }
    
    // MARK: - Text Changes
    
    override func didChangeText() {
        super.didChangeText()
        
        // Notify document of changes
        document?.updateChangeCount(.changeDone)
        
        // Update status bar
        documentViewController?.updateStatusBar()
    }
    
    // MARK: - Key Events
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        
        // Handle custom key events here if needed
        switch event.keyCode {
        default:
            break
        }
    }
    
    // MARK: - Menu Validation
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let action = menuItem.action else { return false }
        
        switch action {
        case #selector(cut(_:)), #selector(copy(_:)):
            return selectedRange().length > 0
        case #selector(paste(_:)):
            return NSPasteboard.general.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.string.rawValue])
        case #selector(selectAll(_:)):
            return string.count > 0
        default:
            return super.validateMenuItem(menuItem)
        }
    }
    
    // MARK: - Drag and Drop
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard
        
        if pasteboard.types?.contains(.fileURL) == true {
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
                let textFileExtensions = ["txt", "rtf"]
                for url in urls {
                    if textFileExtensions.contains(url.pathExtension.lowercased()) {
                        return .copy
                    }
                }
            }
        }
        
        if pasteboard.types?.contains(.string) == true {
            return .copy
        }
        
        return []
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls {
                DocumentController.shared.openDocumentFromURL(url)
            }
            return true
        }
        
        if let string = pasteboard.string(forType: .string) {
            insertText(string, replacementRange: selectedRange())
            return true
        }
        
        return false
    }
    
    // MARK: - Find and Replace Support
    
    override func performTextFinderAction(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            switch menuItem.tag {
            case NSTextFinder.Action.showFindInterface.rawValue:
                if let scrollView = enclosingScrollView {
                    scrollView.findBarContainer?.findBarView?.isHidden = false
                }
            default:
                super.performTextFinderAction(sender)
            }
        } else {
            super.performTextFinderAction(sender)
        }
    }
}

// MARK: - DocumentViewController

class DocumentViewController: NSViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var textView: DocumentTextView!
    @IBOutlet weak var statusBar: NSView!
    @IBOutlet weak var wordCountLabel: NSTextField!
    @IBOutlet weak var characterCountLabel: NSTextField!
    @IBOutlet weak var cursorPositionLabel: NSTextField!
    
    // MARK: - Properties
    
    var document: Document? {
        didSet {
            setupDocument()
        }
    }
    
    private var zoomLevel: CGFloat = 1.0
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTextView()
        setupStatusBar()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateStatusBar()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Configure the scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        // Set up find bar
        scrollView.findBarContainer = NSTextFinder.FindBarContainer()
    }
    
    private func setupTextView() {
        textView.documentViewController = self
        
        // Set up text view in scroll view if not already done
        if textView.enclosingScrollView != scrollView {
            scrollView.documentView = textView
        }
    }
    
    private func setupDocument() {
        guard let document = document else { return }
        
        // Connect text storage
        textView.textStorage?.setAttributedString(NSAttributedString())
        textView.layoutManager?.replaceTextStorage(document.textStorage)
        
        updateStatusBar()
    }
    
    private func setupStatusBar() {
        // Configure status bar appearance
        statusBar.wantsLayer = true
        statusBar.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Initial status
        updateStatusBar()
    }
    
    // MARK: - Status Bar Updates
    
    func updateStatusBar() {
        guard let document = document else { return }
        
        let stats = document.getDocumentStatistics()
        
        DispatchQueue.main.async {
            self.wordCountLabel.stringValue = "Words: \(stats.words)"
            self.characterCountLabel.stringValue = "Characters: \(stats.characters)"
            
            // Update cursor position
            let selectedRange = self.textView.selectedRange()
            let lineNumber = self.lineNumber(for: selectedRange.location)
            let columnNumber = self.columnNumber(for: selectedRange.location)
            self.cursorPositionLabel.stringValue = "Line: \(lineNumber), Column: \(columnNumber)"
        }
    }
    
    private func lineNumber(for location: Int) -> Int {
        let text = textView.string
        let index = text.index(text.startIndex, offsetBy: min(location, text.count))
        let substring = text[..<index]
        return substring.components(separatedBy: .newlines).count
    }
    
    private func columnNumber(for location: Int) -> Int {
        let text = textView.string
        guard location <= text.count else { return 1 }
        
        let index = text.index(text.startIndex, offsetBy: location)
        let substring = text[..<index]
        
        if let lastNewlineRange = substring.range(of: "\n", options: .backwards) {
            let lineStart = text.index(after: lastNewlineRange.lowerBound)
            return text.distance(from: lineStart, to: index) + 1
        } else {
            return location + 1
        }
    }
    
    // MARK: - Zoom Functionality
    
    func zoomIn() {
        zoomLevel = min(zoomLevel * 1.2, 3.0)
        applyZoom()
    }
    
    func zoomOut() {
        zoomLevel = max(zoomLevel / 1.2, 0.5)
        applyZoom()
    }
    
    func zoomActualSize() {
        zoomLevel = 1.0
        applyZoom()
    }
    
    private func applyZoom() {
        let currentFont = textView.font ?? NSFont.systemFont(ofSize: 12)
        let newSize = currentFont.pointSize * zoomLevel
        let newFont = NSFont(name: currentFont.fontName, size: newSize) ?? NSFont.systemFont(ofSize: newSize)
        
        // Apply to selection or entire document
        let selectedRange = textView.selectedRange()
        if selectedRange.length > 0 {
            textView.textStorage?.addAttribute(.font, value: newFont, range: selectedRange)
        } else {
            textView.font = newFont
        }
    }
    
    // MARK: - Text Formatting Actions
    
    @IBAction func toggleBold(_ sender: Any?) {
        NSFontManager.shared.addFontTrait(sender)
    }
    
    @IBAction func toggleItalic(_ sender: Any?) {
        NSFontManager.shared.addFontTrait(sender)
    }
    
    @IBAction func toggleUnderline(_ sender: Any?) {
        textView.underline(sender)
    }
    
    @IBAction func showFontPanel(_ sender: Any?) {
        NSFontManager.shared.orderFrontFontPanel(sender)
    }
    
    @IBAction func showColorPanel(_ sender: Any?) {
        NSColorPanel.shared.orderFront(sender)
    }
}
