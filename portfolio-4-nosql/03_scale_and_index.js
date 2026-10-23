// =====================================================================
// MIT 8103 Advanced Database Systems - Portfolio 4 (NoSQL, MongoDB)
// File : 03_scale_and_index.js
// Purpose: add 50,000 synthetic visits, then compare a query's execution
//          before and after creating an index (like Portfolio 2 in MySQL).
//
// HOW TO USE: in the Compass shell, paste ONE statement at a time.
// Synthetic visits use patientId 6-20000 and carry synthetic: true, so
// the hand-made sample visits (patients 1-5) are not affected.
// =====================================================================
db = db.getSiblingDB('stjude_his_nosql');

// ---------------------------------------------------------------------
// Step 1. Generate 50,000 synthetic visits (prints 50000 when done)
// ---------------------------------------------------------------------
Object.keys(db.visits.insertMany(Array.from({ length: 50000 }, (_, i) => ({ appointmentId: 100000 + i, patientId: 6 + (i * 7919) % 19995, doctor: { doctorId: 101 + (i % 3), name: ["Dr Amina Bello", "Dr Chidi Okafor", "Dr Ngozi Eze"][i % 3], department: ["General Practice", "Cardiology", "Paediatrics"][i % 3] }, appointmentDate: new Date(Date.UTC(2026, 0, 1, 8, 0) + (i % 125) * 86400000 + (i % 16) * 1800000), reason: "Synthetic visit", status: ["Completed", "Completed", "Completed", "Completed", "Completed", "Completed", "Completed", "Completed", "Cancelled", "No-Show"][i % 10], consultation: { diagnosis: ["Hypertension (Stage 1)", "Malaria", "Type 2 diabetes", "Upper respiratory infection", "Asthma", "Typhoid fever", "Migraine", "No abnormality found"][i % 8] }, prescriptions: [{ medication: "Paracetamol", strength: "500 mg", form: "Tablet", dosage: "2 tablets", frequency: "As needed", durationDays: 5 }], synthetic: true }))).insertedIds).length

// Step 2. Count the documents (expected: 50008 = 50000 + the 8 sample visits)
db.visits.countDocuments()

// ---------------------------------------------------------------------
// Step 3. BEFORE: how much work does a patient lookup need with no index?
//         Run it twice and keep the second result.
//         Expected: nReturned 3, totalKeysExamined 0, totalDocsExamined 50008
// ---------------------------------------------------------------------
(() => { const s = db.visits.find({ patientId: 12345 }).explain("executionStats").executionStats; return { nReturned: s.nReturned, totalKeysExamined: s.totalKeysExamined, totalDocsExamined: s.totalDocsExamined, executionTimeMillis: s.executionTimeMillis }; })()

// ---------------------------------------------------------------------
// Step 4. Create a compound index: equality field first, then the date
// ---------------------------------------------------------------------
db.visits.createIndex({ patientId: 1, appointmentDate: 1 }, { name: "idx_patient_date" })

// ---------------------------------------------------------------------
// Step 5. AFTER: run the same measurement again.
//         Expected: nReturned 3, totalKeysExamined 3, totalDocsExamined 3
// ---------------------------------------------------------------------
(() => { const s = db.visits.find({ patientId: 12345 }).explain("executionStats").executionStats; return { nReturned: s.nReturned, totalKeysExamined: s.totalKeysExamined, totalDocsExamined: s.totalDocsExamined, executionTimeMillis: s.executionTimeMillis }; })()

// ---------------------------------------------------------------------
// OPTIONAL clean-up (removes only the synthetic visits and the index)
// ---------------------------------------------------------------------
// db.visits.deleteMany({ synthetic: true })
// db.visits.dropIndex("idx_patient_date")
