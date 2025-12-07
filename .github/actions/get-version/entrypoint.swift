#!/usr/bin/env swift
import Foundation

// MARK: - GitHub Summary Helper
func updateSummary(_ message: String) {
    if let summaryPath = ProcessInfo.processInfo.environment["GITHUB_STEP_SUMMARY"] {
        let entry = message + "\n"
        if let data = entry.data(using: .utf8) {
            if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: summaryPath)) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            } else {
                try? entry.write(toFile: summaryPath, atomically: true, encoding: .utf8)
            }
        }
    }
}

// MARK: - Logging
func log(_ message: String) {
    print("[get-version] \(message)")
}

func writeStandardError(_ message: String) {
    if let data = (message + "\n").data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

func exitWithError(_ message: String) -> Never {
    writeStandardError("❌ \(message)")
    updateSummary("❌ \(message)")
    exit(1)
}

// MARK: - Argument Parsing
guard CommandLine.arguments.count == 2 else {
    exitWithError("Usage: \(CommandLine.arguments[0]) <release-type>")
}

let releaseType = CommandLine.arguments[1].lowercased()

// MARK: - Shell Helper
func shellOutput(_ command: String) -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", command]
    let pipe = Pipe()
    task.standardOutput = pipe
    try? task.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    return String(data: data, encoding: .utf8) ?? ""
}

// MARK: - Get Latest Tag
// Determine tag pattern based on release type
// Staging builds (build) use 4-part versions: 1.2.3.4
// Production releases (major/minor/patch) use 3-part versions: 1.2.3
let isProductionRelease = ["major", "minor", "patch"].contains(releaseType)

let tagPattern: String
let defaultVersion: String

if isProductionRelease {
    // Production: 3-part version (MAJOR.MINOR.PATCH)
    tagPattern = "^[0-9]+\\.[0-9]+\\.[0-9]+$"
    defaultVersion = "0.1.0"
    log("Looking for 3-part production version tags")
} else {
    // Staging: 4-part version (MAJOR.MINOR.PATCH.BUILD)
    tagPattern = "^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$"
    defaultVersion = "0.1.0.1"
    log("Looking for 4-part staging version tags")
}

let tag = shellOutput("git tag --sort=-creatordate | grep -E '" + tagPattern + "' | head -n1 || true")
    .trimmingCharacters(in: .whitespacesAndNewlines)

let currentVersion = tag.isEmpty ? defaultVersion : tag
log("Current version found: \(currentVersion)")

// MARK: - Write Current Version to Output
if let githubOutput = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] {
    if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: githubOutput)) {
        handle.seekToEndOfFile()
        if let data = "current=\(currentVersion)\n".data(using: .utf8) {
            handle.write(data)
        }
        handle.closeFile()
    }
}

updateSummary("✅ Current version found: \(currentVersion)")

// MARK: - Version Parsing
func parseVersion(_ version: String, expectedParts: Int) -> [Int] {
    let parts = version.split(separator: ".").compactMap { Int($0) }
    var components = parts

    // Ensure we have the expected number of components
    while components.count < expectedParts {
        if expectedParts == 4 {
            // For 4-part versions, BUILD defaults to 1, others to 0
            components.append(components.count == 3 ? 1 : 0)
        } else {
            // For 3-part versions, all default to 0
            components.append(0)
        }
    }

    // Trim to expected parts if needed
    return Array(components.prefix(expectedParts))
}

func formatVersion(_ version: [Int]) -> String {
    return version.map(String.init).joined(separator: ".")
}

// MARK: - Calculate Next Version
var nextVersion: String

switch releaseType {
case "major":
    // Production: 3-part version
    var versionParts = parseVersion(currentVersion, expectedParts: 3)
    versionParts[0] += 1  // Increment major
    versionParts[1] = 0   // Reset minor
    versionParts[2] = 0   // Reset patch
    nextVersion = formatVersion(versionParts)
    log("New major release will be created with version \(nextVersion)")

case "minor":
    // Production: 3-part version
    var versionParts = parseVersion(currentVersion, expectedParts: 3)
    versionParts[1] += 1  // Increment minor
    versionParts[2] = 0   // Reset patch
    nextVersion = formatVersion(versionParts)
    log("New minor release will be created with version \(nextVersion)")

case "patch":
    // Production: 3-part version
    var versionParts = parseVersion(currentVersion, expectedParts: 3)
    versionParts[2] += 1  // Increment patch
    nextVersion = formatVersion(versionParts)
    log("New patch release will be created with version \(nextVersion)")

case "build":
    // Staging: 4-part version
    var versionParts = parseVersion(currentVersion, expectedParts: 4)
    versionParts[3] += 1  // Increment build
    nextVersion = formatVersion(versionParts)
    log("New build version will be created with version \(nextVersion)")

default:
    exitWithError("Unknown release type: \(releaseType)")
}

// MARK: - Write Release Version to Output
if let githubOutput = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] {
    if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: githubOutput)) {
        handle.seekToEndOfFile()
        if let data = "release=\(nextVersion)\n".data(using: .utf8) {
            handle.write(data)
        }
        handle.closeFile()
    }
}

updateSummary("✅ New \(releaseType) release will be created with version \(nextVersion)")

log("Version calculation complete: \(currentVersion) → \(nextVersion)")
