# Nextcloud-FPM

Nextcloud deployed with a split PHP-FPM and Nginx architecture on OKD.

## Architecture

- **Web Server (`components/nginx`)**: Unprivileged Nginx (`nginxinc/nginx-unprivileged:1.31-alpine`) running on port `8080`, handling client connections, SSL termination headers, static asset caching, and FastCGI proxying to PHP-FPM.
- **Backend Application (`components/nextcloud`)**: Nextcloud PHP-FPM (`docker.io/nextcloud:35.0.1-fpm`) on port `9000`.
- **Database (`components/cnpg`)**: CloudNativePG PostgreSQL cluster (`nextcloud`) backed by NVMe-oF block storage (`tns-nvmeof-nvme`).
- **Cache & Locking (`components/valkey`)**: In-memory Redis-compatible Valkey service (`nextcloud-valkey`) on port `6379`.
- **Ingress (`components/openshift`)**: OpenShift Route with Edge TLS termination at `https://nextcloud.apps.okd.claffey.cloud`.
- **Background Tasks**:
  - `nextcloud-cron`: Batch CronJob executing `php /var/www/html/cron.php` every 10 minutes.
  - `nextcloud-preview`: Batch CronJob running `/var/www/html/occ preview:pre-generate -vvv` every 3 hours.
- **Storage**: Multi-pod ReadWriteMany (RWX) volumes provisioned by `truenas-nfs-bulk`.

## Directory Structure

```text
kubernetes/nextcloud-fpm/
├── base/                     # Core namespace, limits, RWX PVCs, default NetworkPolicies
├── components/
│   ├── nextcloud/            # PHP-FPM deployment, service, cronjobs, HPA, PDB
│   ├── nginx/                # Unprivileged Nginx deployment, nginx.conf, service, HPA, PDB
│   ├── valkey/               # Valkey deployment, service, PVC, NetworkPolicy
│   ├── cnpg/                 # CloudNativePG Cluster, RBAC, NetworkPolicy
│   └── openshift/            # OpenShift Route with HAProxy upload timeout tuning
├── overlays/
│   └── okd/                  # Main OKD Kustomization assembling base + components
└── README.md
```

## Manual occ Commands

To run Nextcloud `occ` commands against the running deployment:

```bash
POD=$(oc get pods -n nextcloud-fpm -l app=nextcloud -o jsonpath='{.items[0].metadata.name}')
oc exec -n nextcloud-fpm -it "${POD}" -c nextcloud -- php /var/www/html/occ status
```
