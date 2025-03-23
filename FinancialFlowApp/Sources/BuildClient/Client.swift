//
//  Client.swift
//
//
//  Created by Ibrahim Koteish on 9/5/24.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct BuildClient: Sendable {

  /// Value under *CFBundleVersion* key.
  ///
  /// The version of the build that identifies the *iteration* of the bundle.
  /// This key is a machine-readable string composed of one to three period
  /// separated integers, such as 10.14.1.
  /// The string can only contain numeric characters (0-9) and periods.
  public var buildNumber: @Sendable () -> String = { "" }

  /// Value under *CFBundleShortVersionString* key.
  ///
  /// The release or version number of the bundle.
  /// This key is a user-visible string for the *version* of the bundle.
  /// The required format is three period-separated integers, such as 10.14.1.
  /// The string can only contain numeric characters (0-9) and periods.
  public var buildVersion: @Sendable () -> String = { "" }
}

extension BuildClient: DependencyKey {
  public static var liveValue: BuildClient {
    let bundle = LockIsolated(Bundle.main)

    return BuildClient(
      buildNumber: {
        bundle.value.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""

      },
      buildVersion: {
        bundle.value.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
      }
    )
  }
}

public extension DependencyValues {
  var build: BuildClient {
    get { self[BuildClient.self] }
    set { self[BuildClient.self] = newValue }
  }
}
