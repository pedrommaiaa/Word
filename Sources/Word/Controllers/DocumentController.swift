import Cocoa
import UniformTypeIdentifiers

class DocumentController: NSDocumentController {
    
    // MARK: - Properties
    
    private var recentDocuments: [URL] = []
    private let maxRecentDocuments = 10
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        loadRecentDocuments()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadRecentDocuments()
    }
    
    // MARK: - Document Management
    
    override func makeUntitledDocument(ofType typeName: String) throws -> NSDocument {
        // Create our custom Document directly
        let document = Document()
        return document
    }
    
    override func makeDocument(withContentsOf url: URL, ofType typeName: String) throws -> NSDocument {
        let document = try super.makeDocument(withContentsOf: url, ofType: typeName)
        addRecentDocument(url)
        return document
    }
    
    // MARK: - Document Types
    
    override var documentClassNames: [String] {
        return ["Word.Document"]
    }
    
    override var defaultType: String? {
        return "public.plain-text"
    }
    
    override func documentClass(forType typeName: String) -> AnyClass? {
        switch typeName {
        case "public.plain-text", "public.rtf":
            return Document.self
        default:
            return Document.self
        }
    }
    
    override func displayName(forType typeName: String) -> String {
        switch typeName {
        case "public.plain-text":
            return "Plain Text"
        case "public.rtf":
            return "Rich Text Format"
        default:
            return "Document"
        }
    }
    
    override func typeForContents(of url: URL) throws -> String {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "txt":
            return "public.plain-text"
        case "rtf":
            return "public.rtf"
        default:
            // Try to determine type by content
            if let data = try? Data(contentsOf: url) {
                // Check if it's RTF
                if data.starts(with: "{\\rtf".data(using: .ascii) ?? Data()) {
                    return "public.rtf"
                }
            }
            // Default to plain text
            return "public.plain-text"
        }
    }
    
    // MARK: - New Document
    
    @IBAction override func newDocument(_ sender: Any?) {
        do {
            let document = try makeUntitledDocument(ofType: defaultType ?? "public.plain-text")
            addDocument(document)
            document.makeWindowControllers()
            document.showWindows()
        } catch {
            _ = presentError(error)
        }
    }
    
    // MARK: - Open Document
    
    @IBAction override func openDocument(_ sender: Any?) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [
            UTType.plainText,
            UTType.rtf
        ]
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        
        openPanel.begin { response in
            if response == .OK {
                for url in openPanel.urls {
                    self.openDocument(withContentsOf: url, display: true) { document, documentWasAlreadyOpen, error in
                        if let error = error {
                            _ = self.presentError(error)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Documents
    
    private func loadRecentDocuments() {
        if let data = UserDefaults.standard.data(forKey: "RecentDocuments") {
            do {
                if let urls = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSURL.self], from: data) as? [URL] {
                    recentDocuments = urls
                }
            } catch {
                // Failed to load recent documents, start with empty list
                recentDocuments = []
            }
        }
    }
    
    private func saveRecentDocuments() {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: recentDocuments, requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: "RecentDocuments")
        }
    }
    
    private func addRecentDocument(_ url: URL) {
        // Remove if already exists
        recentDocuments.removeAll { $0 == url }
        
        // Add to beginning
        recentDocuments.insert(url, at: 0)
        
        // Limit to max count
        if recentDocuments.count > maxRecentDocuments {
            recentDocuments = Array(recentDocuments.prefix(maxRecentDocuments))
        }
        
        saveRecentDocuments()
        updateRecentDocumentsMenu()
    }
    
    func getRecentDocuments() -> [URL] {
        return recentDocuments.filter { url in
            // Only return documents that still exist
            FileManager.default.fileExists(atPath: url.path)
        }
    }
    
    private func updateRecentDocumentsMenu() {
        // This would update the "Open Recent" menu if we implement it
        // TODO: Implement recent documents menu
    }
    
    // MARK: - Document Window Management
    
    override func addDocument(_ document: NSDocument) {
        super.addDocument(document)
        
        // Configure the document
        if document is Document {
            // Set up any additional document configuration here
        }
    }
    
    // MARK: - Error Handling
    
    override func presentError(_ error: Error) -> Bool {
        let alert = NSAlert(error: error)
        alert.alertStyle = .warning
        
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window) { _ in }
        } else {
            alert.runModal()
        }
        
        return true
    }
    
    // MARK: - File Operations Helper
    
    func createNewDocumentWindow() {
        newDocument(nil)
    }
    
    func openDocumentFromURL(_ url: URL) {
        openDocument(withContentsOf: url, display: true) { document, documentWasAlreadyOpen, error in
            if let error = error {
                _ = self.presentError(error)
            }
        }
    }
    
}
