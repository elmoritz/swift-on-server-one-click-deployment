#!/usr/bin/env swift
import Foundation

// MARK: - Argument Parsing
guard CommandLine.arguments.count == 2 else {
    print("Usage: \(CommandLine.arguments[0]) <version_file>")
    exit(1)
}

let versionFile = CommandLine.arguments[1]

// MARK: - Read Version
guard FileManager.default.fileExists(atPath: versionFile) else {
    print("ERROR: VERSION file not found at \(versionFile)")
    exit(1)
}

do {
    let version = try String(contentsOfFile: versionFile, encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines)

    // Write to GitHub output
    if let githubOutput = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] {
        try "version=\(version)\n".write(toFile: githubOutput, atomically: true, encoding: .utf8)
    }

    // Print formatted output
    print("=========================================")
    print("Version Information")
    print("=========================================")
    print("Version: \(version)")
    print("Source:  \(versionFile)")
    print("=========================================")

} catch {
    print("ERROR: Failed to read version file: \(error)")
    exit(1)
}
