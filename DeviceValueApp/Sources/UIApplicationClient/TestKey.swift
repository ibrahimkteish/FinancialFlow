import Dependencies

public extension DependencyValues {
  var applicationClient: UIApplicationClient {
    get { self[UIApplicationClient.self] }
    set { self[UIApplicationClient.self] = newValue }
  }
}

extension UIApplicationClient: TestDependencyKey {
  public static let previewValue = Self.noop
  public static let testValue = Self()
}

public extension UIApplicationClient {
  static let noop = Self(
    setUserInterfaceStyle: { _ in },
    openSettings: { @MainActor in }
  )
}
