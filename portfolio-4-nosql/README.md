# Portfolio 4: NoSQL and Advanced Data Models

Case study: **St. Jude Clinical Health Information System (HIS)**, the same clinic modelled relationally in [Portfolio 1](../portfolio-1-database-design/README.md).
NoSQL type: **document database (MongoDB)**.
Environment: MongoDB Community Server 9.0.4 on Windows, MongoDB Compass and its built-in shell (`mongosh`), connection `mongodb://localhost:27017`, database `stjude_his_nosql`.

## 1. Why a document model for this case study

A clinic record is naturally a nested structure: a visit contains a diagnosis, vitals, prescriptions and lab results, and these are almost always read together. In the relational design, showing one patient's history with prescriptions needed a join across **eight tables** (Portfolio 1, Test 8). In a document database the same information can sit inside one document, so it can be read in one operation.

## 2. The data model

| MySQL tables (Portfolios 1 to 3) | MongoDB collection | How it is stored |
|---|---|---|
| Patient | `patients` | One document per patient. Contact, address, allergies and chronic conditions are **embedded** |
| Doctor, Department | `doctors` | One document per doctor, with the department name stored as a value |
| Appointment, Consultation, Prescription, PrescriptionItem, LabResult | `visits` | One document per appointment. Consultation (with vitals), prescriptions and lab results are **embedded**. The doctor's id, name and department are copied in. The patient is **referenced** by `patientId` |

Sample data was taken from the MySQL sample rows: 5 patients, 3 doctors and 8 visits (4 visits correspond to MySQL appointments 1 to 4, and 4 more were added for variety).

### Embedding versus referencing

The rule followed was to **embed what is read together and stays small, and reference what grows without limit**.

- **Embedded in a visit:** consultation, vitals, prescriptions, lab results. They belong to exactly one visit, are always read with it, and each visit stays small (about 557 bytes on average, see the table in section 4).
- **Referenced by `patientId`:** the visits of a patient. The number of visits grows over time, and a patient profile should be readable without loading the whole history. Putting every visit inside the patient document would also tie the patient to MongoDB's 16 MB document limit (at about 0.5 KB per visit that is roughly 30,000 visits, so the limit is far away, but unbounded growth is still the wrong design).
- **Copied into a visit (denormalised):** the doctor's name and department, so a visit can be displayed without looking up the doctor. The cost is that a change to a doctor's name would have to be applied to many visit documents.

### Flexible schema

Documents in one collection need not have the same fields. Hauwa Ibrahim (a child) has a `guardian` field, and Zainab Musa has an `insurance` field. Other patients have neither, and nothing is stored for them. A cancelled visit has no `consultation` or `prescriptions` at all. In MySQL, each of these would be a `NULL`-filled column or an extra table.

## 3. Implementation

1. Installed MongoDB Community Server and Compass, and connected to `localhost:27017`.
2. Created the database `stjude_his_nosql` with collections `patients`, `doctors` and `visits`.
3. Imported `patients.json` (5 documents), `doctors.json` (3) and `visits.json` (8) with Compass.
4. Ran eight queries in the Compass shell (`02_queries.js`).

| Collection | Documents | Avg. document size | Data size |
|---|---|---|---|
| `doctors` | 3 | 166 B | 500 B |
| `patients` | 5 | 279 B | 1.40 kB |
| `visits` | 8 | 557 B | 4.46 kB |

Evidence: `step1-compass-connected.png`, `step2-patients-imported.png`, `step3-patients-documents.png`, `step4-doctors-imported.png`, `step5-visits-documents.png`, `step6-collections-overview.png`.

## 4. Queries and results

| Query | What it does | Result observed |
|---|---|---|
| Q1 | A patient's history in one read: `db.visits.find({ patientId: 1 })` with a projection and sort | Patient 1's visits with the doctor name, diagnosis and prescriptions already inside each document (the 15 October visit shows Amlodipine and Paracetamol). **No join** |
| Q2 | `db.patients.findOne({ _id: 1 })` | Tunde Adeyemi's single document, with nested `contact`, `address`, `allergies` and `chronicConditions` |
| Q3 | Allergy check: `{ allergies: "Penicillin" }` | One patient: Tunde Adeyemi |
| Q4 | `{ guardian: { $exists: true } }` and `{ insurance: { $exists: true } }` | `guardian` found only on Hauwa Ibrahim, `insurance` only on Zainab Musa |
| Q5 | Search inside embedded fields: diagnosis matches `/hypertension/i` | Two visits, both patient 1 (15 October and 12 November) |
| Q6 | Aggregation: completed visits per diagnosis | `Hypertension (Stage 1)`: 2; `Atrial fibrillation (confirmed)`, `Migraine`, `Suspected atrial fibrillation`, `Upper respiratory infection`: 1 each |
| Q7 | `$lookup` to attach patient names to visits | All 8 visits in date order with patient names, from Grace Okoro (2 September) to Emeka Nwosu (20 November) |
| Q8 | `updateOne` with `$push` to add a prescription to visit `90001` | `matchedCount: 1`, `modifiedCount: 1`; the verification query then showed **two** prescriptions (Amlodipine, Atorvastatin) |

Evidence: `q1-patient-history.png`, `q2-patient-profile.png`, `q3-allergy-search.png`, `q4-flexible-schema.png`, `q4b-flexible-schema.png`, `q5-diagnosis-search.png`, `q6-diagnosis-counts.png`, `q7-lookup-join.png`, `q7b-lookup-join.png`, `q8-update-push.png`, `q8b-update-verified.png`.

**Reading the results.** Q1 and Q2 show the main benefit: related data comes back together in one read. Q7 shows the cost of referencing: because a visit stores only `patientId`, getting the patient's name needs `$lookup`, MongoDB's join step. Q8 adds a prescription to an existing visit by changing one document, and a single-document update is atomic, so no multi-statement transaction was needed (compare Demo 1 in Portfolio 3, which needed one transaction across four tables).

## 5. Suitability: document model versus relational model for this clinic

| Need | Document model (MongoDB) | Relational model (MySQL) |
|---|---|---|
| Show one patient's full history | One read, no join | Join across many tables |
| Records with different optional fields | Natural | `NULL` columns or extra tables |
| Strict rules (no double booking, foreign keys, CHECK values) | Must be enforced by the application, or by unique indexes | Built in (`UNIQUE`, `FOREIGN KEY`, `CHECK`), see Portfolio 1 |
| Changing a shared value (a drug name, a doctor's name) | Update many documents if it was copied | Update one row |
| Reports across many patients | Aggregation pipeline, which is flexible but more verbose | SQL `GROUP BY`, which is concise |
| Multi-table transactions with rollback | Possible but not needed when everything is in one document | Core strength (Portfolio 3) |

**Conclusion.** Patient clinical records (the medical file a doctor reads) suit a document database well. Booking, scheduling and billing, where rules like "no double booking" must never be broken, suit the relational database. A realistic system could use both, with the relational database as the source of truth for appointments.

**Other NoSQL types considered.** Key-value stores suit sessions and caches (for example a logged-in receptionist's session). Column-family stores suit very large time-series data such as device readings. Graph databases suit relationship questions, for example referral networks between doctors. None was needed for the core clinic records.

## 6. Limitations and practical notes

- The dataset is very small (5, 3 and 8 documents), so these results show the design, not performance. No performance measurement was made in this portfolio.
- No schema validation rules were added. MongoDB accepts documents of any shape unless a validator is defined, so data quality depends on the application.
- Referential integrity is not enforced: a visit could reference a `patientId` that does not exist.
- The double-booking rule from Portfolio 1 was not rebuilt here. In MongoDB it would need a unique index on doctor and date, which I did not test.
- Collection names are case-sensitive. My first queries returned nothing because two collections had been created as `Doctors` and `Visits` with capital letters. I renamed them to lowercase so the queries and files match.
- Q8 changed the live database only. `visits.json` still holds the original data.

## 7. How to reproduce

```text
1. Install MongoDB Community Server and Compass; connect to mongodb://localhost:27017
2. Create database stjude_his_nosql with collections patients, doctors, visits
3. In Compass, ADD DATA -> Import JSON: patients.json, doctors.json, visits.json
4. Open the MongoDB shell in Compass, run: use stjude_his_nosql
5. Paste the queries from 02_queries.js one at a time
```
