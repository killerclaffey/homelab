# OKD Agent-Based Installation with Static IPs

This guide walks you through creating ISO files for an OKD cluster with static IP addresses using the agent-based installation method.

## Overview

**Cluster Configuration:**
- Cluster Name: `okd`
- Base Domain: `claffey.cloud`
- Network: `10.0.20.0/24`
- Gateway: `10.0.20.1`
- DNS Server: `10.0.20.1`

**Node Configuration:**
| Hostname | IP Address    | Role   | MAC Address Required |
|----------|---------------|--------|---------------------|
| k81      | 10.0.20.100   | Master | Yes                 |
| k82      | 10.0.20.101   | Master | Yes                 |
| k83      | 10.0.20.102   | Master | Yes                 |

## Prerequisites

### 1. Download OpenShift Installer

Download the latest OKD installer from the [OKD releases page](https://github.com/okd-project/okd/releases):

```bash
# Example for OKD 4.15
wget https://github.com/okd-project/okd/releases/download/4.15.0-0.okd-2024-01-27-070424/openshift-install-linux-4.15.0-0.okd-2024-01-27-070424.tar.gz
tar -xzf openshift-install-linux-4.15.0-0.okd-2024-01-27-070424.tar.gz
sudo mv openshift-install /usr/local/bin/
```

### 2. Gather Required Information

#### A. MAC Addresses
Get MAC addresses for each node's primary network interface:

```bash
# On each node, run:
ip link show

# Example output:
# 2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
#     link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
```

#### B. SSH Key
Generate an SSH key if you don't have one:

```bash
ssh-keygen -t rsa -b 4096 -C "okd-cluster-access"
cat ~/.ssh/id_rsa.pub
```

#### C. Network Interface Name
Verify the network interface name (commonly `enp1s0`, `ens3`, `eth0`, etc.):

```bash
ip link show
```

### 3. DNS Configuration

**Required DNS Records:**

```bind
; A Records
api.okd.claffey.cloud.          IN  A   10.0.20.100
api-int.okd.claffey.cloud.      IN  A   10.0.20.100
k81.okd.claffey.cloud.          IN  A   10.0.20.100
k82.okd.claffey.cloud.          IN  A   10.0.20.101
k83.okd.claffey.cloud.          IN  A   10.0.20.102

; Wildcard for apps
*.apps.okd.claffey.cloud.       IN  A   10.0.20.100

; SRV Records for etcd
_etcd-server-ssl._tcp.okd.claffey.cloud. 86400 IN SRV 0 10 2380 k81.okd.claffey.cloud.
_etcd-server-ssl._tcp.okd.claffey.cloud. 86400 IN SRV 0 10 2380 k82.okd.claffey.cloud.
_etcd-server-ssl._tcp.okd.claffey.cloud. 86400 IN SRV 0 10 2380 k83.okd.claffey.cloud.

; PTR Records (Reverse DNS)
100.20.0.10.in-addr.arpa.       IN  PTR k81.okd.claffey.cloud.
101.20.0.10.in-addr.arpa.       IN  PTR k82.okd.claffey.cloud.
102.20.0.10.in-addr.arpa.       IN  PTR k83.okd.claffey.cloud.
```

Test DNS resolution:

```bash
nslookup api.okd.claffey.cloud
nslookup k81.okd.claffey.cloud
nslookup 10.0.20.100
```

## Configuration Files

### 1. install-config.yaml

Update the following fields:
- `sshKey`: Your SSH public key

```yaml
apiVersion: v1
baseDomain: claffey.cloud
metadata:
  name: okd
compute:
- name: worker
  replicas: 0
controlPlane:
  name: master
  replicas: 3
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  networkType: OVNKubernetes
platform:
  none: {}
pullSecret: '{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}'
sshKey: 'YOUR_SSH_PUBLIC_KEY_HERE'
```

### 2. agent-config.yaml

Update the following fields:
- `macAddress`: MAC address for each node
- `interfaces[].name`: Network interface name (if different from `enp1s0`)
- `dns-resolver.config.server`: DNS server IP (if different)
- `routes.config.next-hop-address`: Gateway IP (if different)

**Key Points:**
- `rendezvousIP`: Must be set to the IP of the first master node (10.0.20.100)
- Each host must have a unique `hostname`, `macAddress`, and IP address
- The `networkConfig` section uses NMState format for network configuration

## Installation Steps

### Step 1: Prepare Configuration Files

```bash
# Create working directory
mkdir okd-install
cd okd-install

# Copy the provided configuration files
cp /path/to/install-config.yaml .
cp /path/to/agent-config.yaml .

# Update the files with your specific values
vim install-config.yaml  # Update SSH key
vim agent-config.yaml    # Update MAC addresses and interface names
```

### Step 2: Generate the ISO

```bash
# Make the script executable
chmod +x generate-iso.sh

# Run the generation script
./generate-iso.sh
```

Or manually:

```bash
openshift-install agent create image
```

This will create:
- `agent.x86_64.iso` - The bootable ISO for all nodes
- `auth/kubeconfig` - Cluster access credentials (after installation)
- `auth/kubeadmin-password` - Admin password (after installation)

### Step 3: Boot Nodes from ISO

**Important:** Boot the rendezvous host (k81 - 10.0.20.100) first!

1. Copy the ISO to each node or make it available via network boot:
   ```bash
   # Using scp
   scp agent.x86_64.iso root@k81:/tmp/
   
   # Or use IPMI/iDRAC/iLO to mount the ISO remotely
   ```

2. Boot sequence:
   - **First**: Boot k81 (10.0.20.100) - This is the rendezvous host
   - Wait 5-10 minutes for it to start
   - **Then**: Boot k82 (10.0.20.101) and k83 (10.0.20.102)

### Step 4: Monitor Installation

The installation process has two main phases:

#### Phase 1: Bootstrap

```bash
openshift-install agent wait-for bootstrap-complete --log-level=info
```

This typically takes 15-30 minutes. You'll see output like:
```
INFO Waiting up to 30m0s for the Kubernetes API at https://api.okd.claffey.cloud:6443...
INFO API v1.28.0 up
INFO Waiting up to 30m0s for bootstrapping to complete...
```

#### Phase 2: Install Complete

```bash
openshift-install agent wait-for install-complete --log-level=info
```

This takes another 30-45 minutes. You'll see:
```
INFO Waiting up to 40m0s for the cluster at https://api.okd.claffey.cloud:6443 to initialize...
INFO Cluster is initialized
INFO Waiting up to 10m0s for the openshift-console route to be created...
INFO Install complete!
```

### Step 5: Access Your Cluster

```bash
# Set the kubeconfig
export KUBECONFIG=$PWD/auth/kubeconfig

# Verify nodes
oc get nodes
oc get co  # Check cluster operators

# Get console URL
oc get route console -n openshift-console

# Get admin credentials
cat auth/kubeadmin-password
```

## Troubleshooting

### Check Node Status

```bash
# SSH into a node (password: core)
ssh -i ~/.ssh/id_rsa core@10.0.20.100

# Check network configuration
ip addr show
ip route show
cat /etc/resolv.conf

# Check agent status
sudo journalctl -u agent.service -f

# Check assisted-service logs
sudo podman logs assisted-service
```

### Common Issues

#### 1. Nodes Not Discovering Each Other

**Symptom:** Only one node appears in the cluster

**Solution:**
- Ensure all nodes are on the same network
- Check firewall rules allow traffic between nodes
- Verify DNS resolution from each node
- Ensure rendezvous host (k81) was booted first

#### 2. Static IP Not Applied

**Symptom:** Node gets DHCP address instead of static IP

**Solution:**
- Verify MAC address matches the physical hardware
- Check interface name is correct (enp1s0, ens3, etc.)
- Review agent logs: `sudo journalctl -u agent.service`

#### 3. DNS Resolution Failures

**Symptom:** Nodes cannot resolve cluster domains

**Solution:**
- Verify DNS server is accessible from nodes
- Check DNS records are properly configured
- Test with: `nslookup api.okd.claffey.cloud 10.0.20.1`

#### 4. Installation Hangs

**Symptom:** Installation stops progressing

**Solution:**
```bash
# Check cluster operators
oc get co

# Check for failing pods
oc get pods --all-namespaces | grep -v Running

# Check specific operator logs
oc logs -n openshift-<operator-name> <pod-name>
```

### Required Firewall Ports

Ensure these ports are open between cluster nodes:

| Port      | Protocol | Purpose                  |
|-----------|----------|--------------------------|
| 6443      | TCP      | Kubernetes API           |
| 22623     | TCP      | Machine Config Server    |
| 2379-2380 | TCP      | etcd                     |
| 10250     | TCP      | Kubelet                  |
| 9000-9999 | TCP/UDP  | Host services            |
| 4789      | UDP      | VXLAN (OVN)             |
| 6081      | UDP      | Geneve (OVN)            |
| 30000-32767 | TCP    | NodePort services        |

## Post-Installation

### Add Worker Nodes

To add worker nodes later:

1. Create a new `agent-config.yaml` with worker nodes
2. Generate new ISO: `openshift-install agent create image`
3. Boot worker nodes with the new ISO

### Configure Storage

```bash
# For local storage (development)
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}}}}'

# For production, configure persistent storage
```

### Configure Authentication

```bash
# Remove temporary kubeadmin user after configuring identity provider
oc delete secrets kubeadmin -n kube-system
```

## Additional Resources

- [OKD Documentation](https://docs.okd.io/)
- [Agent-Based Installer Documentation](https://docs.okd.io/latest/installing/installing_with_agent_based_installer/preparing-to-install-with-agent-based-installer.html)
- [NMState Configuration Examples](https://nmstate.io/examples.html)
- [OKD GitHub Repository](https://github.com/okd-project/okd)

## Network Configuration Details

### Static IP Configuration (NMState Format)

The `networkConfig` in `agent-config.yaml` uses NMState format:

```yaml
networkConfig:
  interfaces:
    - name: enp1s0           # Interface name
      type: ethernet
      state: up
      ipv4:
        enabled: true
        address:
          - ip: 10.0.20.100  # Static IP
            prefix-length: 24 # Subnet mask (255.255.255.0)
        dhcp: false          # Disable DHCP
  dns-resolver:
    config:
      server:
        - 10.0.20.1          # DNS server
  routes:
    config:
      - destination: 0.0.0.0/0      # Default route
        next-hop-address: 10.0.20.1  # Gateway
        next-hop-interface: enp1s0
```

### Multiple Network Interfaces

If your nodes have multiple interfaces:

```yaml
networkConfig:
  interfaces:
    - name: enp1s0
      type: ethernet
      state: up
      ipv4:
        enabled: true
        address:
          - ip: 10.0.20.100
            prefix-length: 24
        dhcp: false
    - name: enp2s0
      type: ethernet
      state: up
      ipv4:
        enabled: true
        address:
          - ip: 192.168.1.100
            prefix-length: 24
        dhcp: false
```

## Support

For issues or questions:
- OKD Discussion: https://github.com/okd-project/okd/discussions
- Kubernetes Slack: #openshift-users channel
