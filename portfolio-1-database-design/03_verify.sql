-- =====================================================================
-- Portfolio 1 - Verification script (run after 01 and 02)
-- Run each block separately and screenshot the output as evidence.
-- =====================================================================
USE stjude_his;

-- Test 1: all tables exist
SHOW TABLES;

-- Test 2: row counts
SELECT 'Department' AS tbl, COUNT(*) AS n FROM Department UNION ALL
SELECT 'Doctor',            COUNT(*) FROM Doctor          UNION ALL
SELECT 'Patient',           COUNT(*) FROM Patient         UNION ALL
SELECT 'Appointment',       COUNT(*) FROM Appointment     UNION ALL
SELECT 'Consultation',      COUNT(*) FROM Consultation    UNION ALL
SELECT 'Medication',        COUNT(*) FROM Medication      UNION ALL
SELECT 'Prescription',      COUNT(*) FROM Prescription    UNION ALL
SELECT 'PrescriptionItem',  COUNT(*) FROM PrescriptionItem UNION ALL
SELECT 'LabTest',           COUNT(*) FROM LabTest         UNION ALL
SELECT 'LabResult',         COUNT(*) FROM LabResult;

-- Test 3: double-booking MUST FAIL (expect ERROR 1062 Duplicate entry)
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Status)
VALUES (2, 101, '2026-10-15 10:00:00', 'Confirmed');

-- Test 4: re-booking a free slot MUST SUCCEED (11:00 is taken, 12:00 is free)
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Status)
VALUES (2, 101, '2026-10-15 12:00:00', 'Confirmed');

-- Test 5: invalid status MUST FAIL (expect CHECK constraint violation)
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Status)
VALUES (2, 102, '2026-10-17 09:00:00', 'Maybe');

-- Test 6: foreign key MUST FAIL (patient 999 does not exist)
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Status)
VALUES (999, 102, '2026-10-17 10:00:00', 'Scheduled');

-- Test 7: a cancelled slot is re-bookable.
-- Cancel appointment 2 (doctor 101, 11:00), then book that slot for patient 5.
UPDATE Appointment SET Status = 'Cancelled' WHERE AppointmentID = 2;
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Status)
VALUES (5, 101, '2026-10-15 11:00:00', 'Confirmed');   -- should succeed

-- Test 8: a patient's full history (appointments -> diagnosis -> drugs)
SELECT  CONCAT(p.FirstName, ' ', p.LastName) AS Patient,
        a.AppointmentDate,
        CONCAT('Dr ', d.LastName)            AS Doctor,
        dep.DepartmentName,
        c.Diagnosis,
        m.MedicationName, m.Strength, pi.Frequency, pi.DurationDays
FROM Patient p
JOIN Appointment a        ON a.PatientID = p.PatientID
JOIN Doctor d             ON d.DoctorID = a.DoctorID
JOIN Department dep       ON dep.DepartmentID = d.DepartmentID
LEFT JOIN Consultation c  ON c.AppointmentID = a.AppointmentID
LEFT JOIN Prescription pr ON pr.ConsultationID = c.ConsultationID
LEFT JOIN PrescriptionItem pi ON pi.PrescriptionID = pr.PrescriptionID
LEFT JOIN Medication m    ON m.MedicationID = pi.MedicationID
WHERE p.PatientID = 1
ORDER BY a.AppointmentDate;
