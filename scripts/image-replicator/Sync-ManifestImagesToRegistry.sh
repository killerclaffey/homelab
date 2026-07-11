#!/usr/bin/env bash
#
# Sync-ManifestImagesToRegistry.sh
#
# Discovers container images in declarative Kubernetes manifests and copies them to GitLab Container Registry.
# Supports both OpenShift/OKD clusters (via 'oc' CLI) and standard Kubernetes clusters (via 'kubectl').
# Requires python3 with 'pyyaml' module installed.
#

# --- Clean error exit helper ---
exit_with_error() {
  local msg="$1"
  local code="${2:-1}"
  echo -e "ERROR: $msg" >&2
  exit "$code"
}

# --- Default parameters ---
MANIFESTS_DIR=""
DEST_REGISTRY="registry.apps.okd.claffey.cloud"
DEFAULT_PROJECT="rclaffey/homelab"
CUSTOM_PROJECT_PREFIX="rclaffey"
MODE="All"
FLATTEN=false
INCLUDE_NAMESPACE=""
EXCLUDE_NAMESPACE=""
CLI_TYPE="auto"
GITLAB_USER="root"
GITLAB_TOKEN=""
COPIER_NAMESPACE="gitlab-system"
DRY_RUN=false
NON_INTERACTIVE=false

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifests-dir)
      MANIFESTS_DIR="$2"
      shift 2
      ;;
    --dest-registry)
      DEST_REGISTRY="$2"
      shift 2
      ;;
    --default-project)
      DEFAULT_PROJECT="$2"
      shift 2
      ;;
    --custom-project-prefix)
      CUSTOM_PROJECT_PREFIX="$2"
      shift 2
      ;;
    --mode)
      if [[ "$2" != "All" && "$2" != "CustomOnly" ]]; then
        exit_with_error "Invalid mode: $2. Must be 'All' or 'CustomOnly'."
      fi
      MODE="$2"
      shift 2
      ;;
    --flatten)
      FLATTEN=true
      shift
      ;;
    --include-namespace)
      INCLUDE_NAMESPACE="$2"
      shift 2
      ;;
    --exclude-namespace)
      EXCLUDE_NAMESPACE="$2"
      shift 2
      ;;
    --cli-type)
      if [[ "$2" != "auto" && "$2" != "oc" && "$2" != "kubectl" ]]; then
        exit_with_error "Invalid cli-type: $2. Must be 'auto', 'oc', or 'kubectl'."
      fi
      CLI_TYPE="$2"
      shift 2
      ;;
    --gitlab-user)
      GITLAB_USER="$2"
      shift 2
      ;;
    --gitlab-token)
      GITLAB_TOKEN="$2"
      shift 2
      ;;
    --copier-namespace)
      COPIER_NAMESPACE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --manifests-dir <dir>       Path to Kubernetes manifests directory."
      echo "  --dest-registry <host>      Target registry host (default: registry.apps.okd.claffey.cloud)."
      echo "  --default-project <prefix>  GitLab project path for public images (default: rclaffey/homelab)."
      echo "  --custom-project-prefix <p> GitLab group prefix for custom images (default: rclaffey)."
      echo "  --mode <All|CustomOnly>     Selection scope (default: All)."
      echo "  --flatten                   Flatten all internal images under default project."
      echo "  --include-namespace <ns>    Comma-separated list of namespaces to include."
      echo "  --exclude-namespace <ns>    Comma-separated list of namespaces to exclude."
      echo "  --cli-type <auto|oc|k8s>    Force cluster CLI tool usage (default: auto)."
      echo "  --gitlab-user <user>        GitLab registry username (default: root)."
      echo "  --gitlab-token <token>      GitLab registry password/token."
      echo "  --copier-namespace <ns>     Namespace for public copier pods (default: gitlab-system)."
      echo "  --dry-run                   Perform a dry run without copying images."
      echo "  --non-interactive           Disable interactive login prompts."
      exit 0
      ;;
    *)
      exit_with_error "Unknown option: $1. Run with --help for usage."
      ;;
  esac
done

# Set up script pathing defaults
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "$MANIFESTS_DIR" ]]; then
  MANIFESTS_DIR="$SCRIPT_DIR/../../kubernetes"
fi
RESOLVED_MANIFESTS_DIR="$(cd "$MANIFESTS_DIR" &>/dev/null && pwd)"

# Verify manifests directory exists
if [[ -z "$RESOLVED_MANIFESTS_DIR" || ! -d "$RESOLVED_MANIFESTS_DIR" ]]; then
  exit_with_error "Manifests directory not found or unreachable: $MANIFESTS_DIR"
fi

# Check if terminal is interactive
if [[ -t 0 && -t 1 && "$NON_INTERACTIVE" = false && -z "${CI}" ]]; then
  IS_INTERACTIVE=true
else
  IS_INTERACTIVE=false
fi

# Validate parameters against shell injection patterns
SECURE_PATTERN='^[a-zA-Z0-9\.\-_/:]+$'
if [[ ! "$DEST_REGISTRY" =~ $SECURE_PATTERN ]]; then
  exit_with_error "Invalid target registry name: $DEST_REGISTRY"
fi
if [[ ! "$DEFAULT_PROJECT" =~ $SECURE_PATTERN ]]; then
  exit_with_error "Invalid default project prefix: $DEFAULT_PROJECT"
fi
if [[ ! "$CUSTOM_PROJECT_PREFIX" =~ $SECURE_PATTERN ]]; then
  exit_with_error "Invalid custom project prefix: $CUSTOM_PROJECT_PREFIX"
fi

echo "=== OKD/Kubernetes Image Copier Script (Bash) ==="
echo "Verifying prerequisites..."

# --- 1. Resolve Python Command ---
PYTHON_CMD=""
if command -v python3 &>/dev/null; then
  PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
  # Check if python maps to Python 3
  PYTHON_VER=$(python -c 'import sys; print(sys.version_info[0])' 2>/dev/null)
  if [[ "$PYTHON_VER" -eq 3 ]]; then
    PYTHON_CMD="python"
  fi
fi

if [[ -z "$PYTHON_CMD" ]]; then
  exit_with_error "Python 3 ('python3') is required for parsing manifests but was not found in the PATH."
fi

# Verify PyYAML is available
if ! $PYTHON_CMD -c "import yaml" &>/dev/null; then
  exit_with_error "Python 'pyyaml' module is required. Please install it using 'pip install pyyaml'."
fi

# --- 2. Resolve Cluster CLI tool ---
CLI=""
if [[ "$CLI_TYPE" = "oc" ]]; then
  if ! command -v oc &>/dev/null; then
    exit_with_error "The 'oc' command-line tool (OpenShift CLI) was explicitly requested but not found in the PATH."
  fi
  CLI="oc"
elif [[ "$CLI_TYPE" = "kubectl" ]]; then
  if ! command -v kubectl &>/dev/null; then
    exit_with_error "The 'kubectl' command-line tool was explicitly requested but not found in the PATH."
  fi
  CLI="kubectl"
else
  # Auto-detect, preferring 'oc' for OpenShift/OKD environments
  if command -v oc &>/dev/null; then
    CLI="oc"
  elif command -v kubectl &>/dev/null; then
    CLI="kubectl"
  else
    exit_with_error "Neither 'oc' (OpenShift CLI) nor 'kubectl' (Kubernetes CLI) was found in your PATH."
  fi
fi

echo "Using CLI tool: $CLI"

# --- 3. Verify Cluster Connection ---
echo "Testing cluster connection..."
$CLI api-versions &>/dev/null
IS_CONNECTED=$?

if [[ $IS_CONNECTED -ne 0 ]]; then
  echo "WARNING: Not currently connected to a cluster or session expired." >&2
  
  if [[ "$CLI" = "oc" ]]; then
    if [[ "$IS_INTERACTIVE" = true ]]; then
      echo -e "\nWould you like to authenticate to your OKD/OpenShift cluster now?"
      echo "1) Web Browser Authentication (oc login --web)"
      echo "2) CLI Authentication (oc login)"
      echo "3) Exit / Abort"
      read -r -p "Select an option [1-3]: " choice
      
      case "$choice" in
        1)
          echo "Launching web browser login..."
          $CLI login --web
          ;;
        2)
          echo "Launching CLI login..."
          $CLI login
          ;;
        *)
          exit_with_error "Aborted. Please connect to your cluster and try again."
          ;;
      esac
      
      # Re-test connection
      echo "Re-testing cluster connection..."
      if ! $CLI api-versions &>/dev/null; then
        exit_with_error "Authentication failed or cluster remains unreachable."
      fi
      echo "Successfully connected to OKD/OpenShift cluster."
    else
      exit_with_error "Cluster is unreachable. Cannot authenticate in non-interactive/CI mode. Please run 'oc login' before executing this script."
    fi
  else
    exit_with_error "Kubernetes cluster is unreachable. Please verify your kubeconfig context or network connection."
  fi
else
  echo "Cluster connection verified successfully."
fi

# Log Connection Identity
if [[ "$CLI" = "oc" ]]; then
  whoami=$($CLI whoami 2>/dev/null)
  if [[ $? -eq 0 && -n "$whoami" ]]; then
    echo "Authenticated to OKD/OpenShift as user: ${whoami}"
  fi
else
  context=$($CLI config current-context 2>/dev/null)
  if [[ $? -eq 0 && -n "$context" ]]; then
    echo "Connected to Kubernetes using context: ${context}"
  fi
fi

echo "Scanning manifests in: $RESOLVED_MANIFESTS_DIR"

# --- 4. Resolve GitLab Credentials ---
PLAIN_PASS=""

if [[ -n "$GITLAB_TOKEN" ]]; then
  PLAIN_PASS="$GITLAB_TOKEN"
elif [[ -n "${GITLAB_TOKEN_ENV:-$GITLAB_PASSWORD_ENV}" ]]; then
  # Fallback to env variables if set
  PLAIN_PASS="${GITLAB_TOKEN_ENV:-$GITLAB_PASSWORD_ENV}"
  echo "Using GitLab credentials from environment variables."
elif [[ -n "${GITLAB_TOKEN:-$GITLAB_PASSWORD}" ]]; then
  PLAIN_PASS="${GITLAB_TOKEN:-$GITLAB_PASSWORD}"
  echo "Using GitLab credentials from environment variables."
else
  # Attempt to retrieve root password automatically from cluster secret
  echo "Attempting to retrieve GitLab root password from cluster secret..."
  root_pass_b64=$($CLI get secret gitlab-gitlab-initial-root-password -n gitlab-system -o jsonpath='{.data.password}' 2>/dev/null)
  
  if [[ -n "$root_pass_b64" ]]; then
    PLAIN_PASS=$(echo "$root_pass_b64" | base64 --decode 2>/dev/null)
    if [[ $? -eq 0 && -n "$PLAIN_PASS" ]]; then
      echo "Successfully retrieved GitLab initial root password from secret."
    else
      PLAIN_PASS=""
      echo "WARNING: Failed to base64-decode the retrieved password secret." >&2
    fi
  else
    echo "GitLab root password secret not found or accessible in 'gitlab-system' namespace."
  fi

  # Interactive prompt if needed
  if [[ -z "$PLAIN_PASS" ]]; then
    if [[ "$IS_INTERACTIVE" = true ]]; then
      echo -e "\nGitLab registry credentials needed."
      read -r -p "Enter GitLab Registry Username [root]: " gitlab_user_input
      if [[ -n "$gitlab_user_input" ]]; then
        GITLAB_USER="$gitlab_user_input"
      fi
      # Prompt for password securely
      read -r -s -p "Enter GitLab Access Token or Password: " gitlab_pass_input
      echo ""
      if [[ -n "$gitlab_pass_input" ]]; then
        PLAIN_PASS="$gitlab_pass_input"
      fi
    fi
  fi
fi

if [[ "$DRY_RUN" = false && -z "$PLAIN_PASS" ]]; then
  exit_with_error "GitLab credentials are required but could not be resolved. Please specify --gitlab-token, set GITLAB_TOKEN/GITLAB_PASSWORD env variables, or ensure you have access to the cluster initial root password secret."
fi

# --- 5. Extract and Map Images via Python Helper ---
echo "Scanning manifests and extracting images..."

# Create temporary Python helper script
TEMP_DIR="${TMPDIR:-/tmp}"
TEMP_PYTHON_PATH=$(mktemp "$TEMP_DIR/extract_images_XXXXXX.py")

cat << 'EOF' > "$TEMP_PYTHON_PATH"
import os
import sys
import yaml
import json
import re

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
                except:
                    pass
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
                except:
                    pass
    except:
        pass
    return None

def get_destination_path(img, ns, container_name, dest_registry, default_project, custom_project_prefix, flatten, is_custom):
    digest = ""
    tag = ""
    parts = img.split("@")
    base_with_tag = parts[0]
    if len(parts) > 1:
        digest = "@" + parts[1]
        
    path_without_registry = base_with_tag
    url_parts = base_with_tag.split('/')
    if len(url_parts) > 1 and ('.' in url_parts[0] or ':' in url_parts[0] or url_parts[0] == 'localhost'):
        path_without_registry = '/'.join(url_parts[1:])
        
    last_colon = path_without_registry.rfind(':')
    if last_colon > -1:
        repo_path = path_without_registry[:last_colon]
        tag = path_without_registry[last_colon:]
    else:
        repo_path = path_without_registry
        tag = ":latest"
        
    if is_custom:
        if flatten:
            flat_repo_path = repo_path.replace("/", "-")
            dest_path = f"{default_project}/{flat_repo_path}{tag}{digest}"
        else:
            repo_name = repo_path.split("/")[-1]
            dest_path = f"{custom_project_prefix}/{ns}/{repo_name}{tag}{digest}"
    else:
        flat_repo_path = repo_path.replace("/", "-")
        dest_path = f"{default_project}/{flat_repo_path}{tag}{digest}"
        
    return f"{dest_registry}/{dest_path}"

def main():
    manifests_dir = sys.argv[1]
    dest_registry = sys.argv[2]
    default_project = sys.argv[3]
    custom_project_prefix = sys.argv[4]
    mode = sys.argv[5]
    flatten = sys.argv[6].lower() == 'true'
    include_namespaces = sys.argv[7].split(',') if sys.argv[7] else []
    exclude_namespaces = sys.argv[8].split(',') if sys.argv[8] else []
    
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
                                if isinstance(data.get('metadata'), dict):
                                    resource_ns = data['metadata'].get('namespace') or current_ns
                                if 'image' in data and isinstance(data['image'], str):
                                    img_str = data['image'].strip()
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

    image_regex = re.compile(r'^[a-zA-Z0-9\.\-\/:_]+(?:@sha256:[a-fA-F0-9]{64})?$')
    dns_regex = re.compile(r'^[a-zA-Z0-9\.\-_]+$')
    
    public_images = []
    custom_images = {}
    
    for item in unique_images.values():
        img = item['image']
        ns = item['namespace']
        container = item['container_name']
        
        if not image_regex.match(img):
            print(f"Warning: Skipping potentially unsafe image name: {img}", file=sys.stderr)
            continue
        if ns and not dns_regex.match(ns):
            print(f"Warning: Skipping item with invalid namespace: {ns}", file=sys.stderr)
            continue
        if container and not dns_regex.match(container):
            print(f"Warning: Skipping item with invalid container name: {container}", file=sys.stderr)
            continue
            
        if include_namespaces and ns not in include_namespaces:
            continue
        if exclude_namespaces and ns in exclude_namespaces:
            continue
            
        is_custom = 'image-registry.openshift-image-registry.svc' in img
        dest = get_destination_path(img, ns, container, dest_registry, default_project, custom_project_prefix, flatten, is_custom)
        
        mapped_item = {
            'source': img,
            'destination': dest
        }
        
        if is_custom:
            if ns not in custom_images:
                custom_images[ns] = []
            custom_images[ns].append(mapped_item)
        else:
            if mode == 'All':
                public_images.append(mapped_item)
                
    print(json.dumps({
        'public_images': public_images,
        'custom_images': custom_images
    }, indent=2))

if __name__ == '__main__':
    main()
EOF

# Run parser
PLAN_JSON=$($PYTHON_CMD "$TEMP_PYTHON_PATH" \
  "$RESOLVED_MANIFESTS_DIR" \
  "$DEST_REGISTRY" \
  "$DEFAULT_PROJECT" \
  "$CUSTOM_PROJECT_PREFIX" \
  "$MODE" \
  "$FLATTEN" \
  "$INCLUDE_NAMESPACE" \
  "$EXCLUDE_NAMESPACE")

# Clean up temp Python script
rm -f "$TEMP_PYTHON_PATH"

if [[ -z "$PLAN_JSON" ]]; then
  exit_with_error "No images extracted from manifests or Python parser failed."
fi

# Print discovery summary
public_count=$($PYTHON_CMD -c "import json, sys; data = json.load(sys.stdin); print(len(data.get('public_images', [])))" <<< "$PLAN_JSON")
custom_count=$($PYTHON_CMD -c "import json, sys; data = json.load(sys.stdin); print(sum(len(x) for x in data.get('custom_images', {}).values()))" <<< "$PLAN_JSON")
total_count=$((public_count + custom_count))

echo "Discovered $total_count image declarations in manifests."
echo "Selected for copying: $custom_count custom-built images, $public_count public images."

# --- 6. Execution Block ---
copied_images=()
failed_images=()

run_copier_pod() {
  local namespace="$1"
  local is_custom="$2"
  local images_list=("$3")
  
  # Determine count
  local img_count=${#images_list[@]}
  if [[ $img_count -eq 0 ]]; then
    return
  fi
  
  # Generate unique secret name
  local secret_suffix
  secret_suffix=$($PYTHON_CMD -c "import uuid; print(uuid.uuid4().hex[:8])")
  local secret_name="skopeo-creds-$secret_suffix"
  
  # A. Clean up potential leftover pods from previous runs
  $CLI delete pod skopeo-copier -n "$namespace" --wait=true --timeout=30s &>/dev/null
  
  # B. Create a temporary Kubernetes Secret containing credentials safely
  if [[ "$DRY_RUN" = false && -n "$PLAIN_PASS" ]]; then
    echo "Creating temporary credentials secret $secret_name in namespace $namespace..."
    local secret_json
    secret_json=$($PYTHON_CMD -c "
import json
obj = {
    'apiVersion': 'v1',
    'kind': 'Secret',
    'metadata': {
        'name': '$secret_name',
        'namespace': '$namespace'
    },
    'type': 'Opaque',
    'stringData': {
        'username': '$GITLAB_USER',
        'password': \"\"\"$PLAIN_PASS\"\"\"
    }
}
print(json.dumps(obj))
")
    if ! echo "$secret_json" | $CLI apply -f - &>/dev/null; then
      echo "WARNING: Failed to create credentials secret $secret_name in namespace $namespace. Image copying may fail if authentication is required." >&2
    fi
  fi
  
  # C. Build Skopeo command list
  local commands=()
  commands+=("echo 'Starting skopeo copier job...'")
  local counter=0
  
  for pair in "${images_list[@]}"; do
    IFS='|' read -r src dest <<< "$pair"
    ((counter++))
    
    local src_creds_part=""
    if [[ "$is_custom" = true ]]; then
      src_creds_part="--src-creds=serviceaccount:\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) "
    fi
    
    commands+=("echo '--------------------------------------------------'")
    commands+=("echo 'Copy [$counter/$img_count]: $src -> $dest'")
    commands+=("skopeo copy $src_creds_part--dest-creds=\"\$GITLAB_USER:\$GITLAB_PASSWORD\" --src-tls-verify=false --dest-tls-verify=false --all \"docker://$src\" \"docker://$dest\"")
    commands+=("if [ \$? -eq 0 ]; then echo 'RESULT: SUCCESS: $src'; else echo 'RESULT: FAILED: $src'; fi")
  done
  
  commands+=("echo '--------------------------------------------------'")
  commands+=("echo 'Job completed!'")
  
  # Join with semicolons
  local command_string
  command_string=$(printf " ; %s" "${commands[@]}")
  command_string="${command_string:3}"
  
  # D. Construct overrides object for restricted-v2 / PSS compliance
  local overrides_json
  overrides_json=$($PYTHON_CMD -c "
import json
obj = {
    'spec': {
        'securityContext': {
            'seccompProfile': {'type': 'RuntimeDefault'}
        },
        'containers': [
            {
                'name': 'skopeo-copier',
                'image': 'quay.io/containers/skopeo:latest',
                'command': ['/bin/sh', '-c', \"\"\"$command_string\"\"\"],
                'env': [
                    {
                        'name': 'GITLAB_USER',
                        'valueFrom': {
                            'secretKeyRef': {'name': '$secret_name', 'key': 'username'}
                        }
                    },
                    {
                        'name': 'GITLAB_PASSWORD',
                        'valueFrom': {
                            'secretKeyRef': {'name': '$secret_name', 'key': 'password'}
                        }
                    }
                ],
                'securityContext': {
                    'allowPrivilegeEscalation': False,
                    'capabilities': {'drop': ['ALL']},
                    'runAsNonRoot': True,
                    'seccompProfile': {'type': 'RuntimeDefault'}
                }
            }
        ]
    }
}
print(json.dumps(obj))
")

  # E. Create Pod
  echo "Creating skopeo-copier pod in namespace $namespace..."
  if ! $CLI run skopeo-copier -n "$namespace" --image=quay.io/containers/skopeo:latest --restart=Never --overrides="$overrides_json" &>/dev/null; then
    echo "WARNING: Failed to initiate pod/skopeo-copier creation in namespace $namespace." >&2
    $CLI delete secret "$secret_name" -n "$namespace" --wait=false &>/dev/null
    return
  fi

  # F. Wait for Pod startup
  $CLI wait --for=condition=Ready pod/skopeo-copier -n "$namespace" --timeout=120s &>/dev/null
  local wait_exit=$?
  local phase
  phase=$($CLI get pod skopeo-copier -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null)
  
  if [[ $wait_exit -ne 0 && "$phase" != "Succeeded" && "$phase" != "Running" ]]; then
    echo "WARNING: Pod skopeo-copier in namespace $namespace failed to enter running/succeeded state." >&2
    local pod_status
    pod_status=$($CLI get pod skopeo-copier -n "$namespace" -o json 2>/dev/null)
    if [[ -n "$pod_status" ]]; then
      local pod_phase
      pod_phase=$($PYTHON_CMD -c "import json, sys; data = json.load(sys.stdin); print(data.get('status', {}).get('phase'))" <<< "$pod_status")
      local container_waiting_reason
      container_waiting_reason=$($PYTHON_CMD -c "
import json, sys
data = json.load(sys.stdin)
statuses = data.get('status', {}).get('containerStatuses', [])
if statuses:
    print(statuses[0].get('state', {}).get('waiting', {}).get('reason', ''))
else:
    print('')
" <<< "$pod_status")
      local container_waiting_msg
      container_waiting_msg=$($PYTHON_CMD -c "
import json, sys
data = json.load(sys.stdin)
statuses = data.get('status', {}).get('containerStatuses', [])
if statuses:
    print(statuses[0].get('state', {}).get('waiting', {}).get('message', ''))
else:
    print('')
" <<< "$pod_status")
      
      if [[ -n "$container_waiting_reason" ]]; then
        echo "WARNING: Pod Phase: $pod_phase. Container Status: $container_waiting_reason - $container_waiting_msg" >&2
      else
        echo "WARNING: Pod Phase: $pod_phase." >&2
      fi
    else
      echo "WARNING: Failed to retrieve status for pod/skopeo-copier." >&2
    fi
    
    echo "Cleaning up failed resources..."
    $CLI delete pod skopeo-copier -n "$namespace" --wait=false &>/dev/null
    $CLI delete secret "$secret_name" -n "$namespace" --wait=false &>/dev/null
    return
  fi
  
  # G. Stream logs and capture results
  echo "Streaming copy logs..."
  
  # Use process substitution to parse results while streaming logs in real time
  while IFS= read -r line; do
    echo "$line"
    if [[ "$line" =~ RESULT:\ SUCCESS:\ (.*) ]]; then
      local img_name="${BASH_REMATCH[1]}"
      copied_images+=("$img_name")
    elif [[ "$line" =~ RESULT:\ FAILED:\ (.*) ]]; then
      local img_name="${BASH_REMATCH[1]}"
      failed_images+=("$img_name")
    fi
  done < <($CLI logs -f pod/skopeo-copier -n "$namespace" 2>/dev/null)
  
  # Check container exit code
  local exit_code
  exit_code=$($CLI get pod skopeo-copier -n "$namespace" -o jsonpath='{.status.containerStatuses[0].state.terminated.exitCode}' 2>/dev/null)
  if [[ $? -eq 0 && -n "$exit_code" && "$exit_code" -ne 0 ]]; then
    echo "WARNING: The copier container exited with a non-zero exit code: $exit_code. The operation may have been aborted." >&2
  fi
  
  # H. Clean up
  echo "Cleaning up copier pod and secret in namespace $namespace..."
  $CLI delete pod skopeo-copier -n "$namespace" --wait=false &>/dev/null
  $CLI delete secret "$secret_name" -n "$namespace" --wait=false &>/dev/null
}

# --- 7. Execution Logic ---

if [[ "$DRY_RUN" = true ]]; then
  echo -e "\n=== DRY RUN SUMMARY ==="
  echo "The following copies would be performed (No modifications will be made):"
  
  # Dry Run: Public
  if [[ $public_count -gt 0 ]]; then
    echo -e "\n[Pod in Namespace: $COPIER_NAMESPACE] (Public Images)"
    public_pairs=$($PYTHON_CMD -c "
import json, sys
data = json.load(sys.stdin)
for x in data.get('public_images', []):
    print(f\"  - {x['source']} -> {x['destination']}\")
" <<< "$PLAN_JSON")
    echo "$public_pairs"
  fi
  
  # Dry Run: Custom
  ns_list=$($PYTHON_CMD -c "import json, sys; data = json.load(sys.stdin); print(' '.join(data.get('custom_images', {}).keys()))" <<< "$PLAN_JSON")
  for ns in $ns_list; do
    echo -e "\n[Pod in Namespace: $ns] (Custom Internal Images)"
    custom_pairs=$($PYTHON_CMD -c "
import json, sys
data = json.load(sys.stdin)
for x in data.get('custom_images', {}).get('$ns', []):
    print(f\"  - {x['source']} -> {x['destination']}\")
" <<< "$PLAN_JSON")
    echo "$custom_pairs"
  done
  
  echo -e "\nDry run complete. Run without --dry-run to perform copy."
  exit 0
fi

# Start timer
start_time=$(date +%s)

# A. Process Public Images
if [[ "$MODE" = "All" && $public_count -gt 0 ]]; then
  echo -e "\n=== Copying Public/External Images ==="
  # Extract pairs array
  mapfile -t pub_pairs_arr < <($PYTHON_CMD -c "
import json, sys
data = json.load(sys.stdin)
for x in data.get('public_images', []):
    print(f\"{x['source']}|{x['destination']}\")
" <<< "$PLAN_JSON")
  run_copier_pod "$COPIER_NAMESPACE" false "${pub_pairs_arr[@]}"
fi

# B. Process Custom Images
ns_list=$($PYTHON_CMD -c "import json, sys; data = json.load(sys.stdin); print(' '.join(data.get('custom_images', {}).keys()))" <<< "$PLAN_JSON")
for ns in $ns_list; do
  echo -e "\n=== Copying Custom Images in Namespace: $ns ==="
  mapfile -t custom_pairs_arr < <($PYTHON_CMD -c "
import json, sys
data = json.load(sys.stdin)
for x in data.get('custom_images', {}).get('$ns', []):
    print(f\"{x['source']}|{x['destination']}\")
" <<< "$PLAN_JSON")
  run_copier_pod "$ns" true "${custom_pairs_arr[@]}"
done

# End timer
end_time=$(date +%s)
duration=$((end_time - start_time))
formatted_duration=$(printf "%02d:%02d:%02d" $((duration/3600)) $((duration%3600/60)) $((duration%60)))

# --- 8. Reporting Summary ---
echo -e "\n=== Copy Execution Complete ==="
echo "Time Elapsed: $formatted_duration"
echo "Successfully Copied: ${#copied_images[@]} images"
for img in "${copied_images[@]}"; do
  echo "  [SUCCESS] $img"
done

failed_count=${#failed_images[@]}
echo "Failed to Copy: $failed_count images"
if [[ $failed_count -gt 0 ]]; then
  for img in "${failed_images[@]}"; do
    echo "  [FAILED] $img" >&2
  done
  exit_with_error "Some image copy operations failed."
fi

echo "All operations completed successfully!"
exit 0
