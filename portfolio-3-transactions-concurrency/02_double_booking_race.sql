-- =====================================================================
-- Portfolio 3 - Demo 2: Two receptionists book the same slot at once
-- File : 02_double_booking_race.sql
-- Control mechanism: the UNIQUE constraint (uq_doctor_active_slot) plus
-- InnoDB row locking. The second booker WAITS for the first transaction
-- to finish, then either gets a duplicate-key error (first one committed)
-- or succeeds (first one rolled back).
--
-- YOU NEED TWO SESSIONS ("TAB A" and "TAB B"):
--   File -> New Query Tab twice, or open the connection twice.
--   In each tab run:  SELECT CONNECTION_ID();
--   The two numbers MUST be different. If they match, open the second
--   tab by double-clicking the connection on the Workbench home page.
--   Also run  USE stjude_his;  in BOTH tabs.
--
-- TIMING WARNING: when TAB B is waiting, you have about 40 seconds to
-- go to TAB A and COMMIT/ROLLBACK before MySQL gives up (error 1205).
-- Run 00_reset_portfolio3.sql first to start clean.
-- Run each statement one at a time (click inside it, Ctrl+Enter).
-- =====================================================================

-- =====================================================================
-- SCENARIO 1: first booker COMMITS, second booker is rejected
-- Slot used: Doctor 103 at 2026-11-03 10:00
-- =====================================================================

-- ---- TAB A (step 1) ----
START TRANSACTION;
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Reason, Status)
VALUES (3, 103, '2026-11-03 10:00:00', 'Check-up', 'Confirmed');
-- Do NOT commit yet. Screenshot: race-1-tabA-inserted.png

-- ---- TAB B (step 2) ----
START TRANSACTION;
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Reason, Status)
VALUES (4, 103, '2026-11-03 10:00:00', 'Fever', 'Confirmed');
-- TAB B now WAITS (the toolbar shows it still executing).
-- Screenshot the waiting tab: race-2-tabB-waiting.png

-- ---- TAB A (step 3, within ~40 seconds) ----
COMMIT;

-- ---- TAB B (step 4) ----
-- The waiting INSERT now fails with: Error 1062 Duplicate entry ...
-- Screenshot the error: race-3-tabB-duplicate-error.png
ROLLBACK;

-- =====================================================================
-- SCENARIO 2: first booker ROLLS BACK, second booker succeeds
-- Slot used: Doctor 103 at 2026-11-03 10:30
-- =====================================================================

-- ---- TAB A (step 5) ----
START TRANSACTION;
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Reason, Status)
VALUES (3, 103, '2026-11-03 10:30:00', 'Follow-up', 'Confirmed');

-- ---- TAB B (step 6) ----
START TRANSACTION;
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Reason, Status)
VALUES (4, 103, '2026-11-03 10:30:00', 'Follow-up', 'Confirmed');
-- TAB B waits again.

-- ---- TAB A (step 7, within ~40 seconds) ----
ROLLBACK;

-- ---- TAB B (step 8) ----
-- The INSERT now succeeds (1 row affected).
-- Screenshot: race-4-tabB-success.png
COMMIT;

-- =====================================================================
-- FINAL CHECK (either tab)
-- Expected: 10:00 booked by patient 3; 10:30 booked by patient 4.
-- Screenshot: race-5-final-state.png
-- =====================================================================
SELECT AppointmentID, PatientID, DoctorID, AppointmentDate, Status
FROM Appointment
WHERE DoctorID = 103 AND AppointmentDate >= '2026-11-03'
ORDER BY AppointmentDate;
