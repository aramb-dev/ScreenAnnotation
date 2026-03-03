import Cocoa

class TextAnnotation: Identifiable {
    let id = UUID()
    var text: String
    var position: CGPoint
    var font: NSFont
    var color: NSColor
    var alignment: NSTextAlignment
    var isBold: Bool
    var isItalic: Bool
    var bounds: CGRect
    
    init(text: String = "", position: CGPoint, font: NSFont = .systemFont(ofSize: 16), color: NSColor = .black) {
        self.text = text
        self.position = position
        self.font = font
        self.color = color
        self.alignment = .left
        self.isBold = false
        self.isItalic = false
        self.bounds = CGRect(origin: position, size: CGSize(width: 200, height: 30))
    }
    
    var effectiveFont: NSFont {
        var traits: NSFontTraitMask = []
        if isBold { traits.insert(.boldFontMask) }
        if isItalic { traits.insert(.italicFontMask) }
        
        if !traits.isEmpty {
            return NSFontManager.shared.convert(font, toHaveTrait: traits)
        }
        return font
    }
    
    var attributedString: NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        return NSAttributedString(
            string: text,
            attributes: [
                .font: effectiveFont,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
        )
    }
    
    func render(in context: CGContext) {
        let attrString = attributedString
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let framePath = CGPath(rect: bounds, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), framePath, nil)

        context.saveGState()

        // CoreText uses Y-up coordinates. When drawing in a flipped view,
        // we need to flip the context around the text bounds, draw, then restore.
        context.translateBy(x: bounds.origin.x, y: bounds.origin.y + bounds.height)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)

        CTFrameDraw(frame, context)
        context.restoreGState()
    }
}
