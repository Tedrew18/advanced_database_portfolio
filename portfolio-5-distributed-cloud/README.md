# Portfolio 5: Distributed and Cloud Database Exercise

Case study: **St. Jude Clinical Health Information System (HIS)**.
Practical part: a **three-node MongoDB replica set** (`rs0`) with a failover test.
Written part: a design for **sharding**, a discussion of **consistency and availability**, and a **cloud deployment** proposal. These written parts are designs. They were not built.
Environment: MongoDB Community Server 9.0.4 on one Windows PC, three `mongod` processes on ports 27018, 27019 and 27020, MongoDB Compass shell, database `stjude_his_rs`.

## 1. Why the clinic needs a distributed database

A clinic cannot lose access to patient records when one server fails. A **replica set** keeps the same data on several servers (nodes). One node, the **primary**, accepts all writes. The others, the **secondaries**, copy the primary's changes. If the primary fails, the remaining nodes hold an election and one of them becomes the new primary, so the system stays available. **Sharding** is different: it splits the data across several replica sets so that no single server has to hold all of it. Replication gives availability and copies. Sharding gives capacity.

## 2. Setup (practical)

1. Created one data folder per node (`C:\mongo-rs\node1` to `node3`, outside the Git repository).
2. Started three `mongod` processes with `--replSet rs0` on ports 27018, 27019 and 27020 (`01_start_replica_set.ps1`).
3. Connected Compass directly to node 1 and ran `rs.initiate(...)` with all three members (`02_replica_set_commands.js`).
4. Checked the members with `rs.status()`.

Evidence: `rs-1b-nodes-listening.png` (all three ports listening), `rs-2-initiate.png` (`ok: 1`), `rs-3-members.png` (`27018` PRIMARY, `27019` and `27020` SECONDARY).

## 3. Replication test

| Step | Result observed | Evidence |
|---|---|---|
| Wrote three patient documents through the primary with `w: "majority"` | `acknowledged: true`, ids 1, 3 and 4 | `rep-1-write-primary.png` |
| Read the collection directly from a secondary (port 27019) | All three patients returned | `rep-2-read-secondary.png` |
| Tried to write to the secondary | `MongoServerError[NotWritablePrimary]: not primary` | `rep-3-write-rejected-secondary.png` |

The secondary received its own copy of the data automatically, but refused writes. Only the primary accepts writes, which keeps every copy consistent.

## 4. Failover and recovery test

| Step | Result observed | Evidence |
|---|---|---|
| Before: node 27019 was primary | `27018` SECONDARY, `27019` PRIMARY, `27020` SECONDARY | `fo-1-before-failover.png` |
| Stopped the primary's process (only that node) | Two ports left listening (27018, 27020) | `fo-2-primary-stopped.png` |
| Checked the members again | `27019` showed `(not reachable/healthy)`, and **`27020` had become PRIMARY** | `fo-3-new-primary.png` |
| Wrote a new patient (Grace Okoro) with `w: "majority"` while one node was down | `acknowledged: true` | `fo-4-write-during-failover.png` |
| Restarted node 27019 | All three ports listening again, with a new process ID | `fo-5-node-restarted.png` |
| Checked the members | `27019` rejoined as SECONDARY. `27020` **stayed primary** | `fo-6-rejoined.png` |
| Read from the restarted node | `countDocuments()` returned 4, and Grace Okoro's record (written while it was down) was present | `fo-7-caught-up.png` |

**What this shows.** After the primary was stopped, a new primary was elected without any manual action, and the cluster kept accepting writes with two of its three nodes alive. The restarted node caught up on the write it had missed. The old primary did not reclaim its role. MongoDB's default election timeout is 10 seconds (I did not measure the election time here).

## 5. Consistency and availability

- **Majority writes.** `w: "majority"` makes MongoDB confirm a write only after most nodes hold it. With three nodes, the majority is two, so the cluster can lose one node and still accept confirmed writes (shown in section 4).
- **Losing two of three nodes.** The remaining node cannot elect itself primary, because it cannot see a majority. Writes would stop. Reads from the survivor could still be served, but might not include the latest writes. This is MongoDB choosing **consistency over write availability**, in the sense of the CAP theorem, when the cluster cannot reach a majority. I did not run this as a controlled test. At one point all three nodes were stopped by mistake, which meant nothing could be read or written, and restarting them from their data folders restored the set without losing data (the original three patients were still present in `fo-7`).
- **Reading from secondaries.** A secondary can lag slightly behind the primary, so it may return slightly older data. For the clinic, records that must be current when a doctor prescribes (allergies, current medications) should be read from the primary. Reports and statistics could be read from secondaries.
- **Compared with Portfolio 3.** In the single MySQL server, consistency came from transactions, locks and isolation levels. Here, consistency across servers comes from a single primary and majority acknowledgement.

## 6. Sharding design (not built)

A sharded MongoDB cluster has **shards** (each one a replica set), **config servers** (a replica set holding the cluster's metadata) and **mongos** routers that direct each query. I did not build one, because it needs many more processes than one PC comfortably runs. This is a design for the `visits` collection from [Portfolio 4](../portfolio-4-nosql/README.md), the part that would grow largest.

| Candidate shard key | Assessment |
|---|---|
| `appointmentDate` | Poor. Dates only increase, so all new writes would hit the last shard, and a patient's history would be spread across all shards |
| `doctor.doctorId` | Poor. Only about 50 distinct values, so chunks would be uneven and could not split further |
| **`{ patientId: 1, appointmentDate: 1 }`** | **Recommended.** High cardinality. A patient's visits stay together and sorted by date, so the most common query (patient history) goes to one shard |
| Hashed `patientId` | Also reasonable. Spreads writes most evenly, but a range of one patient's dates is not stored in order |

Consequences of the recommended key:
- A doctor's weekly schedule would query all shards (scatter-gather). An index on `doctor.doctorId` and `appointmentDate` would help each shard answer quickly.
- In a sharded collection, a unique index must include the shard key. So the double-booking rule (`UNIQUE` on doctor and time slot, built in Portfolio 1) could not be enforced on `visits` this way. This supports a **hybrid design**: appointment booking stays in the relational database, where the unique constraint and transactions work (Portfolios 1 and 3), and clinical records live in MongoDB.
- The `doctors` collection is tiny and would stay on a single replica set. `patients` could be sharded on a hashed `_id` once it grows.

## 7. Cloud deployment proposal (not built)

| Area | Proposal |
|---|---|
| Service | A managed database service such as MongoDB Atlas for the document data, and a managed MySQL service for appointments. This removes the work of running servers, patching and backups |
| High availability | A three-node replica set spread across three availability zones in one region, so one data-centre failure does not take the system down |
| Disaster recovery | Automated backups with point-in-time restore, and a tested restore procedure. A copy in a second region for serious outages |
| Security | Encryption in transit and at rest, authentication with separate roles for doctors, receptionists and administrators, a network allow-list so only the clinic's applications can connect, and audit logging |
| Compliance | Health records are sensitive personal data. Nigerian data protection requirements (the Nigeria Data Protection Act 2023) must be checked for consent, security and where data may be stored, before choosing a cloud region |
| Cost versus benefit | A managed three-node cluster costs more than one server, but it removes single points of failure and the staff time to operate the database |
| Scaling path | Start with one replica set. Add read-only secondaries for reports. Shard `visits` only if the data outgrows one replica set |

## 8. Limitations and practical notes

- **All three nodes ran on one PC.** They share one machine, one disk and one power supply, so this demonstrates the replication logic but not real fault tolerance.
- **No authentication or TLS was enabled.** This is acceptable for a local exercise only, never for real patient data.
- **Replication lag was not measured**, and only one failover was tested (election time not timed).
- **Sharding and the cloud proposal are written designs.** They were not implemented or tested.
- **The nodes are ordinary processes.** They stop when their window is closed or the PC sleeps or restarts, which interrupted the exercise more than once, and restarting them from `C:\mongo-rs` restored the set.
- **A stale Compass connection** to a deleted replica set of the same name produced a "primary marked stale" error. Disconnecting and fully restarting Compass fixed it.
- At one point I mistakenly stopped all three nodes with three stop commands. The failover test was then repeated correctly, stopping only the primary, and `fo-2` shows that correct run.

## 9. How to reproduce

```text
1. Run the blocks in 01_start_replica_set.ps1 one at a time (PowerShell)
2. In Compass, connect to mongodb://localhost:27018/?directConnection=true and run rs.initiate(...)
3. Reconnect with mongodb://localhost:27018,localhost:27019,localhost:27020/?replicaSet=rs0
4. Follow 02_replica_set_commands.js: write on the primary, read on a secondary, stop the primary, check the new primary, write again, restart the node
```
