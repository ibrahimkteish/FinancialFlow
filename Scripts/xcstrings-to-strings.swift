#!/usr/bin/env swift


import Foundation

let arguments = CommandLine.arguments

if arguments.count < 3 {
    print("Usage: xcstrings-to-strings <input.xcstrings> <output.strings>")
} else {
  do {
    let inputPath = arguments[1]
    let outputPath = arguments[2]
    try convertXCStringsToStrings(inputPath: inputPath, outputPath: outputPath)

    print("Conversion complete: \(outputPath)")
  } catch {
    print("Failed to convert xcstrings to strings: \(error)")
  }
}

func convertXCStringsToStrings(inputPath: String, outputPath: String) throws {
  let inputURL = URL(fileURLWithPath: inputPath)
  let outputURL = URL(fileURLWithPath: outputPath)
  let outputDirectory = outputURL.deletingLastPathComponent()

  let data = try Data(contentsOf: inputURL)

  guard
    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
    let strings = json["strings"] as? [String: Any]
  else {
    print("Failed to read or parse \(inputPath)")
    return
  }

  let sourceLanguage = (json["sourceLanguage"] as? String) ?? "en"
  print("Source language: \(sourceLanguage)")

  var result = ""
  for (key, value) in strings.sorted(by: { $0.key < $1.key }) {
    guard
      let details = value as? [String: Any],
      let localizations = details["localizations"] as? [String: Any],
      let enLocalization = localizations[sourceLanguage] as? [String: Any],
      let stringUnit = enLocalization["stringUnit"] as? [String: Any],
      let translation = stringUnit["value"] as? String
    else {
      print("Failed to parse \(key) in \(inputPath)")
      continue
    }

    result += "\"\(key)\" = \"\(translation.escaped)\";\n"
    
  }

    // Ensure output directory exists
  if !FileManager.default.fileExists(atPath: outputDirectory.path) {
    do {
      try FileManager.default.createDirectory(
        at: outputDirectory,
        withIntermediateDirectories: true,
        attributes: nil
      )
      print("📁 Created directory: \(outputDirectory.path)")
    } catch {
      print("❌ Error: Failed to create directory \(outputDirectory.path)")
      return
    }
  }

  try result.write(to: outputURL, atomically: true, encoding: .utf8)
  print("Conversion complete: \(outputPath)")
}

extension String {
  var escaped: String {
    self
      .replacingOccurrences(of: "\\", with: "\\\\")  // Escape backslash first!
      .replacingOccurrences(of: "\"", with: "\\\"")  // Escape double quotes
      .replacingOccurrences(of: "\n", with: "\\n")   // Escape new lines
      .replacingOccurrences(of: "\t", with: "\\t")   // Escape tab characters
      .replacingOccurrences(of: "\r", with: "\\r")   // Escape carriage returns
  }
}