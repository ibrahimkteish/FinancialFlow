import Foundation
import IdentifiedCollections

struct Acknowledgement: Identifiable, Equatable {
  let name: String
  let url: URL

  var id: String { self.name }
}

extension IdentifiedArrayOf<Acknowledgement> {
  static let acknowledgements: Self = [
    .init(
      name: "The Composable Architecture",
      url: URL(string: "https://github.com/pointfreeco/swift-composable-architecture")!
    ),
    .init(
      name: "Swift Dependencies",
      url: URL(string: "https://github.com/pointfreeco/swift-dependencies")!
    ),
    .init(
      name: "GRDB",
      url: URL(string: "https://github.com/groue/GRDB.swift")!
    ),
    .init(
      name: "Sharing GRDB",
      url: URL(string: "https://github.com/pointfreeco/sharing-grdb")!
    )
  ]
}
