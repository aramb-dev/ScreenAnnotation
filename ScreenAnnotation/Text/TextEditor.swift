import Cocoa

/// Inline text editor overlay for text annotations.
class TextEditorView: NSTextField {
    
    var annotation: TextAnnotation?
    var onCommit: ((String) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isBordered = false
        drawsBackground = false
        isEditable = true
        isSelectable = true
        focusRingType = .none
        alignment = .left
        cell?.wraps = true
        cell?.isScrollable = false
    }
    
    func startEditing(annotation: TextAnnotation) {
        self.annotation = annotation
        self.frame = annotation.bounds
        self.font = annotation.effectiveFont
        self.textColor = annotation.color
        self.alignment = annotation.alignment
        self.stringValue = annotation.text
        
        isHidden = false
        window?.makeFirstResponder(self)
    }
    
    func commitEditing() {
        guard let annotation = annotation else { return }
        annotation.text = stringValue
        annotation.bounds = frame
        onCommit?(stringValue)
        
        isHidden = true
        self.annotation = nil
    }
    
    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        commitEditing()
    }
    
    override func cancelOperation(_ sender: Any?) {
        commitEditing()
    }
}
