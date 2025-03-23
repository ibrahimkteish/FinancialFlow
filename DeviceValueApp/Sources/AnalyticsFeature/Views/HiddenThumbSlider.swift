import SwiftUI
import UIKit

/// A custom slider that hides the thumb (ball) by using a transparent image.
struct HiddenThumbSlider: UIViewRepresentable {
  var value: Double
  var range: ClosedRange<Double>
  var accentColor: UIColor

  func makeUIView(context: Context) -> UISlider {
    let slider = UISlider(frame: .zero)
    slider.minimumValue = Float(self.range.lowerBound)
    slider.maximumValue = Float(self.range.upperBound)
    slider.value = Float(self.value)
    // Hide the thumb by setting an empty image
    slider.setThumbImage(UIImage(), for: .normal)
    slider.setThumbImage(UIImage(), for: .highlighted)
    slider.isUserInteractionEnabled = false
    slider.minimumTrackTintColor = self.accentColor
    slider.maximumTrackTintColor = UIColor.systemGray4
    return slider
  }

  func updateUIView(_ uiView: UISlider, context: Context) {
    uiView.value = Float(self.value)
    uiView.minimumTrackTintColor = self.accentColor
  }
}

#Preview(traits: .sizeThatFitsLayout) {
  HiddenThumbSlider(value: 50, range: 0 ... 100, accentColor: .green)
    .padding()
}
