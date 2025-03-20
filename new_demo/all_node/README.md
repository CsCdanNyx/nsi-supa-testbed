# Explaination
all_node is the combination of nycu_node and icair_node in one docker compose project.
It is for testing so setup all nodes into one project.

# Nodes
Basically, a node contains following services:
- Aggregator Agent (AG):
    - Safnari
    - DDS (Document Distribution Service)
    - PCE (Path Calculation Engine)
- Provider Agent (PA):
    - SuPA
    - PolyNSI: Translate SOAP message to gRPC for SuPA.
- Requester Agent (RA):
    - nsi-requester: Can be placed anywhere, but setup one for one node.


# Test Environment
For the testing, I deployed all nodes (icair_node & nycu_node) on the same Ubuntu 20 host at 192.168.13.63.

The following ports are exposed on host's ip for other node interconnections and for access from internet:

nycu_node exposed ports:
- 8401: DDS document port.
- 9080: Safnari port.
- 4321: SuPA document port.
- 8443: PolyNSI SOAP port.
- 9000: NSI-Requester port.


icair_node exposed ports:
- 8402: DDS document port.
- 9082: Safnari port.
- 4322: SuPA document port.
- 8442: PolyNSI SOAP port.
- 9002: NSI-Requester port.

All services for both nodes can reach each others via the same docker compose network `nsi-network` .


# First Test (DDS)

For the first test, I only start DDS, PolyNSI and SuPA for both nodes to see if DDS can successfully fetch the document from peer dds. The command is like this:
```
docker compose up icair-nsi-dds icair-nsi-supa icair-polynsi nycu-nsi-dds nycu-nsi-supa nycu-polynsi
```

## Test Result
In the ideal case, both DDS should fetch the documents from the local PA and peer DDS.
nycu-nsi-dds should fetch from local nycu-nsi-supa's documents and peer icair-nsi-dds's documents; icair-nsi-dds should fetch from local icair-nsi-supa's documents and peer nycu-nsi-dds's documents

But the result is both DDS can only fetch the topology document for the local SuPA on the same node, cannot fetch peer dds's document.
The /dds enpoint documents for icair_node and nycu_node are stored as `nycu_node-dds-endpoint.xml` and `icair_node-dds-endpoint.xml` .

## Test Logs
The logs for docker compose is stored as `all_node-first-test-docker-compose.log`

The logs seems like both dds got read timed out.
And I can assure that (I have tested) dds on both nodes can reach each other's /dds endpoint.
