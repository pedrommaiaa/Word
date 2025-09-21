import Cocoa
import UniformTypeIdentifiers

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

class Document: NSDocument {
    
    // MARK: - Properties
    
    /// The main text content of the document
    var textStorage = NSTextStorage()
    
    /// Current font settings - Always Courier for typewriter feel
    var defaultFont: NSFont = NSFont(name: "Courier", size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    
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
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = displayName.isEmpty ? "Untitled" : displayName
        window.minSize = NSSize(width: 600, height: 400)
        
        // Force light appearance (no dark mode)
        window.appearance = NSAppearance(named: .aqua)
        window.backgroundColor = NSColor.white
        
        // Create the main view with white background
        let mainView = NSView()
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = NSColor.white.cgColor
        mainView.layer?.zPosition = 0  // Keep main view in back
        
        // Create text view using the EXACT method that worked
        let textView = NSTextView(frame: NSRect(x: 0, y: 30, width: 800, height: 570))
        
        // WORKING settings - don't change these!
        textView.backgroundColor = NSColor.white
        textView.textColor = NSColor.black
        textView.insertionPointColor = NSColor.black
        
        // Use Courier font as requested
        let courierFont = NSFont(name: "Courier", size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.font = courierFont
        
        // Set typing attributes
        textView.typingAttributes = [
            .font: courierFont,
            .foregroundColor: NSColor.black
        ]
        
        // Basic text settings
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.allowsUndo = true
        textView.isRichText = false
        textView.textContainerInset = NSSize(width: 20, height: 20)
        
        // Set our document to use the text view's text storage
        if let textViewStorage = textView.textStorage {
            textStorage = textViewStorage
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
        
        // Add views directly - use the method that WORKED
        mainView.addSubview(textView)
        mainView.addSubview(statusBar)
        
        // Fixed positioning - this is what worked!
        statusBar.frame = NSRect(x: 0, y: 0, width: 800, height: 30)
        wordLabel.frame = NSRect(x: 20, y: 5, width: 300, height: 20)
        
        window.contentView = mainView
        window.center()
        
        let windowController = NSWindowController(window: window)
        addWindowController(windowController)
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
