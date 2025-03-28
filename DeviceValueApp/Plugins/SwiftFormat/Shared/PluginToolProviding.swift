import Foundation
import PackagePlugin

// MARK: - PluginToolProviding

protocol PluginToolProviding {
    func tool(named name: String) throws -> PackagePlugin.PluginContext.Tool
}

// MARK: - PluginContext + PluginToolProviding

extension PluginContext: PluginToolProviding { }

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension XcodePluginContext: PluginToolProviding { }
#endif
