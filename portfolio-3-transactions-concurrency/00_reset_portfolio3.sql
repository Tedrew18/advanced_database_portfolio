-- =====================================================================
-- MIT 8103 Advanced Database Systems - Portfolio 3
-- File    : 00_reset_portfolio3.sql
-- Purpose : Remove everything the Portfolio 3 demos create, so any demo
--           can be repeated from a clean state.
-- How     : All Portfolio 3 demo appointments are dated 2026-11-01 or later.
--           Portfolio 1 and 2 data (all earlier than 2026-11-01) is not touched.
-- Run     : select all (Ctrl+A) and press Ctrl+Enter, or click the lightning bolt.
-- =====================================================================
USE stjude_his;

SET SQL_SAFE_UPDATES = 0;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Prescription items are removed automatically (ON DELETE CASCADE)
DELETE pr
FROM Prescription pr
JOIN Consultation c ON c.ConsultationID = pr.ConsultationID
JOIN Appointment a  ON a.AppointmentID  = c.AppointmentID
WHERE a.AppointmentDate >= '2026-11-01';

DELETE c
FROM Consultation c
JOIN Appointment a ON a.AppointmentID = c.AppointmentID
WHERE a.AppointmentDate >= '2026-11-01';

DELETE FROM Appointment WHERE AppointmentDate >= '2026-11-01';

SET SQL_SAFE_UPDATES = 1;

-- Expected: 0
SELECT COUNT(*) AS remaining_portfolio3_appointments
FROM Appointment
WHERE AppointmentDate >= '2026-11-01';
