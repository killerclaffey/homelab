#!/bin/bash
# OKD Agent-Based Installation ISO Generation Script
# This script generates ISO files for agent-based installation with static IPs

set -e

echo "=========================================="
echo "OKD Agent-Based Installation Setup"
echo "=========================================="
echo ""

# Configuration
CLUSTER_NAME="okd"
BASE_DOMAIN="claffey.cloud"
WORK_DIR="./okd-install"
RENDEZVOUS_IP="10.0.20.100"

# Node Configuration
declare -A NODES
NODES[k81]="10.0.20.100"
NODES[k82]="10.0.20.101"
NODES[k83]="10.0.20.102"

# Network Configuration
GATEWAY="10.0.20.1"
DNS_SERVER="10.0.20.1"
NETMASK="24"
INTERFACE_NAME="enp1s0"  # Adjust this to match your hardware

echo "Step 1: Prerequisites Check"
echo "-------------------------------------------"
if ! command -v openshift-install &> /dev/null; then
    echo "ERROR: openshift-install not found!"
    echo "Please download it from: https://github.com/okd-project/okd/releases"
    exit 1
fi

echo "✓ openshift-install found: $(openshift-install version)"
echo ""

echo "Step 2: Create Working Directory"
echo "-------------------------------------------"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
echo "✓ Created directory: $WORK_DIR"
echo ""

echo "Step 3: Important Information"
echo "-------------------------------------------"
echo "You need to update the following in the configuration files:"
echo ""
echo "1. MAC Addresses for each node:"
echo "   - Find MAC addresses with: ip link show"
echo "   - Update MAC_ADDRESS_K81, MAC_ADDRESS_K82, MAC_ADDRESS_K83 in agent-config.yaml"
echo ""
echo "2. SSH Public Key:"
echo "   - Update YOUR_SSH_PUBLIC_KEY_HERE in install-config.yaml"
echo "   - Generate with: ssh-keygen -t rsa -b 4096"
echo ""
echo "3. Network Interface Name:"
echo "   - Current default: $INTERFACE_NAME"
echo "   - Verify with: ip link show"
echo "   - Update 'enp1s0' in agent-config.yaml if different"
echo ""
echo "4. DNS Configuration:"
echo "   - Ensure DNS records exist for:"
echo "     * api.$CLUSTER_NAME.$BASE_DOMAIN"
echo "     * api-int.$CLUSTER_NAME.$BASE_DOMAIN"
echo "     * *.apps.$CLUSTER_NAME.$BASE_DOMAIN"
echo "     * k81.$CLUSTER_NAME.$BASE_DOMAIN -> 10.0.20.100"
echo "     * k82.$CLUSTER_NAME.$BASE_DOMAIN -> 10.0.20.101"
echo "     * k83.$CLUSTER_NAME.$BASE_DOMAIN -> 10.0.20.102"
echo ""

read -p "Have you updated the configuration files? (yes/no): " confirm
if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Please update the configuration files first, then run this script again."
    exit 0
fi
echo ""

echo "Step 4: Generate Agent ISO"
echo "-------------------------------------------"
echo "Running: openshift-install agent create image"
echo ""

# Copy configuration files to working directory
cp ../install-config.yaml .
cp ../agent-config.yaml .

# Generate the agent image
openshift-install agent create image

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ ISO generation completed successfully!"
    echo ""
    echo "=========================================="
    echo "Generated Files:"
    echo "=========================================="
    ls -lh *.iso 2>/dev/null || echo "Note: ISO file location may vary"
    echo ""
    echo "The agent.x86_64.iso file has been created."
    echo ""
else
    echo "ERROR: ISO generation failed!"
    exit 1
fi

echo "Step 5: Next Steps"
echo "-------------------------------------------"
echo "1. Copy the ISO to your nodes:"
echo "   scp agent.x86_64.iso user@host:/path/to/iso"
echo ""
echo "2. Boot each node from the ISO:"
echo "   - k81 (10.0.20.100) - First node (rendezvous host)"
echo "   - k82 (10.0.20.101)"
echo "   - k83 (10.0.20.102)"
echo ""
echo "3. Monitor installation progress:"
echo "   openshift-install agent wait-for bootstrap-complete --log-level=info"
echo ""
echo "4. After bootstrap completes:"
echo "   openshift-install agent wait-for install-complete --log-level=info"
echo ""
echo "5. Access your cluster:"
echo "   export KUBECONFIG=$PWD/auth/kubeconfig"
echo "   oc get nodes"
echo ""
echo "=========================================="
echo "Installation preparation complete!"
echo "=========================================="
