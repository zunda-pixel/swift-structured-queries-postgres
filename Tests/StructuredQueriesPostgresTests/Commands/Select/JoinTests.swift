import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.Commands.Select {
  @Suite struct JoinTests {
    @Test func basics() async {
      await assertSQL(
        of:
          Reminder
          .order { $0.dueDate.desc() }
          .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
          .select { ($0.title, $1.title) }
      ) {
        """
        SELECT "reminders"."title", "remindersLists"."title"
        FROM "reminders"
        JOIN "remindersLists" ON ("reminders"."remindersListID") = ("remindersLists"."id")
        ORDER BY "reminders"."dueDate" DESC
        """
      }
    }

    @Test func outerJoinOptional() async {
      await assertSQL(
        of:
          RemindersList
          .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
          .select {
            PriorityRow.Columns(value: $1.priority)
          }
      ) {
        """
        SELECT "reminders"."priority" AS "value"
        FROM "remindersLists"
        LEFT OUTER JOIN "reminders" ON ("remindersLists"."id") = ("reminders"."remindersListID")
        """
      }
    }

    @Test func leftJoinLateralLatestChild() async {
      await assertSQL(
        of:
          RemindersList
          .leftJoinLateral { list in
            Reminder
              .where { $0.remindersListID.eq(list.id) }
              .order { $0.updatedAt.desc() }
              .limit(1)
          }
          .select { ($0.title, $1.title) }
      ) {
        """
        SELECT "remindersLists"."title", "reminders"."title"
        FROM "remindersLists"
        LEFT OUTER JOIN LATERAL (SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "reminders"
        WHERE ("reminders"."remindersListID") = ("remindersLists"."id")
        ORDER BY "reminders"."updatedAt" DESC
        LIMIT 1) AS "reminders" ON TRUE
        """
      }
    }

    @Test func innerJoinLateral() async {
      await assertSQL(
        of:
          RemindersList
          .joinLateral { list in
            Reminder
              .where { $0.remindersListID.eq(list.id) }
              .order(by: \.dueDate)
              .limit(1)
          }
          .select { ($0.title, $1.title) }
      ) {
        """
        SELECT "remindersLists"."title", "reminders"."title"
        FROM "remindersLists"
        INNER JOIN LATERAL (SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "reminders"
        WHERE ("reminders"."remindersListID") = ("remindersLists"."id")
        ORDER BY "reminders"."dueDate"
        LIMIT 1) AS "reminders" ON TRUE
        """
      }
    }

    @Test func leftJoinLateralFromWhere() async {
      await assertSQL(
        of:
          RemindersList
          .where { $0.position.gt(0) }
          .leftJoinLateral { list in
            Reminder
              .where { $0.remindersListID.eq(list.id) }
              .order { $0.updatedAt.desc() }
              .limit(1)
          }
          .select { ($0.title, $1.title) }
      ) {
        """
        SELECT "remindersLists"."title", "reminders"."title"
        FROM "remindersLists"
        LEFT OUTER JOIN LATERAL (SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "reminders"
        WHERE ("reminders"."remindersListID") = ("remindersLists"."id")
        ORDER BY "reminders"."updatedAt" DESC
        LIMIT 1) AS "reminders" ON TRUE
        WHERE ("remindersLists"."position") > (0)
        """
      }
    }
  }
}

@Selection
private struct PriorityRow {
  let value: Priority?
}
