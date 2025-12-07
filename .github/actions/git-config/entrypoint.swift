#!/usr/bin/env swift
import Foundation

// MARK: - Argument Parsing
guard CommandLine.arguments.count == 3 else {
    print("Usage: \(CommandLine.arguments[0]) <user_name> <user_email>")
    exit(1)
}

let userName = CommandLine.arguments[1]
let userEmail = CommandLine.arguments[2]

// MARK: - Helper Function
func runGit(_ arguments: [String]) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = arguments

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        return false
    }
}

// MARK: - Configure Git
if runGit(["config", "user.name", userName]) && runGit(["config", "user.email", userEmail]) {
    print("✅ Git configured as \(userName)")
} else {
    print("❌ Failed to configure Git")
    exit(1)
}
