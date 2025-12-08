#!/usr/bin/env swift
import Foundation

// MARK: - Argument Parsing
guard CommandLine.arguments.count == 8 else {
    print("Usage: \(CommandLine.arguments[0]) <base_url> <endpoint> <max_retries> <retry_interval> <expected_version> <expected_build_number> <expected_environment>")
    exit(1)
}

let baseURL = CommandLine.arguments[1]
let endpoint = CommandLine.arguments[2]
let maxRetries = Int(CommandLine.arguments[3]) ?? 30
let retryInterval = Int(CommandLine.arguments[4]) ?? 2
let expectedVersion = CommandLine.arguments[5].isEmpty ? nil : CommandLine.arguments[5]
let expectedBuildNumber = CommandLine.arguments[6].isEmpty ? nil : CommandLine.arguments[6]
let expectedEnvironment = CommandLine.arguments[7].isEmpty ? nil : CommandLine.arguments[7]

// MARK: - URL Construction
func buildURL(base: String, endpoint: String) -> String {
    var cleanBase = base.trimmingCharacters(in: .whitespaces)
    var cleanEndpoint = endpoint.trimmingCharacters(in: .whitespaces)

    // Remove trailing slash from base URL
    while cleanBase.hasSuffix("/") {
        cleanBase.removeLast()
    }

    // Remove leading slash from endpoint
    while cleanEndpoint.hasPrefix("/") {
        cleanEndpoint.removeFirst()
    }

    // Construct full URL with exactly one slash
    return "\(cleanBase)/\(cleanEndpoint)"
}

let fullURL = buildURL(base: baseURL, endpoint: endpoint)

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

// MARK: - Version Response Structure
struct VersionResponse: Codable {
    let version: String
    let buildNumber: String
    let environment: String
}

func verifyVersion() -> Bool {
    guard expectedVersion != nil || expectedBuildNumber != nil || expectedEnvironment != nil else {
        // No version check requested
        return true
    }

    print("")
    printSection("Version Verification")

    let versionURL = buildURL(base: baseURL, endpoint: "version")
    print("Fetching version from: \(versionURL)")

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
    process.arguments = ["-s", "-f", versionURL]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    do {
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let decoder = JSONDecoder()
        let versionResponse = try decoder.decode(VersionResponse.self, from: data)

        print("")
        print("Deployed version:")
        print("  Version: \(versionResponse.version)")
        print("  Build Number: \(versionResponse.buildNumber)")
        print("  Environment: \(versionResponse.environment)")
        print("")

        var allMatch = true

        if let expected = expectedVersion {
            if versionResponse.version == expected {
                printSuccess("Version matches: \(expected)")
            } else {
                printError("Version mismatch! Expected: \(expected), Got: \(versionResponse.version)")
                allMatch = false
            }
        }

        if let expected = expectedBuildNumber {
            if versionResponse.buildNumber == expected {
                printSuccess("Build number matches: \(expected)")
            } else {
                printError("Build number mismatch! Expected: \(expected), Got: \(versionResponse.buildNumber)")
                allMatch = false
            }
        }

        if let expected = expectedEnvironment {
            if versionResponse.environment == expected {
                printSuccess("Environment matches: \(expected)")
            } else {
                printError("Environment mismatch! Expected: \(expected), Got: \(versionResponse.environment)")
                allMatch = false
            }
        }

        return allMatch
    } catch {
        printError("Failed to verify version: \(error)")
        return false
    }
}

// MARK: - Health Check Logic
printSection("Health Check")
print("URL: \(fullURL)")
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
        fullURL
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

                // Verify version if expected values were provided
                if verifyVersion() {
                    print("")
                    printSuccess("All checks passed!")
                    writeGitHubOutput("status", "success")
                    exit(0)
                } else {
                    print("")
                    printError("Version verification failed")
                    writeGitHubOutput("status", "failure")
                    exit(1)
                }
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
writeGitHubOutput("status", "failure")
exit(1)
