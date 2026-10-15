-- =====================================================================
-- MIT 8103 Advanced Database Systems - Portfolio 1
-- Case study : St. Jude Clinical Health Information System (HIS)
-- Target     : MySQL 8.0.16+ (CHECK constraints are enforced from 8.0.16)
-- File       : 01_schema.sql  (run first)
-- =====================================================================

DROP DATABASE IF EXISTS stjude_his;
CREATE DATABASE stjude_his CHARACTER SET utf8mb4;
USE stjude_his;

-- ---------------------------------------------------------------------
-- 1. DEPARTMENT
-- ---------------------------------------------------------------------
CREATE TABLE Department (
    DepartmentID   INT AUTO_INCREMENT PRIMARY KEY,
    DepartmentName VARCHAR(80) NOT NULL,
    CONSTRAINT uq_department_name UNIQUE (DepartmentName)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 2. DOCTOR
-- ---------------------------------------------------------------------
CREATE TABLE Doctor (
    DoctorID     INT AUTO_INCREMENT PRIMARY KEY,
    DepartmentID INT          NOT NULL,
    FirstName    VARCHAR(50)  NOT NULL,
    LastName     VARCHAR(50)  NOT NULL,
    LicenseNo    VARCHAR(30)  NOT NULL,
    Email        VARCHAR(100) NOT NULL,
    Phone        VARCHAR(20),
    CONSTRAINT uq_doctor_license UNIQUE (LicenseNo),
    CONSTRAINT uq_doctor_email   UNIQUE (Email),
    CONSTRAINT fk_doctor_department
        FOREIGN KEY (DepartmentID) REFERENCES Department (DepartmentID)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 3. PATIENT
-- ---------------------------------------------------------------------
CREATE TABLE Patient (
    PatientID    INT AUTO_INCREMENT PRIMARY KEY,
    FirstName    VARCHAR(50)  NOT NULL,
    LastName     VARCHAR(50)  NOT NULL,
    DateOfBirth  DATE         NOT NULL,
    Gender       CHAR(1)      NOT NULL,
    Phone        VARCHAR(20)  NOT NULL,
    Email        VARCHAR(100),
    Address      VARCHAR(200),
    RegisteredAt DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_patient_gender CHECK (Gender IN ('M', 'F', 'O')),
    CONSTRAINT uq_patient_email   UNIQUE (Email)   -- NULLs allowed, duplicates not
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 4. APPOINTMENT
-- ActiveSlot is NULL when the appointment is Cancelled, so a cancelled
-- slot can be re-booked, while any non-cancelled appointment still
-- blocks double-booking of the same doctor at the same time.
-- ---------------------------------------------------------------------
CREATE TABLE Appointment (
    AppointmentID   INT AUTO_INCREMENT PRIMARY KEY,
    PatientID       INT          NOT NULL,
    DoctorID        INT          NOT NULL,
    AppointmentDate DATETIME     NOT NULL,
    Reason          VARCHAR(200),
    Status          VARCHAR(20)  NOT NULL DEFAULT 'Scheduled',
    ActiveSlot      DATETIME GENERATED ALWAYS AS
                    (IF(Status = 'Cancelled', NULL, AppointmentDate)) STORED,
    CONSTRAINT chk_appointment_status
        CHECK (Status IN ('Scheduled', 'Confirmed', 'Completed', 'Cancelled', 'No-Show')),
    CONSTRAINT uq_doctor_active_slot UNIQUE (DoctorID, ActiveSlot),
    CONSTRAINT fk_appointment_patient
        FOREIGN KEY (PatientID) REFERENCES Patient (PatientID),
    CONSTRAINT fk_appointment_doctor
        FOREIGN KEY (DoctorID)  REFERENCES Doctor (DoctorID)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 5. CONSULTATION  (diagnosis recorded for an attended appointment)
-- One appointment has at most one consultation (UNIQUE on AppointmentID).
-- ---------------------------------------------------------------------
CREATE TABLE Consultation (
    ConsultationID INT AUTO_INCREMENT PRIMARY KEY,
    AppointmentID  INT          NOT NULL,
    Diagnosis      VARCHAR(255) NOT NULL,
    Notes          TEXT,
    ConsultedAt    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_consultation_appointment UNIQUE (AppointmentID),
    CONSTRAINT fk_consultation_appointment
        FOREIGN KEY (AppointmentID) REFERENCES Appointment (AppointmentID)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 6. MEDICATION (catalogue)
-- ---------------------------------------------------------------------
CREATE TABLE Medication (
    MedicationID   INT AUTO_INCREMENT PRIMARY KEY,
    MedicationName VARCHAR(100) NOT NULL,
    Strength       VARCHAR(30)  NOT NULL,
    Form           VARCHAR(30)  NOT NULL,
    CONSTRAINT uq_medication UNIQUE (MedicationName, Strength, Form)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 7. PRESCRIPTION (header)
-- ---------------------------------------------------------------------
CREATE TABLE Prescription (
    PrescriptionID INT AUTO_INCREMENT PRIMARY KEY,
    ConsultationID INT      NOT NULL,
    IssuedAt       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_prescription_consultation
        FOREIGN KEY (ConsultationID) REFERENCES Consultation (ConsultationID)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 8. PRESCRIPTION_ITEM (resolves the many-to-many between
--    Prescription and Medication; composite primary key)
-- ---------------------------------------------------------------------
CREATE TABLE PrescriptionItem (
    PrescriptionID INT         NOT NULL,
    MedicationID   INT         NOT NULL,
    Dosage         VARCHAR(50) NOT NULL,
    Frequency      VARCHAR(50) NOT NULL,
    DurationDays   SMALLINT    NOT NULL,
    PRIMARY KEY (PrescriptionID, MedicationID),
    CONSTRAINT chk_item_duration CHECK (DurationDays > 0),
    CONSTRAINT fk_item_prescription
        FOREIGN KEY (PrescriptionID) REFERENCES Prescription (PrescriptionID)
        ON DELETE CASCADE,
    CONSTRAINT fk_item_medication
        FOREIGN KEY (MedicationID) REFERENCES Medication (MedicationID)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 9. LAB_TEST (catalogue)
-- ---------------------------------------------------------------------
CREATE TABLE LabTest (
    LabTestID      INT AUTO_INCREMENT PRIMARY KEY,
    TestName       VARCHAR(100) NOT NULL,
    Unit           VARCHAR(20)  NOT NULL,
    ReferenceRange VARCHAR(50),
    CONSTRAINT uq_labtest_name UNIQUE (TestName)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 10. LAB_RESULT (a test ordered during a consultation, and its result)
-- ---------------------------------------------------------------------
CREATE TABLE LabResult (
    LabResultID    INT AUTO_INCREMENT PRIMARY KEY,
    ConsultationID INT           NOT NULL,
    LabTestID      INT           NOT NULL,
    OrderedAt      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ResultValue    DECIMAL(10,2),
    ResultedAt     DATETIME,
    Status         VARCHAR(15)   NOT NULL DEFAULT 'Ordered',
    CONSTRAINT chk_labresult_status
        CHECK (Status IN ('Ordered', 'Completed', 'Cancelled')),
    CONSTRAINT fk_labresult_consultation
        FOREIGN KEY (ConsultationID) REFERENCES Consultation (ConsultationID),
    CONSTRAINT fk_labresult_test
        FOREIGN KEY (LabTestID) REFERENCES LabTest (LabTestID)
) ENGINE = InnoDB;
