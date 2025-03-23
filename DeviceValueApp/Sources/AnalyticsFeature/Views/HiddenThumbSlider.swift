import SwiftUI
import UIKit

/// A custom slider that hides the thumb (ball) by using a transparent image.
struct HiddenThumbSlider: UIViewRepresentable {
    var value: Double
    var range: ClosedRange<Double>
    var accentColor: UIColor

    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider(frame: .zero)
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
        // Hide the thumb by setting an empty image
        slider.setThumbImage(UIImage(), for: .normal)
        slider.setThumbImage(UIImage(), for: .highlighted)
        slider.isUserInteractionEnabled = false
        slider.minimumTrackTintColor = accentColor
        slider.maximumTrackTintColor = UIColor.systemGray4
        return slider
    }

    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = Float(value)
        uiView.minimumTrackTintColor = accentColor
    }
}

#Preview(traits: .sizeThatFitsLayout) {
  HiddenThumbSlider(value: 50, range: 0...100, accentColor: .green)
    .padding()
} 
