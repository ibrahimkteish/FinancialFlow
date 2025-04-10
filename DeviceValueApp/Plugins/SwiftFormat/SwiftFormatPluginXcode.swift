import Foundation
import PackagePlugin

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftFormatPlugin: XcodeCommandPlugin {
    /// This entry point is called when operating on an Xcode project.
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        if arguments.contains("--verbose") {
            print("Command plugin execution with arguments \(arguments.description) for Swift package \(context.xcodeProject.displayName). All target information: \(context.xcodeProject.targets.description)")
            print("Plugin will run for directory: \(context.xcodeProject.directory.description)")
        }

        var argExtractor = ArgumentExtractor(arguments)
        _ = argExtractor.extractOption(named: "target")

        try formatCode(
            in: context.xcodeProject.directory,
            context: context,
            arguments: argExtractor.remainingArguments,
            source: .xcode)
    }
}
#endif

