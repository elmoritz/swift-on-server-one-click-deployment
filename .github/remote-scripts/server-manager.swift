#!/usr/bin/env swift
import Foundation

// MARK: - Command Type
enum Command: String {
    case deploy
    case rollback
    case cleanup
    case help
}

// MARK: - Helper Functions
func printError(_ message: String) {
    if let data = ("❌ \(message)\n").data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

func exitWithError(_ message: String) -> Never {
    printError(message)
    exit(1)
}

func runCommand(_ executable: String, _ arguments: [String], environment: [String: String]? = nil) -> (success: Bool, output: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments

    if let env = environment {
        var processEnv = ProcessInfo.processInfo.environment
        for (key, value) in env {
            processEnv[key] = value
        }
        process.environment = processEnv
    }

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        return (process.terminationStatus == 0, output)
    } catch {
        return (false, "Failed to execute: \(executable) \(arguments.joined(separator: " "))")
    }
}

func runShell(_ command: String, environment: [String: String]? = nil) -> (success: Bool, output: String) {
    return runCommand("/bin/bash", ["-c", command], environment: environment)
}

func getEnv(_ key: String, default defaultValue: String = "") -> String {
    return ProcessInfo.processInfo.environment[key] ?? defaultValue
}

func getComposeFilePath(composeFolder: String, deployPath: String) -> String? {
    let possibleComposeFileNames = ["docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml"]
    for fileName in possibleComposeFileNames {
        let fullPath: String
        if composeFolder.hasPrefix("/") {
            fullPath = "\(composeFolder)/\(fileName)"
        } else {
            fullPath = "\(deployPath)/\(composeFolder)/\(fileName)"
        }
        if FileManager.default.fileExists(atPath: fullPath) {
            return fullPath
        }
    }
    return nil
}

// MARK: - Deploy Command
func deployContainer() {
    print("=========================================")
    print("🚀 Deploying Container")
    print("=========================================")

    // Get environment variables
    let imageTag = getEnv("IMAGE_TAG")
    let version = getEnv("VERSION")
    let containerName = getEnv("CONTAINER_NAME")
    let portMapping = getEnv("PORT_MAPPING")
    let deployPath = getEnv("DEPLOY_PATH")
    let composeFolder = getEnv("COMPOSE_FOLDER")
    let githubToken = getEnv("GITHUB_TOKEN")
    let githubActor = getEnv("GITHUB_ACTOR")
    let registry = getEnv("REGISTRY")

    guard !imageTag.isEmpty, !containerName.isEmpty, !deployPath.isEmpty else {
        exitWithError("Missing required environment variables")
    }

    print("Image: \(imageTag)")
    print("Container: \(containerName)")
    print("Deploy Path: \(deployPath)")
    print("=========================================\n")

    // Navigate to deployment directory
    let createDirResult = runShell("mkdir -p \(deployPath)")
    if !createDirResult.success {
        exitWithError("Failed to create deployment directory")
    }

    _ = FileManager.default.changeCurrentDirectoryPath(deployPath)

    // Login to registry
    if !githubToken.isEmpty && !githubActor.isEmpty {
        print("Logging in to \(registry)...")
        let loginResult = runShell("echo '\(githubToken)' | docker login \(registry) -u \(githubActor) --password-stdin")
        if !loginResult.success {
            exitWithError("Failed to login to registry")
        }
        print("✅ Logged in to registry\n")
    }

    // Check if using Docker Compose or Docker run
    if !composeFolder.isEmpty {
        deployWithCompose(composeFolder: composeFolder, deployPath: deployPath)
    } else {
        deployWithDockerRun(
            imageTag: imageTag,
            containerName: containerName,
            portMapping: portMapping,
            deployPath: deployPath
        )
    }

    // Store deployment metadata
    do {
        try version.write(toFile: "\(deployPath)/current-version.txt", atomically: true, encoding: .utf8)
        let timestamp = ISO8601DateFormatter().string(from: Date())
        try timestamp.write(toFile: "\(deployPath)/last-deployment.txt", atomically: true, encoding: .utf8)
    } catch {
        print("⚠️  Warning: Could not write metadata files")
    }

    // Clean up old images
    print("\nCleaning up old images...")
    _ = runShell("docker image prune -f")

    print("\n=========================================")
    print("✅ Deployment Complete!")
    print("=========================================")
}

func deployWithCompose(composeFolder: String, deployPath: String) {
    print("Using Docker Compose deployment")

    // Verify docker-compose.yml exists
    
    guard let composeFile = getComposeFilePath(composeFolder: composeFolder, deployPath: deployPath) else {
        exitWithError("docker-compose-file not found in: \(composeFolder)")
    }

    let composeDir = (composeFile as NSString).deletingLastPathComponent

    print("Compose directory: \(composeDir)")
    _ = FileManager.default.changeCurrentDirectoryPath(composeDir)

    // Backup database if exists
    backupDatabase(deployPath: deployPath)

    // Pull latest images
    print("\nPulling images defined in docker-compose.yml...")
    let pullResult = runShell("docker compose pull")
    if !pullResult.success {
        print("⚠️  Warning: Failed to pull some images")
        print("output: \(pullResult.output)")
    }

    // Stop and remove old containers
    print("Stopping existing services...")
    let stopResult = runShell("docker compose down")
    if !stopResult.success {
        print("⚠️  Warning: Failed to stop some services")
        print("output: \(stopResult.output)")
    }

    // Start services
    print("Starting services with Docker Compose...")
    let upResult = runShell("docker compose up -d")
    if !upResult.success {
        exitWithError("Failed to start services")
        print("output: \(upResult.output)")
    }

    // Wait for services to start
    print("Waiting for services to start...")
    sleep(10)
}

func deployWithDockerRun(imageTag: String, containerName: String, portMapping: String, deployPath: String) {
    print("Using Docker run deployment")

    // Pull latest image
    print("\nPulling image: \(imageTag)")
    let pullResult = runShell("docker pull \(imageTag)")
    if !pullResult.success {
        exitWithError("Failed to pull image")
    }

    // Clean up old backup container
    let checkOldBackup = runShell("docker ps -a --format '{{.Names}}' | grep '^\(containerName)-previous$'")
    if checkOldBackup.success {
        print("Removing old backup container...")
        _ = runShell("docker stop \(containerName)-previous")
        _ = runShell("docker rm \(containerName)-previous")
    }

    // Stop and backup current container
    let checkCurrent = runShell("docker ps -a --format '{{.Names}}' | grep '^\(containerName)$'")
    if checkCurrent.success {
        print("Backing up current container...")
        _ = runShell("docker stop \(containerName)")
        _ = runShell("docker rename \(containerName) \(containerName)-previous")
    }

    // Backup database
    backupDatabase(deployPath: deployPath)

    // Start new container
    print("\nStarting new container: \(containerName)")
    let runCommand = """
    docker run -d \
      --name \(containerName) \
      --restart unless-stopped \
      -p \(portMapping) \
      -v \(deployPath)/data:/app/data \
      -e HOSTNAME=0.0.0.0 \
      -e PORT=8080 \
      \(imageTag)
    """

    let runResult = runShell(runCommand)
    if !runResult.success {
        exitWithError("Failed to start container: \(runResult.output)")
    }

    // Wait for container to start
    print("Waiting for container to start...")
    sleep(10)
}

func backupDatabase(deployPath: String) {
    let dbPath = "\(deployPath)/data/db.sqlite"
    guard FileManager.default.fileExists(atPath: dbPath) else {
        return
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
    let timestamp = dateFormatter.string(from: Date())
    let backupFile = "\(deployPath)/data/db.sqlite.backup.\(timestamp)"

    do {
        let dataDir = "\(deployPath)/data"
        try FileManager.default.createDirectory(atPath: dataDir, withIntermediateDirectories: true)
        try FileManager.default.copyItem(atPath: dbPath, toPath: backupFile)
        print("✅ Database backed up to: \(backupFile)")

        // Keep only last 10 backups
        let backups = try FileManager.default.contentsOfDirectory(atPath: dataDir)
            .filter { $0.hasPrefix("db.sqlite.backup.") }
            .sorted(by: >)

        if backups.count > 10 {
            for oldBackup in backups.dropFirst(10) {
                try? FileManager.default.removeItem(atPath: "\(dataDir)/\(oldBackup)")
            }
        }
    } catch {
        print("⚠️  Warning: Failed to backup database: \(error)")
    }
}

// MARK: - Rollback Command
func rollbackDeployment() {
    print("=========================================")
    print("🔄 Rolling Back Deployment")
    print("=========================================")

    let containerName = getEnv("CONTAINER_NAME")
    let deployPath = getEnv("DEPLOY_PATH")

    guard !containerName.isEmpty, !deployPath.isEmpty else {
        exitWithError("Missing required environment variables")
    }

    print("Container: \(containerName)")
    print("Deploy Path: \(deployPath)")
    print("=========================================\n")

    _ = FileManager.default.changeCurrentDirectoryPath(deployPath)

    // Stop failed container
    print("Stopping failed container...")
    _ = runShell("docker stop \(containerName)")
    _ = runShell("docker rm \(containerName)")

    // Restore database backup
    let dataDir = "\(deployPath)/data"
    do {
        let backups = try FileManager.default.contentsOfDirectory(atPath: dataDir)
            .filter { $0.hasPrefix("db.sqlite.backup.") }
            .sorted(by: >)

        if let latestBackup = backups.first {
            let backupPath = "\(dataDir)/\(latestBackup)"
            let dbPath = "\(dataDir)/db.sqlite"
            try FileManager.default.copyItem(atPath: backupPath, toPath: dbPath)
            print("✅ Database restored from: \(latestBackup)")
        }
    } catch {
        print("⚠️  Warning: Could not restore database backup")
    }

    // Restore previous container
    let checkPrevious = runShell("docker ps -a --format '{{.Names}}' | grep '^\(containerName)-previous$'")
    if checkPrevious.success {
        print("\nRestoring previous container...")
        let renameResult = runShell("docker rename \(containerName)-previous \(containerName)")
        if !renameResult.success {
            exitWithError("Failed to rename previous container")
        }

        let startResult = runShell("docker start \(containerName)")
        if !startResult.success {
            exitWithError("Failed to start previous container")
        }

        print("✅ Rolled back to previous version")
    } else {
        exitWithError("No previous container found for rollback")
    }

    print("\n=========================================")
    print("✅ Rollback Complete")
    print("=========================================")
}

// MARK: - Cleanup Command
func cleanupContainers() {
    print("=========================================")
    print("🧹 Docker Cleanup")
    print("=========================================")

    let containerName = getEnv("CONTAINER_NAME")
    let pruneImages = getEnv("PRUNE_IMAGES", default: "true")

    guard !containerName.isEmpty else {
        exitWithError("Missing CONTAINER_NAME environment variable")
    }

    // Remove old container
    let previousContainerName = "\(containerName)-previous"
    let checkResult = runShell("docker ps -a --format '{{.Names}}' | grep '^\(previousContainerName)$'")

    if checkResult.success {
        print("Removing old container: \(previousContainerName)")
        let removeResult = runShell("docker rm \(previousContainerName)")
        if removeResult.success {
            print("✅ Old container removed")
        } else {
            print("⚠️  Failed to remove old container")
        }
    } else {
        print("No old container found")
    }

    // Prune images if requested
    if pruneImages.lowercased() == "true" {
        print("\nPruning unused Docker images...")
        let pruneResult = runShell("docker image prune -f")
        if pruneResult.success {
            print("✅ Docker images pruned")
        }
    }

    print("=========================================")
}

// MARK: - Help
func printHelp() {
    print("""
    Server Manager - Docker Deployment Management Tool

    Usage: server-manager.swift <command>

    Commands:
      deploy    - Deploy container to server
      rollback  - Rollback to previous container version
      cleanup   - Clean up old containers and images
      help      - Show this help message

    Environment Variables:

    For 'deploy':
      IMAGE_TAG       - Full Docker image tag to deploy
      VERSION         - Version number
      CONTAINER_NAME  - Name for the container
      PORT_MAPPING    - Port mapping (e.g., 8080:8080)
      DEPLOY_PATH     - Deployment directory
      COMPOSE_FOLDER  - (Optional) Docker Compose folder path
      GITHUB_TOKEN    - GitHub token for registry login
      GITHUB_ACTOR    - GitHub username
      REGISTRY        - Container registry URL

    For 'rollback':
      CONTAINER_NAME  - Name of the container
      DEPLOY_PATH     - Deployment directory

    For 'cleanup':
      CONTAINER_NAME  - Name of the container
      PRUNE_IMAGES    - Whether to prune images (true/false)

    Examples:
      # Deploy with Docker run
      IMAGE_TAG=ghcr.io/user/app:1.0.0 \
      VERSION=1.0.0 \
      CONTAINER_NAME=todos-app \
      PORT_MAPPING=8080:8080 \
      DEPLOY_PATH=/opt/todos-app \
      ./server-manager.swift deploy

      # Deploy with Docker Compose
      COMPOSE_FOLDER=compose \
      DEPLOY_PATH=/opt/todos-app \
      GITHUB_TOKEN=ghp_xxx \
      GITHUB_ACTOR=username \
      REGISTRY=ghcr.io \
      ./server-manager.swift deploy

      # Rollback
      CONTAINER_NAME=todos-app \
      DEPLOY_PATH=/opt/todos-app \
      ./server-manager.swift rollback

      # Cleanup
      CONTAINER_NAME=todos-app \
      PRUNE_IMAGES=true \
      ./server-manager.swift cleanup
    """)
}

// MARK: - Main
guard CommandLine.arguments.count >= 2 else {
    printHelp()
    exit(0)
}

let commandString = CommandLine.arguments[1].lowercased()

guard let command = Command(rawValue: commandString) else {
    printError("Unknown command: \(commandString)")
    printHelp()
    exit(1)
}

switch command {
case .deploy:
    deployContainer()
case .rollback:
    rollbackDeployment()
case .cleanup:
    cleanupContainers()
case .help:
    printHelp()
}
