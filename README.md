# Advanced Database Systems Portfolio (MIT 8103)

**Student:** Dagogo Faith Ogan
**Matric number:** Dagogo_Faith_301914344
**Programme:** Master of Information Technology, MIVA Open University
**Course:** MIT 8103 Advanced Database Systems, 2026/2027 First Semester Continuous Assessment
**Assessment:** Individual Practical Database Portfolio

## Selected case study

**St. Jude Clinical Health Information System (HIS)**, a simulated private clinic in Abuja. All five portfolio activities use this one case study.

| | |
|---|---|
| **Nature of the system** | Supports day-to-day clinic operations: patient registration, appointments, consultations and diagnoses, prescriptions and laboratory tests |
| **Users of the database** | Receptionists, doctors, laboratory staff and administrators |
| **Major data stored** | Patients, doctors, departments, appointments, consultations, medications, prescriptions, laboratory tests and results |
| **Key operations** | Book an appointment without double-booking a doctor; cancel an appointment and free the slot; record a diagnosis; issue a prescription with several medications; order a laboratory test and record its result; retrieve a patient's full history |

All data in this repository are fabricated. No real patient data was used.

## Repository structure

```text
advanced-database-portfolio/
├── README.md
├── portfolio-1-database-design/
├── portfolio-2-query-optimisation/
├── portfolio-3-transactions-concurrency/
├── portfolio-4-nosql/
└── portfolio-5-distributed-cloud/
```

Each portfolio folder contains its scripts, its own README (how the work was implemented and tested, with results and limitations) and an `evidence` folder of screenshots.

## The five portfolio activities

| Portfolio | Topic | What was done | Key results |
|---|---|---|---|
| [1](portfolio-1-database-design/README.md) | Database design and modelling | MySQL schema with 10 tables, keys, UNIQUE, CHECK and foreign key constraints, normalised to third normal form, with a generated column that lets a cancelled booking free its slot | Eight tests: duplicate booking rejected (1062), invalid status rejected (3819), unknown patient rejected (1452), cancelled slot re-booked |
| [2](portfolio-2-query-optimisation/README.md) | Query processing and optimisation | 100,007 appointments, 20,000 patients and about 80,000 consultations; five queries compared with EXPLAIN before and after four indexes | Rows examined: Q1 99,918 to 5,600; Q2 19,987 to 201; Q3 99,918 to 2,478; Q4 2,000 to 112. The no-show report went from 0.312 s to 0.015 s |
| [3](portfolio-3-transactions-concurrency/README.md) | Transactions and concurrency | Commit and rollback, a two-session booking race, two isolation levels and a deadlock | Rollback after a foreign-key error left no partial data. The second booker waited, then got 1062 or succeeded. `SELECT ... FOR UPDATE` then `INSERT` deadlocked (1213) |
| [4](portfolio-4-nosql/README.md) | NoSQL and advanced data models | MongoDB document model: `patients`, `doctors` and `visits` collections, with embedding and referencing | Eight queries including an aggregation, a `$lookup` and a `$push` update. A patient's history needs no join |
| [5](portfolio-5-distributed-cloud/README.md) | Distributed and cloud database | Three-node MongoDB replica set with a failover test, plus written sharding and cloud designs | Data replicated to a secondary; a new primary was elected after the primary stopped; the restarted node caught up |

## Tools and versions

- MySQL 8.0.46 (InnoDB) and MySQL Workbench (Portfolios 1 to 3)
- MongoDB Community Server 9.0.4 and MongoDB Compass with its built-in shell (Portfolios 4 and 5)
- Windows, PowerShell, Git and GitHub Desktop

## How to navigate and reproduce

1. **Portfolio 1:** run `01_schema.sql`, then `02_seed_data.sql`, then the tests in `03_verify.sql`.
2. **Portfolio 2:** run `01_generate_data.sql`, run the queries in `02_queries.sql`, then `03_add_indexes.sql`, then the queries again.
3. **Portfolio 3:** run `00_reset_portfolio3.sql` before each demo, then follow the scripts `01_` to `04_`. Demos 2 to 4 need two query sessions.
4. **Portfolio 4:** import the three JSON files with Compass, then run the queries in `02_queries.js` in the shell.
5. **Portfolio 5:** start the nodes with the blocks in `01_start_replica_set.ps1`, then follow `02_replica_set_commands.js`.

Screenshot names use prefixes that match each demo (for example `test`, `before-` and `after-`, `demo1-`, `race-`, `iso-`, `dl-`, `q`, `rs-`, `rep-` and `fo-`). The portfolio READMEs list the files that support each result.

## Academic integrity and AI-use declaration

- **AI tools used:** Claude (Anthropic) and Google Gemini.
- **What they were used for:** explaining concepts, drafting SQL and MongoDB scripts, helping to diagnose errors, and drafting README and polishing report text.
- **How the output was reviewed, corrected, tested and verified:** every script was run by me in MySQL Workbench and MongoDB Compass, and the screenshots in the evidence folders are my own. Review of my first booking transaction found a syntax error and a deadlock risk, and the deadlock was then reproduced in Portfolio 3. Some AI predictions did not match what the database returned (for example the plan MySQL chose for Q3), so the actual outputs were used. Problems found during testing, such as wrong collection names and a stale Compass connection, were corrected.

Sources used: the MySQL 8.0 Reference Manual (https://dev.mysql.com/doc/refman/8.0/en/) and the MongoDB Manual (https://www.mongodb.com/docs/manual/).
