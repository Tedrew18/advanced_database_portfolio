-- =====================================================================
-- Portfolio 2 - Indexing / optimisation
-- File : 03_add_indexes.sql
-- Run ONLY after you have saved the BEFORE screenshots from 02_queries.sql
-- =====================================================================
USE stjude_his;

-- Q1: range search on appointment date
CREATE INDEX idx_appointment_date
    ON Appointment (AppointmentDate);

-- Q2: patient search by name (LastName first, then FirstName)
CREATE INDEX idx_patient_name
    ON Patient (LastName, FirstName);

-- Q3: no-show report. Equality column first (Status), then the range
-- column (AppointmentDate), then DoctorID so the index COVERS the query
-- (MySQL can answer from the index alone, without reading table rows).
CREATE INDEX idx_appt_status_date_doctor
    ON Appointment (Status, AppointmentDate, DoctorID);

-- Q4: doctor schedule. Equality column first (DoctorID), then range.
CREATE INDEX idx_appt_doctor_date
    ON Appointment (DoctorID, AppointmentDate);

-- Refresh optimiser statistics
ANALYZE TABLE Patient, Appointment;

-- ---------------------------------------------------------------------
-- Evidence: list the indexes that now exist (screenshot these)
-- ---------------------------------------------------------------------
SHOW INDEX FROM Appointment;
SHOW INDEX FROM Patient;

-- Cost of indexing: how much disk space each index uses (in KB).
-- (Indexes make reads faster but use space and slow down INSERT/UPDATE.)
SELECT index_name,
       ROUND(stat_value * @@innodb_page_size / 1024) AS size_kb
FROM mysql.innodb_index_stats
WHERE database_name = 'stjude_his'
  AND LOWER(table_name) = 'appointment'
  AND stat_name = 'size'
ORDER BY size_kb DESC;

-- ---------------------------------------------------------------------
-- TO UNDO (only if you need to repeat the BEFORE measurements):
--   DROP INDEX idx_appointment_date        ON Appointment;
--   DROP INDEX idx_patient_name            ON Patient;
--   DROP INDEX idx_appt_status_date_doctor ON Appointment;
--   DROP INDEX idx_appt_doctor_date        ON Appointment;
-- ---------------------------------------------------------------------
