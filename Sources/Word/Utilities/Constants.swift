import Foundation
import Cocoa

struct Constants {
    
    // MARK: - Application
    
    struct App {
        static let name = "Word"
        static let version = "1.0"
        static let identifier = "com.wordclone.app"
    }
    
    // MARK: - Document Types
    
    struct DocumentTypes {
        static let plainText = "public.plain-text"
        static let richText = "public.rtf"
    }
    
    // MARK: - File Extensions
    
    struct FileExtensions {
        static let txt = "txt"
        static let rtf = "rtf"
    }
    
    // MARK: - Default Values
    
    struct Defaults {
        static let fontSize: CGFloat = 12
        static let fontName = "Helvetica"
        static let textColor = NSColor.textColor
        static let backgroundColor = NSColor.textBackgroundColor
        
        // Text container insets
        static let textInsetWidth: CGFloat = 20
        static let textInsetHeight: CGFloat = 20
        
        // Window sizing
        static let minWindowWidth: CGFloat = 600
        static let minWindowHeight: CGFloat = 400
        static let defaultWindowWidth: CGFloat = 800
        static let defaultWindowHeight: CGFloat = 600
        
        // Status bar
        static let statusBarHeight: CGFloat = 30
    }
    
    // MARK: - User Defaults Keys
    
    struct UserDefaultsKeys {
        static let recentDocuments = "RecentDocuments"
        static let defaultFont = "DefaultFont"
        static let defaultFontSize = "DefaultFontSize"
        static let autoSave = "AutoSave"
        static let spellCheck = "SpellCheck"
        static let grammarCheck = "GrammarCheck"
    }
    
    // MARK: - Notification Names
    
    struct NotificationNames {
        static let documentDidChange = Notification.Name("DocumentDidChange")
        static let fontDidChange = Notification.Name("FontDidChange")
        static let zoomDidChange = Notification.Name("ZoomDidChange")
    }
    
    // MARK: - Zoom Levels
    
    struct Zoom {
        static let minimum: CGFloat = 0.5
        static let maximum: CGFloat = 3.0
        static let step: CGFloat = 1.2
        static let normal: CGFloat = 1.0
    }
    
    // MARK: - Colors
    
    struct Colors {
        static let toolbarBackground = NSColor.controlBackgroundColor
        static let statusBarBackground = NSColor.controlBackgroundColor
        static let separatorColor = NSColor.separatorColor
    }
}

// MARK: - Storyboard Identifiers

extension NSStoryboard.SceneIdentifier {
    static let documentWindowController = NSStoryboard.SceneIdentifier("DocumentWindowController")
    static let documentViewController = NSStoryboard.SceneIdentifier("DocumentViewController")
}

// MARK: - Menu Item Tags

extension NSMenuItem {
    struct Tag {
        static let boldMenuItem = 1001
        static let italicMenuItem = 1002
        static let underlineMenuItem = 1003
        static let fontSizeIncrease = 1004
        static let fontSizeDecrease = 1005
    }
}
