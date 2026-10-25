# =====================================================================
# MIT 8103 Advanced Database Systems - Portfolio 5
# Case study : St. Jude Clinical Health Information System (HIS)
# File       : 01_start_replica_set.ps1
# Purpose    : start a 3-node MongoDB replica set (rs0) on one PC, using
#              ONE PowerShell window. Ports 27018, 27019 and 27020 are used,
#              so the normal MongoDB service on 27017 (Portfolio 4 data)
#              is untouched.
#
# HOW TO USE: paste ONE block at a time into a single PowerShell window.
# The data folders live in C:\mongo-rs, OUTSIDE the GitHub repository.
# =====================================================================

# ---- BLOCK A: clean start (stops ONLY the three test nodes, deletes their data)
Get-CimInstance Win32_Process -Filter "Name='mongod.exe'" | Where-Object { $_.CommandLine -like '*mongo-rs*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Start-Sleep -Seconds 3
Remove-Item C:\mongo-rs -Recurse -Force -ErrorAction SilentlyContinue

# ---- BLOCK B: create the folders and start the three nodes in the background
$mongod = "C:\Program Files\MongoDB\Server\9.0\bin\mongod.exe"
Test-Path $mongod
mkdir C:\mongo-rs\node1, C:\mongo-rs\node2, C:\mongo-rs\node3
$n1 = Start-Process $mongod -ArgumentList "--replSet rs0 --port 27018 --dbpath C:\mongo-rs\node1 --bind_ip localhost" -PassThru -WindowStyle Minimized
$n2 = Start-Process $mongod -ArgumentList "--replSet rs0 --port 27019 --dbpath C:\mongo-rs\node2 --bind_ip localhost" -PassThru -WindowStyle Minimized
$n3 = Start-Process $mongod -ArgumentList "--replSet rs0 --port 27020 --dbpath C:\mongo-rs\node3 --bind_ip localhost" -PassThru -WindowStyle Minimized

# ---- BLOCK C: check that all three nodes are listening (expect 3 rows: 27018, 27019, 27020)
Start-Sleep -Seconds 5
Get-NetTCPConnection -LocalPort 27018,27019,27020 -State Listen | Select-Object LocalPort, OwningProcess

# ---------------------------------------------------------------------
# Used later in the failover test
# ---------------------------------------------------------------------
# STOP the node that is listening on a port (example: port 27019):
#   Stop-Process -Id (Get-NetTCPConnection -LocalPort 27019 -State Listen).OwningProcess -Force
# RESTART that node:
#   $mongod = "C:\Program Files\MongoDB\Server\9.0\bin\mongod.exe"
#   Start-Process $mongod -ArgumentList "--replSet rs0 --port 27019 --dbpath C:\mongo-rs\node2 --bind_ip localhost" -WindowStyle Minimized
