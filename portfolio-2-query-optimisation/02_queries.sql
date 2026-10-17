-- =====================================================================
-- Portfolio 2 - Benchmark queries (used BEFORE and AFTER indexing)
-- File : 02_queries.sql
--
-- HOW TO USE
--   Run each statement on its own: click inside it, press Ctrl+Enter.
--   For every query there are two statements:
--     (a) EXPLAIN ...   -> screenshot the result grid (type, key, rows)
--     (b) the query     -> read the Duration in the Output panel.
--         Run (b) TWICE and note the second time (the first run warms
--         the cache).
--   Do this once BEFORE running 03_add_indexes.sql, and once AFTER.
--   Name screenshots like: before-q1-explain.png, after-q1-explain.png
-- =====================================================================
USE stjude_his;

-- ---------------------------------------------------------------------
-- Q1. How many appointments were there in the first week of March?
-- ---------------------------------------------------------------------
EXPLAIN
SELECT COUNT(*)
FROM Appointment
WHERE AppointmentDate >= '2026-03-01'
  AND AppointmentDate <  '2026-03-08';

SELECT COUNT(*)
FROM Appointment
WHERE AppointmentDate >= '2026-03-01'
  AND AppointmentDate <  '2026-03-08';

-- ---------------------------------------------------------------------
-- Q2. Find a patient by full name (reception search)
-- ---------------------------------------------------------------------
EXPLAIN
SELECT PatientID, FirstName, LastName, Phone
FROM Patient
WHERE LastName = 'Okoro'
  AND FirstName = 'Grace';

SELECT PatientID, FirstName, LastName, Phone
FROM Patient
WHERE LastName = 'Okoro'
  AND FirstName = 'Grace';

-- ---------------------------------------------------------------------
-- Q3. No-show report: no-shows per doctor in March
-- ---------------------------------------------------------------------
EXPLAIN
SELECT DoctorID, COUNT(*) AS no_shows
FROM Appointment
WHERE Status = 'No-Show'
  AND AppointmentDate >= '2026-03-01'
  AND AppointmentDate <  '2026-04-01'
GROUP BY DoctorID
ORDER BY no_shows DESC;

SELECT DoctorID, COUNT(*) AS no_shows
FROM Appointment
WHERE Status = 'No-Show'
  AND AppointmentDate >= '2026-03-01'
  AND AppointmentDate <  '2026-04-01'
GROUP BY DoctorID
ORDER BY no_shows DESC;

-- ---------------------------------------------------------------------
-- Q4. A doctor's schedule for one week
-- ---------------------------------------------------------------------
EXPLAIN
SELECT AppointmentID, PatientID, AppointmentDate, Status
FROM Appointment
WHERE DoctorID = 120
  AND AppointmentDate >= '2026-03-01'
  AND AppointmentDate <  '2026-03-08'
ORDER BY AppointmentDate;

SELECT AppointmentID, PatientID, AppointmentDate, Status
FROM Appointment
WHERE DoctorID = 120
  AND AppointmentDate >= '2026-03-01'
  AND AppointmentDate <  '2026-03-08'
ORDER BY AppointmentDate;

-- ---------------------------------------------------------------------
-- Q5. One patient's visit history with diagnoses (a JOIN query).
-- CONTROL query: it should already be fast, because foreign keys
-- automatically create indexes on Appointment.PatientID etc.
-- ---------------------------------------------------------------------
EXPLAIN
SELECT a.AppointmentDate, CONCAT('Dr ', d.LastName) AS Doctor,
       a.Status, c.Diagnosis
FROM Appointment a
JOIN Doctor d            ON d.DoctorID = a.DoctorID
LEFT JOIN Consultation c ON c.AppointmentID = a.AppointmentID
WHERE a.PatientID = 12345
ORDER BY a.AppointmentDate;

SELECT a.AppointmentDate, CONCAT('Dr ', d.LastName) AS Doctor,
       a.Status, c.Diagnosis
FROM Appointment a
JOIN Doctor d            ON d.DoctorID = a.DoctorID
LEFT JOIN Consultation c ON c.AppointmentID = a.AppointmentID
WHERE a.PatientID = 12345
ORDER BY a.AppointmentDate;
