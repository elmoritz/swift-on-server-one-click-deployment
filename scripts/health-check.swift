#!/usr/bin/env swift
import Foundation

// MARK: - Configuration
let baseURL = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "http://localhost:8080"
let maxRetries = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2]) ?? 30 : 30
let retryInterval = CommandLine.arguments.count > 3 ? Int(CommandLine.arguments[3]) ?? 2 : 2

// MARK: - Helper Functions
func printSection(_ message: String) {
    print("========================================")
    print(message)
    print("========================================")
}

func printSuccess(_ message: String) {
    print("✅ \(message)")
}

func printError(_ message: String) {
    print("❌ \(message)")
}

// MARK: - Health Check Logic
printSection("Health Check for Hummingbird Todos")
print("URL: \(baseURL)/health")
print("Max retries: \(maxRetries)")
print("Retry interval: \(retryInterval)s")
print("")

var retryCount = 0

while retryCount < maxRetries {
    retryCount += 1

    print("Attempt \(retryCount)/\(maxRetries)... ", terminator: "")

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
    process.arguments = [
        "-s", "-f", "-w", "\n%{http_code}",
        "\(baseURL)/health"
    ]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    do {
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let response = String(data: data, encoding: .utf8) {
            let lines = response.components(separatedBy: "\n")
            if let httpCode = lines.last, httpCode == "200" {
                print("SUCCESS")
                print("")
                printSuccess("Service is healthy!")
                print("Response code: \(httpCode)")
                exit(0)
            } else {
                print("Unexpected status: \(lines.last ?? "unknown")")
            }
        } else {
            print("Failed")
        }
    } catch {
        print("Failed")
    }

    if retryCount < maxRetries {
        sleep(UInt32(retryInterval))
    }
}

print("")
printError("Health check failed after \(maxRetries) attempts")
exit(1)
