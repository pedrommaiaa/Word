import XCTest
@testable import WordClone

final class DocumentTests: XCTestCase {
    
    func testDocumentCreation() {
        let document = Document()
        XCTAssertNotNil(document)
        XCTAssertEqual(document.textStorage.length, 0)
    }
    
    func testDocumentTextStorage() {
        let document = Document()
        let testString = "Hello, World!"
        
        document.textStorage.replaceCharacters(
            in: NSRange(location: 0, length: 0),
            with: testString
        )
        
        XCTAssertEqual(document.textStorage.string, testString)
        XCTAssertEqual(document.wordCount, 2)
    }
    
    func testDocumentStatistics() {
        let document = Document()
        let testText = "Hello world!\nThis is a test.\nLine three."
        
        document.textStorage.replaceCharacters(
            in: NSRange(location: 0, length: 0),
            with: testText
        )
        
        let stats = document.getDocumentStatistics()
        XCTAssertEqual(stats.words, 8) // "Hello", "world!", "This", "is", "a", "test.", "Line", "three."
        XCTAssertEqual(stats.characters, testText.count)
        XCTAssertEqual(stats.lines, 3)
    }
}
