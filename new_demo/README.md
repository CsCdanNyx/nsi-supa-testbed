#NSI Agent Deployment

## Explaination
The folder contains multiple NSI node deployment using Docker compose.
Each node contains following services:

- Aggregator Agent (AG):
    - Safnari
    - DDS (Document Distribution Service)
    - PCE (Path Calculation Engine)
- Provider Agent (PA):
    - SuPA
    - PolyNSI: Translate SOAP message to gRPC for SuPA.
- Requester Agent (RA):
    - nsi-requester: Can be placed anywhere, but setup one for one node.

For each node, Safnari serve as a local network manager, so each node has its own network.
Nodes are peers with each others, so they will share topology to each others.

## Testing Environment

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




Now, each node can be setup individually and the nsi-requester for each deployment can successfully issue nsi request the each node's own Safnari like the following (arrow is the nsi request path):

On icair_node:
nsi-requester on icair_node --> Safnari on icair_node --> PolyNSI on icair_node --> SuPA on icair_node

But in another scenario, the nsi request cannot work:
nsi-requester on icair_node --> Safnari on nycu_node --> Safnari on icair_node --> PolyNSI on icair_node --> SuPA on icair_node
The NSI Requester Web GUI showed "Could not verify the provider, undefined" when choosing Safnari on nycu_node as provider.


These are some error logs for icair_node's docker compose:
```
polynsi-1                 |
nsi-requester-1           | 2025-03-19T12:01:00.196+0000: [GC (Allocation Failure) [PSYoungGen: 131584K->15052K(153088K)] 138713K->22189K(502784K), 0.0405496 secs] [Times: user=0.10 sys=0.00, real=0.04 secs]
nsi-pce-1                 | 2025-03-19 12:01:07,922 DEBUG [QuartzScheduler_QuartzSchedulerThread] (org.quartz.core.QuartzSchedulerThread:276) - batch acquisition of 0 triggers
nsi-pce-1                 | 2025-03-19 12:01:37,025 DEBUG [QuartzScheduler_QuartzSchedulerThread] (org.quartz.core.QuartzSchedulerThread:276) - batch acquisition of 0 triggers


nsi-dds-1                 | [ERROR] [03/19/2025 12:01:58.418] [NSI-DISCOVERY-akka.actor.default-dispatcher-21] [akka://NSI-DISCOVERY/user/discovery-registrationRouter/$c] org.apache.http.conn.HttpHostConnectException: Connect to 192.168.13.63:8401 [/192.168.13.63] failed: Connection refused
nsi-dds-1                 | jakarta.ws.rs.ProcessingException: org.apache.http.conn.HttpHostConnectException: Connect to 192.168.13.63:8401 [/192.168.13.63] failed: Connection refused
nsi-dds-1                 |     at org.glassfish.jersey.apache.connector.ApacheConnector.apply(ApacheConnector.java:531)
nsi-dds-1                 |     at org.glassfish.jersey.client.ClientRuntime.invoke(ClientRuntime.java:297)
nsi-dds-1                 |     at org.glassfish.jersey.client.JerseyInvocation.lambda$invoke$0(JerseyInvocation.java:662)
nsi-dds-1                 |     at org.glassfish.jersey.client.JerseyInvocation.call(JerseyInvocation.java:697)
nsi-dds-1                 |     at org.glassfish.jersey.client.JerseyInvocation.lambda$runInScope$3(JerseyInvocation.java:691)
nsi-dds-1                 |     at org.glassfish.jersey.internal.Errors.process(Errors.java:292)
nsi-dds-1                 |     at org.glassfish.jersey.internal.Errors.process(Errors.java:274)
nsi-dds-1                 |     at org.glassfish.jersey.internal.Errors.process(Errors.java:205)
nsi-dds-1                 |     at org.glassfish.jersey.process.internal.RequestScope.runInScope(RequestScope.java:390)
nsi-dds-1                 |     at org.glassfish.jersey.client.JerseyInvocation.runInScope(JerseyInvocation.java:691)
nsi-dds-1                 |     at org.glassfish.jersey.client.JerseyInvocation.invoke(JerseyInvocation.java:661)
nsi-dds-1                 |     at org.glassfish.jersey.client.JerseyInvocation$Builder.method(JerseyInvocation.java:439)
nsi-dds-1                 |     at org.glassfish.jersey.client.JerseyInvocation$Builder.post(JerseyInvocation.java:345)
nsi-dds-1                 |     at net.es.nsi.dds.actors.RegistrationActor.register(RegistrationActor.java:141)
nsi-dds-1                 |     at net.es.nsi.dds.actors.RegistrationActor.onReceive(RegistrationActor.java:73)
nsi-dds-1                 |     at akka.actor.UntypedActor$$anonfun$receive$1.applyOrElse(UntypedActor.scala:167)
nsi-dds-1                 |     at akka.actor.Actor$class.aroundReceive(Actor.scala:467)
nsi-dds-1                 |     at akka.actor.UntypedActor.aroundReceive(UntypedActor.scala:97)
nsi-dds-1                 |     at akka.actor.ActorCell.receiveMessage(ActorCell.scala:516)
nsi-dds-1                 |     at akka.actor.ActorCell.invoke(ActorCell.scala:487)
nsi-dds-1                 |     at akka.dispatch.Mailbox.processMailbox(Mailbox.scala:238)
nsi-dds-1                 |     at akka.dispatch.Mailbox.run(Mailbox.scala:220)
nsi-dds-1                 |     at akka.dispatch.ForkJoinExecutorConfigurator$AkkaForkJoinTask.exec(AbstractDispatcher.scala:397)
nsi-dds-1                 |     at scala.concurrent.forkjoin.ForkJoinTask.doExec(ForkJoinTask.java:260)
nsi-dds-1                 |     at scala.concurrent.forkjoin.ForkJoinPool$WorkQueue.runTask(ForkJoinPool.java:1339)
nsi-dds-1                 |     at scala.concurrent.forkjoin.ForkJoinPool.runWorker(ForkJoinPool.java:1979)
nsi-dds-1                 |     at scala.concurrent.forkjoin.ForkJoinWorkerThread.run(ForkJoinWorkerThread.java:107)
nsi-dds-1                 | Caused by: org.apache.http.conn.HttpHostConnectException: Connect to 192.168.13.63:8401 [/192.168.13.63] failed: Connection refused
nsi-dds-1                 |     at org.apache.http.impl.conn.DefaultHttpClientConnectionOperator.connect(DefaultHttpClientConnectionOperator.java:156)
nsi-dds-1                 |     at org.apache.http.impl.conn.PoolingHttpClientConnectionManager.connect(PoolingHttpClientConnectionManager.java:376)
nsi-dds-1                 |     at org.apache.http.impl.execchain.MainClientExec.establishRoute(MainClientExec.java:393)
nsi-dds-1                 |     at org.apache.http.impl.execchain.MainClientExec.execute(MainClientExec.java:236)
nsi-dds-1                 |     at org.apache.http.impl.execchain.ProtocolExec.execute(ProtocolExec.java:186)
nsi-dds-1                 |     at org.apache.http.impl.execchain.RetryExec.execute(RetryExec.java:89)
nsi-dds-1                 |     at org.apache.http.impl.execchain.RedirectExec.execute(RedirectExec.java:110)
nsi-dds-1                 |     at org.apache.http.impl.client.InternalHttpClient.doExecute(InternalHttpClient.java:185)
nsi-dds-1                 |     at org.apache.http.impl.client.CloseableHttpClient.execute(CloseableHttpClient.java:72)
nsi-dds-1                 |     at org.glassfish.jersey.apache.connector.ApacheConnector.apply(ApacheConnector.java:483)
nsi-dds-1                 |     ... 26 more
nsi-dds-1                 | Caused by: java.net.ConnectException: Connection refused
nsi-dds-1                 |     at java.base/sun.nio.ch.Net.pollConnect(Native Method)
nsi-dds-1                 |     at java.base/sun.nio.ch.Net.pollConnectNow(Net.java:660)
nsi-dds-1                 |     at java.base/sun.nio.ch.NioSocketImpl.timedFinishConnect(NioSocketImpl.java:542)
nsi-dds-1                 |     at java.base/sun.nio.ch.NioSocketImpl.connect(NioSocketImpl.java:597)
nsi-dds-1                 |     at java.base/java.net.SocksSocketImpl.connect(SocksSocketImpl.java:333)
nsi-dds-1                 |     at java.base/java.net.Socket.connect(Socket.java:648)
nsi-dds-1                 |     at org.apache.http.conn.ssl.SSLConnectionSocketFactory.connectSocket(SSLConnectionSocketFactory.java:368)
nsi-dds-1                 |     at org.apache.http.impl.conn.DefaultHttpClientConnectionOperator.connect(DefaultHttpClientConnectionOperator.java:142)
nsi-dds-1                 |     ... 35 more
nsi-dds-1                 |
```


## Ultimate Goal
The ultimate goal is to build multiple node NSI networks.
And achieve the following:

nsi-requester (from anywhere) --> Safnari on icair_node --> Safnari on nycu_node
                                        |                           |
                                        V                           V
                                PolyNSI on icair_node       PolyNSI on nycu_node
                                        |                           |
                                        V                           V
                                SuPA on icair_node          SuPA on nycu_node


The nsi-requester issues the nsi request from icair's network stp to nycu's network stp, and for each Safnari will calculate the path and issues the corresponding nsi request segments, then setup the connection from icair network to nycu network.