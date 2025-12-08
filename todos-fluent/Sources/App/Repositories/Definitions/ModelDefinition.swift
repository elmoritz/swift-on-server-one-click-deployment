//
//  File.swift
//  todos-postgres-tutorial
//
//  Created by Moritz Ellerbrock on 08.12.25.
//

import FluentKit

enum ModelDefinition {
    static var schema: String { "todos" }
    enum FieldKeys {
        static var title: FieldKey { "title" }
        static var order: FieldKey { "order" }
        static var url: FieldKey { "url" }
        static var completed: FieldKey { "completed" }
    }
}
