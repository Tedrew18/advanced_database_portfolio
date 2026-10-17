# Portfolio 2: Query Processing and Optimisation

Case study: **St. Jude Clinical Health Information System (HIS)**, the same `stjude_his` database designed in [Portfolio 1](../portfolio-1-database-design/README.md).
Environment: MySQL 8.0.46, MySQL Workbench, Windows.

## 1. Approach

1. Generate realistic volume: about 100,000 appointments, 20,000 patients, 50 doctors and about 80,000 consultations (`01_generate_data.sql`).
2. Write five queries that a clinic would really run (`02_queries.sql`).
3. Record a **baseline** for each: `EXPLAIN` plan, result and execution time, with no extra indexes.
4. Add four indexes designed from the baseline plans (`03_add_indexes.sql`).
5. Run the same queries again and compare.

The baseline was committed to Git before the indexes were created, so the commit history shows the order of work.

## 2. Test data

| Table | Rows |
|---|---|
| Patient | 20,000 |
| Doctor | 50 |
| Appointment | 100,007 |
| Consultation | 80,010 |

Evidence: `evidence/step1-data-generated.png`. Data is synthetic and generated with recursive CTEs (see limitations in section 7).

## 3. Queries

| ID | Business question | Why it matters |
|---|---|---|
| Q1 | How many appointments were there in the first week of March? | Daily and weekly reporting |
| Q2 | Find a patient by last name and first name | Reception search |
| Q3 | No-shows per doctor in March | Management report with `GROUP BY` |
| Q4 | One doctor's schedule for a week | Most frequent operational query |
| Q5 | One patient's history with doctor and diagnosis (3-table JOIN) | Control query: expected to be already efficient |

## 4. Results: before and after

| Query | Plan before | Plan after | Rows examined (before to after) | Time (before to after) |
|---|---|---|---|---|
| Q1 | `ALL` (full table scan), no key | `range` on `idx_appointment_date`, `Using index` | 99,918 to **5,600** | 0.093 s to 0.000 s |
| Q2 | `ALL`, no key | `ref` on `idx_patient_name` | 19,987 to **201** | 0.031 s to 0.016 s |
| Q3 | `index` scan of `uq_doctor_active_slot`; `Using temporary; Using filesort` | `range` on `idx_appt_status_date_doctor`; `Using index; Using temporary; Using filesort` | 99,918 to **2,478** | 0.312 s to 0.015 s |
| Q4 | `ref` on DoctorID only; `Using filesort` | `range` on `idx_appt_doctor_date`; `Using index condition` | 2,000 to **112** | 0.031 s to 0.031 s |
| Q5 (control) | `ref` + `eq_ref` + `eq_ref` | unchanged | 5 / 1 / 1 | 0.000 s to 0.000 s |

Query results were identical before and after indexing (for example Q1 returns 5,600 and Q4 returns the same 112 rows), so indexing changed speed, not answers.

Evidence files are in `evidence/`: `before-q1-explain.png` to `before-q5-explain.png`, `before-q1-result.png`, `after-q1-explain.png` to `after-q5-explain.png`, `after-q1-result.png` to `after-q5-result.png`, `after-timings.png`.

## 5. Indexes created and why

| Index | Table and columns | Design reasoning |
|---|---|---|
| `idx_appointment_date` | Appointment (AppointmentDate) | Q1 filters only on a date range. Without it MySQL scanned all rows. As the query only needs a count, the index also **covers** it (`Using index`) so no table rows are read. |
| `idx_patient_name` | Patient (LastName, FirstName) | Q2 tests equality on both columns. `key_len = 404` in the plan shows both columns were used. |
| `idx_appt_status_date_doctor` | Appointment (Status, AppointmentDate, DoctorID) | Column order follows the rule *equality column first, range column next*. Status (equality) then date (range) lets MySQL seek directly (`key_len = 87` covers Status plus date). DoctorID is last so the index covers the query. |
| `idx_appt_doctor_date` | Appointment (DoctorID, AppointmentDate) | Q4 has equality on DoctorID and a range on date. `key_len = 9` shows both columns used. The existing booking index only helped with DoctorID, so MySQL read 2,000 rows and discarded about 89%. Because this index is already sorted by date, `Using filesort` disappeared. |

## 6. Analysis

**What improved most.** Q3 improved most: it went from reading the entire booking index (99,918 rows) and sorting in a temporary table to a range scan of 2,478 rows, and from 0.312 s to 0.015 s. Q1 and Q2 show the largest drop in rows examined for single-table searches (about 18x and 99x fewer).

**Q5 shows that not every query needs a new index.** Foreign keys already created `fk_appointment_patient`, and the Doctor and Consultation lookups use primary and unique keys (`eq_ref`). Adding indexes there would only cost space.

**A note on timing evidence.** MySQL Workbench reports durations in steps of about 15 to 16 ms (0.015, 0.016, 0.031 and so on). A result of `0.000 sec` therefore means *faster than about 16 ms*, not zero, and an unchanged 0.031 s for Q4 does not prove there was no improvement. The `EXPLAIN` row counts are the more reliable evidence at this data size. The "before" time for Q1 comes from a single run; other times were taken from the Workbench Output panel (`after-timings.png`).

**The cost of indexing.** Index sizes were read from `mysql.innodb_index_stats` (`evidence/step3-index-sizes.png`). The three new Appointment indexes use 3,600 + 2,576 + 2,576 = **8,752 KB**, which is more than the 7,696 KB of the table itself (the clustered primary key). Every INSERT or UPDATE on Appointment now maintains several more index trees. For a booking system with frequent writes, each index should earn its place. I did not measure write slowdown in this portfolio.

**Existing design helped.** The unique constraint `uq_doctor_active_slot` and the foreign-key indexes from Portfolio 1 already served the booking and join queries well. The baseline plans showed exactly where they did not (Q1 to Q4).

## 7. Limitations

- Data is synthetic and unusually uniform: every doctor with no-shows has the same count (71) and a given patient's visits repeat the same time slot. Real clinic data is skewed, which could change the optimiser's choices.
- 100,000 rows is small. Differences in time would be larger at millions of rows.
- Each "after" time is a single reading from the Output panel, and timer resolution is coarse (see section 6).
- Write overhead of the new indexes was not benchmarked.

## 8. How to reproduce

```text
1. Run Portfolio 1: 01_schema.sql then 02_seed_data.sql
2. Run 01_generate_data.sql      (re-runnable)
3. Run each query in 02_queries.sql; screenshot EXPLAIN and note the time   (BEFORE)
4. Run 03_add_indexes.sql
5. Run 02_queries.sql again       (AFTER)
```
