import Cocoa

/// Modern glassmorphism design system for the Word app
class GlassmorphismDesign {
    
    // MARK: - Color Palette
    
    struct Colors {
        // Glassmorphism background gradient
        static let backgroundStart = NSColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0)
        static let backgroundEnd = NSColor(red: 0.92, green: 0.94, blue: 0.97, alpha: 1.0)
        
        // Glass surface colors with transparency
        static let glassSurface = NSColor(white: 1.0, alpha: 0.7)
        static let glassBorder = NSColor(white: 1.0, alpha: 0.2)
        static let glassShadow = NSColor(white: 0.0, alpha: 0.1)
        
        // Accent colors
        static let accentBlue = NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        static let accentBlueLight = NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 0.1)
        
        // Text colors
        static let primaryText = NSColor(white: 0.1, alpha: 1.0)
        static let secondaryText = NSColor(white: 0.4, alpha: 1.0)
        static let tertiaryText = NSColor(white: 0.6, alpha: 1.0)
    }
    
    // MARK: - Blur Effects
    
    static func createBlurView(intensity: CGFloat = 0.8) -> NSVisualEffectView {
        let blurView = NSVisualEffectView()
        blurView.material = .hudWindow
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.alphaValue = intensity
        return blurView
    }
    
    static func createGlassEffect(for view: NSView, cornerRadius: CGFloat = 12) {
        view.wantsLayer = true
        guard let layer = view.layer else { return }
        
        // Glass surface with transparency
        layer.backgroundColor = Colors.glassSurface.cgColor
        layer.cornerRadius = cornerRadius
        
        // Subtle border
        layer.borderWidth = 0.5
        layer.borderColor = Colors.glassBorder.cgColor
        
        // Soft shadow for depth
        layer.shadowColor = Colors.glassShadow.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = NSSize(width: 0, height: -2)
        layer.shadowRadius = 8
        
        // Backdrop filter simulation (using opacity and blur)
        layer.opacity = 0.95
    }
    
    // MARK: - Background Creation
    
    static func createGradientBackground() -> NSView {
        let backgroundView = NSView()
        backgroundView.wantsLayer = true
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            Colors.backgroundStart.cgColor,
            Colors.backgroundEnd.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        
        backgroundView.layer = gradientLayer
        return backgroundView
    }
    
    // MARK: - Floating Paper Design
    
    static func createFloatingPaper(size: NSSize) -> NSView {
        let paperView = NSView()
        paperView.wantsLayer = true
        guard let layer = paperView.layer else { return paperView }
        
        // Pure white paper with subtle transparency
        layer.backgroundColor = NSColor(white: 1.0, alpha: 0.98).cgColor
        layer.cornerRadius = 8
        
        // Elegant shadow for floating effect
        layer.shadowColor = NSColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = NSSize(width: 0, height: 8)
        layer.shadowRadius = 24
        
        // Subtle border
        layer.borderWidth = 0.5
        layer.borderColor = NSColor(white: 0.9, alpha: 0.3).cgColor
        
        return paperView
    }
    
    // MARK: - Floating Status Bar
    
    static func createFloatingStatusBar() -> NSView {
        let statusView = NSView()
        statusView.wantsLayer = true
        
        // Create blur background
        let blurView = createBlurView(intensity: 0.9)
        statusView.addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: statusView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: statusView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: statusView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: statusView.bottomAnchor)
        ])
        
        // Apply glass effect
        createGlassEffect(for: statusView, cornerRadius: 16)
        
        return statusView
    }
    
    // MARK: - Minimal Typography
    
    static func primaryFont(size: CGFloat) -> NSFont {
        return NSFont.systemFont(ofSize: size, weight: .medium)
    }
    
    static func secondaryFont(size: CGFloat) -> NSFont {
        return NSFont.systemFont(ofSize: size, weight: .regular)
    }
    
    static func monoFont(size: CGFloat) -> NSFont {
        return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
    
    // MARK: - Animations
    
    static func fadeInAnimation(duration: TimeInterval = 0.3) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        return animation
    }
    
    static func slideUpAnimation(distance: CGFloat = 20, duration: TimeInterval = 0.4) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.fromValue = distance
        animation.toValue = 0
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        return animation
    }
    
    // MARK: - Window Styling
    
    static func styleWindow(_ window: NSWindow) {
        // Keep title bar but make it blend with content
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        
        // Enable fullscreen and zoom functionality
        window.collectionBehavior = [.fullScreenPrimary]
        
        // Modern window controls - keep them visible and functional
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
        
        // Ensure zoom button works for double-click behavior
        if let zoomButton = window.standardWindowButton(.zoomButton) {
            zoomButton.isEnabled = true
        }
        
        // Subtle window shadow
        window.hasShadow = true
        
        // Full-size content view while maintaining title bar functionality
        window.styleMask.insert(.fullSizeContentView)
        
        // Enable resizable behavior (required for zoom functionality)
        if !window.styleMask.contains(.resizable) {
            window.styleMask.insert(.resizable)
        }
    }
    
    // MARK: - Minimal Scrollbars
    
    static func styleScrollView(_ scrollView: NSScrollView) {
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = NSColor.clear
        scrollView.drawsBackground = false
    }
}
