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
        static let fontSize: CGFloat = 11
        static let fontName = "Arial"
        
        // Window sizing
        static let minWindowWidth: CGFloat = 700
        static let minWindowHeight: CGFloat = 500
        static let defaultWindowWidth: CGFloat = 900
        static let defaultWindowHeight: CGFloat = 700
        
        // Layout
        static let marginSize: CGFloat = 72  // 1 inch margins
        static let statusBarHeight: CGFloat = 30
    }
    
    // MARK: - User Defaults Keys
    
    struct UserDefaultsKeys {
        static let recentDocuments = "RecentDocuments"
    }
    
    // MARK: - Zoom Levels
    
    struct Zoom {
        static let minimum: CGFloat = 0.5
        static let maximum: CGFloat = 3.0
        static let step: CGFloat = 1.2
        static let normal: CGFloat = 1.0
    }
}