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

open class TokenSearchField: NSSearchField {

    public var tokenizableStemWords: [String] = [] {
        didSet {
            self.tokenFieldTextField.tokenizableStemWords = tokenizableStemWords
        }
    }

    public var tokenDelegate: (any TokenSearchFieldDelegate)? {
        get {
            return tokenFieldCell.tokenTextView.tokenDelegate
        }
        set {
            tokenFieldTextField.tokenDelegate = newValue
        }
    }

    private lazy var tokenFieldCell = {
        let tokenFieldCell = TokenSearchFieldCell()
        tokenFieldCell.tokenTextView.tokenizableStemWords = tokenizableStemWords
        return tokenFieldCell
    }()

    private var tokenFieldTextField: TokenTextView {
        return tokenFieldCell.tokenTextView
    }

    // MARK: Init

    public init(frame: CGRect, tokenizableStemWords: [String]) {
        super.init(frame: frame)
        self.tokenizableStemWords = tokenizableStemWords
        setupSearchField()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSearchField()
    }

    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setupSearchField()
    }

    // MARK: Styling

    private func setupSearchField() {
        self.cell = self.tokenFieldCell

        // Setting the cell requires resetting most of these properties so here we are.
        self.maximumNumberOfLines = 1
        self.isBordered = true
        self.drawsBackground = true
        self.backgroundColor = .controlBackgroundColor

        self.isBezeled = true
        self.bezelStyle = .squareBezel
        self.isEnabled = true

        self.isEditable = true
        self.isSelectable = true
        self.focusRingType = .default
        self.cell?.focusRingType = .default
    }

    // MARK: Adding and Removing Tokens

    public var tokens: [TokenSearchFieldToken] {
        return tokenFieldTextField.getAllTokens()
    }

    /// Get all tokens within a specific range
    public func tokens(in range: NSRange) -> [TokenSearchFieldToken] {
        return tokenFieldTextField.tokens(in: range)
    }

    public func replaceText(in range: NSRange, withToken token: TokenSearchFieldToken) {
        tokenFieldTextField.replaceTextInRange(range, withToken: token)
    }

    public func insertToken(_ token: TokenSearchFieldToken, at tokenIndex: Int) {
        tokenFieldTextField.insertTokenAtIndex(token, at: tokenIndex)
    }

    public func removeToken(at tokenIndex: Int) {
        tokenFieldTextField.removeTokenAtIndex(tokenIndex)
    }

    /// Add a token to the end of the token region
    public func appendToken(_ token: TokenSearchFieldToken) {
        let attachment = NSTextAttachment()
        attachment.attachmentCell = TokenAttachmentCell(token: token)
        tokenFieldTextField.appendToken(attachment: attachment)
    }

    /// Remove all tokens
    public func removeAllTokens() {
        let tokenCount = tokens.count
        for i in (0..<tokenCount).reversed() {
            removeToken(at: i)
        }
    }

    /// Get the current text (non-token) content
    public var textContent: String {
        get {
            return tokenFieldTextField.textContent
        }
        set {
            tokenFieldTextField.textContent = newValue
        }
    }
}

/// Details about the token
public struct TokenSearchFieldToken {

    /// An icon to display with the Token. If provided, it will show instead of the tagTitle.
    public var icon: NSImage?
    public var color: NSColor?

    public var representedObject: Any?

    public var tagTitle: String
    public var text: String

    public init(tagTitle: String, text: String, icon: NSImage?, color: NSColor? = nil, representedObject: Any? = nil) {
        self.icon = icon
        self.text = text
        self.representedObject = representedObject
        self.tagTitle = tagTitle
        self.color = color
    }
}

public protocol TokenSearchFieldDelegate {
    func tokenFromTokenizableText(stem: String, value: String) -> TokenSearchFieldToken?
}
