# Lab Preparation Runbook

Chronological list of all steps to fast-track the lab. Steps marked `[SCRIPT]` are automated, steps marked `[UI]` are manual.

## Before You Start

```bash
cd ~/Documents/Lab/CloudExpDay/scripts
```

---

## Step 1: Verify Supervisor [UI]

**VCA (vSphere Client)**
- Menu → Supervisor Management → Supervisors → `supervisor`
- Confirm: Config Status = Running, Host Config Status = Running

---

## Step 2: Register Services on Supervisor [UI]

**VCA (vSphere Client)**

1. **ArgoCD Service**
   - Supervisor Management → Services → Add
   - Upload: `~/Downloads/1.0.1-24896502.yml`
   - Actions → Manage Service → Select `supervisor` → Next → Finish

2. **LCI Service**
   - Services → Add
   - Upload: `~/Downloads/lci-svs-9.0.1.yaml`
   - Actions → Manage Service → Select `supervisor` → Next → Finish

3. **VKS 3.4.0**
   - Kubernetes Service → Actions → Add New Version
   - Upload: `~/Downloads/3.4.0-package.yaml`
   - Wait for Active versions = 3
   - Actions → Manage Service → Select 3.4.0+v1.33 → Select `supervisor` → Finish
   - Wait for Status = Configured

---

## Step 3: Create Content Library and Upload Image [UI]

**VCFA (VCF Automation)**

1. Build & Deploy → Content Libraries → Create Content Library
   - Name: `vm-images`
   - Region: `us-west`, Storage Class: `cluster-wld01-01a-storage-policy`
   - Wait for Ready

2. Click `vm-images` → VM Images → Upload
   - File: `~/Downloads/noble-server-cloudimg-amd64.ova`
   - Wait for Ready

---

## Step 4: Configure Namespace Class [UI]

**VCFA**
- Manage & Govern → Namespace Class → Medium → VM & Storage Class
- Edit `cluster-wld01-01a-storage-policy` → **500 GB** (not MB!)
- Save

---

## Step 5: Create dev Namespace [UI]

**VCFA**
- Manage & Govern → Projects → default-project → Namespaces → New Namespace
- Name: `dev`, Class: `medium`, Region: `us-west`, VPC: `us-west-Default-VPC`, Zone: `z-wld-a`
- Wait for Active

**Record the namespace ID:**
```bash
export DEV_NS=dev-XXXXX   # Replace XXXXX with actual ID
```

---

## Step 6: Create VCFA CLI Context [SCRIPT]

```bash
./step06-vcfa-context.sh
```

This creates the VCF CLI context for VCFA with the API token.

---

## Step 7: Create vks-01 Cluster [UI]

**VCFA — This takes 15-20 minutes, start it now!**

1. Build & Deploy → Select `dev-XXXXX` → Kubernetes → Create → Custom Configuration
2. Configure:
   - Name: `vks-01`
   - Kubernetes Release: latest (v1.33.x)
   - Control Plane: 1 replica, `best-effort-xsmall`
   - Storage: `cluster-wld01-01a-storage-policy`, OS: Photon
   - Add worker nodepool (default settings)
3. **Download YAML files** (right side panel)
4. Click Finish
5. **Do NOT wait** — continue to next steps while cluster provisions

---

## Step 8: Create oc-mysql VM [UI]

**VCFA**

1. Build & Deploy → Select `dev-XXXXX` → Virtual Machines → Create VM → Deploy from OVF
2. Configure:
   - Name: `oc-mysql`
   - Zone: `z-wld-a`
   - Image: `noble-server-cloudimg-amd64`
   - VM Class: `best-effort-small`
   - Power State: Powered On
3. Add 2 Load Balancer ports:
   - SSH: 22 → 22
   - MySQL: 3306 → 3306
4. Guest Customization: Raw Configuration
   - Paste contents of `~/Documents/Lab/oc-mysql-cloud-config.yaml`
   - Add network: hostname=`oc-mysql`, domain=`vcf.lab`, DNS=`8.8.8.8`
5. **Download YAML files**
6. Click Deploy

**After VM is running, record the MySQL LB IP:**
```bash
export MYSQL_LB_IP=X.X.X.X   # From Network Service
```

---

## Step 9: Push OpenCart Image to Harbor [SCRIPT]

```bash
./step09-harbor-push.sh
```

This logs into Harbor, tags, and pushes the OpenCart container image.

---

## Step 10: Wait for vks-01 Ready [SCRIPT]

```bash
./step10-wait-vks01.sh
```

This polls until vks-01 cluster is in Ready state. **Takes 15-20 minutes from Step 7.**

---

## Step 11: Configure vks-01 and Deploy OpenCart [SCRIPT]

```bash
./step11-configure-vks01.sh
```

This script:
- Registers vks-01 with VCFA JWT authenticator
- Exports kubeconfig
- Creates VCF context for vks-01
- Installs Prometheus + Telegraf packages
- Deploys OpenCart LB and application

**Record the OpenCart LB IP from output:**
```bash
export OPENCART_LB_IP=X.X.X.X
```

---

## Step 12: Verify OpenCart Application [UI]

**Browser**
- Open `http://<OPENCART_LB_IP>`
- Browse the store, add items to cart

---

## Step 13: Create test Namespace [UI]

**VCFA**
- Manage & Govern → Projects → default-project → Namespaces → New Namespace
- Name: `test`, Class: `medium`, Region: `us-west`, VPC: `us-west-Default-VPC`, Zone: `z-wld-a`
- Wait for Active

**Record the namespace ID:**
```bash
export TEST_NS=test-XXXXX   # Replace XXXXX with actual ID
```

---

## Step 14: Deploy ArgoCD [SCRIPT]

```bash
./step14-deploy-argocd.sh
```

This script:
- Creates supervisor context
- Switches to test namespace
- Deploys ArgoCD instance
- Waits for pods to be running

**If pods stuck Pending:** Increase CPU limit in VCA:
- Menu → Workload Management → Namespaces → `test-XXXXX` → Configure → CPU: 25 GHz

**Record the ArgoCD IP from output:**
```bash
export ARGOCD_IP=10.1.11.X
```

---

## Step 15: Prepare and Upload Manifests to Gitea [UI]

**Local machine:**
1. Extract downloaded `create-tkg-cluster-yaml-files.zip`
2. Extract downloaded `create-vm-yaml-files.zip`
3. **Edit all YAML files: Remove `namespace:` lines**

**Gitea** (`http://10.1.10.130:3000`, holuser / VMware123!VMware123!):
1. Navigate to `argocd/opencart-infra`
2. Upload: `vks-01.yaml`, `oc-mysql.yaml`, other VM/LB manifests

---

## Step 16: Configure ArgoCD and Register Clusters [SCRIPT]

```bash
./step16-configure-argocd.sh
```

This script:
- Logs into ArgoCD CLI
- Changes admin password
- Registers Supervisor as ArgoCD destination

---

## Step 17: Wait for test vks-01 and Register in ArgoCD [UI + SCRIPT]

**VCFA:**
1. Build & Deploy → Select `test-XXXXX` → Kubernetes
2. Wait for vks-01 to be Ready (created by ArgoCD)
3. Click vks-01 → Download Kubeconfig → Save to `~/Downloads/vks-01-kubeconfig.yaml`

**Then run:**
```bash
./step17-register-test-vks01.sh
```

---

## Step 18: Update opencart.yaml with IPs [UI]

**Gitea:**
1. Navigate to `argocd/opencart-app/opencart.yaml`
2. Edit in browser
3. Get MySQL LB IP: `kubectl get svc` in test namespace (oc-mysql service)
4. Get OpenCart LB IP: `kubectl get svc -n opencart --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml`
5. Update 4 fields:
   - `OPENCART_DATABASE_HOST`: MySQL LB IP
   - `OPENCART_HOST`: OpenCart LB IP (3 places)
6. Commit changes

---

## Step 19: Create ArgoCD Applications [SCRIPT]

```bash
./step19-create-argocd-apps.sh
```

This creates the opencart-lb and opencart-app ArgoCD applications.

---

## Step 20: Verify and Demo GitOps [UI]

**ArgoCD Web UI** (`https://<ARGOCD_IP>`, admin / VMware123!VMware123!):
1. Verify all apps are Healthy: `opencart-infra`, `opencart-lb`, `opencart-app`
2. Click opencart-lb → my-open-cart-lb service → get IP
3. Access `http://<IP>` to verify app

**GitOps Demo:**
1. In Gitea, edit `argocd/opencart-infra/vks-01.yaml`
2. Change worker replicas: 1 → 2
3. Commit
4. Watch ArgoCD auto-sync and new node appear

---

## Quick Reference

| Variable | Where to Find |
|----------|---------------|
| `DEV_NS` | VCFA after Step 5 |
| `TEST_NS` | VCFA after Step 13 |
| `MYSQL_LB_IP` | VCFA Network Service after Step 8 |
| `OPENCART_LB_IP` | Script output in Step 11 |
| `ARGOCD_IP` | Script output in Step 14 |

| Credentials | Username | Password |
|-------------|----------|----------|
| vCenter | administrator@wld.sso | VMware123!VMware123! |
| VCFA | broadcomadmin | VMware123!VMware123! |
| Harbor | admin | Harbor12345 |
| Gitea | holuser | VMware123!VMware123! |
| ArgoCD | admin | VMware123!VMware123! (after change) |

| API Token |
|-----------|
| `0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3` |
