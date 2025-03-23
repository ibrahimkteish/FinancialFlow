import DependenciesMacros
import UIKit

@DependencyClient
public struct UIApplicationClient: Sendable {
  public var setUserInterfaceStyle: @Sendable (UIUserInterfaceStyle) async -> Void
  public var openSettings: @Sendable () async -> Void
}
