import Cocoa

/// A placed signature image on the canvas.
class SignatureAnnotation: Identifiable {
  let id = UUID()
  var image: NSImage
  var frame: CGRect

  init(image: NSImage, frame: CGRect) {
    self.image = image
    self.frame = frame
  }

  func deepCopy() -> SignatureAnnotation {
    return SignatureAnnotation(image: image.copy() as? NSImage ?? image, frame: frame)
  }
}
