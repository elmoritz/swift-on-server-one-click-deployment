#!/usr/bin/env swift
import Foundation

// MARK: - Argument Parsing
guard CommandLine.arguments.count == 4 else {
    print("Usage: \(CommandLine.arguments[0]) <registry> <image_name> <version> [additional_tags]")
    exit(1)
}

let registry = CommandLine.arguments[1]
let imageName = CommandLine.arguments[2]
let version = CommandLine.arguments[3]
let additionalTags = CommandLine.arguments.count > 4 ? CommandLine.arguments[4] : ""

// MARK: - Build Tags
var tags = "\(registry)/\(imageName):\(version)"

// Add additional tags if provided
if !additionalTags.isEmpty {
    let extraTags = additionalTags.split(separator: ",")
    for tag in extraTags {
        let trimmedTag = tag.trimmingCharacters(in: .whitespaces)
        tags += ",\(registry)/\(imageName):\(trimmedTag)"
    }
}

// MARK: - Write Output
if let githubOutput = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] {
    if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: githubOutput)) {
        handle.seekToEndOfFile()
        if let data = "tags=\(tags)\n".data(using: .utf8) {
            handle.write(data)
        }
        handle.closeFile()
    }
}

print("Building with tags: \(tags)")
