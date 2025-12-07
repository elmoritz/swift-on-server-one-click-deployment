#!/usr/bin/env swift
import Foundation

// MARK: - Logging
func log(_ message: String) {
    print("[create-release-branch] \(message)")
}

func writeStandardError(_ message: String) {
    if let data = (message + "\n").data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

func exitWithError(_ message: String) -> Never {
    writeStandardError("❌ \(message)")
    exit(1)
}

// MARK: - Shell Helper
@discardableResult
func runShell(_ command: String, printOutput: Bool = true) -> Int32 {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", command]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    do {
        try task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if printOutput, let output = String(data: data, encoding: .utf8), !output.isEmpty {
            print(output)
        }
        task.waitUntilExit()
        return task.terminationStatus
    } catch {
        exitWithError("Failed to run command: \(command)")
    }
}

// MARK: - Main Logic
guard CommandLine.arguments.count == 4 else {
    exitWithError("Usage: \(CommandLine.arguments[0]) <version> <create_staging> <create_production>")
}

let version = CommandLine.arguments[1]
let createStaging = CommandLine.arguments[2] == "true"
let createProduction = CommandLine.arguments[3] == "true"

log("Creating release branches for version \(version)")
log("Create staging branch: \(createStaging)")
log("Create production branch: \(createProduction)")

// MARK: - Create Staging Branch
if createStaging {
    let stagingBranch = "releases/staging/\(version)"

    // Delete remote branch if exists
    if runShell("git ls-remote --exit-code --heads origin \(stagingBranch)", printOutput: false) == 0 {
        log("Remote staging branch \(stagingBranch) exists. Deleting it.")
        runShell("git push origin --delete \(stagingBranch)")
    }

    // Delete local branch if exists
    if runShell("git show-ref --verify --quiet refs/heads/\(stagingBranch)", printOutput: false) == 0 {
        log("Local staging branch \(stagingBranch) exists. Deleting it.")
        runShell("git branch -D \(stagingBranch)")
    }

    // Create and push staging branch
    log("Creating staging branch: \(stagingBranch)")
    if runShell("git checkout -b \(stagingBranch)") != 0 {
        exitWithError("Failed to create staging branch")
    }

    if runShell("git push --set-upstream origin \(stagingBranch)") != 0 {
        exitWithError("Failed to push staging branch")
    }

    log("✅ Staging branch created: \(stagingBranch)")

    // Return to main
    runShell("git checkout main")
}

// MARK: - Create Production Branch
if createProduction {
    let productionBranch = "releases/production/\(version)"

    // Delete remote branch if exists
    if runShell("git ls-remote --exit-code --heads origin \(productionBranch)", printOutput: false) == 0 {
        log("Remote production branch \(productionBranch) exists. Deleting it.")
        runShell("git push origin --delete \(productionBranch)")
    }

    // Delete local branch if exists
    if runShell("git show-ref --verify --quiet refs/heads/\(productionBranch)", printOutput: false) == 0 {
        log("Local production branch \(productionBranch) exists. Deleting it.")
        runShell("git branch -D \(productionBranch)")
    }

    // Create and push production branch
    log("Creating production branch: \(productionBranch)")
    if runShell("git checkout -b \(productionBranch)") != 0 {
        exitWithError("Failed to create production branch")
    }

    if runShell("git push --set-upstream origin \(productionBranch)") != 0 {
        exitWithError("Failed to push production branch")
    }

    log("✅ Production branch created: \(productionBranch)")

    // Return to main
    runShell("git checkout main")
}

log("Release branches created successfully")
