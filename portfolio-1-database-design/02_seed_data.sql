-- =====================================================================
-- Portfolio 1 - Sample data (run after 01_schema.sql)
-- NOTE: All names/phones/emails are fictional. Larger synthetic data for
-- performance testing is added in Portfolio 2.
-- =====================================================================
USE stjude_his;

INSERT INTO Department (DepartmentID, DepartmentName) VALUES
    (1, 'General Practice'),
    (2, 'Cardiology'),
    (3, 'Paediatrics');

INSERT INTO Doctor (DoctorID, DepartmentID, FirstName, LastName, LicenseNo, Email, Phone) VALUES
    (101, 1, 'Amina',  'Bello',   'MDCN-10101', 'a.bello@stjude.example',  '08010000101'),
    (102, 2, 'Chidi',  'Okafor',  'MDCN-10102', 'c.okafor@stjude.example', '08010000102'),
    (103, 3, 'Ngozi',  'Eze',     'MDCN-10103', 'n.eze@stjude.example',    '08010000103');

INSERT INTO Patient (PatientID, FirstName, LastName, DateOfBirth, Gender, Phone, Email, Address) VALUES
    (1, 'Tunde',  'Adeyemi', '1980-03-14', 'M', '08020000001', 't.adeyemi@mail.example', 'Wuse II, Abuja'),
    (2, 'Zainab', 'Musa',    '1992-07-22', 'F', '08020000002', 'z.musa@mail.example',    'Garki, Abuja'),
    (3, 'Emeka',  'Nwosu',   '1965-11-02', 'M', '08020000003', NULL,                     'Maitama, Abuja'),
    (4, 'Hauwa',  'Ibrahim', '2018-05-30', 'F', '08020000004', NULL,                     'Gwarinpa, Abuja'),
    (5, 'Grace',  'Okoro',   '1999-01-09', 'F', '08020000005', 'g.okoro@mail.example',   'Kubwa, Abuja');

-- Appointment 5 is Cancelled for the same doctor/time as appointment 1,
-- which demonstrates that a cancelled slot does not block the real booking.
INSERT INTO Appointment (AppointmentID, PatientID, DoctorID, AppointmentDate, Reason, Status) VALUES
    (1, 1, 101, '2026-10-15 10:00:00', 'Headache and dizziness',  'Completed'),
    (2, 2, 101, '2026-10-15 11:00:00', 'Routine check-up',        'Confirmed'),
    (3, 3, 102, '2026-10-15 10:00:00', 'Palpitations',            'Completed'),
    (4, 4, 103, '2026-10-16 09:00:00', 'Child immunisation',      'Scheduled'),
    (5, 5, 101, '2026-10-15 10:00:00', 'Fever',                   'Cancelled');

INSERT INTO Consultation (ConsultationID, AppointmentID, Diagnosis, Notes, ConsultedAt) VALUES
    (1, 1, 'Hypertension (Stage 1)',            'BP 150/95. Lifestyle advice given.', '2026-10-15 10:25:00'),
    (2, 3, 'Suspected atrial fibrillation',     'ECG requested.',                     '2026-10-15 10:40:00');

INSERT INTO Medication (MedicationID, MedicationName, Strength, Form) VALUES
    (1, 'Amlodipine',  '5 mg',   'Tablet'),
    (2, 'Paracetamol', '500 mg', 'Tablet'),
    (3, 'Bisoprolol',  '2.5 mg', 'Tablet');

INSERT INTO Prescription (PrescriptionID, ConsultationID, IssuedAt) VALUES
    (1, 1, '2026-10-15 10:30:00'),
    (2, 2, '2026-10-15 10:45:00');

INSERT INTO PrescriptionItem (PrescriptionID, MedicationID, Dosage, Frequency, DurationDays) VALUES
    (1, 1, '1 tablet', 'Once daily',  30),
    (1, 2, '2 tablets', 'As needed, max 4 times daily', 5),
    (2, 3, '1 tablet', 'Once daily',  30);

INSERT INTO LabTest (LabTestID, TestName, Unit, ReferenceRange) VALUES
    (1, 'Fasting Blood Glucose', 'mmol/L', '3.9 - 5.5'),
    (2, 'Serum Creatinine',      'umol/L', '60 - 110'),
    (3, 'Haemoglobin',           'g/dL',   '12 - 17');

INSERT INTO LabResult (LabResultID, ConsultationID, LabTestID, OrderedAt, ResultValue, ResultedAt, Status) VALUES
    (1, 1, 1, '2026-10-15 10:28:00', 5.20, '2026-10-15 14:00:00', 'Completed'),
    (2, 2, 3, '2026-10-15 10:42:00', NULL, NULL,                  'Ordered');
