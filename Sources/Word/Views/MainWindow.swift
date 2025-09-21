import Cocoa

class MainWindowController: NSWindowController {
    
    // MARK: - Properties
    
    var documentViewController: DocumentViewController!
    
    override var document: AnyObject? {
        didSet {
            updateWindowTitle()
            documentViewController?.document = document as? Document
        }
    }
    
    // MARK: - Initialization
    
    override init(window: NSWindow?) {
        super.init(window: window)
        setupWindow()
    }
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        self.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWindow()
    }
    
    // MARK: - Window Lifecycle
    
    override func windowDidLoad() {
        super.windowDidLoad()
        setupToolbar()
    }
    
    // MARK: - Setup
    
    private func setupWindow() {
        guard let window = window else { return }
        
        // Configure window appearance
        window.title = "Untitled"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        
        // Set minimum size
        window.minSize = NSSize(width: 600, height: 400)
        
        // Center window
        window.center()
        
        // Create and set up the document view controller
        documentViewController = DocumentViewController()
        window.contentViewController = documentViewController
        
        // Set up document title binding
        setupTitleBinding()
    }
    
    private func setupTitleBinding() {
        // This will be called when document changes
    }
    
    private func setupToolbar() {
        guard let window = window else { return }
        
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconOnly
        toolbar.sizeMode = .regular
        
        window.toolbar = toolbar
    }
    
    
    private func updateWindowTitle() {
        guard let window = window else { return }
        
        if let document = self.document as? Document {
            if let fileURL = document.fileURL {
                window.title = fileURL.lastPathComponent
                window.representedURL = fileURL
            } else {
                window.title = "Untitled"
                window.representedURL = nil
            }
            
            // Show document modified indicator
            window.isDocumentEdited = document.isDocumentEdited
        } else {
            window.title = "WordClone"
            window.representedURL = nil
            window.isDocumentEdited = false
        }
    }
}

// MARK: - NSToolbarDelegate

extension MainWindowController: NSToolbarDelegate {
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier {
        case .bold:
            return createBoldToolbarItem()
        case .italic:
            return createItalicToolbarItem()
        case .underline:
            return createUnderlineToolbarItem()
        case .fontPanel:
            return createFontPanelToolbarItem()
        case .colorPanel:
            return createColorPanelToolbarItem()
        case .flexibleSpace:
            return NSToolbarItem(itemIdentifier: .flexibleSpace)
        default:
            return nil
        }
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .bold,
            .italic,
            .underline,
            .flexibleSpace,
            .fontPanel,
            .colorPanel
        ]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .bold,
            .italic,
            .underline,
            .fontPanel,
            .colorPanel,
            .flexibleSpace,
            .space
        ]
    }
    
    // MARK: - Toolbar Item Creation
    
    private func createBoldToolbarItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .bold)
        item.label = "Bold"
        item.paletteLabel = "Bold"
        item.toolTip = "Make text bold"
        
        let button = NSButton()
        button.title = "B"
        button.font = NSFont.boldSystemFont(ofSize: 14)
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(toggleBold)
        
        item.view = button
        return item
    }
    
    private func createItalicToolbarItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .italic)
        item.label = "Italic"
        item.paletteLabel = "Italic"
        item.toolTip = "Make text italic"
        
        let button = NSButton()
        button.title = "I"
        button.font = NSFont.systemFont(ofSize: 14).italic()
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(toggleItalic)
        
        item.view = button
        return item
    }
    
    private func createUnderlineToolbarItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .underline)
        item.label = "Underline"
        item.paletteLabel = "Underline"
        item.toolTip = "Underline text"
        
        let button = NSButton()
        button.title = "U"
        button.font = NSFont.systemFont(ofSize: 14)
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(toggleUnderline)
        
        item.view = button
        return item
    }
    
    private func createFontPanelToolbarItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .fontPanel)
        item.label = "Font"
        item.paletteLabel = "Font"
        item.toolTip = "Change font"
        
        let button = NSButton()
        button.title = "Font"
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(showFontPanel)
        
        item.view = button
        return item
    }
    
    private func createColorPanelToolbarItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .colorPanel)
        item.label = "Color"
        item.paletteLabel = "Text Color"
        item.toolTip = "Change text color"
        
        let button = NSButton()
        button.title = "Color"
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(showColorPanel)
        
        item.view = button
        return item
    }
    
    // MARK: - Toolbar Actions
    
    @objc private func toggleBold() {
        if let documentViewController = contentViewController as? DocumentViewController {
            documentViewController.toggleBold(self)
        }
    }
    
    @objc private func toggleItalic() {
        if let documentViewController = contentViewController as? DocumentViewController {
            documentViewController.toggleItalic(self)
        }
    }
    
    @objc private func toggleUnderline() {
        if let documentViewController = contentViewController as? DocumentViewController {
            documentViewController.toggleUnderline(self)
        }
    }
    
    @objc private func showFontPanel() {
        if let documentViewController = contentViewController as? DocumentViewController {
            documentViewController.showFontPanel(self)
        }
    }
    
    @objc private func showColorPanel() {
        if let documentViewController = contentViewController as? DocumentViewController {
            documentViewController.showColorPanel(self)
        }
    }
}

// MARK: - NSToolbarItem.Identifier Extension

extension NSToolbarItem.Identifier {
    static let bold = NSToolbarItem.Identifier("Bold")
    static let italic = NSToolbarItem.Identifier("Italic")
    static let underline = NSToolbarItem.Identifier("Underline")
    static let fontPanel = NSToolbarItem.Identifier("FontPanel")
    static let colorPanel = NSToolbarItem.Identifier("ColorPanel")
}

// MARK: - NSFont Extension

extension NSFont {
    func italic() -> NSFont {
        let italicDescriptor = fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: italicDescriptor, size: pointSize) ?? self
    }
}
