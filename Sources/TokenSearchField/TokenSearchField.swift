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

    /// The font tokens are sized and drawn from. Defaults to 13pt (the original
    /// fixed sizing). Set a larger value to match a larger field font.
    public var tokenFont: NSFont = .systemFont(ofSize: 13) {
        didSet {
            self.tokenFieldTextField.baseFont = tokenFont
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

    /// Removes every token attachment falling within `range` (used to drop a
    /// selected token when replacing it with a refined one).
    public func removeTokens(in range: NSRange) {
        tokenFieldTextField.removeTokens(in: range)
    }

    /// Add a token to the end of the token region
    public func appendToken(_ token: TokenSearchFieldToken) {
        let attachment = NSTextAttachment()
        let cell = TokenAttachmentCell(token: token)
        cell.baseFont = tokenFont
        attachment.attachmentCell = cell
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

    /// How a token is rendered.
    public enum Style {
        /// The default split capsule: a colored title/icon side and a lighter
        /// value side (e.g. `tag — VLAN`, `Text — hero`). Used for typed tokens.
        case twoSided
        /// A single-colored pill of just an icon + name, matching the tag chips.
        /// Used to drop an actual tag into the field alongside typed tokens.
        case simple
    }

    public var style: Style

    /// An icon to display with the Token. If provided, it will show instead of the tagTitle.
    public var icon: NSImage?
    public var color: NSColor?

    public var representedObject: Any?

    public var tagTitle: String
    public var text: String

    public init(tagTitle: String, text: String, icon: NSImage?, color: NSColor? = nil, representedObject: Any? = nil, style: Style = .twoSided) {
        self.icon = icon
        self.text = text
        self.representedObject = representedObject
        self.tagTitle = tagTitle
        self.color = color
        self.style = style
    }

    /// Convenience for a single-pill tag token (icon + name).
    public static func simpleTag(name: String, icon: NSImage?, color: NSColor?, representedObject: Any? = nil) -> TokenSearchFieldToken {
        TokenSearchFieldToken(tagTitle: "", text: name, icon: icon, color: color, representedObject: representedObject, style: .simple)
    }
}

public protocol TokenSearchFieldDelegate {
    func tokenFromTokenizableText(stem: String, value: String) -> TokenSearchFieldToken?

    /// Fired whenever the field editor's selection changes, reporting the tokens
    /// (if any) covered by the current selection. Hosts use this to react to a
    /// token being highlighted — e.g. surfacing that token's options.
    func tokenSelectionDidChange(selectedTokens: [TokenSearchFieldToken])
}

public extension TokenSearchFieldDelegate {
    // Optional by default — hosts that don't care about selection can ignore it.
    func tokenSelectionDidChange(selectedTokens: [TokenSearchFieldToken]) {}
}
