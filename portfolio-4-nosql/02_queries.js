// =====================================================================
// MIT 8103 Advanced Database Systems - Portfolio 4 (NoSQL, MongoDB)
// Case study : St. Jude Clinical Health Information System (HIS)
// File       : 02_queries.js
//
// HOW TO USE: open the MONGOSH panel at the bottom of MongoDB Compass,
// connected to the database stjude_his_nosql. Copy ONE query at a time
// (from its "Q" comment to the end of the statement), paste it into the
// shell and press Enter. Screenshot the result.
// First run this line once:
// =====================================================================
db = db.getSiblingDB('stjude_his_nosql');

// ---------------------------------------------------------------------
// Q1. A patient's full history in ONE read, no joins (patient 1, Tunde)
//     In MySQL this needed a join across many tables (Portfolio 1, Test 8 joined eight).
// ---------------------------------------------------------------------
db.visits.find(
  { patientId: 1 },
  { _id: 0, appointmentDate: 1, "doctor.name": 1, status: 1,
    "consultation.diagnosis": 1, prescriptions: 1 }
).sort({ appointmentDate: 1 })

// ---------------------------------------------------------------------
// Q2. A patient profile with allergies and conditions
// ---------------------------------------------------------------------
db.patients.findOne({ _id: 1 })

// ---------------------------------------------------------------------
// Q3. Patients allergic to a drug (check before prescribing)
// ---------------------------------------------------------------------
db.patients.find({ allergies: "Penicillin" },
                 { firstName: 1, lastName: 1, allergies: 1 })

// ---------------------------------------------------------------------
// Q4. Flexible schema: only some patients have a guardian field
//     (children), and only some have insurance. No NULL columns needed.
// ---------------------------------------------------------------------
db.patients.find({ guardian: { $exists: true } })
db.patients.find({ insurance: { $exists: true } })

// ---------------------------------------------------------------------
// Q5. Search inside embedded documents: visits with a hypertension diagnosis
// ---------------------------------------------------------------------
db.visits.find(
  { "consultation.diagnosis": /hypertension/i },
  { _id: 0, patientId: 1, appointmentDate: 1, "consultation.diagnosis": 1 }
)

// ---------------------------------------------------------------------
// Q6. Aggregation: how many completed visits per diagnosis?
// ---------------------------------------------------------------------
db.visits.aggregate([
  { $match: { status: "Completed" } },
  { $group: { _id: "$consultation.diagnosis", visits: { $sum: 1 } } },
  { $sort: { visits: -1, _id: 1 } }
])

// ---------------------------------------------------------------------
// Q7. Aggregation with $lookup: the cost of REFERENCING. Visits keep only
//     patientId, so showing the patient's name needs a join-like step.
// ---------------------------------------------------------------------
db.visits.aggregate([
  { $lookup: { from: "patients", localField: "patientId",
               foreignField: "_id", as: "patient" } },
  { $unwind: "$patient" },
  { $project: { _id: 0, appointmentDate: 1, status: 1,
                patientName: { $concat: ["$patient.firstName", " ", "$patient.lastName"] } } },
  { $sort: { appointmentDate: 1 } }
])

// ---------------------------------------------------------------------
// Q8. Update: add a prescription to an existing visit with $push
// ---------------------------------------------------------------------
db.visits.updateOne(
  { appointmentId: 90001 },
  { $push: { prescriptions: { medication: "Atorvastatin", strength: "10 mg",
      form: "Tablet", dosage: "1 tablet", frequency: "Once daily at night",
      durationDays: 30 } } }
)
// Verify the change:
db.visits.find({ appointmentId: 90001 }, { _id: 0, appointmentId: 1, prescriptions: 1 })
// To undo it afterwards:
// db.visits.updateOne({ appointmentId: 90001 },
//   { $pull: { prescriptions: { medication: "Atorvastatin" } } })
