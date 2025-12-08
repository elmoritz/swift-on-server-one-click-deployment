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
    print("[calculate-build-number] \(message)")
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
log("Calculating build number from commit count to main branch")

// Get the number of commits to the main branch
let buildNumberString = shellOutput("git rev-list --count main")
    .trimmingCharacters(in: .whitespacesAndNewlines)

guard let buildNumber = Int(buildNumberString), buildNumber > 0 else {
    exitWithError("Failed to calculate build number from git commit count")
}

log("Build number calculated: \(buildNumber)")

// MARK: - Write Build Number to Output
if let githubOutput = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] {
    if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: githubOutput)) {
        handle.seekToEndOfFile()
        if let data = "number=\(buildNumber)\n".data(using: .utf8) {
            handle.write(data)
        }
        handle.closeFile()
    }
}

updateSummary("✅ Build number calculated: **\(buildNumber)**")
log("✅ Build number calculation complete")
