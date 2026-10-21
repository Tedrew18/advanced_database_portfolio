-- =====================================================================
-- Portfolio 3 - Demo 3: Isolation levels
-- File : 03_isolation_levels.sql
-- Scenario: a doctor (TAB A) reads an appointment's status twice inside
-- one transaction while a receptionist (TAB B) cancels it in between.
--   READ COMMITTED   -> the second read sees the change (non-repeatable read)
--   REPEATABLE READ  -> the second read still sees the original value
--                       (MySQL's default level)
--
-- NEEDS TWO SESSIONS, TAB A and TAB B (see the instructions at the top of
-- 02_double_booking_race.sql; check SELECT CONNECTION_ID() differs, and
-- run  USE stjude_his;  in both tabs).
-- Run 00_reset_portfolio3.sql first. Run one statement at a time.
-- =====================================================================

-- ---- SETUP (either tab) ----
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Reason, Status)
VALUES (5, 101, '2026-11-04 09:00:00', 'Routine check-up', 'Confirmed');

-- =====================================================================
-- PART 1: READ COMMITTED
-- =====================================================================

-- ---- TAB A (1) ----
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT @@transaction_isolation AS isolation_level;    -- screenshot: iso-1-readcommitted-setting.png
START TRANSACTION;
SELECT AppointmentID, Status FROM Appointment
WHERE DoctorID = 101 AND AppointmentDate = '2026-11-04 09:00:00';
-- Expected: Confirmed.  Screenshot: iso-2-tabA-first-read.png

-- ---- TAB B (2): the receptionist cancels (autocommit saves it at once) ----
UPDATE Appointment SET Status = 'Cancelled'
WHERE DoctorID = 101 AND AppointmentDate = '2026-11-04 09:00:00';

-- ---- TAB A (3): read AGAIN inside the same transaction ----
SELECT AppointmentID, Status FROM Appointment
WHERE DoctorID = 101 AND AppointmentDate = '2026-11-04 09:00:00';
-- Expected: Cancelled (the value changed mid-transaction).
-- Screenshot: iso-3-tabA-second-read-readcommitted.png
COMMIT;

-- ---- TAB B (4): put the status back for Part 2 ----
UPDATE Appointment SET Status = 'Confirmed'
WHERE DoctorID = 101 AND AppointmentDate = '2026-11-04 09:00:00';

-- =====================================================================
-- PART 2: REPEATABLE READ (MySQL default)
-- =====================================================================

-- ---- TAB A (5) ----
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT @@transaction_isolation AS isolation_level;    -- screenshot: iso-4-repeatableread-setting.png
START TRANSACTION;
SELECT AppointmentID, Status FROM Appointment
WHERE DoctorID = 101 AND AppointmentDate = '2026-11-04 09:00:00';
-- Expected: Confirmed.

-- ---- TAB B (6): cancel again ----
UPDATE Appointment SET Status = 'Cancelled'
WHERE DoctorID = 101 AND AppointmentDate = '2026-11-04 09:00:00';

-- ---- TAB A (7): read AGAIN inside the same transaction ----
SELECT AppointmentID, Status FROM Appointment
WHERE DoctorID = 101 AND AppointmentDate = '2026-11-04 09:00:00';
-- Expected: still Confirmed (TAB A works from its own snapshot).
-- Screenshot: iso-5-tabA-second-read-repeatableread.png
COMMIT;

-- ---- TAB A (8): after the transaction ends, a new read sees the change ----
SELECT AppointmentID, Status FROM Appointment
WHERE DoctorID = 101 AND AppointmentDate = '2026-11-04 09:00:00';
-- Expected: Cancelled.  Screenshot: iso-6-tabA-after-commit.png
