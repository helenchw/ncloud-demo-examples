# Demo pack for Network Coding of nEdge-nCloud

This demo pack starts a nEdge-nCloud cluster and shows the data repair bandwidth for single site failure.
Users can configure the cluster to run with either Reed Solomon codes or F-MSR codes and observe their difference in repair traffic over the network.

The pack adopts the Docker compose example of nEdge-nCloud upstream project [Nexoedge](https://github.com/nexoedge/nexoedge).

To run the demo, simply [install Docker](https://docs.docker.com/engine/install/) (both the Docker engine and Docker Compose plugin) and run `./demo.sh`.

To switch the coding, set the `CODING_SCHEME` variable in `.env`.

- F-MSR codes: "fmsr"
- Reed Solomon codes: "rs"

A recorded demo is available on [YouTube](https://youtu.be/IOcWHKx5Iuo).

## Setup Details

The single cluster consists of

| Component(s) | Service name(s) | Compose file |
|--------------|-----------------|--------------|
| A proxy                           | `proxy`                               | `proxy.yaml`    |
| Five agents                        | `site-1`, `site-2`, `site-3`, `site-4`, `site-5`  | `storage-sites.yaml`   |
| A Samba server with Nexoedge VFS  | `cifs`                                | `nexoedge-cifs-cluster.yaml`  |
| A metadata store                  | `metastore`                           | `proxy.yaml`    |
| A statistics store                | `statsdb`                             | `proxy.yaml`    |
| A reporter for statistics collection   | `reporter`                       | `proxy.yaml`    |
| A portal frontend                 | `portal-frontend`                     | `proxy.yaml`    |
| A portal backend                  | `portal-backend`                      | `proxy.yaml`    |

The cluster setup is defined in the file `nexoedge-cifs-cluster.yml` with the service names listed in the above.

The variables for cluster setup is defined in the file `.env`.

Cluster info

- `PROJECT_NAME`: Name of the Docker compose project

Data Persistence

- `NEXOEDGE_DATA_DIR`: Parent directory for Docker bind mounts.

Nexoedge Configurations

- `NEXOEDGE_PROXY_IP`: IP or domain name of the proxy. It should be reachable by the agents.
- `NEXOEDGE_PROXY_PORT`: Port of the proxy that opens to connections from agents.
- `NEXOEDGE_STORAGE_NODE_1_IP`: IP or domain name of the first agent. It should be reachable by the proxy.
- `NEXOEDGE_STORAGE_NODE_2_IP`: IP or domain name of the second agent. It should be reachable by the proxy.
- `NEXOEDGE_STORAGE_POLICY_N`: Total number of chunks per erasure coded stripe.
- `NEXOEDGE_STORAGE_POLICY_K`: Number of data chunks per erasure coded stripe.
- `NEXOEDGE_STORAGE_POLICY_F`: Number of agents failures to tolerate per erasure coded stripe.
- `NEXOEDGE_STORAGE_POLICY_MAX_CHUNK_SIZE`: Maximum size of an erasure coded chunk.
- `CODING_SCHEME`: Coding scheme to use for data reliability and security

Docker-related Settings

- `NEXOEDGE_NETWORK`: Name of the container network to connect the Nexoedge containers
- `TAG`: Tag of the images to use, e.g., release date or version.
- `NEXOEDGE_CIFS_IMAGE_NAME`: Name of the container image to use for Nexoedge CIFS
- `NEXOEDGE_PROXY_IMAGE_NAME`: Name of the container image to use for Nexoedge proxy
- `NEXOEDGE_AGENT_IMAGE_NAME`: Name of the container image to use for Nexoedge agent 
- `NEXOEDGE_REPORTER_IMAGE_NAME`: Name of the container image to use for Nexoedge reporter 
- `NEXOEDGE_PORTAL_FRONTEND_IMAGE_NAME`: Name of the container image to use for Nexoedge admin portal (web user interface)
- `NEXOEDGE_PORTAL_BACKEND_IMAGE_NAME`: Name of the container image to use for Nexoedge admin portal backend

The script `cmd.sh` is used to start and terminate the cluster. The available commands can be listed by running `./cmd.sh`.
