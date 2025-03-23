import Foundation
import PackagePlugin

// MARK: - RunSource

public enum RunSource {
    case commandLine
    case xcode
}

extension CommandPlugin {
    func formatCode(
        in directory: PackagePlugin.Path,
        context: PluginToolProviding,
        arguments: [String],
        source: RunSource) throws {
        let tool = try context.tool(named: "swiftformat")
        let toolURL = URL(fileURLWithPath: tool.path.string)


        var processArguments: [String] = []
        processArguments.reserveCapacity(1)
        switch source {
        case .commandLine:
            processArguments.append(directory.removingLastComponent().string)

        case .xcode:
            processArguments.append(directory.string)
        }
        print("MYYYYYY", processArguments)
        processArguments.append(contentsOf: arguments)

        let process = Process()
        process.executableURL = toolURL
        process.arguments = processArguments

        try process.run()
        process.waitUntilExit()

        if process.terminationReason == .exit, process.terminationStatus == 0 {
            print("Formatted the source code in \(directory.string).")
        } else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("swiftformat invocation failed: \(problem)")
        }
    }
}
