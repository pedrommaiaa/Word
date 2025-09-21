import Cocoa
import UniformTypeIdentifiers

class Document: NSDocument {
    
    // MARK: - Properties
    
    /// The main text content of the document
    var textStorage = NSTextStorage()
    
    /// Current font settings
    var defaultFont: NSFont = NSFont.systemFont(ofSize: 12)
    
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
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        if let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("DocumentWindowController")) as? NSWindowController {
            addWindowController(windowController)
            
            // Set up the document view controller
            if let documentViewController = windowController.contentViewController as? DocumentViewController {
                documentViewController.document = self
                documentViewController.representedObject = self
            }
        }
    }
    
    // MARK: - Document Setup
    
    private func setupDocument() {
        // Set up default text attributes
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: defaultFont,
            .foregroundColor: NSColor.textColor
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
            return try textStorage.rtf(from: range, documentAttributes: [:])
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
