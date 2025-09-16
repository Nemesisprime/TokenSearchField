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

public class TokenSearchField: NSSearchField {

    public var tokenizableStemWords: [String] = [] {
        didSet {
            self.tokenFieldTextField.tokenizableStemWords = tokenizableStemWords
        }
    }

    var tokenDelegate: (any TokenSearchFieldDelegate)? {
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
    
    var tokens: [TokenSearchFieldToken] {
        return []
    }

    public func replaceText(in range: NSRange, withToken token: TokenSearchFieldToken) {
        
    }

    public func insertToken(_ token: TokenSearchFieldToken, at tokenIndex: Int) {

    }

    public func removeToken(at tokenIndex: Int) {

    }
}

/// Details about the token
public class TokenSearchFieldToken {

    /// An icon to display with the Token. If provided, it will show instead of the tagTitle.
    var icon: NSImage?

    var representedObject: Any?

    var tagTitle: String
    var text: String

    init(icon: NSImage?, tagTitle: String, text: String, representedObject: Any? = nil) {
        self.icon = icon
        self.text = text
        self.representedObject = representedObject
        self.tagTitle = tagTitle
    }
}

public protocol TokenSearchFieldDelegate {
    func tokenFromTokenizableText(tokenizableText: String) -> TokenSearchFieldToken?
}
