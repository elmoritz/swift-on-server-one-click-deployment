#!/usr/bin/env swift
import Foundation

// MARK: - Argument Parsing
guard CommandLine.arguments.count == 5 else {
    print("Usage: \(CommandLine.arguments[0]) <url> <duration_minutes> <check_interval_seconds> <max_consecutive_failures>")
    exit(1)
}

let url = CommandLine.arguments[1]
let durationMinutes = Int(CommandLine.arguments[2]) ?? 5
let intervalSeconds = Int(CommandLine.arguments[3]) ?? 30
let maxFailures = Int(CommandLine.arguments[4]) ?? 3

// MARK: - Calculate Total Checks
let totalChecks = (durationMinutes * 60) / intervalSeconds

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

func getCurrentTimestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.string(from: Date())
}

func performHealthCheck(_ url: String) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
    process.arguments = ["-s", "-w", "\n%{http_code}", url]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    do {
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let response = String(data: data, encoding: .utf8) {
            let lines = response.components(separatedBy: "\n")
            return lines.last ?? "000"
        }
    } catch {
        return "000"
    }

    return "000"
}

// MARK: - Print Header
print("=========================================")
print("Extended Monitoring")
print("=========================================")
print("URL:             \(url)")
print("Duration:        \(durationMinutes) minutes")
print("Check Interval:  \(intervalSeconds) seconds")
print("Total Checks:    \(totalChecks)")
print("Max Failures:    \(maxFailures) consecutive")
print("=========================================")
print("")

// MARK: - Monitoring Loop
var consecutiveFailures = 0
var totalFailures = 0

for i in 1...totalChecks {
    print("Health check \(i)/\(totalChecks) (\(getCurrentTimestamp()))...")

    let httpCode = performHealthCheck(url)

    if httpCode != "200" {
        print("⚠️  WARNING: Health check failed with status: \(httpCode)")
        consecutiveFailures += 1
        totalFailures += 1

        if consecutiveFailures >= maxFailures {
            print("")
            print("=========================================")
            print("❌ ERROR: \(maxFailures) consecutive failures detected!")
            print("=========================================")

            writeGitHubOutput("status", "failure")
            writeGitHubOutput("total_checks", "\(i)")
            writeGitHubOutput("failures", "\(totalFailures)")
            exit(1)
        }
    } else {
        print("✅ Status: OK")
        consecutiveFailures = 0
    }

    // Don't sleep after the last check
    if i < totalChecks {
        sleep(UInt32(intervalSeconds))
    }
}

// MARK: - Success Summary
let successRate = ((totalChecks - totalFailures) * 100) / totalChecks

print("")
print("=========================================")
print("✅ Monitoring Complete - Application Stable!")
print("=========================================")
print("Total Checks:    \(totalChecks)")
print("Total Failures:  \(totalFailures)")
print("Success Rate:    \(successRate)%")
print("=========================================")

writeGitHubOutput("status", "success")
writeGitHubOutput("total_checks", "\(totalChecks)")
writeGitHubOutput("failures", "\(totalFailures)")
