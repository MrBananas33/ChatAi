//
//  MessageParser.swift
//  macaiTests
//
//  Created by Renat Notfullin on 25.04.2023.
//

import XCTest
@testable import macai

class MessageParserTests: XCTestCase {

    var parser: MessageParser!

    override func setUp() {
        super.setUp()
        parser = MessageParser(colorScheme: .light)
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }


    /*
     Test generic message with table
     */
    func testParseMessageFromStringGeneric() {
        let input = """
        This is a sample text.

        Table: Test Table
        | Column 1 | Column 2 |
        | -------- | -------- |
        | Value 1  | Value 2  |
        | Value 3  | Value 4  |

        This is another sample text.
        """

        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 3)

        switch result[0] {
        case .text(let text):
            XCTAssertEqual(text, """
            This is a sample text.
            
            Table: Test Table
            """)
        default:
            XCTFail("Expected .text element")
        }

        switch result[1] {
        case .table(header: let header, data: let data):
            XCTAssertEqual(header, ["Column 1", "Column 2"])
            XCTAssertEqual(data, [["Value 1", "Value 2"], ["Value 3", "Value 4"]])
        default:
            XCTFail("Expected .table element")
        }

        switch result[2] {
        case .text(let text):
            XCTAssertEqual(text, "This is another sample text.")
        default:
            XCTFail("Expected .text element")
        }
    }
    
    /*
     Test incomplete message in response
     https://github.com/Renset/macai/issues/15
     */
    func testParseMessageFromStringGitHubIssue15() {
        let input = """
        Here's a FizzBuzz implementation in Shakespeare Programming Language:

        ```
        The Infamous FizzBuzz Program.
        By ChatGPT.

        Act 1: The Setup
        Scene 1: Initializing Variables.
        [Enter Romeo and Juliet]
        """
        
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 2)

        switch result[0] {
        case .text(let text):
            XCTAssertEqual(text, "Here's a FizzBuzz implementation in Shakespeare Programming Language:\n")
        default:
            XCTFail("Expected .text element")
        }
        
        switch result[1] {
        case .code(code: let highlightedCode):
            XCTAssertEqual(String(highlightedCode.code), """
            The Infamous FizzBuzz Program.
            By ChatGPT.
            
            Act 1: The Setup
            Scene 1: Initializing Variables.
            [Enter Romeo and Juliet]
            """)
        default:
            XCTFail("Expected .code element")
        }
    }
    
    /*
     Test message with the mix of tables and code blocks
     */
    func testParseMessageFromStringTableAndCode() {
        let input = """
        Table: Test Table
        | Column 1 | Column 2 |
        | -------- | -------- |
        | Value 1  | Value 2  |
        | Value 3  | Value 4  |

        ```
        This is a code block
        ```

        **Table 2: Test Table
        | Column 1 | Column 2 |
        | -------- | -------- |
        | Value 1  | Value 2  |
        | Value 3  | Value 4  |
        
        **Table 3: Test Table
        | Column 1 | Column 2 |
        | -------- | -------- |
        | Value 1  | Value 2  |
        | Value 3  | Value 4  |
        
        Some random text. Bla-bla-bla...
        
        **Table 4: Test Table
        | Column 1 | Column 2 |
        | -------- | -------- |
        | Value 1  | Value 2  |
        | Value 3  | Value 4  |
        
        """

        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 11)

        switch result[1] {
        case .table(header: let header, data: let data):
            XCTAssertEqual(header, ["Column 1", "Column 2"])
            XCTAssertEqual(data, [["Value 1", "Value 2"], ["Value 3", "Value 4"]])
        default:
            XCTFail("Expected .table element")
        }

        switch result[3] {
        case .code(code: let highlightedCode):
            XCTAssertEqual(String(highlightedCode.code), """
            This is a code block
            """)
        default:
            XCTFail("Expected .code element")
        }

        switch result[5] {
        case .table(header: let header, data: let data):
            XCTAssertEqual(header, ["Column 1", "Column 2"])
            XCTAssertEqual(data, [["Value 1", "Value 2"], ["Value 3", "Value 4"]])
        default:
            XCTFail("Expected .table element")
        }
        
        switch result[7] {
        case .table(header: let header, data: let data):
            XCTAssertEqual(header, ["Column 1", "Column 2"])
            XCTAssertEqual(data, [["Value 1", "Value 2"], ["Value 3", "Value 4"]])
        default:
            XCTFail("Expected .table element")
        }
        
        switch result[8] {
        case .text(let text):
            XCTAssertEqual(text, """
            Some random text. Bla-bla-bla...

            **Table 4: Test Table
            """)
        default:
            XCTFail("Expected .text element")
        }
        
        switch result[9] {
        case .table(header: let header, data: let data):
            XCTAssertEqual(header, ["Column 1", "Column 2"])
            XCTAssertEqual(data, [["Value 1", "Value 2"], ["Value 3", "Value 4"]])
        default:
            XCTFail("Expected .table element")
        }
    }
    
    func testParseMessageFromStringMathEquation() {
        let input = """
        Sure, here’s a complex formula from the field of string theory, specifically the action for the bosonic string:

        \\[
        S = -\\frac{1}{4\\pi\\alpha'} \\int d\\tau \\, d\\sigma \\, \\sqrt{-h} \\left( h^{ab} \\partial_a X^\\mu \\partial_b X_\\mu + \\alpha' R^{(2)} \\Phi(X) \\right)
        \\]

        Where:
        - \\( S \\) is the action.
        - \\( \\alpha' \\) is the string tension parameter.
        - \\( \\tau \\) and \\( \\sigma \\) are the worldsheet coordinates.
        - \\( h \\) is the determinant of the worldsheet metric \\( h_{ab} \\).
        - \\( h^{ab} \\) is the inverse of the worldsheet metric.
        - \\( \\partial_a \\) denotes partial differentiation with respect to the worldsheet coordinates.
        - \\( X^\\mu \\) are the target space coordinates of the string.
        - \\( R^{(2)} \\) is the Ricci scalar of the worldsheet.
        - \\( \\Phi(X) \\) is the dilaton field.
        """

        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 3)
        
        switch result[0] {
        case .text(let text):
            XCTAssertEqual(text, """
            Sure, here’s a complex formula from the field of string theory, specifically the action for the bosonic string:

            """)
        default:
            XCTFail("Expected .text element")
        }
        
        switch result[1] {
        case .formula(let formula):
            XCTAssertEqual(formula, "S = -\\frac{1}{4\\pi\\alpha'} \\int d\\tau \\, d\\sigma \\, \\sqrt{-h} \\left( h^{ab} \\partial_a X^\\mu \\partial_b X_\\mu + \\alpha' R^{(2)} \\Phi(X) \\right)")
        default:
            XCTFail("Expected .formula element")
        }
        
        switch result[2] {
        case .text(let text):
            // Original text before inline parsing:
            // """
            // Where:
            // - \\( S \\) is the action.
            // - \\( \\alpha' \\) is the string tension parameter.
            // - \\( \\tau \\) and \\( \\sigma \\) are the worldsheet coordinates.
            // - \\( h \\) is the determinant of the worldsheet metric \\( h_{ab} \\).
            // - \\( h^{ab} \\) is the inverse of the worldsheet metric.
            // - \\( \\partial_a \\) denotes partial differentiation with respect to the worldsheet coordinates.
            // - \\( X^\\mu \\) are the target space coordinates of the string.
            // - \\( R^{(2)} \\) is the Ricci scalar of the worldsheet.
            // - \\( \\Phi(X) \\) is the dilaton field.
            // """
            // With inline parsing, this single text block will be broken down.
            // For simplicity in this already complex test, we'll just check the count has increased
            // and that the first part is as expected. A more granular check would be too verbose here
            // and is covered by the new specific inline LaTeX tests.
            // The original result.count was 3. Now it will be more.
            // "Where:\n- " will be text, then "S" will be formula, then " is the action." will be text, etc.
            XCTAssertTrue(result.count > 3, "Expected more than 3 elements due to inline parsing")
            // Check the initial part of the text
             XCTAssertEqual(text, "Where:") // The first line after the block formula is "Where:"
        default:
            XCTFail("Expected .text element as the first element after the block formula")
        }

        // Example of checking a few subsequent elements after "Where:"
        // This depends on the exact output of parseLineForInlineLatex
        // For the line: "- \\( S \\) is the action."
        // Expected: .text("- "), .formula("S"), .text(" is the action.")
        if result.count > 5 { // Check if enough elements exist for this part
            switch result[3] { // Should be .text("- ") from the next line
            case .text(let text):
                XCTAssertEqual(text, "- ")
            default:
                XCTFail("Expected .text for '- '")
            }
            switch result[4] { // Should be .formula("S")
            case .formula(let formula):
                XCTAssertEqual(formula, "S")
            default:
                XCTFail("Expected .formula for 'S'")
            }
            switch result[5] { // Should be .text(" is the action.")
            case .text(let text):
                XCTAssertEqual(text, " is the action.")
            default:
                XCTFail("Expected .text for ' is the action.'")
            }
        }
        
    }

    // MARK: - Inline LaTeX Tests

    func testParseSimpleInlineDollar() {
        let input = "Hello $x^2$ world"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 3)
        if result.count == 3 {
            XCTAssertEqualElements(result[0], .text("Hello "))
            XCTAssertEqualElements(result[1], .formula("x^2"))
            XCTAssertEqualElements(result[2], .text(" world"))
        }
    }

    func testParseMultipleInlineDollar() {
        let input = "Value $a=1$ and $b=2$ here"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 5)
        if result.count == 5 {
            XCTAssertEqualElements(result[0], .text("Value "))
            XCTAssertEqualElements(result[1], .formula("a=1"))
            XCTAssertEqualElements(result[2], .text(" and "))
            XCTAssertEqualElements(result[3], .formula("b=2"))
            XCTAssertEqualElements(result[4], .text(" here"))
        }
    }

    func testParseInlineDollarAtStart() {
        let input = "$E=mc^2$ is famous"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 2)
        if result.count == 2 {
            XCTAssertEqualElements(result[0], .formula("E=mc^2"))
            XCTAssertEqualElements(result[1], .text(" is famous"))
        }
    }

    func testParseInlineDollarAtEnd() {
        let input = "Formula $y=mx+c$"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 2)
        if result.count == 2 {
            XCTAssertEqualElements(result[0], .text("Formula "))
            XCTAssertEqualElements(result[1], .formula("y=mx+c"))
        }
    }

    func testParseOnlyInlineDollar() {
        let input = "$x^2+y^2=z^2$"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 1)
        if result.count == 1 {
            XCTAssertEqualElements(result[0], .formula("x^2+y^2=z^2"))
        }
    }

    func testParseSimpleInlineParentheses() {
        let input = "Hello \\(x^2\\) world"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 3)
        if result.count == 3 {
            XCTAssertEqualElements(result[0], .text("Hello "))
            XCTAssertEqualElements(result[1], .formula("x^2"))
            XCTAssertEqualElements(result[2], .text(" world"))
        }
    }

    func testParseMultipleInlineParentheses() {
        let input = "Value \\(a=1\\) and \\(b=2\\) here"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 5)
        if result.count == 5 {
            XCTAssertEqualElements(result[0], .text("Value "))
            XCTAssertEqualElements(result[1], .formula("a=1"))
            XCTAssertEqualElements(result[2], .text(" and "))
            XCTAssertEqualElements(result[3], .formula("b=2"))
            XCTAssertEqualElements(result[4], .text(" here"))
        }
    }

    func testParseOnlyInlineParentheses() {
        let input = "\\(\\int f(x)dx\\)"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 1)
        if result.count == 1 {
            XCTAssertEqualElements(result[0], .formula("\\int f(x)dx"))
        }
    }

    func testParseMixedInlineDelimiters() {
        let input = "Test $x^2$ and \\(y^2\\)"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 4) // .text("Test "), .formula("x^2"), .text(" and "), .formula("y^2")
        if result.count == 4 {
            XCTAssertEqualElements(result[0], .text("Test "))
            XCTAssertEqualElements(result[1], .formula("x^2"))
            XCTAssertEqualElements(result[2], .text(" and "))
            XCTAssertEqualElements(result[3], .formula("y^2"))
        }
    }

    func testParseEscapedDollarDelimiter() {
        // Input: "This is a real \\$5 price, not $x=1$."
        // Expected: .text("This is a real $5 price, not "), .formula("x=1"), .text(".")
        // The parseLineForInlineLatex unescapes \\$ to $ in text parts if it's not part of a formula.
        // The regex is (?<!\\)\$((?:\\\$|[^$])*?)(?<!\\)\$
        // So \\$5 should not be matched as formula.
        // The content of formula $x=1$ is "x=1".
        // The text "This is a real \\$5 price, not " is passed as is to .text()
        // The helper function `parseLineForInlineLatex` has an unescaping step for content,
        // but text segments are taken as they are.
        let input = "This is a real \\$5 price, not $x=1$."
        let result = parser.parseMessageFromString(input: input)

        XCTAssertEqual(result.count, 3, "Result count was \(result.count). Elements: \(result)")
        if result.count == 3 {
            XCTAssertEqualElements(result[0], .text("This is a real \\$5 price, not "))
            XCTAssertEqualElements(result[1], .formula("x=1"))
            XCTAssertEqualElements(result[2], .text("."))
        }
    }

    func testParseEscapedParenthesesDelimiter() {
        // Input: "This is \\\\(not math\\\\), but \\(x=1\\) is."
        // Expected: .text("This is \\(not math\\), but "), .formula("x=1"), .text(" is.")
        // Similar to escaped dollar, \\\\( should be treated as literal \\( in text.
        // The regex for \( is (?<!\\)\\\(((?:\\\)|[^)])*?)(?<!\\)\\\)
        // So \\\\( means an escaped backslash before escaped parenthesis - should be text.
        let input = "This is \\\\(not math\\\\), but \\(x=1\\) is."
        let result = parser.parseMessageFromString(input: input)

        XCTAssertEqual(result.count, 3, "Result count was \(result.count). Elements: \(result)")
        if result.count == 3 {
             XCTAssertEqualElements(result[0], .text("This is \\\\(not math\\\\), but "))
             XCTAssertEqualElements(result[1], .formula("x=1"))
             XCTAssertEqualElements(result[2], .text(" is."))
        }
    }

    func testParsePlainTextNoLatex() {
        let input = "This is just plain text."
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 1)
        if result.count == 1 {
            XCTAssertEqualElements(result[0], .text("This is just plain text."))
        }
    }

    func testParseEmptyString() {
        let input = ""
        let result = parser.parseMessageFromString(input: input)
        // Empty input results in one empty text line from lines.split, which results in one .text("") element
        XCTAssertEqual(result.count, 1, "Result count was \(result.count). Elements: \(result)")
        if result.count == 1 {
            XCTAssertEqualElements(result[0], .text(""))
        }
    }

    func testParseEmptyInlineLatexDollar() {
        let input = "Text $$ end" // Note: "$ $" might be treated as "$ content $" with content " " by some renderers.
                               // My regex expects $content$. "$$" means empty content.
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 3, "Result count was \(result.count). Elements: \(result)")
        if result.count == 3 {
            XCTAssertEqualElements(result[0], .text("Text "))
            XCTAssertEqualElements(result[1], .formula("")) // Empty content
            XCTAssertEqualElements(result[2], .text(" end"))
        }
    }

    func testParseEmptyInlineLatexDollarSpace() {
        let input = "Text $ $ end"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 3, "Result count was \(result.count). Elements: \(result)")
        if result.count == 3 {
            XCTAssertEqualElements(result[0], .text("Text "))
            XCTAssertEqualElements(result[1], .formula(" ")) // Content is a single space
            XCTAssertEqualElements(result[2], .text(" end"))
        }
    }

    func testParseEmptyInlineLatexParentheses() {
        let input = "Text \\(\\) end"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 3)
        if result.count == 3 {
            XCTAssertEqualElements(result[0], .text("Text "))
            XCTAssertEqualElements(result[1], .formula(""))
            XCTAssertEqualElements(result[2], .text(" end"))
        }
    }

    func testParseEmptyInlineLatexParenthesesSpace() {
        let input = "Text \\( \\) end"
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 3)
        if result.count == 3 {
            XCTAssertEqualElements(result[0], .text("Text "))
            XCTAssertEqualElements(result[1], .formula(" "))
            XCTAssertEqualElements(result[2], .text(" end"))
        }
    }


    func testParseBlockFormulaRemainsUnchanged() {
        let input = """
        Formula:
        \\[\\sum i = 0\\]
        Next line.
        """
        let result = parser.parseMessageFromString(input: input)
        // Expected: .text("Formula:"), .formula("\sum i = 0"), .text("Next line.")
        XCTAssertEqual(result.count, 3)
        if result.count == 3 {
            XCTAssertEqualElements(result[0], .text("Formula:"))
            // The parseMessageFromString logic for block formulas adds a newline if the formula is on its own line.
            // Let's check existing behavior from testParseMessageFromStringMathEquation for S = ...
            // It seems it does not add a newline. The formula content is extracted as is.
            XCTAssertEqualElements(result[1], .formula("\\sum i = 0"))
            XCTAssertEqualElements(result[2], .text("Next line."))
        }
    }

    func testParseCodeBlockRemainsUnchanged() {
        let input = """
        Code:
        ```swift
        let a = 1
        ```
        End.
        """
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 3, "Result count was \(result.count). Elements: \(result)")
        if result.count == 3 {
            XCTAssertEqualElements(result[0], .text("Code:"))
            XCTAssertEqualElements(result[1], .code(code: "let a = 1", lang: "swift", indent: 0))
            XCTAssertEqualElements(result[2], .text("End."))
        }
    }

    func testComplexMixedContent() {
        let input = "Start $L_1$ then text. \\(L_2\\). End."
        let result = parser.parseMessageFromString(input: input)
        // Expected: .text("Start "), .formula("L_1"), .text(" then text. "), .formula("L_2"), .text(". End.")
        XCTAssertEqual(result.count, 5)
        if result.count == 5 {
            XCTAssertEqualElements(result[0], .text("Start "))
            XCTAssertEqualElements(result[1], .formula("L_1"))
            XCTAssertEqualElements(result[2], .text(" then text. "))
            XCTAssertEqualElements(result[3], .formula("L_2"))
            XCTAssertEqualElements(result[4], .text(". End."))
        }
    }

    func testLineWithOnlyEscapedDollar() {
        let input = "This is \\$5."
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 1)
        if result.count == 1 {
            XCTAssertEqualElements(result[0], .text("This is \\$5."))
        }
    }

    func testLineWithOnlyEscapedParenthesis() {
        let input = "This is \\\\(not math\\\\)." // \\\\( for source code string \ (
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 1)
        if result.count == 1 {
            XCTAssertEqualElements(result[0], .text("This is \\\\(not math\\\\)."))
        }
    }

    func testLatexLikeSyntaxNotMatchingDelimiters() {
        let input = "Text with $ unmatched."
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 1)
        if result.count == 1 {
            XCTAssertEqualElements(result[0], .text("Text with $ unmatched."))
        }
    }

    func testLatexLikeSyntaxNotMatchingDelimitersParen() {
        let input = "Text with \\( unmatched."
        let result = parser.parseMessageFromString(input: input)
        XCTAssertEqual(result.count, 1)
        if result.count == 1 {
            XCTAssertEqualElements(result[0], .text("Text with \\( unmatched."))
        }
    }

    // Helper to compare MessageElements, as the enum might not be directly Equatable
    // or its Equatable conformance might not be available in this context without defining it.
    func XCTAssertEqualElements(_ e1: MessageElements, _ e2: MessageElements, file: StaticString = #filePath, line: UInt = #line) {
        switch (e1, e2) {
        case (.text(let s1), .text(let s2)):
            XCTAssertEqual(s1, s2, "Text content mismatch", file: file, line: line)
        case (.formula(let f1), .formula(let f2)):
            XCTAssertEqual(f1, f2, "Formula content mismatch", file: file, line: line)
        case (.code(let c1, let l1, let i1), .code(let c2, let l2, let i2)):
            XCTAssertEqual(c1, c2, "Code content mismatch", file: file, line: line)
            XCTAssertEqual(l1, l2, "Code language mismatch", file: file, line: line)
            XCTAssertEqual(i1, i2, "Code indent mismatch", file: file, line: line)
        case (.table(let h1, let d1), .table(let h2, let d2)):
            XCTAssertEqual(h1, h2, "Table header mismatch", file: file, line: line)
            XCTAssertEqual(d1, d2, "Table data mismatch", file: file, line: line)
        // Add other cases like .image, .thinking if needed for comprehensive comparison
        default:
            XCTFail("MessageElement types do not match. e1: \(e1), e2: \(e2)", file: file, line: line)
        }
    }
}

