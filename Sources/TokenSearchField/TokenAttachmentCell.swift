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

class TokenAttachmentCell: NSTextAttachmentCell {

    let cellMarginSide: CGFloat = 4.0
    let cellDivider: CGFloat = 0.5
    var cellTitleString: String
    var token: TokenSearchFieldToken?

    /// The font tokens are sized and drawn from. The value text uses it
    /// directly; the title, icon, and baseline derive from it proportionally.
    /// Defaults to 13pt, which reproduces the original fixed sizing.
    var baseFont: NSFont = .systemFont(ofSize: 13)

    /// Corner radius of the token capsule. Defaults to 5 to match the tag chips.
    var cornerRadius: CGFloat = 5

    private var valueFont: NSFont { .systemFont(ofSize: (baseFont.pointSize * 0.82).rounded()) }
    private var titleFont: NSFont { .systemFont(ofSize: max(7, (baseFont.pointSize * 0.6).rounded()), weight: .medium) }
    private var iconSize: CGFloat { (baseFont.pointSize * 0.72).rounded() }

    private var isSimple: Bool { token?.style == .simple }
    private let iconTextGap: CGFloat = 4.0

    /// Extra height above and below the value text, giving the capsule some
    /// breathing room so the text reads as vertically centered.
    private let verticalPadding: CGFloat = 3.0

    // Original constructor for backwards compatibility
    init(cellTitle: String, cellValue: String) {
        cellTitleString = cellTitle.uppercased()
        super.init(textCell: cellValue)
    }

    // New constructor for TokenSearchFieldToken
    init(token: TokenSearchFieldToken) {
        self.token = token
        cellTitleString = token.tagTitle.uppercased()
        super.init(textCell: token.text)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var cellSize: NSSize {
        if isSimple { return simpleCellSize() }

        let paddingHorizontal: CGFloat = 4.0

        let titleSize = NSSize(
            width: (cellTitleSize().width + cellValueSize().width) + cellDivider + paddingHorizontal,
            height: cellValueSize().height + (verticalPadding * 2))

        return titleSize
    }

    private func simpleCellSize() -> NSSize {
        let textSize = stringValue.size(withAttributes: [NSAttributedString.Key.font: valueFont])
        let iconPart: CGFloat = (token?.icon != nil) ? (iconSize + iconTextGap) : 0
        let horizontalPadding = (cellMarginSide + 2) * 2
        return NSSize(
            width: horizontalPadding + iconPart + textSize.width,
            height: cellValueSize().height + (verticalPadding * 2)
        )
    }

    func cellTitleSize() -> NSSize {
        if self.token?.icon != nil {
            return CGSize(width: self.iconSize + (cellMarginSide * 2), height: self.iconSize)
        } else {

            let titleStringSize: NSSize = cellTitleString.size(withAttributes: [
                NSAttributedString.Key.font: titleFont
            ])

            return NSSize(
                width: titleStringSize.width + (cellMarginSide * 2),
                height: titleStringSize.height
            )
        }
    }

    func cellValueSize() -> NSSize {
        let valueStringSize: NSSize = stringValue.size(withAttributes: [
            NSAttributedString.Key.font: valueFont
        ])

        return NSSize(
            width: valueStringSize.width + (cellMarginSide * 3),
            height: valueStringSize.height
        )
    }

    override func cellBaselineOffset() -> NSPoint {
        // Center the capsule on the line's cap height so the token sits level
        // with adjacent typed text.
        return NSPoint(x: 0.0, y: (baseFont.capHeight / 2) - (cellSize.height / 2))
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        if isSimple {
            drawSimpleToken(withFrame: cellFrame)
            return
        }

        // Use custom color if available, otherwise use default colors
        var titleBackgroundColor: NSColor
        var valueBackgroundColor: NSColor

        if let customColor = token?.color {
            titleBackgroundColor = customColor.withAlphaComponent(0.8)
            valueBackgroundColor = customColor.withAlphaComponent(0.3)
        } else {
            titleBackgroundColor = NSColor.tokenTitleColor
            valueBackgroundColor = NSColor.tokenValueColor
        }

        if isHighlighted {
            titleBackgroundColor = NSColor(red: 0.62, green: 0.63, blue: 0.64, alpha: 1.0)
            valueBackgroundColor = NSColor(red: 0.62, green: 0.63, blue: 0.64, alpha: 1.0)
        }

        titleBackgroundColor.set()

        let tokenTitlePath: NSBezierPath = tokenTitlePathForBounds(bounds: cellFrame)

        NSGraphicsContext.current?.saveGraphicsState()

        tokenTitlePath.addClip()
        tokenTitlePath.fill()

        NSGraphicsContext.current?.restoreGraphicsState()

        valueBackgroundColor.set()

        NSGraphicsContext.current?.saveGraphicsState()

        let tokenValuePath: NSBezierPath = tokenValuePathForBounds(bounds: cellFrame)
        tokenValuePath.addClip()
        tokenValuePath.fill()

        NSGraphicsContext.current?.restoreGraphicsState()

        let textColor: NSColor = {
            if isHighlighted {
                return NSColor.white
            } else {
                return NSColor.labelColor
            }
        }()

        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byClipping

        // Draw icon if present (for new token model)
        var titleDrawingX = cellFrame.origin.x + cellMarginSide
        if let icon = token?.icon {
            let iconRect = NSRect(
                x: titleDrawingX,
                y: cellFrame.origin.y + (cellFrame.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )

            let tintedIcon = icon.tinted(with: NSColor.white)
            tintedIcon.draw(in: iconRect)
            titleDrawingX += iconSize
        } else {
            let titleSize = cellTitleString.size(withAttributes: [NSAttributedString.Key.font: titleFont])
            cellTitleString.draw(at: CGPoint(
                x: titleDrawingX,
                y: cellFrame.origin.y + (cellFrame.height - titleSize.height) / 2),
                                 withAttributes: [
                                    NSAttributedString.Key.font: titleFont,
                                    NSAttributedString.Key.foregroundColor: textColor,
                                    NSAttributedString.Key.paragraphStyle: paragraphStyle
                                 ])
        }

        let valueSize = stringValue.size(withAttributes: [NSAttributedString.Key.font: valueFont])
        stringValue.draw(at: CGPoint(
            x: cellFrame.origin.x + cellTitleSize().width + 0.5 + cellMarginSide + 2.0,
            y: cellFrame.origin.y + (cellFrame.height - valueSize.height) / 2),
                         withAttributes: [
                            NSAttributedString.Key.font: valueFont,
                            NSAttributedString.Key.foregroundColor: textColor,
                            NSAttributedString.Key.paragraphStyle: paragraphStyle
                         ])
    }

    /// Renders a single-pill tag token: one rounded, lightly-colored capsule
    /// with a color-tinted icon and the tag name.
    private func drawSimpleToken(withFrame cellFrame: NSRect) {
        let tokenColor = token?.color ?? NSColor.tokenValueColor
        var background = tokenColor.withAlphaComponent(0.2)
        var textColor = NSColor.labelColor
        var iconTint = token?.color ?? NSColor.labelColor

        if isHighlighted {
            background = NSColor(red: 0.62, green: 0.63, blue: 0.64, alpha: 1.0)
            textColor = .white
            iconTint = .white
        }

        let rect = NSRect(
            x: cellFrame.origin.x,
            y: cellFrame.origin.y + 0.5,
            width: cellFrame.width,
            height: cellFrame.height - 0.5
        )
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        background.set()
        path.fill()

        var textX = cellFrame.origin.x + (cellMarginSide + 2)
        if let icon = token?.icon {
            let iconRect = NSRect(
                x: textX,
                y: cellFrame.origin.y + (cellFrame.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            icon.tinted(with: iconTint).draw(in: iconRect)
            textX += iconSize + iconTextGap
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byClipping
        let textSize = stringValue.size(withAttributes: [NSAttributedString.Key.font: valueFont])
        stringValue.draw(
            at: CGPoint(x: textX, y: cellFrame.origin.y + (cellFrame.height - textSize.height) / 2),
            withAttributes: [
                NSAttributedString.Key.font: valueFont,
                NSAttributedString.Key.foregroundColor: textColor,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
        )
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?,
                       characterIndex charIndex: Int, layoutManager: NSLayoutManager) {
        draw(withFrame: cellFrame, in: controlView)
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?,
                       characterIndex charIndex: Int) {
        if let textField = controlView as? NSSearchField {
            print(textField.currentEditor()?.selectedRange ?? [])
        }

        draw(withFrame: cellFrame, in: controlView)
    }

    func tokenTitlePathForBounds(bounds: NSRect) -> NSBezierPath {
        let titleBoundsRect: NSRect = NSRect(
            x: bounds.origin.x,
            y: bounds.origin.y,
            width: cellTitleSize().width,
            height: bounds.size.height)

        let xMin: CGFloat = titleBoundsRect.minX
        let xMax: CGFloat = titleBoundsRect.maxX

        let yMin: CGFloat = titleBoundsRect.minY + 0.5
        let yMax: CGFloat = titleBoundsRect.maxY

        let path: NSBezierPath = NSBezierPath()

        path.move(to: NSPoint(x: xMax, y: yMin))
        path.line(to: NSPoint(x: xMax, y: yMax))

        path.appendArc(
            withCenter: NSPoint(x: xMin + cornerRadius, y: yMax - cornerRadius),
            radius: cornerRadius,
            startAngle: 90,
            endAngle: 180,
            clockwise: false
        )

        path.appendArc(
            withCenter: NSPoint(x: xMin + cornerRadius, y: yMin + cornerRadius),
            radius: cornerRadius,
            startAngle: 180,
            endAngle: 270,
            clockwise: false
        )
        path.close()

        return path
    }

    func tokenValuePathForBounds(bounds: NSRect) -> NSBezierPath {
        let valueBoundsRect: NSRect = NSRect(
            x: bounds.origin.x + (cellTitleSize().width + 1),
            y: bounds.origin.y,
            width: cellValueSize().width,
            height: bounds.size.height)

        let xMin: CGFloat = valueBoundsRect.minX
        let xMax: CGFloat = valueBoundsRect.maxX

        let yMin: CGFloat = valueBoundsRect.minY + 0.5
        let yMax: CGFloat = valueBoundsRect.maxY

        let path: NSBezierPath = NSBezierPath()

        path.move(to: NSPoint(x: xMin, y: yMin))
        path.line(to: NSPoint(x: xMin, y: yMax))

        path.appendArc(
            withCenter: NSPoint(x: xMax - cornerRadius, y: yMax - cornerRadius),
            radius: cornerRadius,
            startAngle: 90,
            endAngle: 0,
            clockwise: true
        )

        path.appendArc(
            withCenter: NSPoint(x: xMax - cornerRadius, y: yMin + cornerRadius),
            radius: cornerRadius,
            startAngle: 0,
            endAngle: 270,
            clockwise: true
        )
        path.close()

        return path
    }

    override func wantsToTrackMouse() -> Bool {
        return true
    }

    override func wantsToTrackMouse(for theEvent: NSEvent,
                                    in cellFrame: NSRect,
                                    of controlView: NSView?,
                                    atCharacterIndex charIndex: Int) -> Bool {
        return true
    }

    override func trackMouse(with theEvent: NSEvent,
                             in cellFrame: NSRect,
                             of controlView: NSView?,
                             atCharacterIndex charIndex: Int,
                             untilMouseUp flag: Bool) -> Bool {

        let value: [NSValue] = [NSRange(location: charIndex, length: 1) as NSValue]
        (controlView as? TokenTextView)?.selectedRanges = value

        return theEvent.type == NSEvent.EventType.leftMouseDown
    }

    override func trackMouse(with theEvent: NSEvent,
                             in cellFrame: NSRect,
                             of controlView: NSView?,
                             untilMouseUp flag: Bool) -> Bool {
        return true
    }
}


// MARK: - Utilities

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let tintedImage = NSImage(size: self.size)

        tintedImage.lockFocus()

        // Draw the original image
        self.draw(in: NSRect(origin: .zero, size: self.size))

        // Apply the tint color using sourceAtop blend mode
        color.setFill()
        NSRect(origin: .zero, size: self.size).fill(using: .sourceAtop)

        tintedImage.unlockFocus()

        return tintedImage
    }
}

extension NSColor {

    @objc static var tokenTitleColor: NSColor {
        if #available(macOS 14, *) {
            return NSColor.systemFill
        } else {
            return NSColor(name: "SystemFillPolyfill") { appearance in
                switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
                case .darkAqua:
                    return NSColor(red: 0.294, green: 0.294, blue: 0.306, alpha: 1.0)
                default:
                    return NSColor(red: 0.894, green: 0.894, blue: 0.902, alpha: 1.0)
                }
            }
        }
    }

    @objc static var tokenValueColor: NSColor {
        if #available(macOS 14, *) {
            return NSColor.tertiarySystemFill
        } else {
            return NSColor(name: "SecondarySystemFillPolyfill") { appearance in
                switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
                case .darkAqua:
                    return NSColor(red: 0.259, green: 0.259, blue: 0.271, alpha: 1.0)
                default:
                    return NSColor(red: 0.933, green: 0.933, blue: 0.937, alpha: 1.0)
                }
            }
        }
    }
}
