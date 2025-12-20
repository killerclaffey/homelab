# OKD Cluster Storage Configuration

## Overview
The OKD cluster uses a hybrid storage approach combining local storage on each node and shared network storage provided by TrueNAS Scale. Storage is segregated on VLAN 30 (OKD-Storage) for security and performance isolation.

## Storage Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   OKD Cluster Nodes                      │
│              K81, K82, K83 (VLAN 20)                    │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Local Storage│  │ Local Storage│  │ Local Storage│  │
│  │   ~545 GB    │  │   ~545 GB    │  │   ~545 GB    │  │
│  │   LUKS Enc   │  │   LUKS Enc   │  │   LUKS Enc   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                  │                  │          │
└─────────┼──────────────────┼──────────────────┼──────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                    VLAN 30 (Storage Network)
                       10.0.30.0/24 (Isolated)
                             │
                    ┌────────▼────────┐
                    │  TrueNAS Scale  │
                    │  10.0.30.x      │
                    │                 │
                    │  NFS Server     │
                    │  iSCSI Target   │
                    └─────────────────┘
```

## TrueNAS Scale Integration

### Network Configuration

**TrueNAS Interfaces:**
- **Management**: 10.0.0.62 (VLAN 1 - Management)
- **Storage**: 10.0.30.x (VLAN 30 - OKD-Storage)

**Storage Network (VLAN 30):**
- **Subnet**: 10.0.30.0/24
- **Gateway**: 10.0.30.1 (OPNsense)
- **Purpose**: Isolated NFS/iSCSI traffic
- **Access**: Only from VLAN 20 (OKD-Infra)
- **Security**: No internet access, isolated from other VLANs

### TrueNAS Storage Pools

Configuration to be documented based on actual TrueNAS setup:

```yaml
# Example storage pool configuration
Pool Name: okd-storage
  Type: Mirror/RAIDZ1/RAIDZ2 (to be confirmed)
  Datasets:
    - okd-nfs-pv      # For NFS persistent volumes
    - okd-backups     # For OADP backups
    - okd-registry    # For image registry
    - okd-logging     # For logging storage
```

### NFS Configuration

**NFS Server Setup on TrueNAS:**

1. **Create NFS Shares:**
   - Navigate to: Sharing > Unix Shares (NFS)
   - Configure exports for OKD cluster

**Example NFS Export Configuration:**
```
# TrueNAS NFS export for OKD
Path: /mnt/okd-storage/okd-nfs-pv
Authorized Networks: 10.0.20.0/24 (VLAN 20 - OKD nodes only)
Maproot User: root
Maproot Group: wheel
```

**NFS Security:**
- **NFSv4** recommended (better security, performance)
- **Kerberos**: Optional for enhanced security
- **Firewall**: Allow NFS ports (TCP/UDP 2049) from VLAN 20 only

**Required NFS Ports:**
```
TCP/2049  - NFS
TCP/111   - Portmapper
TCP/2049  - NFSv4 (if using NFSv4 only)
```

### iSCSI Configuration

**iSCSI Target Setup on TrueNAS:**

1. **Portal Configuration:**
   - IP Address: 10.0.30.x (Storage network)
   - Port: 3260

2. **Initiator Groups:**
   - Allow access from OKD nodes (10.0.20.100-102)
   - IQN-based or IP-based authentication

3. **Target Configuration:**
```yaml
Target Name: iqn.2005-10.org.freenas.ctl:okd-cluster
Portal Group: Storage Network (10.0.30.x:3260)
Initiator Group: okd-nodes
```

**iSCSI Security:**
- **CHAP Authentication**: Recommended for security
- **Firewall**: Allow iSCSI (TCP/3260) from VLAN 20 only

## Storage Classes

### Local Storage Class
Provided by the Local Storage Operator for node-local persistent volumes.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

**Use Cases:**
- High-performance local storage
- Temporary data
- Logs and metrics (if not using shared storage)
- etcd storage (built-in)

**Limitations:**
- No data redundancy (single node)
- Pod cannot move to another node
- Manual provisioning required

### NFS Storage Class (Dynamic Provisioning)

Using NFS Subdir External Provisioner or similar:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: nfs.csi.k8s.io
parameters:
  server: 10.0.30.x  # TrueNAS storage IP
  share: /mnt/okd-storage/okd-nfs-pv
  # Mount options for better performance
  mountOptions:
    - nfsvers=4.1
    - hard
    - intr
reclaimPolicy: Retain
volumeBindingMode: Immediate
allowVolumeExpansion: true
```

**Use Cases:**
- Shared storage (ReadWriteMany)
- Application data requiring persistence
- Shared configuration
- Database storage (with appropriate settings)

### iSCSI Storage Class (Block Storage)

For block storage using iSCSI:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: iscsi-storage
provisioner: kubernetes.io/iscsi
parameters:
  targetPortal: 10.0.30.x:3260  # TrueNAS storage IP
  iqn: iqn.2005-10.org.freenas.ctl:okd-cluster
  lun: "0"
  fsType: ext4
  chapAuthDiscovery: "true"
  chapAuthSession: "true"
  # CHAP credentials (use secret)
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

**Use Cases:**
- High-performance block storage
- Databases requiring block devices
- ReadWriteOnce volumes

## Local Storage Operator Configuration

The Local Storage Operator is installed to manage node-local storage.

### LocalVolume Custom Resource

```yaml
apiVersion: local.storage.openshift.io/v1
kind: LocalVolume
metadata:
  name: local-disks
  namespace: openshift-local-storage
spec:
  nodeSelector:
    nodeSelectorTerms:
    - matchExpressions:
      - key: kubernetes.io/hostname
        operator: In
        values:
        - k81
        - k82
        - k83
  storageClassDevices:
    - storageClassName: local-storage
      volumeMode: Filesystem
      fsType: xfs
      devicePaths:
        - /dev/disk/by-id/...  # Specific disk paths
```

### Verification

```bash
# Check Local Storage Operator
oc get pods -n openshift-local-storage

# List local volumes
oc get localvolume -n openshift-local-storage

# Check PVs created by local storage
oc get pv | grep local-storage
```

## Persistent Volume Claims

### Example NFS PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc-example
  namespace: my-app
spec:
  accessModes:
    - ReadWriteMany  # RWX for NFS
  storageClassName: nfs-storage
  resources:
    requests:
      storage: 10Gi
```

### Example Local Storage PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-pvc-example
  namespace: my-app
spec:
  accessModes:
    - ReadWriteOnce  # RWO for local storage
  storageClassName: local-storage
  resources:
    requests:
      storage: 50Gi
```

## Image Registry Storage

OpenShift requires persistent storage for the internal image registry.

### Registry Configuration (Using NFS)

```yaml
oc patch configs.imageregistry.operator.openshift.io cluster \
  --type merge \
  --patch '{"spec":{"storage":{"pvc":{"claim":""}}}}'

# Or specify a PVC
oc patch configs.imageregistry.operator.openshift.io cluster \
  --type merge \
  --patch '{"spec":{"storage":{"pvc":{"claim":"image-registry-storage"}}}}'
```

**Create Image Registry PVC:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: image-registry-storage
  namespace: openshift-image-registry
spec:
  accessModes:
    - ReadWriteMany  # Multiple registry pods
  storageClassName: nfs-storage
  resources:
    requests:
      storage: 100Gi  # Adjust based on image volume
```

### Verification

```bash
# Check registry storage
oc get pvc -n openshift-image-registry

# Check registry deployment
oc get deployment image-registry -n openshift-image-registry

# Check registry pods
oc get pods -n openshift-image-registry
```

## Backup and Disaster Recovery (OADP)

### OADP Operator Configuration

The OADP (OpenShift API for Data Protection) operator is installed for backup and restore.

**DataProtectionApplication CR:**
```yaml
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: okd-backup
  namespace: openshift-adp
spec:
  backupLocations:
    - velero:
        provider: aws  # Using S3-compatible (TrueNAS MinIO or similar)
        default: true
        objectStorage:
          bucket: okd-backups
          prefix: velero
        config:
          region: us-east-1  # Dummy region for S3-compatible
          s3ForcePathStyle: "true"
          s3Url: http://10.0.30.x:9000  # TrueNAS MinIO endpoint
        credential:
          name: cloud-credentials
          key: cloud
  snapshotLocations:
    - velero:
        provider: aws
        config:
          region: us-east-1
  configuration:
    velero:
      defaultPlugins:
        - openshift
        - aws
    restic:
      enable: true  # For file-level backups
```

### Backup Storage Options

**Option 1: TrueNAS S3-Compatible (MinIO)**
- Configure MinIO on TrueNAS
- Create bucket: `okd-backups`
- Use S3-compatible API

**Option 2: NFS for Backups**
- Mount NFS share in OADP pods
- Store backups on TrueNAS NFS

**Option 3: Local Storage**
- Use local storage for temporary backups
- Less reliable (single node)

### Create Backup Schedule

```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-backup
  namespace: openshift-adp
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  template:
    includedNamespaces:
      - "*"
    excludedNamespaces:
      - openshift*
      - kube-system
    storageLocation: default
    ttl: 720h  # 30 days retention
```

### Backup Verification

```bash
# List backups
oc get backups -n openshift-adp

# Check backup status
oc describe backup <backup-name> -n openshift-adp

# List schedules
oc get schedules -n openshift-adp

# Check OADP operator
oc get pods -n openshift-adp
```

## Storage Performance Optimization

### NFS Mount Options

For better NFS performance:
```yaml
mountOptions:
  - nfsvers=4.1      # Use NFSv4.1
  - hard             # Hard mount (retry on failure)
  - intr             # Allow interruption
  - rsize=1048576    # 1MB read size
  - wsize=1048576    # 1MB write size
  - timeo=600        # 60 second timeout
  - retrans=2        # Retry attempts
  - noatime          # Don't update access times
```

### Network Optimization

**VLAN 30 QoS:**
- Priority traffic for storage
- Dedicated bandwidth
- Low latency configuration

**TrueNAS Network Settings:**
- Jumbo frames: MTU 9000 (if supported by network)
- Flow control: Enabled
- Link aggregation: Optional for redundancy

## Monitoring Storage

### Check Storage Usage

```bash
# List all PVs
oc get pv

# Check PVC usage per namespace
oc get pvc --all-namespaces

# Describe PVC for details
oc describe pvc <pvc-name> -n <namespace>

# Check node local storage
oc debug node/k81
df -h
```

### Storage Metrics

Monitor via Cluster Observability:
- PV/PVC capacity and usage
- I/O latency and throughput
- NFS mount statistics
- iSCSI session health

## Troubleshooting

### NFS Mount Issues

```bash
# Test NFS connectivity from node
ssh core@k81
showmount -e 10.0.30.x

# Test NFS mount manually
sudo mount -t nfs -o nfsvers=4.1 10.0.30.x:/mnt/okd-storage/okd-nfs-pv /mnt/test

# Check NFS logs
sudo journalctl -u nfs-client -f

# Verify firewall allows NFS from VLAN 20
# On OPNsense: Check firewall rules for VLAN 20 → VLAN 30 on port 2049
```

### iSCSI Connection Issues

```bash
# Discover iSCSI targets
ssh core@k81
sudo iscsiadm -m discovery -t st -p 10.0.30.x:3260

# List iSCSI sessions
sudo iscsiadm -m session

# Login to target
sudo iscsiadm -m node -T iqn.2005-10.org.freenas.ctl:okd-cluster -p 10.0.30.x:3260 -l

# Check iSCSI logs
sudo journalctl -u iscsid -f
```

### PVC Stuck in Pending

```bash
# Check PVC status
oc describe pvc <pvc-name> -n <namespace>

# Check events
oc get events -n <namespace> --sort-by='.lastTimestamp'

# Check storage class
oc get storageclass

# Verify provisioner is running
oc get pods -n <provisioner-namespace>
```

### Storage Performance Issues

```bash
# Test NFS performance from node
ssh core@k81
dd if=/dev/zero of=/mnt/nfs/testfile bs=1M count=1024
# Should see write speed

# Test read performance
dd if=/mnt/nfs/testfile of=/dev/null bs=1M

# Check network latency to TrueNAS
ping -c 100 10.0.30.x
# Should be <1ms for local network

# Check for packet loss
ping -c 1000 10.0.30.x | grep loss
```

## Security Considerations

### Network Isolation
- VLAN 30 is isolated from other networks
- Only OKD nodes (VLAN 20) can access storage network
- No internet access from VLAN 30

### Access Control
- NFS exports restricted to 10.0.20.0/24
- iSCSI initiator groups limit access
- CHAP authentication for iSCSI (recommended)

### Encryption
- **At Rest**: TrueNAS pool encryption (optional)
- **In Transit**:
  - NFSv4 with Kerberos (optional)
  - iSCSI with CHAP
  - VLAN isolation provides network segregation

### Data Protection
- Regular backups via OADP
- TrueNAS snapshots for quick recovery
- Replication to secondary storage (optional)

## Capacity Planning

### Current Capacity
- **Local Storage**: 1.63 TB total (~545 GB per node)
- **TrueNAS**: Capacity depends on pool configuration

### Storage Growth Monitoring
```bash
# Check cluster-wide storage usage
oc get pv --no-headers | awk '{sum+=$5} END {print sum}'

# Monitor PVC growth trends
oc get pvc --all-namespaces -o json | jq '.items[] | {name: .metadata.name, namespace: .metadata.namespace, capacity: .status.capacity.storage}'
```

### Expansion Procedures
1. **TrueNAS**: Add disks to pool, expand dataset
2. **PVC Expansion**: Edit PVC spec (if storage class allows)
3. **Local Storage**: Add additional local volumes via LocalVolume CR

## Best Practices

### Storage Selection
- **Local Storage**: High-performance, ephemeral workloads
- **NFS**: Shared storage, multi-pod access (RWX)
- **iSCSI**: Database workloads, high I/O requirements

### Data Management
- Use appropriate storage class for workload
- Set resource quotas per namespace
- Implement backup schedules for critical data
- Monitor storage usage regularly

### Performance
- Keep storage network (VLAN 30) dedicated for storage traffic
- Use appropriate NFS mount options
- Consider SSD storage on TrueNAS for high-performance workloads
- Monitor latency and adjust configurations as needed

## Configuration Checklist

- [ ] TrueNAS configured with storage interface on VLAN 30
- [ ] NFS exports created and accessible from OKD nodes
- [ ] iSCSI targets configured (if using block storage)
- [ ] Firewall rules allow VLAN 20 → VLAN 30 (NFS/iSCSI ports)
- [ ] Storage classes created and tested
- [ ] Local Storage Operator configured
- [ ] Image registry storage configured
- [ ] OADP operator configured for backups
- [ ] Backup schedule created and tested
- [ ] Storage monitoring configured
- [ ] Performance testing completed
- [ ] Documentation updated with actual TrueNAS IPs and paths

## References

- [OKD Storage Documentation](https://docs.okd.io/latest/storage/index.html)
- [Local Storage Operator](https://docs.okd.io/latest/storage/persistent_storage/persistent-storage-local.html)
- [OADP Documentation](https://docs.okd.io/latest/backup_and_restore/index.html)
- [TrueNAS Scale NFS](https://www.truenas.com/docs/scale/scaletutorials/shares/nfs/)
- [TrueNAS Scale iSCSI](https://www.truenas.com/docs/scale/scaletutorials/shares/iscsi/)
- [Cluster README](README.md)
- [Network Configuration](Network_Configuration.md)
- [Node Configuration](Node_Configuration.md)
