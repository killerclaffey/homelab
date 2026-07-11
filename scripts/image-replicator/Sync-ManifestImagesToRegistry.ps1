<#
.SYNOPSIS
    Discovers container images in declarative Kubernetes manifests and copies them to GitLab Container Registry.

.DESCRIPTION
    This script parses declarative Kubernetes manifests in a specified directory, identifies all referenced
    container images, and copies them to a private GitLab Container Registry using Skopeo pods in the cluster.
    It supports both custom-built images (from the internal OpenShift registry) and public third-party images.
    It supports both OpenShift/OKD clusters (via the 'oc' CLI) and standard Kubernetes clusters (via 'kubectl').
    It does NOT modify any deployments or running configurations.

.PARAMETER ManifestsDir
    The path to the directory containing Kubernetes YAML manifests. Defaults to '..\..\kubernetes' relative
    to the script directory.

.PARAMETER DestRegistry
    The GitLab Container Registry host. Defaults to 'registry.apps.okd.claffey.cloud'.

.PARAMETER DefaultProject
    The GitLab project prefix for public/flattened images. Defaults to 'rclaffey/homelab'.

.PARAMETER CustomProjectPrefix
    The GitLab group/user prefix for custom images. Defaults to 'rclaffey'.

.PARAMETER Mode
    Specifies which images to copy. Options:
    - 'All': Copies both public/external images and custom-built internal images.
    - 'CustomOnly': Copies only custom-built internal images.
    Defaults to 'All'.

.PARAMETER Flatten
    If specified, flattens all image paths under the DefaultProject (e.g. 'rclaffey/homelab/library-postgres:15-alpine').
    If not specified, custom images are copied to 'rclaffey/<namespace>/<repo-name>:<tag>' and public images
    are copied to 'rclaffey/homelab/<flattened-image-name>:<tag>'.

.PARAMETER IncludeNamespace
    An array of namespaces to process. If specified, only images in these namespaces are processed.

.PARAMETER ExcludeNamespace
    An array of namespaces to exclude from processing.

.PARAMETER CliType
    Specifies the CLI tool to interact with the cluster. Options:
    - 'auto': Auto-detects 'oc', falling back to 'kubectl'.
    - 'oc': Force usage of OpenShift CLI ('oc').
    - 'kubectl': Force usage of Kubernetes CLI ('kubectl').
    Defaults to 'auto'.

.PARAMETER GitLabUser
    The GitLab Registry username. Defaults to 'root'.

.PARAMETER GitLabToken
    The GitLab Access Token or Password. If not provided, the script will first attempt to retrieve the initial
    root password from the cluster secret. If that fails and session is interactive, it prompts the user.

.PARAMETER CopierNamespace
    The namespace to run copier pods for public images. Defaults to 'gitlab-system'.

.PARAMETER DryRun
    If specified, performs a dry run. It scans the manifests, maps all source-to-destination paths,
    displays the planned copier jobs and Skopeo commands, but does not create pods or copy images.

.PARAMETER NonInteractive
    If specified, forces the script to run completely non-interactively, bypassing any login or credential prompts.

.EXAMPLE
    .\Sync-ManifestImagesToRegistry.ps1 -DryRun
    Scans the local manifests directory and outputs the source-to-destination image mappings.

.EXAMPLE
    .\Sync-ManifestImagesToRegistry.ps1 -Mode CustomOnly
    Copies only the custom-built internal registry images to GitLab.

.EXAMPLE
    .\Sync-ManifestImagesToRegistry.ps1 -IncludeNamespace @('bikely', 'uptime-kuma') -Flatten
    Copies images from 'bikely' and 'uptime-kuma' namespaces, flattening all destinations under 'rclaffey/homelab/'.

.EXAMPLE
    $secureToken = Read-Host -AsSecureString -Prompt "Enter Token"
    .\Sync-ManifestImagesToRegistry.ps1 -GitLabToken $secureToken
    Executes the sync using an explicitly passed GitLab secure token.

.NOTES
    Exit Behavior:
    - In an interactive session, failures throw a terminating exception.
    - In a non-interactive/CI session (such as when -NonInteractive is passed or $env:CI is set), failures exit the PowerShell process with a non-zero exit code (defaults to 1).
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$ManifestsDir = "",

    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9\.\-_:]+$')]
    [string]$DestRegistry = "registry.apps.okd.claffey.cloud",

    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9\.\-_\/]+$')]
    [string]$DefaultProject = "rclaffey/homelab",

    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9\.\-_]+$')]
    [string]$CustomProjectPrefix = "rclaffey",

    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "CustomOnly")]
    [string]$Mode = "All",

    [Parameter(Mandatory=$false)]
    [switch]$Flatten,

    [Parameter(Mandatory=$false)]
    [string[]]$IncludeNamespace,

    [Parameter(Mandatory=$false)]
    [string[]]$ExcludeNamespace,

    [Parameter(Mandatory=$false)]
    [ValidateSet("auto", "oc", "kubectl")]
    [string]$CliType = "auto",

    [Parameter(Mandatory=$false)]
    [string]$GitLabUser = "root",

    [Parameter(Mandatory=$false)]
    [System.Security.SecureString]$GitLabToken,

    [Parameter(Mandatory=$false)]
    [string]$CopierNamespace = "gitlab-system",

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
# Prevent native command stderr warnings (like python/oc) from throwing terminating script exceptions
$PSNativeCommandUseErrorActionPreference = $false

# Determine if the session is running interactively
$script:isInteractive = [Environment]::UserInteractive -and -not $env:CI -and -not $NonInteractive

# --- Helper function for clean error exits ---
function Exit-WithErrorMessage {
    param([string]$Message, [int]$ExitCode = 1)
    Write-Host "ERROR: $Message" -ForegroundColor Red
    if ($script:isInteractive) {
        throw $Message
    } else {
        exit $ExitCode
    }
}

# --- 1. Environment Verification & Cluster Connection ---

Write-Host "=== OKD/Kubernetes Image Copier Script ===" -ForegroundColor Cyan
Write-Host "Verifying prerequisites..." -ForegroundColor Gray

# A. Verify and Resolve CLI tool
$script:cli = ""
if ($CliType -eq "oc") {
    if (-not (Get-Command oc -ErrorAction SilentlyContinue)) {
        Exit-WithErrorMessage "The 'oc' command-line tool (OpenShift CLI) was explicitly requested but not found in the PATH."
    }
    $script:cli = "oc"
} elseif ($CliType -eq "kubectl") {
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Exit-WithErrorMessage "The 'kubectl' command-line tool was explicitly requested but not found in the PATH."
    }
    $script:cli = "kubectl"
} else {
    # Auto-detect, preferring 'oc' for OpenShift/OKD environments
    if (Get-Command oc -ErrorAction SilentlyContinue) {
        $script:cli = "oc"
    } elseif (Get-Command kubectl -ErrorAction SilentlyContinue) {
        $script:cli = "kubectl"
    } else {
        Exit-WithErrorMessage "Neither 'oc' (OpenShift CLI) nor 'kubectl' (Kubernetes CLI) was found in your PATH."
    }
}

Write-Host "Using CLI tool: $script:cli" -ForegroundColor Green

# B. Verify Python 3
$script:pythonCmd = ""
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    $script:pythonCmd = "python3"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pyVersion = & python -V 2>&1
    if ($pyVersion -match "Python 3") {
        $script:pythonCmd = "python"
    }
}

if ([string]::IsNullOrEmpty($script:pythonCmd)) {
    Exit-WithErrorMessage "Python 3 ('python3' or 'python') is required for parsing manifests but was not found in the PATH."
}

# C. Verify Python PyYAML module
$null = & $script:pythonCmd -c "import yaml" 2>$null
if ($LASTEXITCODE -ne 0) {
    Exit-WithErrorMessage "Python 'pyyaml' module is required. Please install it using 'pip install pyyaml'."
}

# D. Verify and Establish Cluster Connection
Write-Host "Testing cluster connection..." -ForegroundColor Gray
$oldEap = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$connectionTest = & $script:cli api-versions 2>$null
$ErrorActionPreference = $oldEap
$isConnected = ($LASTEXITCODE -eq 0 -and $connectionTest)

if (-not $isConnected) {
    Write-Warning "Not currently connected to a cluster or session expired."
    
    if ($script:cli -eq "oc") {
        if ($script:isInteractive) {
            Write-Host "`nWould you like to authenticate to your OKD/OpenShift cluster now?" -ForegroundColor Cyan
            Write-Host "1) Web Browser Authentication (oc login --web)"
            Write-Host "2) CLI Authentication (oc login)"
            Write-Host "3) Exit / Abort"
            
            $choice = Read-Host -Prompt "Select an option [1-3]"
            switch ($choice) {
                "1" {
                    Write-Host "Launching web browser login..." -ForegroundColor Cyan
                    & $script:cli login --web
                }
                "2" {
                    Write-Host "Launching CLI login..." -ForegroundColor Cyan
                    & $script:cli login
                }
                default {
                    Exit-WithErrorMessage "Aborted. Please connect to your cluster and try again."
                }
            }
            
            # Re-test connection
            Write-Host "`nRe-testing cluster connection..." -ForegroundColor Gray
            $connectionTest = & $script:cli api-versions 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $connectionTest) {
                Exit-WithErrorMessage "Authentication failed or cluster remains unreachable."
            }
            Write-Host "Successfully connected to OKD/OpenShift cluster." -ForegroundColor Green
        } else {
            Exit-WithErrorMessage "Cluster is unreachable. Cannot authenticate in non-interactive/CI mode. Please run 'oc login' before executing this script."
        }
    } else {
        Exit-WithErrorMessage "Kubernetes cluster is unreachable. Please verify your kubeconfig context or network connection."
    }
} else {
    Write-Host "Cluster connection verified successfully." -ForegroundColor Green
}

# E. Log Connection Identity
if ($script:cli -eq "oc") {
    $whoami = oc whoami 2>$null
    if ($whoami) {
        Write-Host "Authenticated to OKD/OpenShift as user: $($whoami.Trim())" -ForegroundColor Green
    }
} else {
    $context = kubectl config current-context 2>$null
    if ($context) {
        Write-Host "Connected to Kubernetes using context: $($context.Trim())" -ForegroundColor Green
    }
}

# F. Verify Manifests Directory
if ([string]::IsNullOrEmpty($ManifestsDir)) {
    $ManifestsDir = Join-Path $PSScriptRoot "..\..\kubernetes"
}
$resolvedManifestsDir = [System.IO.Path]::GetFullPath($ManifestsDir)
if (-not (Test-Path -Path $resolvedManifestsDir -PathType Container)) {
    Exit-WithErrorMessage "Manifests directory not found: $resolvedManifestsDir"
}
Write-Host "Scanning manifests in: $resolvedManifestsDir" -ForegroundColor Green

# --- 2. GitLab Credentials Resolution ---

$plainPass = ""

if ($GitLabToken) {
    # Use password passed via parameter (safely handle BSTR)
    $BSTR = $null
    try {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GitLabToken)
        $plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
    } finally {
        if ($BSTR) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }
} elseif ($env:GITLAB_TOKEN) {
    $plainPass = $env:GITLAB_TOKEN
    Write-Host "Using GitLab token from environment variable GITLAB_TOKEN." -ForegroundColor Green
} elseif ($env:GITLAB_PASSWORD) {
    $plainPass = $env:GITLAB_PASSWORD
    Write-Host "Using GitLab password from environment variable GITLAB_PASSWORD." -ForegroundColor Green
} else {
    # Attempt to retrieve root password automatically from secret
    Write-Host "Attempting to retrieve GitLab root password from cluster secret..." -ForegroundColor Cyan
    $rootPassBase64 = & $script:cli get secret gitlab-gitlab-initial-root-password -n gitlab-system -o jsonpath='{.data.password}' 2>$null
    
    if ($rootPassBase64) {
        try {
            $plainPass = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($rootPassBase64)).Trim()
            Write-Host "Successfully retrieved GitLab initial root password from secret." -ForegroundColor Green
        } catch {
            Write-Warning "Failed to base64-decode the retrieved password secret."
        }
    } else {
        Write-Host "GitLab root password secret not found or accessible in 'gitlab-system' namespace." -ForegroundColor Yellow
    }

    # Prompt user if auto-retrieval failed and session is interactive
    if ([string]::IsNullOrEmpty($plainPass)) {
        if ($script:isInteractive) {
            Write-Host "`nGitLab registry credentials needed." -ForegroundColor Yellow
            $GitLabUser = Read-Host -Prompt "Enter GitLab Registry Username"
            if ([string]::IsNullOrWhiteSpace($GitLabUser)) {
                $GitLabUser = "root"
            }
            $secureToken = Read-Host -AsSecureString -Prompt "Enter GitLab Access Token or Password"
            if ($secureToken) {
                $BSTR = $null
                try {
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
                    $plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
                } finally {
                    if ($BSTR) {
                        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                    }
                }
            }
        }
    }
}

if (-not $DryRun -and [string]::IsNullOrEmpty($plainPass)) {
    Exit-WithErrorMessage "GitLab credentials are required but could not be resolved. Please specify -GitLabToken, set GITLAB_TOKEN/GITLAB_PASSWORD env variables, or ensure you have access to the cluster initial root password secret."
}

# --- 3. Parsing Manifests for Images ---

Write-Host "`nScanning manifests and extracting images..." -ForegroundColor Cyan

# Write temporary python parser script safely using system temp path
$tempDir = [System.IO.Path]::GetTempPath()
$tempPythonPath = Join-Path $tempDir "extract_images_$([guid]::NewGuid().ToString('N')).py"

$pythonCode = @'
import os
import sys
import yaml
import json

def get_namespace_from_dir(dir_path):
    try:
        for f in os.listdir(dir_path):
            full_path = os.path.join(dir_path, f)
            if not os.path.isfile(full_path):
                continue
            f_lower = f.lower()
            if 'namespace' in f_lower and (f_lower.endswith('.yaml') or f_lower.endswith('.yml')):
                try:
                    with open(full_path, 'r', encoding='utf-8') as file:
                        docs = yaml.safe_load_all(file.read())
                        for doc in docs:
                            if doc and isinstance(doc, dict) and doc.get('kind') == 'Namespace':
                                ns = doc.get('metadata', {}).get('name')
                                if ns: return ns
                except Exception as e:
                    print(f"Warning: Failed to parse namespace file {full_path}: {e}", file=sys.stderr)
        
        for f in os.listdir(dir_path):
            full_path = os.path.join(dir_path, f)
            if not os.path.isfile(full_path):
                continue
            f_lower = f.lower()
            if 'kustomization' in f_lower and (f_lower.endswith('.yaml') or f_lower.endswith('.yml')):
                try:
                    with open(full_path, 'r', encoding='utf-8') as file:
                        doc = yaml.safe_load(file.read())
                        if doc and isinstance(doc, dict) and doc.get('namespace'):
                            return doc.get('namespace')
                except Exception as e:
                    print(f"Warning: Failed to parse kustomization file {full_path}: {e}", file=sys.stderr)
    except Exception as e:
        print(f"Warning: Failed to list directory {dir_path}: {e}", file=sys.stderr)
    return None

def main():
    if len(sys.argv) < 2:
        print("Usage: extract_images.py <manifests_dir>", file=sys.stderr)
        sys.exit(1)
    
    manifests_dir = sys.argv[1]
    images = []
    abs_manifests_dir = os.path.abspath(manifests_dir)
    
    for root, dirs, files in os.walk(abs_manifests_dir):
        dir_ns = get_namespace_from_dir(root)
        if not dir_ns:
            curr = root
            while curr:
                dir_ns = get_namespace_from_dir(curr)
                if dir_ns:
                    break
                if curr == abs_manifests_dir:
                    break
                curr = os.path.dirname(curr)
        
        if not dir_ns:
            rel_path = os.path.relpath(root, abs_manifests_dir)
            parts = rel_path.split(os.sep)
            if parts and parts[0] and parts[0] != '.':
                dir_ns = parts[0]
            else:
                dir_ns = "default"

        for f in files:
            f_lower = f.lower()
            if not (f_lower.endswith('.yaml') or f_lower.endswith('.yml')):
                continue
            path = os.path.join(root, f)
            try:
                with open(path, 'r', encoding='utf-8') as file:
                    content = file.read()
                    if '{{' in content and '}}' in content:
                        continue
                    docs = yaml.safe_load_all(content)
                    for doc in docs:
                        if not doc or not isinstance(doc, dict):
                            continue
                        
                        doc_ns = doc.get('metadata', {}).get('namespace') if isinstance(doc.get('metadata'), dict) else None
                        resolved_ns = doc_ns or dir_ns
                        
                        def search_images(data, current_ns):
                            found = []
                            if isinstance(data, dict):
                                resource_ns = current_ns
                                # Update namespace dynamically if navigating inside a nested resource with its own namespace
                                if isinstance(data.get('metadata'), dict):
                                    resource_ns = data['metadata'].get('namespace') or current_ns
                                
                                if 'image' in data and isinstance(data['image'], str):
                                    img_str = data['image'].strip()
                                    # Accept image names even if they don't have colon/slash/at (e.g. 'nginx' or 'mysql')
                                    if img_str and ' ' not in img_str:
                                        found.append({
                                            'image': img_str,
                                            'container_name': data.get('name'),
                                            'namespace': resource_ns
                                        })
                                for k, v in data.items():
                                    found.extend(search_images(v, resource_ns))
                            elif isinstance(data, list):
                                for item in data:
                                    found.extend(search_images(item, current_ns))
                            return found
                        
                        found_images = search_images(doc, resolved_ns)
                        for item in found_images:
                            item['manifest_path'] = path
                            images.append(item)
            except Exception as e:
                print(f"Warning: Failed to parse manifest {path}: {e}", file=sys.stderr)

    unique_images = {}
    for item in images:
        key = (item['image'], item['namespace'])
        if key not in unique_images:
            unique_images[key] = item

    print(json.dumps(list(unique_images.values()), indent=2))

if __name__ == '__main__':
    main()
'@

try {
    $pythonCode | Out-File -FilePath $tempPythonPath -Encoding utf8 -ErrorAction Stop
    $jsonOutput = & $script:pythonCmd "$tempPythonPath" "$resolvedManifestsDir"
    $pythonExitCode = $LASTEXITCODE
} finally {
    if (Test-Path -Path $tempPythonPath) {
        Remove-Item -Path $tempPythonPath -Force -ErrorAction SilentlyContinue
    }
}

if ($pythonExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($jsonOutput)) {
    Exit-WithErrorMessage "No images extracted from manifests or Python parser failed (exit code: $pythonExitCode)."
}

try {
    $extractedImages = $jsonOutput | ConvertFrom-Json -ErrorAction Stop
} catch {
    Exit-WithErrorMessage "Failed to parse JSON output from the Python parser. Raw output was:`n$jsonOutput"
}

Write-Host "Discovered $($extractedImages.Count) image declarations in manifests." -ForegroundColor Green

# --- 4. Filtering and Classification ---

$publicImages = @()
$customImages = @{} # Grouped by namespace: ns -> list of image items

# Strict regex patterns to prevent shell injection and path traversal
$imageRegex = '^[a-zA-Z0-9\.\-\/:_]+(?:@sha256:[a-fA-F0-9]{64})?$'
$dnsRegex = '^[a-zA-Z0-9\.\-_]+$'

foreach ($item in $extractedImages) {
    $img = $item.image
    $ns = $item.namespace
    
    # Security Validation
    if ($img -notmatch $imageRegex) {
        Write-Warning "Skipping potentially unsafe or invalid image name found in manifests: $img"
        continue
    }
    if ($ns -and $ns -notmatch $dnsRegex) {
        Write-Warning "Skipping item with invalid namespace name: $ns"
        continue
    }
    if ($item.container_name -and $item.container_name -notmatch $dnsRegex) {
        Write-Warning "Skipping item with invalid container name: $($item.container_name)"
        continue
    }
    
    # Apply namespace filters
    if ($ExcludeNamespace -and ($ExcludeNamespace -contains $ns)) {
        continue
    }
    if ($IncludeNamespace -and -not ($IncludeNamespace -contains $ns)) {
        continue
    }
    
    # Classify image
    $isCustom = $img -like "*image-registry.openshift-image-registry.svc*"
    
    if ($isCustom) {
        if (-not $customImages.ContainsKey($ns)) {
            $customImages[$ns] = @()
        }
        $customImages[$ns] += $item
    } else {
        if ($Mode -eq "All") {
            $publicImages += $item
        }
    }
}

$customCount = 0
foreach ($k in $customImages.Keys) {
    $customCount += $customImages[$k].Count
}

Write-Host "Selected for copying: $customCount custom-built images, $($publicImages.Count) public images." -ForegroundColor Green

# --- 5. Helper Functions for Destination Path and Skopeo Commands ---

function Get-DestinationPath {
    param (
        [Parameter(Mandatory=$true)]
        $ImageItem,
        [Parameter(Mandatory=$true)]
        [bool]$IsCustom,
        [Parameter(Mandatory=$true)]
        [string]$DestRegistry,
        [Parameter(Mandatory=$true)]
        [string]$DefaultProject,
        [Parameter(Mandatory=$true)]
        [string]$CustomProjectPrefix,
        [Parameter(Mandatory=$true)]
        [bool]$Flatten
    )
    
    $img = $ImageItem.image
    $ns = $ImageItem.namespace
    
    # Parse tag and digest
    $digest = ""
    $tag = ""
    $parts = $img -split "@"
    $baseWithTag = $parts[0]
    if ($parts.Count -gt 1) {
        $digest = "@" + $parts[1]
    }
    
    # Robust registry host stripping (removes everything up to the first slash if it's a domain/port)
    $pathWithoutRegistry = $baseWithTag
    $urlParts = $baseWithTag -split '/'
    if ($urlParts.Count -gt 1 -and ($urlParts[0] -match '\.' -or $urlParts[0] -match ':' -or $urlParts[0] -eq 'localhost')) {
        $pathWithoutRegistry = ($urlParts[1..($urlParts.Count-1)]) -join '/'
    }
    
    # Parse tag from the last colon index (prevents splitting on internal domain ports)
    $lastColonIndex = $pathWithoutRegistry.LastIndexOf(':')
    if ($lastColonIndex -gt -1) {
        $repoPath = $pathWithoutRegistry.Substring(0, $lastColonIndex)
        $tag = $pathWithoutRegistry.Substring($lastColonIndex)
    } else {
        $repoPath = $pathWithoutRegistry
        $tag = ""
    }
    
    # Default to :latest if both tag and digest are empty
    if ([string]::IsNullOrEmpty($tag) -and [string]::IsNullOrEmpty($digest)) {
        $tag = ":latest"
    }
    
    if ($IsCustom) {
        if ($Flatten) {
            # Flattened: rclaffey/homelab/<namespace>-<repo-name>
            $flatRepoPath = $repoPath -replace "/", "-"
            $destPath = "$DefaultProject/$flatRepoPath$tag$digest"
        } else {
            # Standard: rclaffey/<namespace>/<repo-name> (using repo-name prevents collisions from generic container names like 'web')
            $repoName = $repoPath -split "/" | Select-Object -Last 1
            $destPath = "$CustomProjectPrefix/$ns/$repoName$tag$digest"
        }
    } else {
        # Public images always flatten under DefaultProject
        $flatRepoPath = $repoPath -replace "/", "-"
        $destPath = "$DefaultProject/$flatRepoPath$tag$digest"
    }
    
    return "$DestRegistry/$destPath"
}

function Get-SkopeoCommandString {
    param (
        [Parameter(Mandatory=$true)]
        $ImagesToCopy,
        [Parameter(Mandatory=$true)]
        [bool]$IsCustom,
        [Parameter(Mandatory=$true)]
        [string]$DestRegistry,
        [Parameter(Mandatory=$true)]
        [string]$DefaultProject,
        [Parameter(Mandatory=$true)]
        [string]$CustomProjectPrefix,
        [Parameter(Mandatory=$true)]
        [bool]$Flatten
    )
    
    $commands = @()
    $commands += "echo 'Starting skopeo copier job...'"
    
    $counter = 0
    foreach ($item in $ImagesToCopy) {
        $counter++
        $img = $item.image
        $destUrl = Get-DestinationPath -ImageItem $item -IsCustom $IsCustom -DestRegistry $DestRegistry -DefaultProject $DefaultProject -CustomProjectPrefix $CustomProjectPrefix -Flatten $Flatten
        
        $srcUrl = "docker://$img"
        $destDockerUrl = "docker://$destUrl"
        
        $srcCredsPart = ""
        if ($IsCustom) {
            # Correctly escaped the '$' for $(cat ...) to prevent local PowerShell execution evaluation
            $srcCredsPart = "--src-creds=serviceaccount:`$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) "
        }
        
        $commands += "echo '--------------------------------------------------'"
        $commands += "echo 'Copy [$counter/$($ImagesToCopy.Count)]: $img -> $destUrl'"
        # Correctly escaped the '$' in $GITLAB_USER and $GITLAB_PASSWORD to prevent premature PowerShell expansion
        $commands += "skopeo copy $srcCredsPart--dest-creds=`"`$`GITLAB_USER:`$`GITLAB_PASSWORD`" --src-tls-verify=false --dest-tls-verify=false --all `"$srcUrl`" `"$destDockerUrl`""
        # Correctly escaped the '$' in $? to prevent premature PowerShell evaluation to True/False
        $commands += "if [ `$`? -eq 0 ]; then echo 'RESULT: SUCCESS: $img'; else echo 'RESULT: FAILED: $img'; fi"
    }
    
    $commands += "echo '--------------------------------------------------'"
    $commands += "echo 'Job completed!'"
    
    return $commands -join " ; "
}

function Start-CopierPod {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Namespace,
        [Parameter(Mandatory=$true)]
        [string]$CommandString
    )
    
    $secretName = "skopeo-copier-creds"
    
    # 1. Clean up potential leftover pods and secrets from previous runs
    $null = & $script:cli delete pod skopeo-copier -n $Namespace --wait=true --timeout=30s 2>$null
    $null = & $script:cli delete secret $secretName -n $Namespace --wait=true --timeout=10s 2>$null
    
    # 2. Create a temporary Kubernetes Secret containing credentials securely via stdin
    if (-not $DryRun -and -not [string]::IsNullOrEmpty($plainPass)) {
        Write-Host "Creating temporary credentials secret $secretName in namespace $Namespace..." -ForegroundColor Gray
        $secretManifest = @{
            apiVersion = "v1"
            kind = "Secret"
            metadata = @{
                name = $secretName
                namespace = $Namespace
            }
            type = "Opaque"
            stringData = @{
                username = $GitLabUser
                password = $plainPass
            }
        } | ConvertTo-Json -Depth 10 -Compress
        
        $secretManifest | & $script:cli apply -f - 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to create credentials secret $secretName in namespace $Namespace. Image copying may fail if authentication is required."
        }
    }
    
    # 3. Construct overrides object for restricted-v2 / Restricted PSA compliance
    $overridesObj = @{
        spec = @{
            securityContext = @{
                seccompProfile = @{
                    type = "RuntimeDefault"
                }
            }
            containers = @(
                @{
                    name = "skopeo-copier"
                    image = "quay.io/containers/skopeo:latest"
                    command = @("/bin/sh", "-c", $CommandString)
                    env = @(
                        @{
                            name = "GITLAB_USER"
                            valueFrom = @{
                                secretKeyRef = @{
                                    name = $secretName
                                    key = "username"
                                }
                            }
                        },
                        @{
                            name = "GITLAB_PASSWORD"
                            valueFrom = @{
                                secretKeyRef = @{
                                    name = $secretName
                                    key = "password"
                                }
                            }
                        }
                    )
                    securityContext = @{
                        allowPrivilegeEscalation = $false
                        capabilities = @{
                            drop = @("ALL")
                        }
                        runAsNonRoot = $true
                        # runAsUser is omitted to allow OpenShift dynamic UID allocation (SCC compliance)
                        seccompProfile = @{
                            type = "RuntimeDefault"
                        }
                    }
                }
            )
        }
    }
    $overridesJson = $overridesObj | ConvertTo-Json -Depth 10 -Compress
    
    # 4. Create Pod
    Write-Host "Creating skopeo-copier pod in namespace $Namespace..." -ForegroundColor Cyan
    & $script:cli run skopeo-copier -n $Namespace --image=quay.io/containers/skopeo:latest --restart=Never --overrides=$overridesJson | Out-Null
    if ($LASTEXITCODE -ne 0) {
        # Cleanup secret if pod creation failed
        $null = & $script:cli delete secret $secretName -n $Namespace --wait=false 2>$null
        return
    }

    # 5. Wait for Pod startup (with safety check if pod runs/completes instantly)
    $null = & $script:cli wait --for=condition=Ready pod/skopeo-copier -n $Namespace --timeout=120s 2>$null
    $waitExitCode = $LASTEXITCODE # Capture exit code immediately before it is overwritten
    $phase = & $script:cli get pod skopeo-copier -n $Namespace -o jsonpath='{.status.phase}' 2>$null
    
    if ($waitExitCode -ne 0 -and $phase -ne "Succeeded" -and $phase -ne "Running") {
        Write-Warning "Pod skopeo-copier in namespace $Namespace failed to start or enter running/succeeded state."
        $podStatus = & $script:cli get pod skopeo-copier -n $Namespace -o json 2>$null | ConvertFrom-Json
        if ($podStatus) {
            $podPhase = $podStatus.status.phase
            if ($podStatus.status.containerStatuses -and $podStatus.status.containerStatuses.Count -gt 0) {
                $containerState = $podStatus.status.containerStatuses[0].state
                if ($containerState.waiting) {
                    Write-Warning "Pod Phase: $podPhase. Container Status: $($containerState.waiting.reason) - $($containerState.waiting.message)"
                } else {
                    Write-Warning "Pod Phase: $podPhase. Container State: $($containerState | ConvertTo-Json -Depth 2)"
                }
            } else {
                Write-Warning "Pod Phase: $podPhase. No container statuses available."
            }
        } else {
            Write-Warning "Failed to retrieve status for pod/skopeo-copier in namespace $Namespace."
        }
        
        Write-Host "Cleaning up failed resources..." -ForegroundColor Cyan
        $null = & $script:cli delete pod skopeo-copier -n $Namespace --wait=false 2>$null
        $null = & $script:cli delete secret $secretName -n $Namespace --wait=false 2>$null
        return
    }
    
    # 6. Stream logs and capture results
    Write-Host "Streaming copy logs..." -ForegroundColor Gray
    
    & $script:cli logs -f pod/skopeo-copier -n $Namespace | ForEach-Object {
        Write-Host $_
        if ($_ -match "RESULT: SUCCESS: (.*)") {
            $script:copiedImages += $Matches[1].Trim()
        } elseif ($_ -match "RESULT: FAILED: (.*)") {
            $script:failedImages += $Matches[1].Trim()
        }
    }
    
    # Check container exit code for unexpected crash/termination
    $exitCode = & $script:cli get pod skopeo-copier -n $Namespace -o jsonpath='{.status.containerStatuses[0].state.terminated.exitCode}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $exitCode -and $exitCode -ne 0) {
        Write-Warning "The copier container exited with a non-zero exit code: $exitCode. The operation may have been aborted."
    }
    
    # 7. Clean up
    Write-Host "Cleaning up copier pod and secret in namespace $Namespace..." -ForegroundColor Cyan
    $null = & $script:cli delete pod skopeo-copier -n $Namespace --wait=false 2>$null
    $null = & $script:cli delete secret $secretName -n $Namespace --wait=false 2>$null
}

# --- 6. Execution ---

# Variables for statistics
$script:copiedImages = @()
$script:failedImages = @()

if ($DryRun) {
    Write-Host "`n=== DRY RUN SUMMARY ===" -ForegroundColor Yellow
    Write-Host "The following copies would be performed (No modifications will be made):" -ForegroundColor Gray
    
    # Public Images Plan
    if ($publicImages.Count -gt 0) {
        Write-Host "`n[Pod in Namespace: $CopierNamespace] (Public Images)" -ForegroundColor Cyan
        foreach ($item in $publicImages) {
            $dest = Get-DestinationPath -ImageItem $item -IsCustom $false -DestRegistry $DestRegistry -DefaultProject $DefaultProject -CustomProjectPrefix $CustomProjectPrefix -Flatten $Flatten
            Write-Host "  - $($item.image) -> $dest" -ForegroundColor Gray
        }
    }
    
    # Custom Images Plan
    foreach ($ns in $customImages.Keys) {
        $nsImages = $customImages[$ns]
        if ($nsImages.Count -gt 0) {
            Write-Host "`n[Pod in Namespace: $ns] (Custom Internal Images)" -ForegroundColor Cyan
            foreach ($item in $nsImages) {
                $dest = Get-DestinationPath -ImageItem $item -IsCustom $true -DestRegistry $DestRegistry -DefaultProject $DefaultProject -CustomProjectPrefix $CustomProjectPrefix -Flatten $Flatten
                Write-Host "  - $($item.image) -> $dest" -ForegroundColor Gray
            }
        }
    }
    Write-Host "`nDry run complete. Run without -DryRun to perform copy." -ForegroundColor Yellow
    return
}

# Real Execution
$startTime = [DateTime]::Now

# A. Copy public/external images (if any and in Mode 'All')
if ($Mode -eq "All" -and $publicImages.Count -gt 0) {
    Write-Host "`n=== Copying Public/External Images ===" -ForegroundColor Yellow
    $pubCommand = Get-SkopeoCommandString -ImagesToCopy $publicImages -IsCustom $false -DestRegistry $DestRegistry -DefaultProject $DefaultProject -CustomProjectPrefix $CustomProjectPrefix -Flatten $Flatten
    Start-CopierPod -Namespace $CopierNamespace -CommandString $pubCommand
}

# B. Copy custom/internal images (grouped by namespace)
foreach ($ns in $customImages.Keys) {
    $nsImages = $customImages[$ns]
    if ($nsImages.Count -gt 0) {
        Write-Host "`n=== Copying Custom Images in Namespace: $ns ===" -ForegroundColor Yellow
        $customCommand = Get-SkopeoCommandString -ImagesToCopy $nsImages -IsCustom $true -DestRegistry $DestRegistry -DefaultProject $DefaultProject -CustomProjectPrefix $CustomProjectPrefix -Flatten $Flatten
        Start-CopierPod -Namespace $ns -CommandString $customCommand
    }
}

# --- 7. Reporting Summary ---

$endTime = [DateTime]::Now
$duration = $endTime - $startTime

Write-Host "`n=== Copy Execution Complete ===" -ForegroundColor Green
Write-Host "Time Elapsed: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
Write-Host "Successfully Copied: $($script:copiedImages.Count) images" -ForegroundColor Green
if ($script:copiedImages.Count -gt 0) {
    foreach ($img in $script:copiedImages) {
        Write-Host "  [SUCCESS] $img" -ForegroundColor Green
    }
}
$failColor = if ($script:failedImages.Count -gt 0) { "Red" } else { "Gray" }
Write-Host "Failed to Copy: $($script:failedImages.Count) images" -ForegroundColor $failColor
if ($script:failedImages.Count -gt 0) {
    foreach ($img in $script:failedImages) {
        Write-Host "  [FAILED] $img" -ForegroundColor Red
    }
    Exit-WithErrorMessage "Some image copy operations failed."
}

Write-Host "All operations completed successfully!" -ForegroundColor Green
