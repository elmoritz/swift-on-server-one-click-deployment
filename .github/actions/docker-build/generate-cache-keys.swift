#!/usr/bin/env swift
import Foundation

// MARK: - Helper Functions
func runShell(_ command: String) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = ["-c", command]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    do {
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    } catch {
        return ""
    }
}

func writeGitHubOutput(_ key: String, _ value: String) {
    if let githubOutput = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] {
        if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: githubOutput)) {
            handle.seekToEndOfFile()
            if let data = "\(key)=\(value)\n".data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        }
    }
}

// MARK: - Generate Hashes
// Generate hash of Package.resolved for dependency caching
let depsHash = runShell("sha256sum todos-fluent/Package.resolved | cut -d' ' -f1 | cut -c1-12")
writeGitHubOutput("deps-hash", depsHash)

// Generate hash of source files for incremental builds
let sourceHash = runShell("find todos-fluent/Sources -type f -name \"*.swift\" -exec sha256sum {} \\; | sort | sha256sum | cut -d' ' -f1 | cut -c1-12")
writeGitHubOutput("source-hash", sourceHash)

print("Dependencies hash: \(depsHash)")
print("Source code hash: \(sourceHash)")
