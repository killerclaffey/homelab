param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("k81", "k82", "k83")]
    [string]$Node
)

# Resolve local paths matching Kustomize structure
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = "." }
$GrubCfgPath = Join-Path $ScriptDir "base" "grub.cfg"
$BootUuidPath = Join-Path $ScriptDir "overlays" $Node "bootuuid.cfg"

if (-not (Test-Path $GrubCfgPath)) {
    Write-Error "Base configuration file 'grub.cfg' not found in $(Join-Path $ScriptDir 'base')."
    exit 1
}

if (-not (Test-Path $BootUuidPath)) {
    Write-Error "Overlay file 'bootuuid.cfg' for node $Node not found in $(Join-Path $ScriptDir 'overlays' $Node)."
    exit 1
}

# Load the base and overlay files
$GrubContent = Get-Content $GrubCfgPath -Raw
$BootUuidContent = Get-Content $BootUuidPath -Raw

Write-Host "Applying declarative boot configuration to node $Node (Kustomize structure)..." -ForegroundColor Cyan

# Encode to base64 to prevent any command parsing/escaping issues over the oc debug tunnel
$Base64Grub = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($GrubContent))
$Base64Uuid = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($BootUuidContent))

$RemoteScript = @"
set -e
mkdir -p /tmp/efi
mount /dev/nvme0n1p2 /tmp/efi

echo 'Writing /EFI/centos/grub.cfg (from base)...'
echo '$Base64Grub' | base64 -d > /tmp/efi/EFI/centos/grub.cfg
chmod 755 /tmp/efi/EFI/centos/grub.cfg

echo 'Writing /EFI/centos/bootuuid.cfg (from overlay)...'
echo '$Base64Uuid' | base64 -d > /tmp/efi/EFI/centos/bootuuid.cfg
chmod 755 /tmp/efi/EFI/centos/bootuuid.cfg

echo '=== Verification ==='
ls -la /tmp/efi/EFI/centos/grub.cfg /tmp/efi/EFI/centos/bootuuid.cfg
echo '=== grub.cfg ==='
cat /tmp/efi/EFI/centos/grub.cfg
echo '=== bootuuid.cfg ==='
cat /tmp/efi/EFI/centos/bootuuid.cfg

umount /tmp/efi
echo 'Unmounted EFI partition. Boot configuration successfully updated!'
"@

# Execute via oc debug node/
oc debug node/$Node -- chroot /host sh -c $RemoteScript
