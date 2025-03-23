import Dependencies
import UIKit

@available(iOSApplicationExtension, unavailable)
extension UIApplicationClient: DependencyKey {
  public static let liveValue = Self(
    setUserInterfaceStyle: { userInterfaceStyle in
      await MainActor.run {
        guard
          let scene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene })
          as? UIWindowScene
        else { return }
        scene.keyWindow?.overrideUserInterfaceStyle = userInterfaceStyle
      }
    },
    openSettings: { @MainActor in
      await UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
  )
}
