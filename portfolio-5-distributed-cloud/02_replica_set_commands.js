// =====================================================================
// MIT 8103 Advanced Database Systems - Portfolio 5 (replication)
// File : 02_replica_set_commands.js
// Run these in the MongoDB shell inside Compass, ONE statement at a time.
// =====================================================================

// ---------------------------------------------------------------------
// A. Create the replica set (connected DIRECTLY to node 1:
//    mongodb://localhost:27018/?directConnection=true). Expected: { ok: 1 }
// ---------------------------------------------------------------------
rs.initiate({ _id: "rs0", members: [ { _id: 0, host: "localhost:27018" }, { _id: 1, host: "localhost:27019" }, { _id: 2, host: "localhost:27020" } ] })

// Wait about 10 seconds, then list the members.
// Expected: one PRIMARY and two SECONDARY
rs.status().members.map(m => ({ name: m.name, state: m.stateStr }))

// ---------------------------------------------------------------------
// B. Replication: write through the PRIMARY, read from a SECONDARY.
//    Connect Compass with the replica-set address
//    mongodb://localhost:27018,localhost:27019,localhost:27020/?replicaSet=rs0
//    so the shell is attached to whichever node is primary.
// ---------------------------------------------------------------------
db = db.getSiblingDB('stjude_his_rs');

db.patients.insertMany([{ _id: 1, firstName: "Tunde", lastName: "Adeyemi", allergies: ["Penicillin"] }, { _id: 3, firstName: "Emeka", lastName: "Nwosu", allergies: ["Aspirin"] }, { _id: 4, firstName: "Hauwa", lastName: "Ibrahim", allergies: [] }], { writeConcern: { w: "majority" } })

// Now connect Compass DIRECTLY to a secondary
// (mongodb://localhost:27019/?directConnection=true) and run:
db.getSiblingDB('stjude_his_rs').patients.find()

// ---------------------------------------------------------------------
// C. Failover: stop the PRIMARY node's process (see the "Used later in the
//    failover test" notes in 01_start_replica_set.ps1). After about 15
//    seconds, connect with the replica-set address again and run:
// ---------------------------------------------------------------------
rs.status().members.map(m => ({ name: m.name, state: m.stateStr }))

// A write still works, because one of the remaining nodes became primary:
db.getSiblingDB('stjude_his_rs').patients.insertOne({ _id: 5, firstName: "Grace", lastName: "Okoro", allergies: ["Sulfa drugs"] }, { writeConcern: { w: "majority" } })

// ---------------------------------------------------------------------
// D. Recovery: restart the stopped node (restart command in
//    01_start_replica_set.ps1). It rejoins as a SECONDARY and catches up.
//    Connect directly to it and check it received the write made while it
//    was down (expected: 4 documents):
// ---------------------------------------------------------------------
db.getSiblingDB('stjude_his_rs').patients.countDocuments()
