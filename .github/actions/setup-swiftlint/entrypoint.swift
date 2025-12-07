#!/usr/bin/env swift
import Foundation

// MARK: - Argument Parsing
guard CommandLine.arguments.count == 3 else {
    print("Usage: \(CommandLine.arguments[0]) <version> <install_path>")
    exit(1)
}

let version = CommandLine.arguments[1]
let installPath = CommandLine.arguments[2]

// MARK: - Helper Function
func runCommand(_ executable: String, _ arguments: [String]) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        print("❌ Failed to run command: \(executable) \(arguments.joined(separator: " "))")
        return false
    }
}

// MARK: - Print Header
print("=========================================")
print("Installing SwiftLint")
print("=========================================")
print("Version:      \(version)")
print("Install Path: \(installPath)")
print("=========================================")

// MARK: - Download SwiftLint
let downloadURL = "https://github.com/realm/SwiftLint/releases/download/\(version)/swiftlint_linux.zip"
print("Downloading SwiftLint from: \(downloadURL)")

if !runCommand("/usr/bin/wget", ["-q", downloadURL]) {
    print("❌ Failed to download SwiftLint")
    exit(1)
}

// MARK: - Extract
print("Extracting SwiftLint...")
if !runCommand("/usr/bin/unzip", ["-q", "swiftlint_linux.zip"]) {
    print("❌ Failed to extract SwiftLint")
    exit(1)
}

// MARK: - Make Executable
if !runCommand("/bin/chmod", ["+x", "swiftlint"]) {
    print("❌ Failed to make SwiftLint executable")
    exit(1)
}

// MARK: - Move to Install Path
print("Installing to: \(installPath)")
if !runCommand("/usr/bin/sudo", ["mv", "swiftlint", installPath]) {
    print("❌ Failed to install SwiftLint")
    exit(1)
}

// MARK: - Clean up
_ = runCommand("/bin/rm", ["-f", "swiftlint_linux.zip"])

// MARK: - Verify Installation
print("\nVerifying installation...")
if !runCommand("/usr/local/bin/swiftlint", ["version"]) {
    print("❌ SwiftLint installation verification failed")
    exit(1)
}

print("\n✅ SwiftLint \(version) installed successfully")
