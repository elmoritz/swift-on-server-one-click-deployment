#!/usr/bin/env swift
import Foundation

// MARK: - Argument Parsing
guard CommandLine.arguments.count == 4 else {
    print("Usage: \(CommandLine.arguments[0]) <registry> <image_name> <tags>")
    exit(1)
}

let registry = CommandLine.arguments[1]
let imageName = CommandLine.arguments[2]
let tagsString = CommandLine.arguments[3]

// MARK: - Helper Function
func runDocker(_ arguments: [String]) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/docker")
    process.arguments = arguments

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        return false
    }
}

// MARK: - Load Image
print("Loading Docker image from /tmp/image.tar")
if !runDocker(["load", "--input", "/tmp/image.tar"]) {
    print("❌ Failed to load image from tar")
    exit(1)
}
print("✅ Image loaded successfully")

// Show loaded images
_ = runDocker(["images"])

// MARK: - Push Images
print("\nPushing images with tags: \(tagsString)")

let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

for tag in tags {
    print("Pushing: \(tag)")
    if !runDocker(["push", tag]) {
        print("❌ Failed to push: \(tag)")
        exit(1)
    }
    print("✅ Pushed: \(tag)")
}

// MARK: - Display Summary
print("")
print("=========================================")
print("✅ Docker Push Complete")
print("=========================================")
print("Registry: \(registry)")
print("Image: \(imageName)")
print("Tags pushed: \(tagsString)")
print("=========================================")
