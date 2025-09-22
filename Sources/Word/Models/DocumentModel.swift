import Cocoa
import UniformTypeIdentifiers

/// Core document model - handles only data and persistence
class DocumentModel: NSDocument {
    
    // MARK: - Properties
    
    /// The main text content of the document
    var textStorage = NSTextStorage()
    
    /// Current font settings
    var defaultFont: NSFont = NSFont(name: "Arial", size: 11) ?? NSFont.systemFont(ofSize: 11)
    
    // MARK: - Document Lifecycle
    
    override init() {
        super.init()
        setupDocument()
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }
    
    override func makeWindowControllers() {
        // Get minimum window size from document layout standards
        let minSize = DocumentLayout.getMinimumWindowSize()
        
        // Create a document window with professional dimensions
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1000, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = displayName.isEmpty ? "Untitled" : displayName
        window.minSize = minSize  // Enforce minimum size for proper document display
        
        // Apply modern glassmorphism window styling
        GlassmorphismDesign.styleWindow(window)
        
        // Create document view controller
        let documentViewController = DocumentViewController()
        documentViewController.document = self
        window.contentViewController = documentViewController
        
        window.center()
        
        let windowController = NSWindowController(window: window)
        addWindowController(windowController)
    }
    
    // MARK: - Document Setup
    
    private func setupDocument() {
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: defaultFont,
            .foregroundColor: NSColor.black
        ]
        
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
                    .foregroundColor: NSColor.black
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
        return ["public.plain-text", "public.rtf"]
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
    
    // MARK: - Text Statistics
    
    func getDocumentStatistics() -> (words: Int, characters: Int, lines: Int) {
        let text = textStorage.string
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let characters = text.count
        let lines = max(1, text.components(separatedBy: .newlines).count)
        
        return (words: words, characters: characters, lines: lines)
    }
}
