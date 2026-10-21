-- =====================================================================
-- Portfolio 3 - Demo 4: Deadlock from "SELECT ... FOR UPDATE, then INSERT"
-- File : 04_deadlock_select_for_update.sql
-- This is the booking pattern from the start of the project:
--   lock the slot with SELECT ... FOR UPDATE, then INSERT if free.
-- When the slot is EMPTY, FOR UPDATE locks a GAP in the index, not a row.
-- Two sessions can both hold that gap lock at the same time, and then
-- each INSERT waits for the other's lock -> DEADLOCK. InnoDB detects it,
-- rolls one transaction back (error 1213) and lets the other continue.
-- Demo 2 shows the better pattern: plain INSERT + the UNIQUE constraint.
--
-- NEEDS TWO SESSIONS, TAB A and TAB B (see 02_double_booking_race.sql;
-- check SELECT CONNECTION_ID() differs, and run USE stjude_his; in both).
-- Isolation must be REPEATABLE READ (the default): run in both tabs
--   SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- Run 00_reset_portfolio3.sql first. Run one statement at a time.
-- Slot used: Doctor 102 at 2026-11-05 11:00 (empty)
-- =====================================================================

-- ---- TAB A (1) ----
START TRANSACTION;
SELECT AppointmentID FROM Appointment
WHERE DoctorID = 102 AND AppointmentDate = '2026-11-05 11:00:00'
FOR UPDATE;
-- Expected: 0 rows (the slot is free). Screenshot: dl-1-tabA-locked.png

-- ---- TAB B (2) ----
START TRANSACTION;
SELECT AppointmentID FROM Appointment
WHERE DoctorID = 102 AND AppointmentDate = '2026-11-05 11:00:00'
FOR UPDATE;
-- Also 0 rows, and it is NOT blocked. Both tabs now hold a gap lock.
-- Screenshot: dl-2-tabB-locked.png

-- ---- TAB A (3) ----
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Reason, Status)
VALUES (3, 102, '2026-11-05 11:00:00', 'Check-up', 'Confirmed');
-- TAB A now WAITS for TAB B's gap lock.

-- ---- TAB B (4, within ~40 seconds) ----
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Reason, Status)
VALUES (4, 102, '2026-11-05 11:00:00', 'Fever', 'Confirmed');
-- EXPECTED: one tab gets
--   Error Code: 1213. Deadlock found when trying to get lock;
--   try restarting transaction
-- Screenshot the error: dl-3-deadlock-error.png
-- The other tab's INSERT then completes.

-- ---- THE TAB THAT DID NOT GET THE ERROR ----
COMMIT;

-- ---- THE TAB THAT GOT THE ERROR: its transaction was rolled back already.
-- Nothing to undo. (Running ROLLBACK anyway is harmless.)
ROLLBACK;

-- ---- OPTIONAL EVIDENCE (either tab) ----
-- The LATEST DETECTED DEADLOCK section describes what happened.
-- In Workbench, click the cell in the "Status" column, then the
-- "Open value in viewer" icon, to read it.
SHOW ENGINE INNODB STATUS;

-- ---- FINAL CHECK (either tab): only ONE appointment exists for the slot
SELECT AppointmentID, PatientID, DoctorID, AppointmentDate, Status
FROM Appointment
WHERE DoctorID = 102 AND AppointmentDate = '2026-11-05 11:00:00';
