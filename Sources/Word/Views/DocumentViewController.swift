import Cocoa

class DocumentViewController: NSViewController {
    
    // MARK: - UI Components
    
    private var scrollView: NSScrollView!
    private var paperContainer: NSView!
    private var paperView: NSView!
    private var textView: NSTextView!
    private var statusBar: NSView!
    private var statusLabel: NSTextField!
    
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
        view = DocumentLayout.createWorkspaceView()
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
        textView.window?.makeFirstResponder(textView)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        createScrollView()
        createPaperViews()
        createTextView()
        createStatusBar()
        setupConstraints()
        layoutPaper()
    }
    
    private func createScrollView() {
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = NSColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
        scrollView.drawsBackground = true
        
        view.addSubview(scrollView)
    }
    
    private func createPaperViews() {
        // Container for centering the paper
        paperContainer = NSView()
        
        // The paper view
        let paperSize = DocumentLayout.calculatePaperSize(for: view.frame.size, zoomLevel: zoomLevel)
        paperView = DocumentLayout.createPaperView(size: paperSize)
        
        paperContainer.addSubview(paperView)
        scrollView.documentView = paperContainer
    }
    
    private func createTextView() {
        textView = NSTextView()
        let paperSize = DocumentLayout.calculatePaperSize(for: view.frame.size, zoomLevel: zoomLevel)
        DocumentLayout.setupTextView(textView, paperSize: paperSize, zoomLevel: zoomLevel)
        
        paperView.addSubview(textView)
        textView.frame = NSRect(x: 0, y: 0, width: paperSize.width, height: paperSize.height)
    }
    
    private func createStatusBar() {
        statusBar = NSView()
        statusBar.wantsLayer = true
        statusBar.layer?.backgroundColor = NSColor.white.cgColor
        
        statusLabel = NSTextField(labelWithString: "Words: 0 | Characters: 0")
        statusLabel.textColor = NSColor.black
        statusBar.addSubview(statusLabel)
        
        view.addSubview(statusBar)
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        statusBar.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll view fills most of the view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: statusBar.topAnchor, constant: -10),
            
            // Status bar at bottom
            statusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 30),
            
            // Status label
            statusLabel.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor, constant: 20),
            statusLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor)
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSText.didChangeNotification,
            object: textView,
            queue: .main
        ) { [weak self] _ in
            self?.textDidChange()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: view.window,
            queue: .main
        ) { [weak self] _ in
            self?.windowDidResize()
        }
    }
    
    private func setupDocument() {
        guard let document = document else { return }
        
        // Connect the text storage
        if textView?.textStorage != nil {
            textView.layoutManager?.replaceTextStorage(document.textStorage)
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
        
        // Update text view size and setup with proper zoom
        textView.frame = NSRect(x: 0, y: 0, width: paperSize.width, height: paperSize.height)
        DocumentLayout.setupTextView(textView, paperSize: paperSize, zoomLevel: zoomLevel)
        
        // Apply formatting to existing text
        if let textStorage = textView.textStorage, textStorage.length > 0 {
            let range = NSRange(location: 0, length: textStorage.length)
            let baseFontSize: CGFloat = 11
            let scaledFontSize = baseFontSize * zoomLevel
            let font = NSFont(name: "Arial", size: scaledFontSize) ?? NSFont.systemFont(ofSize: scaledFontSize)
            
            textStorage.addAttribute(.font, value: font, range: range)
        }
    }
    
    // MARK: - Event Handlers
    
    private func textDidChange() {
        document?.updateChangeCount(.changeDone)
        updateStatusBar()
    }
    
    private func windowDidResize() {
        DispatchQueue.main.async { [weak self] in
            self?.layoutPaper()
        }
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
    
    func zoomIn() {
        zoomLevel = min(zoomLevel * 1.2, 3.0)
        DispatchQueue.main.async { [weak self] in
            self?.layoutPaper()
        }
    }
    
    func zoomOut() {
        zoomLevel = max(zoomLevel / 1.2, 0.5)
        DispatchQueue.main.async { [weak self] in
            self?.layoutPaper()
        }
    }
    
    func zoomActualSize() {
        zoomLevel = 1.0
        DispatchQueue.main.async { [weak self] in
            self?.layoutPaper()
        }
    }
}
