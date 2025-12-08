//
//  CreateBlogPostModel.swift
//  todos-postgres-tutorial
//
//  Created by Moritz Ellerbrock on 08.12.25.
//


import FluentKit

struct CreateTodoModel: AsyncMigration {
    typealias ToDoFieldKeys = ModelDefinition.FieldKeys
    func prepare(on database: any Database) async throws {
        try await database.schema(ModelDefinition.schema)
            .id()
            .field(ToDoFieldKeys.title, .string, .required)
            .field(ToDoFieldKeys.order, .int16)
            .field(ToDoFieldKeys.url, .string)
            .field(ToDoFieldKeys.completed, .bool, .required)

            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(ModelDefinition.schema)
            .delete()
    }
}
