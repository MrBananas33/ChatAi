import CoreData
//
//  MessageParser.swift
//  macai
//
//  Created by Renat Notfullin on 25.04.2023.
//
import Foundation
import Highlightr
import SwiftUI

struct MessageParser {
    @State var colorScheme: ColorScheme

    enum BlockType {
        case text
        case table
        case codeBlock
        case formulaBlock
        case formulaLine
        case thinking
        case imageUUID
    }

    func detectBlockType(line: String) -> BlockType {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        if trimmedLine.hasPrefix("<think>") {
            return .thinking
        }
        else if trimmedLine.hasPrefix("```") {
            return .codeBlock
        }
        else if trimmedLine.first == "|" {
            return .table
        }
        else if trimmedLine.hasPrefix("\\[") {
            return trimmedLine.replacingOccurrences(of: " ", with: "") == "\\[" ? .formulaBlock : .formulaLine
        }
        else if trimmedLine.hasPrefix("\\]") {
            return .formulaLine
        }
        else if trimmedLine.hasPrefix("<image-uuid>") {
            return .imageUUID
        }
        else {
            return .text
        }
    }

    // Helper function to parse a single line for inline LaTeX
    private func parseLineForInlineLatex(line: String) -> [MessageElements] {
        var elements: [MessageElements] = []
        var currentIndex = line.startIndex
        // Regex for $...$ (non-greedy) and \(...\) (non-greedy), handling escaped delimiters
        // Need to be careful with Swift's regex syntax.
        // Pattern: (\$((?:\\.|[^$])*)\$)|(\\\(((?:\\.|[^)])*)\\\))
        // Breaking it down:
        // (\$((?:\\.|[^$])*)\$) - For $...$
        //   \$ - Matches the opening $
        //   ((?:\\.|[^$])*) - Captures the content. Allows any character that is not $ (non-greedy) or any escaped character.
        //   \$ - Matches the closing $
        // (\\\( ((?:\\.|[^)])*) \\\)) - For \(...\)
        //   \\\( - Matches the opening \(
        //   ((?:\\.|[^)])*) - Captures the content. Allows any character that is not \) (non-greedy) or any escaped character.
        //   \\\) - Matches the closing \)
        // The outer non-capturing group (?:...) is used to make the * non-greedy for the content itself.
        // The overall regex needs to find any of these two patterns.
        // Let's try a combined regex.
        // Simpler approach for now: (\$[^$]*\$)|(\\\(.*?\)\\\)) - This might not handle escaped delimiters correctly yet.
        // For Swift, the NSRegularExpression is more robust.

        // Using a simpler regex for now, will refine if needed.
        // Pattern for $...$: \$([^$]*)\$
        // Pattern for \(...\): \\\\\((.*?)\\\\\)
        // Combined: (\$[^$]*\$|\\\\\((.*?)\\\\\))
        // Let's try to match one at a time to handle indices correctly.

        // Regex for $...$ (non-greedy): \$(.*?)\$
        // Regex for \(...\) (non-greedy): \\((.*?)\\)
        // Combined for searching: (\$[^$]*\$|\\\(.*?\\\)) -> Swift string: "(\\$[^$]*\\$|\\\\\\(.*?\\\\\\))"
        // The regex needs to handle escaped delimiters like \$ and \\(
        // Let's use a more robust regex:
        // For $...$: (?<!\\)\$((?:\\\$|[^$])*?)(?<!\\)\$
        // For \(...\): (?<!\\)\\\(((?:\\\)|[^)])*?)(?<!\\)\\\)
        // Combined: (?<!\\)\$((?:\\\$|[^$])*?)(?<!\\)\$|(?<!\\)\\\(((?:\\\)|[^)])*?)(?<!\\)\\\)

        // Let's use the suggested regex and adapt it for Swift:
        // Original: (\$([^$]|\\$)*\$)|(\\\(.*?\\\))
        // Swift version needs double backslashes for literal backslashes in the pattern.
        // And be careful with capture groups.
        // Let's try a simpler regex first that finds either pattern, then extract content.
        // This regex finds $...$ or \(...\)
        // (\$[^$]*\$)|(\\\(.*?\)\\\))
        // It needs to be non-greedy for the content.
        // (\$[^$]*?\$)|(\\\(.*?\)\\\))
        // Let's refine to handle escaped delimiters.
        // The regex: (?<!\\)\$((?:\\\$|[^$])*?)(?<!\\)\$|(?<!\\)\\\(((?:\\\)|[^)])*?)(?<!\\)\\\)
        // For Swift strings, this becomes:
        let latexRegexPattern = #"(?<!\\)\$((?:\\\$|[^$])*?)(?<!\\)\$|(?<!\\)\\\(((?:\\\)|[^)])*?)(?<!\\)\\\)"#
        // Or, using the one from the problem description, adapted:
        // (\$)((?:[^$]|\\\$)*)(\$)|(\\\()((?:[^)]|\\\))*(\\\))
        // This has issues with greedy * if not careful.
        // Let's use the one from the problem description and make it non-greedy for the content part.
        // (\$((?:[^$]|\\\$)*?)\$)|(\\\((?:[^)]|\\\))*?\\\))
        // For Swift:
        let pattern = #"(\$((?:[^$]|\\\$)*?)\$)|(\\\((?:[^)]|\\\))*?\\\))"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            // If regex fails, return the whole line as text
            if !line.isEmpty {
                elements.append(.text(line))
            }
            return elements
        }

        let nsLine = line as NSString
        let lineRange = NSRange(location: 0, length: nsLine.length)
        var matches = regex.matches(in: line, options: [], range: lineRange)

        var lastIndexProcessed = line.startIndex

        for match in matches {
            let matchRange = match.range
            guard let swiftRange = Range(matchRange, in: line) else { continue }

            // Add text before the match
            if swiftRange.lowerBound > lastIndexProcessed {
                let textBefore = String(line[lastIndexProcessed..<swiftRange.lowerBound])
                if !textBefore.isEmpty {
                    elements.append(.text(textBefore))
                }
            }

            let matchedSubstring = nsLine.substring(with: matchRange)
            var latexContent = ""

            // Determine which pattern matched and extract content accordingly
            // Group 2 for $...$ content, Group 5 for \(...\) content (based on the regex structure)
            // (\$((?:[^$]|\\\$)*?)\$)|(\\\((?:[^)]|\\\))*?\\\))
            //   12------------------21   34------------------43
            // Group 1: $...$ full match
            // Group 2: content of $...$
            // Group 3: \(...\) full match
            // Group 4: content of \(...\)

            if match.range(at: 2).location != NSNotFound, let contentRange = Range(match.range(at: 2), in: line) {
                // Matched $...$
                latexContent = String(line[contentRange])
            } else if match.range(at: 4).location != NSNotFound, let contentRange = Range(match.range(at: 4), in: line) {
                // Matched \(...\)
                // The regex for this part is (\\((?:[^)]|\\))*?\\))
                // Content is group 4: ((?:[^)]|\\))*)
                latexContent = String(line[contentRange])
            } else {
                // Fallback or error, should not happen if regex is correct
                // For now, let's just take the matched string without delimiters if specific groups fail
                if matchedSubstring.hasPrefix("$") && matchedSubstring.hasSuffix("$") && matchedSubstring.count >= 2 {
                    latexContent = String(matchedSubstring.dropFirst().dropLast())
                } else if matchedSubstring.hasPrefix("\\(") && matchedSubstring.hasSuffix("\\)") && matchedSubstring.count >= 4 {
                    latexContent = String(matchedSubstring.dropFirst(2).dropLast(2))
                }
            }

            // Unescape delimiters like \$ and \\( and \\) within the content
            latexContent = latexContent.replacingOccurrences(of: "\\$", with: "$")
                                      .replacingOccurrences(of: "\\(", with: "(")
                                      .replacingOccurrences(of: "\\)", with: ")")

            if !latexContent.isEmpty {
                 elements.append(.formula(latexContent))
            } else if matchedSubstring == "$" || matchedSubstring == "\\(" || matchedSubstring == "\\)" {
                // If we only matched a single delimiter, treat it as text.
                // This can happen if the regex is not perfect or if the input is just "$".
                elements.append(.text(matchedSubstring))
            }


            lastIndexProcessed = swiftRange.upperBound
        }

        // Add any remaining text after the last match
        if lastIndexProcessed < line.endIndex {
            let remainingText = String(line[lastIndexProcessed...])
            if !remainingText.isEmpty {
                elements.append(.text(remainingText))
            }
        }

        // If no matches were found at all, and the line is not empty, add the whole line as text.
        if matches.isEmpty && !line.isEmpty {
            elements.append(.text(line))
        }

        return elements
    }

    func parseMessageFromString(input: String) -> [MessageElements] {

        let lines = input.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        var elements: [MessageElements] = []
        var currentHeader: [String] = []
        var currentTableData: [[String]] = []
        var textLines: [String] = []
        var codeLines: [String] = []
        var formulaLines: [String] = []
        var firstTableRowProcessed = false
        var isCodeBlockOpened = false
        var isFormulaBlockOpened = false
        var codeBlockLanguage = ""
        var leadingSpaces = 0

        func toggleCodeBlock(line: String) {
            if isCodeBlockOpened {
                appendCodeBlockIfNeeded()
                isCodeBlockOpened = false
                codeBlockLanguage = ""
                leadingSpaces = 0
            }
            else {
                // extract codeBlockLanguage and remove leading spaces
                codeBlockLanguage = line.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "```", with: "")
                isCodeBlockOpened = true
            }
        }

        func openFormulaBlock() {
            isFormulaBlockOpened = true
        }

        func closeFormulaBlock() {
            isFormulaBlockOpened = false
        }

        func handleFormulaLine(line: String) {
            let formulaString = line.replacingOccurrences(of: "\\[", with: "").replacingOccurrences(of: "\\]", with: "")
            formulaLines.append(formulaString)
        }

        func appendFormulaLines() {
            let combinedLines = formulaLines.joined(separator: "\n")
            elements.append(.formula(combinedLines))
        }

        func handleTableLine(line: String) {

            combineTextLinesIfNeeded()

            let rowData = parseRowData(line: line)

            if rowDataIsTableDelimiter(rowData: rowData) {
                return
            }

            if !firstTableRowProcessed {
                handleFirstRowData(rowData: rowData)
            }
            else {
                handleSubsequentRowData(rowData: rowData)
            }
        }

        func rowDataIsTableDelimiter(rowData: [String]) -> Bool {
            return rowData.allSatisfy({ $0.allSatisfy({ $0 == "-" || $0 == ":" }) })
        }

        func parseRowData(line: String) -> [String] {
            return line.split(separator: "|")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        func handleFirstRowData(rowData: [String]) {
            currentHeader = rowData
            firstTableRowProcessed = true
        }

        func handleSubsequentRowData(rowData: [String]) {
            currentTableData.append(rowData)
        }

        func combineTextLinesIfNeeded() {
            if !textLines.isEmpty {
                let combinedText = textLines.reduce("") { (result, line) -> String in
                    if result.isEmpty {
                        return line
                    }
                    else {
                        return result + "\n" + line
                    }
                }
                elements.append(.text(combinedText))
                textLines = []
            }
        }

        func appendTableIfNeeded() {
            if !currentTableData.isEmpty {
                appendTable()
            }
        }

        func appendTable() {
            elements.append(.table(header: currentHeader, data: currentTableData))
            currentHeader = []
            currentTableData = []
            firstTableRowProcessed = false
        }

        func appendCodeBlockIfNeeded() {
            if !codeLines.isEmpty {
                let combinedCode = codeLines.joined(separator: "\n")
                elements.append(.code(code: combinedCode, lang: codeBlockLanguage, indent: leadingSpaces))
                codeLines = []
            }
        }

        func extractImageUUID(_ line: String) -> UUID? {
            let pattern = "<image-uuid>(.*?)</image-uuid>"
            if let range = line.range(of: pattern, options: .regularExpression) {
                let uuidString = String(line[range])
                    .replacingOccurrences(of: "<image-uuid>", with: "")
                    .replacingOccurrences(of: "</image-uuid>", with: "")
                return UUID(uuidString: uuidString)
            }
            return nil
        }

        func loadImageFromCoreData(uuid: UUID) -> NSImage? {
            let viewContext = PersistenceController.shared.container.viewContext

            let fetchRequest: NSFetchRequest<ImageEntity> = ImageEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            fetchRequest.fetchLimit = 1

            do {
                let results = try viewContext.fetch(fetchRequest)
                if let imageEntity = results.first, let imageData = imageEntity.image {
                    return NSImage(data: imageData)
                }
            }
            catch {
                print("Error fetching image from CoreData: \(error)")
            }

            return nil
        }

        var thinkingLines: [String] = []
        var isThinkingBlockOpened = false

        func appendThinkingBlockIfNeeded() {
            if !thinkingLines.isEmpty {
                let combinedThinking = thinkingLines.joined(separator: "\n")
                    .replacingOccurrences(of: "<think>", with: "")
                    .replacingOccurrences(of: "</think>", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                elements.append(.thinking(combinedThinking, isExpanded: false))
                thinkingLines = []
            }
        }

        func finalizeParsing() {
            combineTextLinesIfNeeded() // This might need adjustment
            appendCodeBlockIfNeeded()
            appendTableIfNeeded()
            appendThinkingBlockIfNeeded()
        }

        for line in lines {
            let blockType = detectBlockType(line: line)

            switch blockType {

            case .codeBlock:
                leadingSpaces = line.count - line.trimmingCharacters(in: .whitespaces).count
                combineTextLinesIfNeeded()
                appendTableIfNeeded()
                toggleCodeBlock(line: line)

            case .table:
                handleTableLine(line: line)

            case .formulaBlock:
                combineTextLinesIfNeeded()
                appendTableIfNeeded()
                openFormulaBlock()

            case .formulaLine:
                combineTextLinesIfNeeded()
                appendTableIfNeeded()
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("\\]") {
                    closeFormulaBlock()
                    appendFormulaLines()
                }
                else {
                    handleFormulaLine(line: line)
                    if !isFormulaBlockOpened {
                        appendFormulaLines()
                    }
                }

            case .thinking:
                if line.contains("</think>") {
                    let thinking =
                        line
                        .replacingOccurrences(of: "<think>", with: "")
                        .replacingOccurrences(of: "</think>", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    elements.append(.thinking(thinking, isExpanded: false))
                }
                else if line.contains("<think>") {
                    combineTextLinesIfNeeded()
                    appendTableIfNeeded()
                    isThinkingBlockOpened = true

                    let firstLine = line.replacingOccurrences(of: "<think>", with: "")
                    if !firstLine.isEmpty {
                        thinkingLines.append(firstLine)
                    }
                }

            case .imageUUID:
                if let uuid = extractImageUUID(line), let image = loadImageFromCoreData(uuid: uuid) {
                    combineTextLinesIfNeeded()
                    elements.append(.image(image))
                }
                else {
                    textLines.append(line)
                }

            case .text:
                if isThinkingBlockOpened {
                    if line.contains("</think>") {
                        let lastLine = line.replacingOccurrences(of: "</think>", with: "")
                        if !lastLine.isEmpty {
                            thinkingLines.append(lastLine)
                        }
                        isThinkingBlockOpened = false
                        appendThinkingBlockIfNeeded()
                    }
                    else {
                        thinkingLines.append(line)
                    }
                }
                else if isCodeBlockOpened {
                    if leadingSpaces > 0 {
                        codeLines.append(String(line.dropFirst(leadingSpaces)))
                    }
                    else {
                        codeLines.append(line)
                    }
                }
                else if isFormulaBlockOpened {
                    handleFormulaLine(line: line)
                }
                else {
                    if !currentTableData.isEmpty {
                        appendTable()
                    }
                    // textLines.append(line) // Old logic
                    // New logic: parse line for inline LaTeX
                    combineTextLinesIfNeeded() // Flush any previously accumulated text from other types
                    let inlineElements = parseLineForInlineLatex(line: line)
                    elements.append(contentsOf: inlineElements)
                }
            }
        }

        finalizeParsing() // combineTextLinesIfNeeded() inside finalizeParsing might be redundant or needs care
        // After the loop, ensure any pending multi-line text elements are combined.
        // However, parseLineForInlineLatex should handle line-by-line emissions.
        // The existing combineTextLinesIfNeeded() is problematic with the new approach.
        // Let's remove it from finalizeParsing and rely on flushing text before other blocks.
        // And the new text handling within the .text case.

        // We need to rethink how `combineTextLinesIfNeeded` is used.
        // The new `parseLineForInlineLatex` emits elements directly.
        // `textLines` array is now largely bypassed for the .text case.
        // It's still used if a text line comes from image fallback or similar.

        // Let's ensure `combineTextLinesIfNeeded` is called before processing any non-text block,
        // and before calling `parseLineForInlineLatex` if `textLines` could have content.
        // The current loop structure calls combineTextLinesIfNeeded() before most other block types,
        // which is good.

        // The `combineTextLinesIfNeeded` in `finalizeParsing` should be okay
        // if `textLines` is only used for exceptional cases now.
        // But if `parseLineForInlineLatex` always processes `.text` lines, `textLines`
        // should ideally be empty when `finalizeParsing` is called, unless there are other
        // paths that still add to `textLines`.

        // Let's review `combineTextLinesIfNeeded` calls.
        // It's called before:
        // - .codeBlock
        // - .table (indirectly via handleTableLine)
        // - .formulaBlock
        // - .formulaLine
        // - .thinking (if <think> is the start)
        // - .imageUUID (if image loads)

        // In the .text case:
        // `combineTextLinesIfNeeded()` is called, then `parseLineForInlineLatex`.
        // This means any old `textLines` are flushed, then the current line is parsed. This is correct.

        return elements
    }
}
