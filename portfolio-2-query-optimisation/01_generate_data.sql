-- =====================================================================
-- MIT 8103 Advanced Database Systems - Portfolio 2
-- Case study : St. Jude Clinical Health Information System (HIS)
-- File       : 01_generate_data.sql
-- Purpose    : Generate ~100,000 synthetic appointments so that indexes
--              and EXPLAIN plans show a measurable difference.
-- Target     : MySQL 8.0 (uses recursive CTEs)
-- Prerequisite: Portfolio 1 scripts (01_schema.sql, 02_seed_data.sql)
--               have already been run. All data is fictional.
-- Re-runnable: yes. The CLEAN-UP section removes earlier generated rows
--               (generated appointments are all dated before 2026-10-01;
--               the Portfolio 1 sample appointments are in October 2026).
-- =====================================================================
USE stjude_his;

-- Workbench "safe update" mode blocks DELETEs that do not use a key.
SET SQL_SAFE_UPDATES = 0;
-- Recursive CTEs stop at 1000 rows by default; raise the limit.
SET SESSION cte_max_recursion_depth = 200000;

-- ---------------------------------------------------------------------
-- CLEAN-UP (safe to run on a fresh database too)
-- ---------------------------------------------------------------------
DELETE c FROM Consultation c
JOIN Appointment a ON a.AppointmentID = c.AppointmentID
WHERE a.AppointmentDate < '2026-10-01';

DELETE FROM Appointment WHERE AppointmentDate < '2026-10-01';
DELETE FROM Patient     WHERE PatientID > 5;
DELETE FROM Doctor      WHERE DoctorID > 103;

-- ---------------------------------------------------------------------
-- 1. DOCTORS: add 47 more (IDs 104-150) -> 50 doctors in total
-- ---------------------------------------------------------------------
INSERT INTO Doctor (DoctorID, DepartmentID, FirstName, LastName, LicenseNo, Email, Phone)
WITH RECURSIVE seq AS (
    SELECT 104 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 150
)
SELECT n,
       1 + n % 3,
       ELT(1 + n % 5, 'Amina', 'Chidi', 'Ngozi', 'Yusuf', 'Folake'),
       ELT(1 + n % 7, 'Bello', 'Okafor', 'Eze', 'Danjuma', 'Balogun', 'Adebayo', 'Nnamdi'),
       CONCAT('MDCN-', 10000 + n),
       CONCAT('doctor', n, '@stjude.example'),
       CONCAT('0809', LPAD(n, 7, '0'))
FROM seq;

-- ---------------------------------------------------------------------
-- 2. PATIENTS: add 19,995 more (IDs 6-20000) -> 20,000 in total
-- ---------------------------------------------------------------------
INSERT INTO Patient (PatientID, FirstName, LastName, DateOfBirth, Gender, Phone, Email, Address)
WITH RECURSIVE seq AS (
    SELECT 6 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 20000
)
SELECT n,
       ELT(1 + n % 10, 'Tunde', 'Zainab', 'Emeka', 'Hauwa', 'Grace',
                       'Ibrahim', 'Funke', 'Musa', 'Ada', 'Samuel'),
       ELT(1 + (n DIV 10) % 10, 'Adeyemi', 'Musa', 'Nwosu', 'Ibrahim', 'Okoro',
                                'Bello', 'Eze', 'Okafor', 'Danjuma', 'Balogun'),
       DATE_ADD('1950-01-01', INTERVAL ((n * 37) % 25000) DAY),
       ELT(1 + n % 2, 'M', 'F'),
       CONCAT('081', LPAD(n, 8, '0')),
       CONCAT('patient', n, '@mail.example'),
       ELT(1 + n % 5, 'Wuse II, Abuja', 'Garki, Abuja', 'Maitama, Abuja',
                      'Gwarinpa, Abuja', 'Kubwa, Abuja')
FROM seq;

-- ---------------------------------------------------------------------
-- 3. APPOINTMENTS: 100,000 rows
-- Doctor = 101 + (n mod 50); time slot = n DIV 50, so every
-- (doctor, slot) pair is unique and the double-booking constraint holds.
-- 16 half-hour slots per day starting 08:00, from 2026-01-01.
-- Status mix: 80% Completed, 10% Cancelled, 10% No-Show.
-- ---------------------------------------------------------------------
INSERT INTO Appointment (PatientID, DoctorID, AppointmentDate, Reason, Status)
WITH RECURSIVE seq AS (
    SELECT 0 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 99999
)
SELECT 1 + (n * 7919) % 20000,
       101 + (n % 50),
       CAST('2026-01-01 08:00:00' AS DATETIME)
           + INTERVAL ((n DIV 50) DIV 16) DAY
           + INTERVAL (((n DIV 50) MOD 16) * 30) MINUTE,
       ELT(1 + (n DIV 3) % 6, 'Routine check-up', 'Fever', 'Headache',
                              'Follow-up visit', 'Blood pressure review', 'Vaccination'),
       ELT(1 + (n DIV 7) % 10, 'Completed', 'Completed', 'Completed', 'Completed',
                               'Completed', 'Completed', 'Completed', 'Completed',
                               'Cancelled', 'No-Show')
FROM seq;

-- ---------------------------------------------------------------------
-- 4. CONSULTATIONS: one for every generated Completed appointment
-- ---------------------------------------------------------------------
INSERT INTO Consultation (AppointmentID, Diagnosis, ConsultedAt)
SELECT AppointmentID,
       ELT(1 + (AppointmentID DIV 5) % 8, 'Hypertension', 'Malaria', 'Type 2 diabetes',
                                          'Upper respiratory infection', 'Asthma',
                                          'Typhoid fever', 'Migraine', 'No abnormality found'),
       AppointmentDate + INTERVAL 20 MINUTE
FROM Appointment
WHERE Status = 'Completed'
  AND AppointmentDate < '2026-10-01';

-- ---------------------------------------------------------------------
-- 5. Refresh optimiser statistics and re-enable safe updates
-- ---------------------------------------------------------------------
ANALYZE TABLE Patient, Doctor, Appointment, Consultation;
SET SQL_SAFE_UPDATES = 1;

-- ---------------------------------------------------------------------
-- 6. VERIFY (expected: Patient 20000, Doctor 50, Appointment about
--    100000 plus a few from Portfolio 1 tests, Consultation about 80000)
-- ---------------------------------------------------------------------
SELECT 'Patient'      AS tbl, COUNT(*) AS n FROM Patient      UNION ALL
SELECT 'Doctor',              COUNT(*)      FROM Doctor       UNION ALL
SELECT 'Appointment',         COUNT(*)      FROM Appointment  UNION ALL
SELECT 'Consultation',        COUNT(*)      FROM Consultation;
