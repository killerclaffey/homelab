# OKD Agent-Based Installation - Quick Reference

## Pre-Installation Checklist

### ☐ Hardware Requirements
- [ ] k81: Minimum 4 CPU cores, 16GB RAM, 120GB disk
- [ ] k82: Minimum 4 CPU cores, 16GB RAM, 120GB disk
- [ ] k83: Minimum 4 CPU cores, 16GB RAM, 120GB disk
- [ ] All nodes on same network (10.0.20.0/24)

### ☐ Network Configuration
- [ ] Gateway configured: 10.0.20.1
- [ ] DNS server configured: 10.0.20.1
- [ ] All nodes can reach internet (for pulling images)
- [ ] Firewall ports open between nodes

### ☐ DNS Records Created
- [ ] api.okd.claffey.cloud → 10.0.20.100
- [ ] api-int.okd.claffey.cloud → 10.0.20.100
- [ ] *.apps.okd.claffey.cloud → 10.0.20.100
- [ ] k81.okd.claffey.cloud → 10.0.20.100
- [ ] k82.okd.claffey.cloud → 10.0.20.101
- [ ] k83.okd.claffey.cloud → 10.0.20.102
- [ ] etcd SRV records created
- [ ] Reverse DNS (PTR) records created

### ☐ Information Gathered
- [ ] SSH public key generated
- [ ] MAC addresses recorded:
  - k81: ________________
  - k82: ________________
  - k83: ________________
- [ ] Network interface name verified: ________________

### ☐ Software Downloaded
- [ ] OpenShift installer downloaded
- [ ] openshift-install in PATH

### ☐ Configuration Files Prepared
- [ ] install-config.yaml updated with SSH key
- [ ] agent-config.yaml updated with MAC addresses
- [ ] agent-config.yaml updated with interface names

## Installation Command Reference

### Generate ISO
```bash
cd okd-install
openshift-install agent create image
```

### Boot Sequence
1. Boot k81 (10.0.20.100) first - wait 5-10 minutes
2. Boot k82 (10.0.20.101)
3. Boot k83 (10.0.20.102)

### Monitor Progress
```bash
# Bootstrap phase (15-30 min)
openshift-install agent wait-for bootstrap-complete --log-level=info

# Installation phase (30-45 min)
openshift-install agent wait-for install-complete --log-level=info
```

### Access Cluster
```bash
export KUBECONFIG=$PWD/auth/kubeconfig
oc get nodes
oc get co
```

### Login Credentials
- Username: kubeadmin
- Password: `cat auth/kubeadmin-password`
- Console: https://console-openshift-console.apps.okd.claffey.cloud

## Troubleshooting Commands

### Check Node Status
```bash
ssh core@10.0.20.100
sudo journalctl -u agent.service -f
ip addr show
ip route show
```

### Check Cluster Status
```bash
oc get nodes
oc get co
oc get pods --all-namespaces | grep -v Running
oc get events --all-namespaces --sort-by='.lastTimestamp'
```

### Common Issues

#### Issue: Node not getting static IP
**Check:**
```bash
# Verify MAC address
ip link show

# Check agent logs
sudo journalctl -u agent.service | grep -i network
```

#### Issue: DNS not resolving
**Check:**
```bash
# From each node
cat /etc/resolv.conf
nslookup api.okd.claffey.cloud
dig @10.0.20.1 k81.okd.claffey.cloud
```

#### Issue: Nodes not discovering each other
**Check:**
```bash
# Ensure rendezvous host is running
ping 10.0.20.100

# Check if assisted-service is running on rendezvous
ssh core@10.0.20.100
sudo podman ps | grep assisted
```

## Important Notes

1. **Rendezvous Host**: k81 (10.0.20.100) must boot first and stay running
2. **Boot Order**: Always boot k81 first, wait 5-10 minutes, then boot others
3. **ISO Reuse**: Same ISO can be used for all nodes
4. **Installation Time**: Total installation takes 60-90 minutes
5. **Network Access**: All nodes need internet access to pull container images
6. **Firewall**: Ensure firewall allows traffic between cluster nodes

## Required Ports

### Between Cluster Nodes (All must be open)
- 6443/TCP - Kubernetes API
- 22623/TCP - Machine Config Server
- 2379-2380/TCP - etcd
- 10250/TCP - Kubelet
- 9000-9999/TCP - Host services
- 4789/UDP - VXLAN
- 6081/UDP - Geneve
- 30000-32767/TCP - NodePort services

### Outbound Internet Access
- 443/TCP - HTTPS (for pulling images from quay.io, registry.fedoraproject.org)
- 80/TCP - HTTP (for package downloads)

## Post-Installation Tasks

### 1. Configure Image Registry (Required)
```bash
# For development (ephemeral storage)
oc patch configs.imageregistry.operator.openshift.io cluster --type merge \
  --patch '{"spec":{"storage":{"emptyDir":{}}}}'

# For production, configure persistent storage
```

### 2. Verify All Operators
```bash
oc get co
# All should show AVAILABLE=True, PROGRESSING=False, DEGRADED=False
```

### 3. Add Worker Nodes (Optional)
- Create new agent-config.yaml with worker nodes
- Generate new ISO
- Boot worker nodes

### 4. Configure Authentication
- Set up identity provider (LDAP, OAuth, etc.)
- Remove kubeadmin user after configuring alternative auth

### 5. Configure Monitoring
```bash
# Check monitoring stack
oc get pods -n openshift-monitoring
```

## Backup Important Files

After installation, backup these files:
```bash
cp -r auth/ ~/okd-cluster-backup/
cp install-config.yaml ~/okd-cluster-backup/
cp agent-config.yaml ~/okd-cluster-backup/
```

## Emergency Recovery

### If Installation Fails
1. Collect logs: `openshift-install agent gather`
2. Reboot nodes with ISO again
3. Check DNS and network connectivity
4. Review agent logs on each node

### If Node Fails to Join
1. SSH to node: `ssh core@<node-ip>`
2. Check agent service: `sudo systemctl status agent.service`
3. Check logs: `sudo journalctl -u agent.service --no-pager`
4. Reboot node if needed

## Success Indicators

Installation is successful when:
- ✅ All 3 nodes show as Ready: `oc get nodes`
- ✅ All cluster operators are Available: `oc get co`
- ✅ Console URL is accessible: `oc get route console -n openshift-console`
- ✅ Can login with kubeadmin credentials

## Next Steps After Successful Installation

1. Configure persistent storage
2. Set up monitoring and logging
3. Configure backup solution
4. Set up GitOps (ArgoCD)
5. Configure network policies
6. Set up certificate management
7. Configure identity provider
8. Add worker nodes if needed
9. Deploy first application to test
