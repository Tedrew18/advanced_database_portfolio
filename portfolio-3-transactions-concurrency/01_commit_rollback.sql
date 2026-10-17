-- =====================================================================
-- Portfolio 3 - Demo 1: COMMIT and ROLLBACK (atomicity)
-- File : 01_commit_rollback.sql
-- Business process: "complete a consultation". Four tables change
-- together: the appointment status, the consultation, the prescription
-- and the prescription item. Either ALL changes are saved, or NONE.
--
-- HOW TO RUN: use ONE query tab for the whole demo.
--   Highlight a BLOCK with the mouse (from its "BLOCK" comment to the
--   last statement before the next block) and press Ctrl+Enter.
--   Take a screenshot after each block, as noted.
-- =====================================================================
USE stjude_his;

-- ---------------------------------------------------------------------
-- BLOCK 0: current settings (screenshot: demo1-settings.png)
-- autocommit = 1 means every statement is saved immediately UNLESS you
-- start a transaction with START TRANSACTION.
-- ---------------------------------------------------------------------
SELECT @@autocommit AS autocommit, @@transaction_isolation AS isolation_level;

-- ---------------------------------------------------------------------
-- BLOCK 1: setup - two appointments to work with
-- ---------------------------------------------------------------------
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Reason, Status)
VALUES (1, 102, '2026-11-02 09:00:00', 'Chest pain review',      'Confirmed'),
       (2, 102, '2026-11-02 09:30:00', 'Blood pressure review',  'Confirmed');

SET @appt_commit   = (SELECT AppointmentID FROM Appointment
                      WHERE DoctorID = 102 AND AppointmentDate = '2026-11-02 09:00:00');
SET @appt_rollback = (SELECT AppointmentID FROM Appointment
                      WHERE DoctorID = 102 AND AppointmentDate = '2026-11-02 09:30:00');

SELECT AppointmentID, PatientID, DoctorID, AppointmentDate, Status
FROM Appointment
WHERE AppointmentID IN (@appt_commit, @appt_rollback);

-- ---------------------------------------------------------------------
-- BLOCK 2: a transaction that COMMITS (screenshot: demo1-commit-block.png)
-- ---------------------------------------------------------------------
START TRANSACTION;

UPDATE Appointment SET Status = 'Completed' WHERE AppointmentID = @appt_commit;

INSERT INTO Consultation (AppointmentID, Diagnosis, Notes)
VALUES (@appt_commit, 'Hypertension (Stage 1)', 'BP 150/95. Started on amlodipine.');
SET @consult_commit = LAST_INSERT_ID();

INSERT INTO Prescription (ConsultationID) VALUES (@consult_commit);
SET @rx_commit = LAST_INSERT_ID();

INSERT INTO PrescriptionItem (PrescriptionID, MedicationID, Dosage, Frequency, DurationDays)
VALUES (@rx_commit, 1, '1 tablet', 'Once daily', 30);

-- Visible inside this transaction, not yet permanent:
SELECT AppointmentID, Status FROM Appointment WHERE AppointmentID = @appt_commit;

COMMIT;

-- ---------------------------------------------------------------------
-- BLOCK 3: verify the committed work (screenshot: demo1-commit-result.png)
-- Expected: Status = Completed, a diagnosis and Amlodipine appear.
-- ---------------------------------------------------------------------
SELECT a.AppointmentID, a.Status, c.Diagnosis, m.MedicationName, pi.Frequency
FROM Appointment a
LEFT JOIN Consultation c       ON c.AppointmentID  = a.AppointmentID
LEFT JOIN Prescription pr      ON pr.ConsultationID = c.ConsultationID
LEFT JOIN PrescriptionItem pi  ON pi.PrescriptionID = pr.PrescriptionID
LEFT JOIN Medication m         ON m.MedicationID    = pi.MedicationID
WHERE a.AppointmentID = @appt_commit;

-- ---------------------------------------------------------------------
-- BLOCK 4: a transaction that FAILS part-way
-- The last INSERT uses medication 999, which does not exist, so MySQL
-- raises error 1452 (foreign key). Highlight and run this whole block;
-- it stops at the error, which is expected.
-- (screenshot the Output panel: demo1-rollback-error.png)
-- ---------------------------------------------------------------------
START TRANSACTION;

UPDATE Appointment SET Status = 'Completed' WHERE AppointmentID = @appt_rollback;

INSERT INTO Consultation (AppointmentID, Diagnosis, Notes)
VALUES (@appt_rollback, 'Migraine', 'Photophobia, mild nausea.');
SET @consult_rb = LAST_INSERT_ID();

INSERT INTO Prescription (ConsultationID) VALUES (@consult_rb);
SET @rx_rb = LAST_INSERT_ID();

INSERT INTO PrescriptionItem (PrescriptionID, MedicationID, Dosage, Frequency, DurationDays)
VALUES (@rx_rb, 999, '1 tablet', 'Twice daily', 5);

-- ---------------------------------------------------------------------
-- BLOCK 5: the transaction is STILL OPEN. Only the failed statement was
-- undone; the earlier changes are pending.
-- Expected: appointment_status = Completed, consultations = 1, prescriptions = 1
-- (screenshot: demo1-pending-state.png)
-- ---------------------------------------------------------------------
SELECT Status AS appointment_status,
       (SELECT COUNT(*) FROM Consultation WHERE AppointmentID  = @appt_rollback) AS consultations,
       (SELECT COUNT(*) FROM Prescription WHERE ConsultationID = @consult_rb)    AS prescriptions
FROM Appointment
WHERE AppointmentID = @appt_rollback;

-- ---------------------------------------------------------------------
-- BLOCK 6: undo everything in the transaction
-- ---------------------------------------------------------------------
ROLLBACK;

-- ---------------------------------------------------------------------
-- BLOCK 7: verify nothing was saved (screenshot: demo1-after-rollback.png)
-- Expected: appointment_status = Confirmed, consultations = 0, prescriptions = 0
-- ---------------------------------------------------------------------
SELECT Status AS appointment_status,
       (SELECT COUNT(*) FROM Consultation WHERE AppointmentID  = @appt_rollback) AS consultations,
       (SELECT COUNT(*) FROM Prescription WHERE ConsultationID = @consult_rb)    AS prescriptions
FROM Appointment
WHERE AppointmentID = @appt_rollback;
