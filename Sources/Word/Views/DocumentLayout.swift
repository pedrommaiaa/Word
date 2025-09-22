import Cocoa
import CoreText

/// Handles document layout calculations and paper sizing with Google Docs precision
class DocumentLayout {
    
    // MARK: - Constants
    
    private static let marginSize: CGFloat = 72           // 1" margins
    private static let workspaceGray = NSColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
    
    // Professional document standards
    private static let standardPaperWidthPoints: CGFloat = 612    // 8.5" × 72 pts/inch = 612 pts
    private static let standardPaperHeightPoints: CGFloat = 792   // 11" × 72 pts/inch = 792 pts
    private static let usableTextWidth: CGFloat = 468             // 612 - (72 × 2) = 468 pts (6.5")
    
    // Typography standards for optimal readability
    private static let optimalCharactersPerLine = 65    // Sweet spot between 45-75 chars
    private static let minimumWindowWidth: CGFloat = 800  // Minimum to show paper + controls
    private static let minimumWindowHeight: CGFloat = 600
    
    // MARK: - Font Metrics (WYSIWYG Industry Standards)
    
    // Get precise font metrics using CoreText (like Google Docs/MS Word)
    private static func getFontMetrics(font: NSFont) -> (ascent: CGFloat, descent: CGFloat, leading: CGFloat, unitsPerEm: CGFloat) {
        let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        
        let ascent = CTFontGetAscent(ctFont)
        let descent = CTFontGetDescent(ctFont)
        let leading = CTFontGetLeading(ctFont)
        let unitsPerEm = CGFloat(CTFontGetUnitsPerEm(ctFont))
        
        return (ascent, descent, leading, unitsPerEm)
    }
    
    // Calculate exact glyph advance width using CoreText (industry standard)
    private static func getGlyphAdvanceWidth(for character: Character, font: NSFont) -> CGFloat {
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
    
    // Measure exact width of a text string using CoreText (like Google Docs/MS Word)
    private static func measureTextWidth(text: String, font: NSFont) -> CGFloat {
        let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [.font: ctFont]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        let line = CTLineCreateWithAttributedString(attributedString)
        return CTLineGetTypographicBounds(line, nil, nil, nil)
    }
    
    // Calculate proper line height using font metrics (industry standard)
    static func calculateLineHeight(font: NSFont, lineSpacing: CGFloat = 1.15) -> CGFloat {
        let metrics = getFontMetrics(font: font)
        let naturalLineHeight = metrics.ascent + metrics.descent + metrics.leading
        return naturalLineHeight * lineSpacing
    }
    
    // MARK: - Professional Document Layout Standards
    
    static func calculatePaperSize(for windowSize: NSSize, zoomLevel: CGFloat = 1.0) -> NSSize {
        // FIXED paper dimensions - independent of window size (like professional word processors)
        // Standard US Letter: 8.5" × 11" = 612pt × 792pt
        let logicalPaperWidth = standardPaperWidthPoints
        let logicalPaperHeight = standardPaperHeightPoints
        
        // Apply zoom for visual scaling only - line length stays EXACTLY the same
        let visualPaperWidth = logicalPaperWidth * zoomLevel
        let visualPaperHeight = logicalPaperHeight * zoomLevel
        
        return NSSize(width: visualPaperWidth, height: visualPaperHeight)
    }
    
    // Verify line length meets typography standards
    static func validateLineLength(font: NSFont) -> Bool {
        // Test with optimal character count (65 characters)
        let testString = String(repeating: "M", count: optimalCharactersPerLine) // 'M' is widest char
        let actualWidth = measureTextWidth(text: testString, font: font)
        
        // Should fit within usable text width (6.5" = 468pt)
        return actualWidth <= usableTextWidth
    }
    
    // Get minimum window size needed to properly display the document
    static func getMinimumWindowSize() -> NSSize {
        return NSSize(width: minimumWindowWidth, height: minimumWindowHeight)
    }
    
    static func createPaperView(size: NSSize) -> NSView {
        let paperView = NSView()
        paperView.wantsLayer = true
        paperView.layer?.backgroundColor = NSColor.white.cgColor
        paperView.layer?.shadowColor = NSColor.black.cgColor
        paperView.layer?.shadowOpacity = 0.2
        paperView.layer?.shadowOffset = NSSize(width: 2, height: -2)
        paperView.layer?.shadowRadius = 3
        paperView.layer?.borderWidth = 0.5
        paperView.layer?.borderColor = NSColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0).cgColor
        
        return paperView
    }
    
    static func createWorkspaceView() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = workspaceGray.cgColor
        return view
    }
    
    static func setupTextView(_ textView: NSTextView, paperSize: NSSize, zoomLevel: CGFloat = 1.0) {
        // Configure text view for document editing
        textView.backgroundColor = NSColor.clear
        textView.textColor = NSColor.black
        textView.insertionPointColor = NSColor.black
        
        // Use Google Docs standard font with zoom scaling
        let baseFontSize: CGFloat = 11
        let scaledFontSize = baseFontSize * zoomLevel
        let font = NSFont(name: "Arial", size: scaledFontSize) ?? NSFont.systemFont(ofSize: scaledFontSize)
        textView.font = font
        
        // Set up margins with zoom scaling
        let scaledMarginSize = marginSize * zoomLevel
        textView.textContainerInset = NSSize(width: scaledMarginSize, height: scaledMarginSize)
        
        // Configure text container with FIXED width (professional standard)
        if let textContainer = textView.textContainer {
            // CRITICAL: Use fixed usable width, NOT paper size dependent
            // This ensures consistent line length regardless of zoom or window size
            let fixedUsableWidth = usableTextWidth * zoomLevel  // 468pt scaled by zoom only
            let usableHeight = paperSize.height - (scaledMarginSize * 2)
            
            textContainer.size = NSSize(width: fixedUsableWidth, height: usableHeight)
            textContainer.widthTracksTextView = false
            textContainer.heightTracksTextView = false
            textContainer.lineFragmentPadding = 0
        }
        
        // Configure text behavior for clean editing
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = true
        textView.allowsUndo = true
        textView.isRichText = false  // Keep it simple like the original
        
        // Modern text styling
        textView.selectedTextAttributes = [
            .backgroundColor: GlassmorphismDesign.Colors.accentBlueLight,
            .foregroundColor: GlassmorphismDesign.Colors.primaryText
        ]
        
        // Set up Google Docs compatible paragraph style
        let lineHeight = calculateLineHeight(font: font, lineSpacing: 1.15)
        let paragraphStyle = NSMutableParagraphStyle()
        
        // Google Docs formatting standards
        paragraphStyle.alignment = .left
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 0
        paragraphStyle.tailIndent = 0
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.paragraphSpacingBefore = 0
        
        // Line spacing (1.15 ratio - Google Docs standard)
        paragraphStyle.lineSpacing = 0
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.lineHeightMultiple = 1.15
        
        // Tab stops every 0.5" (Google Docs standard) with zoom scaling
        let tabStopWidth = 36 * zoomLevel  // 0.5" = 36pt, scaled with zoom
        var tabStops: [NSTextTab] = []
        for i in 1...20 {
            let location = CGFloat(i) * tabStopWidth
            tabStops.append(NSTextTab(textAlignment: .left, location: location))
        }
        paragraphStyle.tabStops = tabStops
        
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: GlassmorphismDesign.Colors.primaryText,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    static func centerPaper(_ paperView: NSView, in containerView: NSView, paperSize: NSSize) {
        let containerSize = containerView.frame.size
        let x = max(0, (containerSize.width - paperSize.width) / 2)
        let y = max(0, (containerSize.height - paperSize.height) / 2)
        
        paperView.frame = NSRect(x: x, y: y, width: paperSize.width, height: paperSize.height)
    }
}
