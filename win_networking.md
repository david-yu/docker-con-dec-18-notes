# Windows networking

Shows some of Swarm's Windows networking capabilities. Assumes a running Swarmkit cluster with at least a couple of Windows nodes, and one Linux node.

## Ingress service publishing

Shows that services are accessible through any node in the cluster, regardless of which nodes their containers are actually running on.

Create a Windows IIS service:
```bash
docker service create --name iis --replicas 1 -p 8080:80 --constraint node.platform.os==windows microsoft/iis:windowsservercore-1709
```

Check that there is just one replica running on a single node by running `docker service ps iis`.

Even though it's running on a single node, it can be accessed from any node in the cluster: opening `http://<NODE_IP>:8080/` in a browser, where `NODE_IP` is the IP of any node (Windows or Linux) in the cluster, should display IIS' welcome page.

## Virtual IP service discovery

Shows that services can interact which each other (i.e. do DNS resolution) using just their names.

Create two services on the same overlay network:
```bash
docker network create overlay1 --driver overlay
docker service create --name s1 --replicas 2 --network overlay1 --constraint node.platform.os==windows microsoft/iis:windowsservercore-1709
docker service create --name s2 --replicas 2 --network overlay1 --constraint node.platform.os==windows microsoft/iis:windowsservercore-1709
```

Then on a Windows node, running:
```powershell
docker ps --format "{{.ID}}: {{.Names}}"
```
should give you the ID of a container running service s1; get a PowerShell prompt inside that container (`docker exec -it <CONTAINER_ID> powershell`), and run:
```powershell
Invoke-WebRequest -Uri http://s2 -UseBasicParsing
```
which should show a successful web request hit service s2.
