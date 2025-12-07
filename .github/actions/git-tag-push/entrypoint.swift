#!/usr/bin/env swift
import Foundation

// MARK: - Argument Parsing
guard CommandLine.arguments.count == 7 else {
    print("Usage: \(CommandLine.arguments[0]) <version> <branch> <tag_prefix> <tag_message> <push_tag> <push_branch>")
    exit(1)
}

let version = CommandLine.arguments[1]
let branch = CommandLine.arguments[2]
let tagPrefix = CommandLine.arguments[3]
let tagMessage = CommandLine.arguments[4]
let pushTag = CommandLine.arguments[5] == "true"
let pushBranch = CommandLine.arguments[6] == "true"

let tagName = "\(tagPrefix)\(version)"

// MARK: - Helper Function
func runGit(_ arguments: [String], errorMessage: String) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = arguments

    do {
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            print("❌ \(errorMessage)")
            return false
        }
        return true
    } catch {
        print("❌ \(errorMessage): \(error)")
        return false
    }
}

// MARK: - Print Header
print("=========================================")
print("Git Tag and Push")
print("=========================================")
print("Tag:     \(tagName)")
print("Branch:  \(branch)")
print("Message: \(tagMessage) \(version)")
print("=========================================")

// MARK: - Create Tag
if !runGit(["tag", "-a", tagName, "-m", "\(tagMessage) \(version)"], errorMessage: "Failed to create tag") {
    exit(1)
}
print("✅ Tag created: \(tagName)")

// MARK: - Push Branch
if pushBranch {
    if !runGit(["push", "origin", branch], errorMessage: "Failed to push branch") {
        exit(1)
    }
    print("✅ Pushed branch: \(branch)")
}

// MARK: - Push Tag
if pushTag {
    if !runGit(["push", "origin", tagName], errorMessage: "Failed to push tag") {
        exit(1)
    }
    print("✅ Pushed tag: \(tagName)")
}

// MARK: - Write GitHub Output
if let githubOutput = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] {
    try? "tag_name=\(tagName)\n".write(toFile: githubOutput, atomically: true, encoding: .utf8)
}

print("=========================================")
