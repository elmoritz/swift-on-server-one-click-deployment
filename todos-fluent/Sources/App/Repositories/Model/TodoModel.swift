//
//  Todo.swift
//  todos-postgres-tutorial
//
//  Created by Moritz Ellerbrock on 08.12.25.
//


import FluentKit
import Foundation
import Hummingbird

/// Database description of a Todo
final class TodoModel: Model {
    typealias ToDoFieldKeys = ModelDefinition.FieldKeys

    static let schema = "todos"

    @ID(key: .id)
    var id: UUID?

    @Field(key: ToDoFieldKeys.title)
    var title: String

    @Field(key: ToDoFieldKeys.order)
    var order: Int?

    @Field(key: ToDoFieldKeys.url)
    var url: String?

    @Field(key: ToDoFieldKeys.completed)
    var completed: Bool

    init() {}

    init(id: UUID? = nil, title: String, order: Int? = nil, url: String? = nil, completed: Bool = false) {
        self.id = id
        self.title = title
        self.order = order
        self.url = url
        self.completed = completed
    }

    func update(title: String? = nil, order: Int? = nil, completed: Bool? = nil) {
        if let title {
            self.title = title
        }
        if let completed {
            self.completed = completed
        }

        if let order {
            self.order = order
        }
    }
}


extension TodoModel {
    func toDTO() -> Todo? {
        guard let id else {
            return nil
        }
        return Todo(id: id, title: self.title, order: self.order, url: self.url ?? "", completed: self.completed)
    }
}
