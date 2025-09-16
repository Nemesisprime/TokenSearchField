/*
 MIT License

 Copyright (c) 2016 Crosscoded (Kit Cross)

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/
import Cocoa

class TokenTextView: NSTextView {

    var tokenDelegate: (any TokenSearchFieldDelegate)?

    /// Stem words which will cause the creation of a token
    var tokenizableStemWords: [String] = []

    /// The characters that will trigger the auto-creation of a token.
    var tokenizingCharacterSet: CharacterSet = CharacterSet.newlines

    convenience init(tokenizableStemWords: [String] = []) {
        self.init()
        self.tokenizableStemWords = tokenizableStemWords
    }


    // MARK: - Token Position Management

    /// Returns the range where all tokens are located (from start to end of last token)
    private var tokenRegion: NSRange {
        guard let textStorage = self.textStorage else {
            return NSRange(location: 0, length: 0)
        }

        var lastTokenEnd = 0

        textStorage.enumerateAttribute(
            NSAttributedString.Key.attachment,
            in: NSRange(location: 0, length: textStorage.length),
            options: []
        ) { (value, range, stop) in
            if value is NSTextAttachment {
                lastTokenEnd = max(lastTokenEnd, NSMaxRange(range))
            }
        }

        return NSRange(location: 0, length: lastTokenEnd)
    }

    /// Returns the range where text (non-tokens) should be located
    private var textRegion: NSRange {
        guard let textStorage = self.textStorage else {
            return NSRange(location: 0, length: 0)
        }

        let tokenRegion = self.tokenRegion
        let textStart = tokenRegion.length
        let textLength = textStorage.length - textStart

        return NSRange(location: textStart, length: textLength)
    }

    /// Ensures tokens are contiguous at the beginning by reorganizing the attributed string
    private func enforceTokenContiguity() {
        guard let textStorage = self.textStorage else { return }

        let fullRange = NSRange(location: 0, length: textStorage.length)
        let attributedString = textStorage.attributedSubstring(from: fullRange)

        let tokens = NSMutableAttributedString()
        let text = NSMutableAttributedString()

        // Separate tokens from text
        attributedString.enumerateAttribute(
            NSAttributedString.Key.attachment,
            in: fullRange,
            options: []
        ) { (value, range, stop) in
            let substring = attributedString.attributedSubstring(from: range)

            if value is NSTextAttachment {
                tokens.append(substring)
            } else {
                text.append(substring)
            }
        }

        // Rebuild with tokens first, then text
        let reorganized = NSMutableAttributedString()
        reorganized.append(tokens)
        reorganized.append(text)

        // Replace the content
        textStorage.replaceCharacters(in: fullRange, with: reorganized)
    }


    // MARK: - Token Creation (Modified)

    func makeToken(with event: NSEvent) {
        guard let textStorage = textStorage else { return }
        let textString = textStorage.string

        // Search for tokenizable text in the entire string
        if let tokenRange = rangeOfTokenString(string: textString) {
            let textStringNew = textString as NSString
            let subString = textStringNew.substring(with: tokenRange)
            let (cellTitle, cellValue) = tokenComponents(string: subString)

            guard let cellTitle = cellTitle else { return }

            let attachment = NSTextAttachment()
            attachment.attachmentCell = TokenAttachmentCell(cellTitle: cellTitle, cellValue: cellValue!)

            let tokenString = NSMutableAttributedString(attachment: attachment)
            tokenString.addAttributes([
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 13)
            ], range: NSRange(location: 0, length: tokenString.length))

            // Remove the original tokenizable text from wherever it was found
            textStorage.replaceCharacters(in: tokenRange, with: NSAttributedString(string: ""))

            // Add the token at the end of the token region
            let currentTokenRegion = self.tokenRegion
            let insertionPoint = currentTokenRegion.length
            textStorage.replaceCharacters(in: NSRange(location: insertionPoint, length: 0), with: tokenString)

            // Clean up any extra spaces that might be left behind
            cleanupExtraSpaces()
        }
    }

    /// Removes extra consecutive spaces that might be left after token extraction
    private func cleanupExtraSpaces() {
        guard let textStorage = textStorage else { return }

        let tokenRegion = self.tokenRegion
        let textRange = NSRange(location: tokenRegion.length, length: textStorage.length - tokenRegion.length)

        if textRange.length > 0 {
            let textPortion = textStorage.attributedSubstring(from: textRange)
            let cleanedText = textPortion.string.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            let cleanedAttributedString = NSAttributedString(string: cleanedText, attributes: textPortion.attributes(at: 0, effectiveRange: nil))
            textStorage.replaceCharacters(in: textRange, with: cleanedAttributedString)
        }
    }


    // MARK: - Text Input Override

    override func insertText(_ string: Any, replacementRange: NSRange) {
        let insertionRange = replacementRange.location == NSNotFound ? selectedRange() : replacementRange
        let tokenRegion = self.tokenRegion

        // If trying to insert text within the token region, move it to after tokens
        if NSLocationInRange(insertionRange.location, tokenRegion) {
            let textStart = tokenRegion.length
            let newRange = NSRange(location: textStart, length: 0)
            super.insertText(string, replacementRange: newRange)
        } else {
            super.insertText(string, replacementRange: insertionRange)
        }
    }

    override func setSelectedRange(_ charRange: NSRange) {
        let tokenRegion = self.tokenRegion

        // Don't allow cursor placement within token region for text editing
        if charRange.length == 0 && NSLocationInRange(charRange.location, tokenRegion) {
            // Move cursor to start of text region
            let textStart = tokenRegion.length
            super.setSelectedRange(NSRange(location: textStart, length: 0))
        } else {
            super.setSelectedRange(charRange)
        }
    }


    // MARK: - Token Management

    public func insertToken(attachment: NSTextAttachment, range: NSRange) {
        let replacementString = NSAttributedString(attachment: attachment)

        var rect = firstRect(forCharacterRange: range, actualRange: nil)
        rect = (window?.convertFromScreen(rect))!
        rect.origin = convert(rect.origin, to: nil)

        textStorage?.replaceCharacters(in: range, with: replacementString)
        enforceTokenContiguity()
    }

    /// Add a token at the end of the token region
    public func appendToken(attachment: NSTextAttachment) {
        let tokenRegion = self.tokenRegion
        let insertionPoint = tokenRegion.length

        let replacementString = NSAttributedString(attachment: attachment)
        textStorage?.replaceCharacters(in: NSRange(location: insertionPoint, length: 0), with: replacementString)
    }


    // MARK: - Existing Methods (Unchanged)

    private func setHighlightedAtRanges(_ ranges: [NSRange], newHighlight: Bool) {
        guard let textStorage = self.textStorage else { return }

        for range in ranges {
            let intersection = NSIntersectionRange(NSMakeRange(0, textStorage.length), range)

            if intersection.length == 0 { continue }

            textStorage.enumerateAttribute(
                NSAttributedString.Key.attachment,
                in: intersection,
                options: NSAttributedString.EnumerationOptions()
            ) { (value: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                if let cell = (value as? NSTextAttachment)?.attachmentCell {
                    if let tokenSearchField = (cell.attachment?.attachmentCell as? TokenAttachmentCell) {
                        tokenSearchField.isHighlighted = newHighlight
                    }
                }
            }
        }
    }

    override func setSelectedRanges(_ ranges: [NSValue], affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        setHighlightedAtRanges((self.selectedRanges as! [NSRange]), newHighlight: false)
        setHighlightedAtRanges(ranges as! [NSRange], newHighlight: true)
        super.setSelectedRanges(ranges, affinity: affinity, stillSelecting: stillSelectingFlag)
    }

    func tokenComponents(string: String) -> (stem: String?, value: String?) {
        let stringComponents = string.components(separatedBy: ":").map { String($0) }
        let tokenStem = stringComponents.first?.trimmingCharacters(in: .whitespaces)
        let tokenValue = stringComponents.last?.trimmingCharacters(in: .whitespaces)
        return (tokenStem, tokenValue)
    }

    func rangeOfTokenString(string: String) -> NSRange? {
        let string = string as NSString

        for stem in self.tokenizableStemWords {
            let stemRange = string.range(of: stem)
            if stemRange.location != NSNotFound {
                return NSRange(
                    location: stemRange.location,
                    length: string.length - stemRange.location
                )
            }
        }
        return nil
    }

    override func keyDown(with event: NSEvent) {
        let index = event.characters?.startIndex
        if let characters = event.characters {
            let character = characters[index!]
            let stringOfCharacter = String(character)
            let scalars = stringOfCharacter.unicodeScalars
            let scalar = scalars[scalars.startIndex]

            if tokenizingCharacterSet.contains(scalar) {
                makeToken(with: event)
            } else {
                super.keyDown(with: event)
            }
        }
    }
}
