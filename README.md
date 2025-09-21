# WordClone - Minimalist Text Editor for macOS

A clean, minimalist text editor for macOS inspired by Microsoft Word 2007, built with Swift and AppKit for native performance and integration.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

### Core Text Editing
- **Rich Text Support** - Full Unicode text editing with `.txt` and `.rtf` file support
- **Spell & Grammar Check** - Built-in macOS spell checking and grammar checking
- **Undo/Redo** - Unlimited undo/redo with standard keyboard shortcuts
- **Cut/Copy/Paste** - Standard clipboard operations with Cmd+X/C/V

### File Operations
- **New Documents** - Create new documents with Cmd+N
- **Open Files** - Support for `.txt` and `.rtf` files with Cmd+O
- **Save/Save As** - Save documents with Cmd+S or Save As with Cmd+Shift+S
- **Recent Documents** - Automatic tracking of recently opened files
- **Auto-save** - Document changes are automatically tracked

### Text Formatting
- **Font Management** - Change fonts via Font Panel (Cmd+T)
- **Text Styles** - Bold (Cmd+B), Italic (Cmd+I), Underline (Cmd+U)
- **Text Color** - Color selection via Color Panel
- **Zoom Controls** - Zoom in (Cmd++), Zoom out (Cmd+-), Actual size (Cmd+0)

### User Interface
- **Minimalist Design** - Clean, distraction-free interface
- **Toolbar** - Quick access to formatting tools
- **Status Bar** - Live word count, character count, and cursor position
- **Native Integration** - Full macOS menu bar and keyboard shortcuts
- **Drag & Drop** - Drop text files directly into the editor

## 🚀 Quick Start

### Prerequisites

- **macOS 13.0** or later
- **Xcode 15.0** or later (for development)
- **Swift 5.9** or later

### Installation & Running

1. **Clone or Download** the project:
   ```bash
   git clone <your-repo-url>
   cd word
   ```

2. **Build the project**:
   ```bash
   swift build
   ```

3. **Run the application**:
   ```bash
   swift run
   ```

That's it! WordClone will launch and you can start using it immediately.

### Alternative: Using Xcode

1. Open the project folder in Xcode
2. Select the WordClone scheme
3. Press Cmd+R to build and run

## 📖 Usage Guide

### Basic Operations

| Action | Keyboard Shortcut | Menu Location |
|--------|------------------|---------------|
| New Document | Cmd+N | File → New |
| Open Document | Cmd+O | File → Open... |
| Save Document | Cmd+S | File → Save |
| Save As | Cmd+Shift+S | File → Save As... |
| Print | Cmd+P | File → Print... |

### Text Editing

| Action | Keyboard Shortcut | Menu Location |
|--------|------------------|---------------|
| Undo | Cmd+Z | Edit → Undo |
| Redo | Cmd+Shift+Z | Edit → Redo |
| Cut | Cmd+X | Edit → Cut |
| Copy | Cmd+C | Edit → Copy |
| Paste | Cmd+V | Edit → Paste |
| Select All | Cmd+A | Edit → Select All |
| Find | Cmd+F | Edit → Find... |

### Text Formatting

| Action | Keyboard Shortcut | Toolbar Button |
|--------|------------------|----------------|
| Bold | Cmd+B | **B** |
| Italic | Cmd+I | *I* |
| Underline | Cmd+U | <u>U</u> |
| Font Panel | Cmd+T | Font |
| Color Panel | - | Color |

### View Controls

| Action | Keyboard Shortcut | Menu Location |
|--------|------------------|---------------|
| Zoom In | Cmd++ | View → Zoom In |
| Zoom Out | Cmd+- | View → Zoom Out |
| Actual Size | Cmd+0 | View → Actual Size |

### Supported File Formats

- **Plain Text** (`.txt`) - Standard UTF-8 text files
- **Rich Text Format** (`.rtf`) - Rich text with formatting preserved

## 🛠️ Development

### Project Structure

```
WordClone/
├── Sources/WordClone/           # Main source code
│   ├── Controllers/             # App logic and coordination
│   │   ├── AppDelegate.swift    # Application lifecycle & menus
│   │   └── DocumentController.swift # File operations
│   ├── Models/                  # Data models
│   │   └── Document.swift       # Document representation
│   ├── Views/                   # User interface
│   │   ├── MainWindow.swift     # Window management
│   │   └── DocumentView.swift   # Text editing interface
│   ├── Utilities/               # Helper code
│   │   └── Constants.swift      # App constants
│   └── main.swift              # Application entry point
├── Tests/WordCloneTests/        # Unit tests
├── docs/                       # Documentation
└── README.md                   # This file
```

### Building for Distribution

To create a distributable app bundle:

```bash
# Build in release mode
swift build -c release

# The executable will be in .build/release/WordClone
```

### Running Tests

```bash
swift test
```

All tests should pass. The test suite includes:
- Document creation and text storage
- Word/character counting
- Basic text operations

### Development Setup

1. **Open in Xcode**:
   ```bash
   open Package.swift
   ```

2. **Set up the scheme** for easier debugging and development

3. **Enable breakpoints** and debugging as needed

## 🎯 Current Status

**✅ Phase 1 Complete** - Core functionality implemented:
- Text editing with rich text support
- File operations (New, Open, Save)
- Basic formatting (Bold, Italic, Underline)
- Native macOS integration
- Clean, minimalist interface

**🚧 Coming in Phase 2** (Future updates):
- Advanced text formatting (alignment, spacing, lists)
- Enhanced find and replace
- Print preview
- Document preferences
- Cross-platform support considerations

## 🐛 Troubleshooting

### Common Issues

**App won't launch**:
- Ensure you're running macOS 13.0 or later
- Try rebuilding: `swift clean && swift build`

**Build errors**:
- Verify Xcode Command Line Tools are installed: `xcode-select --install`
- Check Swift version: `swift --version`

**File operations not working**:
- Check file permissions
- Ensure the file format is supported (.txt or .rtf)

### Getting Help

1. **Check the logs** - Look for error messages in Console.app
2. **Rebuild** - Try `swift clean && swift build && swift run`
3. **File permissions** - Ensure you have read/write access to documents

## 🤝 Contributing

This project follows a clean architecture with:
- **MVC pattern** for clear separation of concerns
- **Swift Package Manager** for dependency management
- **Unit tests** for reliability
- **Native AppKit** for performance

When contributing:
1. Follow the existing code style
2. Add unit tests for new features
3. Update documentation as needed
4. Test on multiple macOS versions if possible

## 📄 License

This project is available under the MIT License. See LICENSE file for details.

## 🙏 Acknowledgments

- Built with Swift and AppKit for native macOS performance
- Inspired by the clean design philosophy of Microsoft Word 2007
- Uses standard macOS design patterns and HIG guidelines

---

**Enjoy writing with WordClone!** 📝✨

For more detailed technical information, see the documentation in the `docs/` folder.
