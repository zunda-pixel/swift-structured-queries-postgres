// MARK: - LATERAL JOIN Operations
//
// PostgreSQL-specific `JOIN LATERAL` / `LEFT JOIN LATERAL` support.
//
// Unlike regular joins, a `LATERAL` subquery may reference columns from the
// preceding FROM-clause items. This is useful for correlated lookups such as
// "latest child row per parent". The correlation closure receives the outer
// table columns so the subquery's `WHERE`/`ORDER`/`LIMIT` can reference them.
//
// Example:
//   RemindersList.leftJoinLateral { list in
//     Reminder
//       .where { $0.remindersListID.eq(list.id) }
//       .order { $0.updatedAt.desc() }
//       .limit(1)
//   }
//
// Generated SQL:
//   FROM "remindersLists"
//   LEFT OUTER JOIN LATERAL (
//     SELECT ... FROM "reminders"
//     WHERE "reminders"."remindersListID" = "remindersLists"."id"
//     ORDER BY "reminders"."updatedAt" DESC
//     LIMIT 1
//   ) AS "reminders" ON TRUE

extension Table {
  /// A select statement for this table inner-joined to a correlated `LATERAL` subquery.
  ///
  /// The subquery may reference columns from this table.
  ///
  /// - Parameter buildSubquery: A closure that receives this table's columns and returns
  ///   a select statement for the lateral subquery.
  /// - Returns: A select statement that `JOIN LATERAL`s the subquery.
  public static func joinLateral<F: Table, each J: Table>(
    _ buildSubquery: (TableColumns) -> some SelectStatement<(), F, (repeat each J)>
  ) -> Select<(), Self, (F, repeat each J)> {
    let subquery = buildSubquery(Self.columns).asSelect()
    let join = _JoinClause(
      operator: .inner,
      table: F.self,
      lateralSubquery: subquery.query
    )
    var result = Select<(), Self, (F, repeat each J)>()
    result.joins = [join]
    return result
  }

  /// A select statement for this table left-joined to a correlated `LATERAL` subquery.
  ///
  /// The subquery may reference columns from this table. Use this for "latest child per
  /// parent" style queries where the child row may not exist.
  ///
  /// - Parameter buildSubquery: A closure that receives this table's columns and returns
  ///   a select statement for the lateral subquery.
  /// - Returns: A select statement that `LEFT JOIN LATERAL`s the subquery.
  public static func leftJoinLateral<F: Table, each J: Table>(
    _ buildSubquery: (TableColumns) -> some SelectStatement<(), F, (repeat each J)>
  ) -> Select<(), Self, (F._Optionalized, repeat (each J)._Optionalized)> {
    let subquery = buildSubquery(Self.columns).asSelect()
    let join = _JoinClause(
      operator: .left,
      table: F.self,
      lateralSubquery: subquery.query
    )
    var result = Select<(), Self, (F._Optionalized, repeat (each J)._Optionalized)>()
    result.joins = [join]
    return result
  }
}

extension Select {
  /// Creates a new select statement from this one by inner-joining a correlated `LATERAL`
  /// subquery.
  ///
  /// The subquery closure receives the FROM table's columns plus any already-joined tables'
  /// columns so the lateral body may correlate against them.
  ///
  /// - Parameter buildSubquery: A closure that receives the available columns and returns
  ///   a select statement for the lateral subquery.
  /// - Returns: A select statement that `JOIN LATERAL`s the subquery.
  public func joinLateral<F: Table, each J: Table, each J2: Table>(
    _ buildSubquery: (
      (From.TableColumns, repeat (each J).TableColumns)
    ) -> some SelectStatement<(), F, (repeat each J2)>
  ) -> Select<(), From, (repeat each J, F, repeat each J2)>
  where Columns == (), Joins == (repeat each J) {
    let subquery = buildSubquery((From.columns, repeat (each J).columns)).asSelect()
    let join = _JoinClause(
      operator: .inner,
      table: F.self,
      lateralSubquery: subquery.query
    )
    var result = Select<(), From, (repeat each J, F, repeat each J2)>(clauses: clauses)
    result.joins = joins + [join]
    return result
  }

  /// Creates a new select statement from this one by left-joining a correlated `LATERAL`
  /// subquery.
  ///
  /// The subquery closure receives the FROM table's columns plus any already-joined tables'
  /// columns so the lateral body may correlate against them.
  ///
  /// - Parameter buildSubquery: A closure that receives the available columns and returns
  ///   a select statement for the lateral subquery.
  /// - Returns: A select statement that `LEFT JOIN LATERAL`s the subquery.
  public func leftJoinLateral<F: Table, each J: Table, each J2: Table>(
    _ buildSubquery: (
      (From.TableColumns, repeat (each J).TableColumns)
    ) -> some SelectStatement<(), F, (repeat each J2)>
  ) -> Select<
    (),
    From,
    (repeat each J, F._Optionalized, repeat (each J2)._Optionalized)
  >
  where Columns == (), Joins == (repeat each J) {
    let subquery = buildSubquery((From.columns, repeat (each J).columns)).asSelect()
    let join = _JoinClause(
      operator: .left,
      table: F.self,
      lateralSubquery: subquery.query
    )
    var result = Select<
      (),
      From,
      (repeat each J, F._Optionalized, repeat (each J2)._Optionalized)
    >(clauses: clauses)
    result.joins = joins + [join]
    return result
  }
}

extension Where {
  /// A select statement for the filtered table inner-joined to a correlated `LATERAL`
  /// subquery.
  public func joinLateral<F: Table, each J: Table>(
    _ buildSubquery: (From.TableColumns) -> some SelectStatement<(), F, (repeat each J)>
  ) -> Select<(), From, (F, repeat each J)> {
    let subquery = buildSubquery(From.columns).asSelect()
    let join = _JoinClause(
      operator: .inner,
      table: F.self,
      lateralSubquery: subquery.query
    )
    var result = Select<(), From, (F, repeat each J)>(clauses: _selectClauses)
    result.joins.append(join)
    return result
  }

  /// A select statement for the filtered table left-joined to a correlated `LATERAL`
  /// subquery.
  public func leftJoinLateral<F: Table, each J: Table>(
    _ buildSubquery: (From.TableColumns) -> some SelectStatement<(), F, (repeat each J)>
  ) -> Select<(), From, (F._Optionalized, repeat (each J)._Optionalized)> {
    let subquery = buildSubquery(From.columns).asSelect()
    let join = _JoinClause(
      operator: .left,
      table: F.self,
      lateralSubquery: subquery.query
    )
    var result = Select<
      (),
      From,
      (F._Optionalized, repeat (each J)._Optionalized)
    >(clauses: _selectClauses)
    result.joins.append(join)
    return result
  }
}
