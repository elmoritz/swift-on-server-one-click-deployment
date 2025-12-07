#!/usr/bin/env swift
import Foundation

// MARK: - Argument Parsing
guard CommandLine.arguments.count >= 3 else {
    print("Usage: \(CommandLine.arguments[0]) <status> <environment> [version] [version_type] [url] [message] [timestamp]")
    exit(1)
}

let status = CommandLine.arguments[1]
let environment = CommandLine.arguments[2]
let version = CommandLine.arguments.count > 3 && !CommandLine.arguments[3].isEmpty ? CommandLine.arguments[3] : nil
let versionType = CommandLine.arguments.count > 4 && !CommandLine.arguments[4].isEmpty ? CommandLine.arguments[4] : nil
let url = CommandLine.arguments.count > 5 && !CommandLine.arguments[5].isEmpty ? CommandLine.arguments[5] : nil
let message = CommandLine.arguments.count > 6 && !CommandLine.arguments[6].isEmpty ? CommandLine.arguments[6] : nil
let timestamp = CommandLine.arguments.count > 7 && !CommandLine.arguments[7].isEmpty ? CommandLine.arguments[7] : nil

// MARK: - Get Timestamp
func getCurrentTimestamp() -> String {
    let formatter = ISO8601DateFormatter()
    return formatter.string(from: Date())
}

let deployTimestamp = timestamp ?? getCurrentTimestamp()

// MARK: - Determine Status Symbol and Message
let (symbol, statusMessage): (String, String)

switch status.lowercased() {
case "success":
    symbol = "✅"
    statusMessage = "SUCCESSFUL"
case "failure":
    symbol = "❌"
    statusMessage = "FAILED"
case "warning":
    symbol = "⚠️"
    statusMessage = "WARNING"
default:
    symbol = "ℹ️"
    statusMessage = status.uppercased()
}

// MARK: - Print Notification
print("=========================================")
print("\(symbol) \(environment.uppercased()) DEPLOYMENT \(statusMessage)")
print("=========================================")

if let version = version {
    print("Version: \(version)")
}

if let versionType = versionType {
    print("Type: \(versionType)")
}

if let url = url {
    print("URL: \(url)")
}

print("Deployed at: \(deployTimestamp)")

if let message = message {
    print("")
    print(message)
}

print("=========================================")

// MARK: - Exit with Error if Failure
if status.lowercased() == "failure" {
    exit(1)
}
