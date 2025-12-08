#!/usr/bin/env swift
import Foundation

// MARK: - Configuration
guard let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] else {
    print("❌ Error: API_BASE_URL environment variable not set")
    exit(1)
}

// MARK: - Test DSL

struct APITest {
    let name: String
    let request: HTTPRequest
    let expectations: [Expectation]

    static func test(_ name: String, _ builder: () -> APITest) -> APITest {
        return builder()
    }
}

struct HTTPRequest {
    let method: String
    let path: String
    var headers: [String: String] = [:]
    var body: String?

    static func get(_ path: String) -> HTTPRequest {
        HTTPRequest(method: "GET", path: path)
    }

    static func post(_ path: String, body: String) -> HTTPRequest {
        HTTPRequest(method: "POST", path: path, body: body)
    }

    static func patch(_ path: String, body: String) -> HTTPRequest {
        HTTPRequest(method: "PATCH", path: path, body: body)
    }

    static func delete(_ path: String) -> HTTPRequest {
        HTTPRequest(method: "DELETE", path: path)
    }

    func header(_ key: String, _ value: String) -> HTTPRequest {
        var copy = self
        copy.headers[key] = value
        return copy
    }
}

enum Expectation {
    case status(Int)
    case jsonKeyEquals(String, equals: String)
    case jsonKeyExists(String, exists: Bool)
    case jsonArray
    case bodyContains(String)
}

// Builder methods
extension HTTPRequest {
    func expect(status: Int) -> APITestBuilder {
        return APITestBuilder(request: self, expectations: [.status(status)])
    }
}

struct APITestBuilder {
    let request: HTTPRequest
    var expectations: [Expectation]

    func expect(status: Int) -> APITestBuilder {
        var copy = self
        copy.expectations.append(.status(status))
        return copy
    }

    func expect(jsonKey: String, equals value: String) -> APITestBuilder {
        var copy = self
        copy.expectations.append(.jsonKeyEquals(jsonKey, equals: value))
        return copy
    }

    func expect(jsonKey: String, exists: Bool) -> APITestBuilder {
        var copy = self
        copy.expectations.append(.jsonKeyExists(jsonKey, exists: exists))
        return copy
    }

    func expect(jsonArray: Bool) -> APITestBuilder {
        var copy = self
        if jsonArray {
            copy.expectations.append(.jsonArray)
        }
        return copy
    }

    func expect(bodyContains text: String) -> APITestBuilder {
        var copy = self
        copy.expectations.append(.bodyContains(text))
        return copy
    }

    func named(_ name: String) -> APITest {
        return APITest(name: name, request: request, expectations: expectations)
    }
}

// MARK: - Test Execution

class TestRunner {
    let baseURL: String
    private var passedTests = 0
    private var failedTests = 0
    private var createdTodoId: String?

    init(baseURL: String) {
        self.baseURL = baseURL
    }

    func run(_ tests: [APITest]) async -> Bool {
        print("=========================================")
        print("🧪 API Integration Tests")
        print("=========================================")
        print("Target: \(baseURL)")
        print("")

        for test in tests {
            await runTest(test)
        }

        print("")
        print("=========================================")
        print("📊 Test Results")
        print("=========================================")
        print("✅ Passed: \(passedTests)")
        print("❌ Failed: \(failedTests)")
        print("Total: \(passedTests + failedTests)")

        return failedTests == 0
    }

    private func runTest(_ test: APITest) async {
        print("🔍 \(test.name)")

        // Replace {todoId} placeholder with actual ID
        var requestPath = test.request.path
        if let todoId = createdTodoId {
            requestPath = requestPath.replacingOccurrences(of: "{todoId}", with: todoId)
        }

        let fullURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + requestPath

        guard let url = URL(string: fullURL) else {
            print("   ❌ Invalid URL: \(fullURL)")
            failedTests += 1
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = test.request.method
        request.timeoutInterval = 10

        // Set headers
        for (key, value) in test.request.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Set body
        if let body = test.request.body {
            request.httpBody = body.data(using: .utf8)
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("   ❌ Invalid response type")
                failedTests += 1
                return
            }

            let bodyString = String(data: data, encoding: .utf8) ?? ""
            var json: [String: Any]?
            var jsonArray: [[String: Any]]?

            if !data.isEmpty {
                if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    json = obj
                    // Capture todo ID if this is a create request
                    if test.request.method == "POST" && test.request.path.contains("/todos"),
                       let id = obj["id"] as? String {
                        createdTodoId = id
                    }
                } else if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    jsonArray = arr
                }
            }

            // Check expectations
            var allPassed = true
            for expectation in test.expectations {
                let passed = checkExpectation(expectation, status: httpResponse.statusCode, json: json, jsonArray: jsonArray, body: bodyString)
                if !passed {
                    allPassed = false
                }
            }

            if allPassed {
                print("   ✅ Passed")
                passedTests += 1
            } else {
                print("   ❌ Failed")
                failedTests += 1
            }

        } catch {
            print("   ❌ Request failed: \(error.localizedDescription)")
            failedTests += 1
        }
    }

    private func checkExpectation(_ expectation: Expectation, status: Int, json: [String: Any]?, jsonArray: [[String: Any]]?, body: String) -> Bool {
        switch expectation {
        case .status(let expected):
            if status == expected {
                print("   ✓ Status: \(status)")
                return true
            } else {
                print("   ✗ Expected status \(expected), got \(status)")
                return false
            }

        case let .jsonKeyEquals(key, expected):
            if let value = json?[key] as? String, value == expected {
                print("   ✓ JSON[\(key)] = \"\(value)\"")
                return true
            } else if let value = json?[key] {
                print("   ✗ Expected JSON[\(key)] = \"\(expected)\", got \"\(value)\"")
                return false
            } else {
                print("   ✗ JSON key \"\(key)\" not found")
                return false
            }

        case let .jsonKeyExists(key, shouldExist):
            let exists = json?[key] != nil
            if exists == shouldExist {
                print("   ✓ JSON[\(key)] exists: \(exists)")
                return true
            } else {
                print("   ✗ Expected JSON[\(key)] exists: \(shouldExist), got: \(exists)")
                return false
            }

        case .jsonArray:
            if jsonArray != nil {
                print("   ✓ Response is JSON array")
                return true
            } else {
                print("   ✗ Expected JSON array, got: \(json != nil ? "object" : "invalid")")
                return false
            }

        case let .bodyContains(text):
            if body.contains(text) {
                print("   ✓ Body contains: \"\(text)\"")
                return true
            } else {
                print("   ✗ Body does not contain: \"\(text)\"")
                return false
            }
        }
    }
}

// MARK: - Test Suite Definition

let tests: [APITest] = [
    // Health and Version Checks
    HTTPRequest.get("/health")
        .expect(status: 200)
        .expect(jsonKey: "status", equals: "ok")
        .expect(jsonKey: "databaseConnected", exists: true)
        .named("Health check endpoint"),

    HTTPRequest.get("/version")
        .expect(status: 200)
        .expect(jsonKey: "version", exists: true)
        .expect(jsonKey: "buildNumber", exists: true)
        .expect(jsonKey: "environment", exists: true)
        .named("Version endpoint"),

    // Todo CRUD Operations
    HTTPRequest.get("/todos")
        .expect(status: 200)
        .expect(jsonArray: true)
        .named("List all todos"),

    HTTPRequest.post("/todos", body: """
        {
            "title": "Test Todo from API Tests",
            "order": 1
        }
        """)
        .header("Content-Type", "application/json")
        .expect(status: 201)
        .expect(jsonKey: "id", exists: true)
        .expect(jsonKey: "title", equals: "Test Todo from API Tests")
        .expect(jsonKey: "url", exists: true)
        .named("Create a new todo"),

    HTTPRequest.get("/todos/{todoId}")
        .expect(status: 200)
        .expect(jsonKey: "id", exists: true)
        .expect(jsonKey: "title", equals: "Test Todo from API Tests")
        .named("Get specific todo by ID"),

    HTTPRequest.patch("/todos/{todoId}", body: """
        {
            "title": "Updated Test Todo",
            "completed": true
        }
        """)
        .header("Content-Type", "application/json")
        .expect(status: 200)
        .expect(jsonKey: "title", equals: "Updated Test Todo")
        .expect(jsonKey: "completed", exists: true)
        .named("Update todo"),

    HTTPRequest.delete("/todos/{todoId}")
        .expect(status: 200)
        .named("Delete specific todo"),

    // Create another todo for delete all test
    HTTPRequest.post("/todos", body: """
        {
            "title": "Todo to be deleted",
            "order": 1
        }
        """)
        .header("Content-Type", "application/json")
        .expect(status: 201)
        .named("Create todo for cleanup test"),

    HTTPRequest.delete("/todos")
        .expect(status: 200)
        .named("Delete all todos"),

    HTTPRequest.get("/todos")
        .expect(status: 200)
        .expect(jsonArray: true)
        .named("Verify all todos deleted"),
]

// MARK: - Main Execution

Task {
    let runner = TestRunner(baseURL: baseURL)
    let success = await runner.run(tests)

    exit(success ? 0 : 1)
}

// Keep the script running
RunLoop.main.run()
