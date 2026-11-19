//
//  Connection+SafeReads.swift
//  tealium-prism
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite

extension Connection {
    /// Every row of `query`, read with `prepareRowIterator`: its `failableNext()` throws on a row it can't read, while `prepare(_:)`'s
    /// iterator, like any `next()`, is a `try!` and would crash.
    func allRows(_ query: QueryType) throws -> [Row] {
        try Array(prepareRowIterator(query))
    }

    /// Every row of `sql` with `bindings`.
    func allRows(_ sql: String, _ bindings: [Binding?]) throws -> [[Binding?]] {
        let statement = try prepare(sql, bindings)
        var rows = [[Binding?]]()
        // Not `for … in`: the statement's iterator is a `try!` in SQLite.swift.
        while let row = try statement.failableNext() {
            rows.append(row)
        }
        return rows
    }

    /// The value of `query`'s first row. Unlike SQLite.swift's typed `scalar(_:)`, which force-unwraps and force-casts, it throws on a missing row, a `NULL` or a value that isn't a `V`.
    ///
    /// - Throws: `QueryError.unexpectedNullValue` if there is no row, or its value is `NULL` or not a `V`.
    func checkedScalar<V: Value>(_ query: ScalarQuery<V>) throws -> V {
        let expression = query.expression
        let statement = try prepare(expression.template, expression.bindings)
        guard let row = try statement.failableNext(),
              let datatypeValue = row.first as? V.Datatype,
              let value = try V.fromDatatypeValue(datatypeValue) as? V else {
            throw QueryError.unexpectedNullValue(name: expression.template)
        }
        return value
    }
}
