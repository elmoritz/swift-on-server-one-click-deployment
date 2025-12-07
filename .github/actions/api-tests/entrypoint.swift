#!/usr/bin/env swift
import Foundation

// MARK: - Argument Parsing
guard CommandLine.arguments.count == 3 else {
    print("Usage: \(CommandLine.arguments[0]) <base_url> <test_script>")
    exit(1)
}

let baseURL = CommandLine.arguments[1]
let testScript = CommandLine.arguments[2]

// MARK: - Helper Functions
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

// MARK: - Make Script Executable
let chmodProcess = Process()
chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
chmodProcess.arguments = ["+x", testScript]
try? chmodProcess.run()
chmodProcess.waitUntilExit()

// MARK: - Print Header
print("=========================================")
print("API Integration Tests")
print("=========================================")
print("Target: \(baseURL)")
print("Script: \(testScript)")
print("")

// MARK: - Run Tests
let testProcess = Process()
testProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
testProcess.arguments = ["-c", testScript]
testProcess.environment = ProcessInfo.processInfo.environment.merging(["API_BASE_URL": baseURL]) { _, new in new }

do {
    try testProcess.run()
    testProcess.waitUntilExit()

    if testProcess.terminationStatus == 0 {
        writeGitHubOutput("result", "success")
        print("")
        print("✅ All API tests passed!")
        exit(0)
    } else {
        writeGitHubOutput("result", "failure")
        print("")
        print("❌ API tests failed!")
        exit(1)
    }
} catch {
    writeGitHubOutput("result", "failure")
    print("❌ Failed to run tests: \(error)")
    exit(1)
}
