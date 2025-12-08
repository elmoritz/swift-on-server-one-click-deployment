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
    print("[get-semantic-version] \(message)")
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

// MARK: - Shell Helper
func shellOutput(_ command: String) -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", command]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = Pipe()
    try? task.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    return String(data: data, encoding: .utf8) ?? ""
}

// MARK: - Main Logic
log("Looking for semantic version tags (MAJOR.MINOR.PATCH format)")

// Get the latest semantic version tag (MAJOR.MINOR.PATCH format, with or without 'v' prefix)
let tag = shellOutput("git tag --sort=-creatordate | grep -E '^v?[0-9]+\\.[0-9]+\\.[0-9]+$' | head -n1 || true")
    .trimmingCharacters(in: .whitespacesAndNewlines)

let version: String
if tag.isEmpty {
    version = "0.1.0"
    log("⚠️  No semantic version tag found, using default: \(version)")
} else {
    // Remove 'v' prefix if present
    version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    log("✅ Found semantic version tag: \(tag) -> \(version)")
}

// MARK: - Write Version to Output
if let githubOutput = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] {
    if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: githubOutput)) {
        handle.seekToEndOfFile()
        if let data = "version=\(version)\n".data(using: .utf8) {
            handle.write(data)
        }
        handle.closeFile()
    }
}

updateSummary("✅ Semantic version: **\(version)**")
log("✅ Version detection complete")
