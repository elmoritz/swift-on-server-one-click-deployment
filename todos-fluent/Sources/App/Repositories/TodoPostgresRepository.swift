import FluentKit
import Foundation
import Hummingbird

struct TodoPostgresRepository: Sendable {
    private(set) var db: any Database

    public init(db: any Database) {
        self.db = db
    }

    private func query() -> QueryBuilder<TodoModel> {
        TodoModel.query(on: db)
    }

    private func query(_ id: UUID) throws -> QueryBuilder<TodoModel> {
        query().filter(\.$id == id)
    }

    private func query(_ ids: [UUID]) throws -> QueryBuilder<TodoModel> {
        query().filter(\.$id ~~ ids)
    }
}

extension TodoPostgresRepository: TodoRepository {
    func create(title: String, order: Int?, urlPrefix: String) async throws -> Todo {
        let model = TodoModel(title: title, order: order, url: "", completed: false)
        try await model.save(on: db)

        guard
            let uuidString = model.id?.uuidString,
            let todo = model.toDTO()
        else {
            throw TodoPostgresRepositoryError.entityNotCreated
        }

        model.url = urlPrefix + uuidString
        try await model.update(on: db)

        return todo
    }

    func get(id: UUID) async throws -> Todo? {
        guard let model = try await query(id).first() else {
            throw TodoPostgresRepositoryError.entityNotFound
        }

        return model.toDTO()
    }

    func list() async throws -> [Todo] {
        let models = try await query().all()
        return models.compactMap { $0.toDTO() }
    }

    func update(id: UUID, title: String?, order: Int?, completed: Bool?) async throws -> Todo? {
        guard let model = try await query(id).first() else {
            throw TodoPostgresRepositoryError.entityNotFound
        }

        if let title {
            model.title = title
        }

        if let order {
            model.order = order
        }

        if let completed {
            model.completed = completed
        }

        try await model.update(on: db)

        return model.toDTO()
    }

    func delete(id: UUID) async throws -> Bool {
        guard let model = try await query(id).first() else {
            return true
        }

        try await model.delete(on: db)
        return true
    }

    func deleteAll() async throws {
        try await query().all().delete(on: db)
    }
}
