#!/usr/bin/env swift
import Foundation

// MARK: - Constants
let versionFile = "VERSION"

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

// MARK: - Version Management
func initVersion() {
    if !FileManager.default.fileExists(atPath: versionFile) {
        do {
            try "0.1.0.1".write(toFile: versionFile, atomically: true, encoding: .utf8)
            printSuccess("Initialized version file with 0.1.0.1")
        } catch {
            exitWithError("Failed to initialize version file: \(error)")
        }
    }
}

func readVersion() -> String {
    initVersion()

    do {
        return try String(contentsOfFile: versionFile, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        exitWithError("Failed to read version file: \(error)")
    }
}

func parseVersion(_ version: String) -> [Int] {
    let components = version.split(separator: ".").compactMap { Int($0) }
    guard components.count == 4 else {
        exitWithError("Invalid version format: \(version). Expected MAJOR.MINOR.PATCH.BUILD")
    }
    return components
}

func formatVersion(_ components: [Int]) -> String {
    return components.map(String.init).joined(separator: ".")
}

func writeVersion(_ version: String) {
    do {
        try version.write(toFile: versionFile, atomically: true, encoding: .utf8)
        printSuccess("Version updated to: \(version)")
    } catch {
        exitWithError("Failed to write version file: \(error)")
    }
}

func incrementBuild() -> String {
    let current = readVersion()
    var components = parseVersion(current)
    components[3] += 1
    let newVersion = formatVersion(components)
    writeVersion(newVersion)
    return newVersion
}

func incrementPatch() -> String {
    let current = readVersion()
    var components = parseVersion(current)
    components[2] += 1
    components[3] = 1  // Reset build number
    let newVersion = formatVersion(components)
    writeVersion(newVersion)
    return newVersion
}

func incrementMinor() -> String {
    let current = readVersion()
    var components = parseVersion(current)
    components[1] += 1
    components[2] = 0  // Reset patch
    components[3] = 1  // Reset build number
    let newVersion = formatVersion(components)
    writeVersion(newVersion)
    return newVersion
}

func incrementMajor() -> String {
    let current = readVersion()
    var components = parseVersion(current)
    components[0] += 1
    components[1] = 0  // Reset minor
    components[2] = 0  // Reset patch
    components[3] = 1  // Reset build number
    let newVersion = formatVersion(components)
    writeVersion(newVersion)
    return newVersion
}

func showVersion() {
    let version = readVersion()
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
}

func createTag(message: String? = nil) {
    let version = readVersion()
    let tagName = "v\(version)"
    let tagMessage = message ?? "Release version \(version)"

    // Check if tag already exists
    let checkProcess = Process()
    checkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    checkProcess.arguments = ["rev-parse", tagName]
    checkProcess.standardOutput = Pipe()
    checkProcess.standardError = Pipe()

    do {
        try checkProcess.run()
        checkProcess.waitUntilExit()

        if checkProcess.terminationStatus == 0 {
            printWarning("Tag \(tagName) already exists")
            exit(1)
        }
    } catch {
        // Tag doesn't exist, continue
    }

    // Create tag
    let tagProcess = Process()
    tagProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    tagProcess.arguments = ["tag", "-a", tagName, "-m", tagMessage]

    do {
        try tagProcess.run()
        tagProcess.waitUntilExit()

        if tagProcess.terminationStatus == 0 {
            printSuccess("Created tag: \(tagName)")
            printInfo("To push the tag, run: git push origin \(tagName)")
        } else {
            exitWithError("Failed to create tag")
        }
    } catch {
        exitWithError("Failed to create tag: \(error)")
    }
}

func printUsage() {
    print("""
    Usage: version-manager.swift <command> [options]

    Commands:
      show                    Show current version
      build                   Increment build number (0.1.0.1 -> 0.1.0.2)
      patch|bugfix           Increment patch version (0.1.0.5 -> 0.1.1.1)
      minor|feature          Increment minor version (0.1.5.3 -> 0.2.0.1)
      major|breaking         Increment major version (1.2.3.4 -> 2.0.0.1)
      tag [message]          Create git tag for current version
      get                    Get current version (output only)

    Examples:
      version-manager.swift show                           # Display version info
      version-manager.swift build                          # Increment build number
      version-manager.swift patch                          # Create bugfix version
      version-manager.swift minor                          # Create feature version
      version-manager.swift major                          # Create breaking change version
      version-manager.swift tag 'Release notes here'       # Tag current version

    Version Format: MAJOR.MINOR.PATCH.BUILD
      MAJOR - Incompatible API changes
      MINOR - Add functionality (backwards compatible)
      PATCH - Bug fixes (backwards compatible)
      BUILD - Build/commit number (auto-incremented)
    """)
}

// MARK: - Main Logic
guard CommandLine.arguments.count >= 2 else {
    printUsage()
    exit(0)
}

let command = CommandLine.arguments[1].lowercased()

initVersion()

switch command {
case "show":
    showVersion()

case "build":
    let newVersion = incrementBuild()
    printSuccess("Build number incremented")
    print(newVersion)

case "patch", "bugfix":
    let newVersion = incrementPatch()
    printSuccess("Patch version incremented (bugfix)")
    print(newVersion)

case "minor", "feature":
    let newVersion = incrementMinor()
    printSuccess("Minor version incremented (new feature)")
    print(newVersion)

case "major", "breaking":
    let newVersion = incrementMajor()
    printSuccess("Major version incremented (breaking change)")
    print(newVersion)

case "tag":
    let message = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil
    createTag(message: message)

case "get":
    print(readVersion())

default:
    printError("Unknown command: \(command)")
    print("")
    printUsage()
    exit(1)
}
