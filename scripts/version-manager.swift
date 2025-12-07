#!/usr/bin/env swift
import Foundation

// MARK: - Constants
let tagPattern = "^[0-9]+\\.[0-9]+\\.[0-9]+(\\.[0-9]+)?$"

// MARK: - Helper Functions
func printInfo(_ message: String) {
    print("ℹ️  [INFO] \(message)")
}

func printSuccess(_ message: String) {
    print("✅ [SUCCESS] \(message)")
}

func printError(_ message: String) {
    if let data = ("❌ [ERROR] \(message)\n").data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

func printWarning(_ message: String) {
    print("⚠️  [WARNING] \(message)")
}

func exitWithError(_ message: String) -> Never {
    printError(message)
    exit(1)
}

// MARK: - Shell Helper
func shellOutput(_ command: String) -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", command]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = Pipe()

    do {
        try task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    } catch {
        return ""
    }
}

func runCommand(_ command: String) -> Bool {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", command]

    do {
        try task.run()
        task.waitUntilExit()
        return task.terminationStatus == 0
    } catch {
        return false
    }
}

// MARK: - Version Management
func getLatestTag() -> String {
    let tag = shellOutput("git tag --sort=-creatordate | grep -E '\(tagPattern)' | head -n1 || true")
    return tag.isEmpty ? "0.1.0.1" : tag
}

func parseVersion(_ version: String) -> [Int] {
    let parts = version.split(separator: ".").compactMap { Int($0) }
    var components = parts
    while components.count < 4 {
        components.append(components.count == 3 ? 1 : 0)
    }
    return components
}

func formatVersion(_ components: [Int]) -> String {
    return components.map(String.init).joined(separator: ".")
}

func incrementBuild() -> String {
    let current = getLatestTag()
    var components = parseVersion(current)
    components[3] += 1
    return formatVersion(components)
}

func incrementPatch() -> String {
    let current = getLatestTag()
    var components = parseVersion(current)
    components[2] += 1
    components[3] = 1
    return formatVersion(components)
}

func incrementMinor() -> String {
    let current = getLatestTag()
    var components = parseVersion(current)
    components[1] += 1
    components[2] = 0
    components[3] = 1
    return formatVersion(components)
}

func incrementMajor() -> String {
    let current = getLatestTag()
    var components = parseVersion(current)
    components[0] += 1
    components[1] = 0
    components[2] = 0
    components[3] = 1
    return formatVersion(components)
}

func showVersion() {
    let version = getLatestTag()
    let components = parseVersion(version)

    print("========================================")
    print("Current Version Information")
    print("========================================")
    print("Full Version: \(version)")
    print("Major:        \(components[0])")
    print("Minor:        \(components[1])")
    print("Patch:        \(components[2])")
    print("Build:        \(components[3])")
    print("========================================")
    print("")
    print("Version source: Git tags")
    print("========================================")
}

func createTag(version: String, message: String? = nil) {
    let tagName = version
    let tagMessage = message ?? "Release version \(version)"

    // Check if tag already exists
    let tagExists = shellOutput("git rev-parse \(tagName) 2>/dev/null")
    if !tagExists.isEmpty {
        printWarning("Tag \(tagName) already exists")
        exit(1)
    }

    // Create tag
    let command = "git tag -a \(tagName) -m '\(tagMessage)'"
    if runCommand(command) {
        printSuccess("Created tag: \(tagName)")
        printInfo("To push the tag, run: git push origin \(tagName)")
    } else {
        exitWithError("Failed to create tag")
    }
}

func printUsage() {
    print("""
    Usage: version-manager.swift <command> [options]

    Commands:
      show                    Show current version from git tags
      build                   Calculate next build number (0.1.0.1 -> 0.1.0.2)
      patch|bugfix           Calculate next patch version (0.1.0.5 -> 0.1.1.1)
      minor|feature          Calculate next minor version (0.1.5.3 -> 0.2.0.1)
      major|breaking         Calculate next major version (1.2.3.4 -> 2.0.0.1)
      tag <version> [message] Create git tag for specific version
      get                    Get current version from git tags (output only)

    Examples:
      version-manager.swift show                           # Display version info
      version-manager.swift build                          # Calculate next build
      version-manager.swift patch                          # Calculate next patch
      version-manager.swift minor                          # Calculate next minor
      version-manager.swift major                          # Calculate next major
      version-manager.swift tag 1.2.3.4 'Release notes'   # Create specific tag
      version-manager.swift get                            # Get current version

    Version Format: MAJOR.MINOR.PATCH.BUILD
      MAJOR - Incompatible API changes
      MINOR - Add functionality (backwards compatible)
      PATCH - Bug fixes (backwards compatible)
      BUILD - Build/commit number (auto-incremented)

    Note: This version uses GIT TAGS as the source of truth.
          No VERSION file is used or modified.
    """)
}

// MARK: - Main Logic
guard CommandLine.arguments.count >= 2 else {
    printUsage()
    exit(0)
}

let command = CommandLine.arguments[1].lowercased()

switch command {
case "show":
    showVersion()

case "build":
    let newVersion = incrementBuild()
    printSuccess("Next build version calculated")
    print(newVersion)

case "patch", "bugfix":
    let newVersion = incrementPatch()
    printSuccess("Next patch version calculated")
    print(newVersion)

case "minor", "feature":
    let newVersion = incrementMinor()
    printSuccess("Next minor version calculated")
    print(newVersion)

case "major", "breaking":
    let newVersion = incrementMajor()
    printSuccess("Next major version calculated")
    print(newVersion)

case "tag":
    guard CommandLine.arguments.count >= 3 else {
        exitWithError("Usage: version-manager.swift tag <version> [message]")
    }
    let version = CommandLine.arguments[2]
    let message = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : nil
    createTag(version: version, message: message)

case "get":
    print(getLatestTag())

default:
    printError("Unknown command: \(command)")
    print("")
    printUsage()
    exit(1)
}
