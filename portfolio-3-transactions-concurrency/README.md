# Portfolio 3: Transactions and Concurrency

Case study: **St. Jude Clinical Health Information System (HIS)**, the `stjude_his` database from [Portfolio 1](../portfolio-1-database-design/README.md) with the data volume added in [Portfolio 2](../portfolio-2-query-optimisation/README.md).
Environment: MySQL 8.0.46 (InnoDB), MySQL Workbench, two separate query sessions (checked with `CONNECTION_ID()`).

## 1. What was tested

| Demo | Question | Script | Evidence prefix |
|---|---|---|---|
| 1 | Are multi-table changes all-or-nothing (commit and rollback)? | `01_commit_rollback.sql` | `demo1-` |
| 2 | What happens when two receptionists book the same slot at the same time? | `02_double_booking_race.sql` | `race-` |
| 3 | What does each isolation level let a transaction see? | `03_isolation_levels.sql` | `iso-` |
| 4 | Is "lock the slot with `SELECT ... FOR UPDATE`, then `INSERT`" safe? | `04_deadlock_select_for_update.sql` | `dl-` |

`00_reset_portfolio3.sql` removes the demo data (appointments dated 2026-11-01 or later) so any demo can be repeated. Portfolio 1 and 2 data is not touched.

## 2. Demo 1: Commit and rollback (atomicity)

**Business process:** completing a consultation changes four tables together: `Appointment` (status), `Consultation`, `Prescription` and `PrescriptionItem`.

**Commit path.** One transaction updated the appointment to `Completed`, inserted the consultation, the prescription and a prescription item, then ran `COMMIT`. A follow-up query returned appointment `131081`, status `Completed`, diagnosis `Hypertension (Stage 1)`, medication `Amlodipine`, frequency `Once daily`.

**Rollback path.** A second transaction did the same steps, but the last `INSERT` referenced medication `999`, which does not exist. MySQL raised `Error Code: 1452 ... a foreign key constraint fails ('stjude_his'.'prescriptionitem' ...)`.

| State | Appointment status | Consultations | Prescriptions |
|---|---|---|---|
| After the error, transaction still open | `Completed` | 1 | 1 |
| After `ROLLBACK` | `Confirmed` | 0 | 0 |

The failed statement undid only itself. The earlier changes stayed pending inside the open transaction until `ROLLBACK`, which removed all of them, so no half-finished consultation was left behind.

Evidence: `demo1-settings.png`, `demo1-commit-block.png`, `demo1-commit-result.png`, `demo1-rollback-error.png`, `demo1-pending-state.png`, `demo1-after-rollback.png`.

## 3. Demo 2: Two receptionists book the same slot (concurrency control)

Two sessions ran at once (connection IDs 124 and 126). Both tried to book Doctor 103 at the same time. The control mechanism is the `UNIQUE (DoctorID, ActiveSlot)` constraint from Portfolio 1 together with InnoDB row locking. No `SELECT ... FOR UPDATE` was used.

**Scenario 1: the first booker commits.**
1. Session A started a transaction and inserted the 10:00 booking, without committing.
2. Session B inserted the same slot and **waited** (the insert took 8.047 s).
3. Session A ran `COMMIT`. Session B then failed with `Error Code: 1062. Duplicate entry '103-2026-11-03 10:00:00' for key 'appointment.uq_doctor_active_slot'`.
4. A final query showed one appointment for that slot (`131086`, patient 3).

**Scenario 2: the first booker rolls back.**
1. Session A inserted the 10:30 booking without committing.
2. Session B inserted the same slot and waited (the insert took 14.594 s).
3. Session A ran `ROLLBACK`. Session B's insert then succeeded (`1 row(s) affected`) and was committed.

The second session never saw an inconsistent state. It waited, then either received a clean duplicate-key error or got the slot, depending on what the first session did.

Evidence: `race-0-tabA-connection.png`, `race-0-tabB-connection.png`, `race-1-tabA-inserted.png`, `race-2-tabB-waiting.png`, `race-3-tabB-duplicate-error.png`, `race-3b-slot-owner.png`, `race-5-tabB-success.png`, `race-6-final-state.png`.

## 4. Demo 3: Isolation levels

One appointment (`131100`) was read twice by Session A inside a single open transaction. Between the two reads, Session B cancelled the appointment and saved the change.

| Isolation level | First read | Second read (same transaction) | After `COMMIT` |
|---|---|---|---|
| `READ COMMITTED` | `Confirmed` (12:04:16) | **`Cancelled`** (12:11:46) | not tested |
| `REPEATABLE READ` (MySQL default) | `Confirmed` (12:25:50) | **`Confirmed`** (12:30:54) | `Cancelled` (12:33:43) |

Under `READ COMMITTED` the same query gave two different answers inside one transaction (a non-repeatable read). Under `REPEATABLE READ` the transaction kept seeing the snapshot taken at its first read until it committed. In both runs there was no `COMMIT` between the two reads, as the Output panel rows show.

Evidence: `iso-1-readcommitted-setting.png`, `iso-2-tabA-first-read.png`, `iso-3-tabA-second-read-readcommitted.png`, `iso-4-repeatableread-setting.png`, `iso-4b-tabA-first-read-repeatableread.png`, `iso-5-tabA-second-read-repeatableread.png`, `iso-6-tabA-after-commit.png`.

## 5. Demo 4: Deadlock from `SELECT ... FOR UPDATE` then `INSERT`

This is the booking pattern used at the start of the project: lock the slot with `SELECT ... FOR UPDATE`, then insert if it is free. It was run for an empty slot (Doctor 102 at 2026-11-05 11:00) with both sessions at `REPEATABLE READ`.

1. Session A: `START TRANSACTION` and `SELECT ... FOR UPDATE` returned **0 rows**.
2. Session B: the same two statements also returned **0 rows** and **were not blocked**, even though A's lock was still held.
3. Session A ran its `INSERT` and had to wait.
4. Session B ran its `INSERT`. MySQL detected that the two sessions were waiting for each other and cancelled Session B's transaction with `Error Code: 1213. Deadlock found when trying to get lock; try restarting transaction` (after 0.047 s).
5. Session A's insert then completed. Afterwards one appointment existed for the slot (`131101`).

**Why it happens.** When the slot is empty there is no row to lock, so `FOR UPDATE` takes a gap lock on the index range instead. Gap locks held by different sessions do not conflict with each other, so both sessions got them. Each `INSERT` then needed to place a row inside a gap the other session had locked. I did not inspect the exact lock type or index in `SHOW ENGINE INNODB STATUS`.

No double booking occurred, because the unique constraint still protected the data, but one transaction was lost and the application would have to catch error `1213` and retry.

Evidence: `dl-1-tabA-locked.png`, `dl-2-tabB-locked.png`, `dl-3-deadlock-error.png`, `dl-4-final-state.png`.

## 6. Comparison and recommendation

| Approach | Result observed | Verdict |
|---|---|---|
| Plain `INSERT` + unique constraint (Demo 2) | Second session waits, then gets `1062` or succeeds | **Recommended.** Simple, no deadlock seen |
| `SELECT ... FOR UPDATE`, then `INSERT` (Demo 4) | Both sessions locked the empty slot; deadlock `1213` | Works, but adds a lock that does not help here and causes errors |
| Multi-table transaction (Demo 1) | All four tables saved together, or none | Use for any process that changes several tables |

Recommendations for the clinic system:
- Rely on the unique constraint for double-booking, and show the user "slot already taken" when `1062` occurs.
- Wrap multi-table work in one transaction and `ROLLBACK` on any error.
- Retry a transaction that fails with `1213`.
- Keep transactions short, because open transactions hold locks and snapshots (my Demo 3 transactions were open for minutes, which is only safe because they read only).
- Keep the default `REPEATABLE READ` unless a reporting query needs to see other sessions' changes immediately.

## 7. Limitations and practical notes

- The demos were run by hand in two Workbench sessions, so waiting times (8.047 s, 14.594 s) depend on how quickly I switched tabs.
- Workbench's read timeout interrupted my first race attempt (`Error 2013` after 30 s). Waiting sessions must be resolved before that limit.
- I did not test `READ COMMITTED` in the deadlock demo. In InnoDB, `READ COMMITTED` reduces gap locking, so the outcome might differ. This is untested here.
- The `FOR UPDATE` lookup uses whichever index the optimiser picks, which may include the index added in Portfolio 2. I did not verify this.
- Each demo used a single run, not repeated trials.

## 8. How to reproduce

```text
1. Run Portfolio 1 and Portfolio 2 scripts first (schema, data).
2. Run 00_reset_portfolio3.sql before each demo.
3. Demo 1: one query tab, run the blocks of 01_commit_rollback.sql in order.
4. Demos 2-4: open two query tabs with different CONNECTION_ID() values,
   run USE stjude_his; in both, and follow the TAB A / TAB B steps in the scripts.
```
