# VCF Field Demo Lab — Complete Instructor Reference

> **What this lab does:** Deploy OpenCart (MySQL VM + containerized frontend) twice — first manually in `dev-xxxxx`, then automated via ArgoCD in `test-xxxxx`.

---

## Table of Contents

- [Module 2: Enabling VCF Cloud Services](#module-2-enabling-vcf-cloud-services)
  - [Chapter 2 — VM Service Setup](#chapter-2--vm-service-setup-pg-1851)
  - [Chapter 3 — Add Services](#chapter-3--add-services-pg-6270)
  - [Chapter 4 — VKS Update](#chapter-4--vks-update-pg-7984)
- [Module 3: Building Cloud Topology](#module-3-building-cloud-topology)
  - [Chapter 2 — Org Setup](#chapter-2--org-setup-pg-121122)
- [Module 4: Consuming VCF Cloud Services](#module-4-consuming-vcf-cloud-services)
  - [Chapter 2 — Deploy MySQL VM](#chapter-2--deploy-mysql-vm-pg-139154)
  - [Chapter 3 — Harbor](#chapter-3--harbor-pg-159164)
  - [Chapter 4 — vks-01 Cluster Manually](#chapter-4--vks-01-cluster-manually-pg-169222)
  - [Chapter 5 — vks-01 Cluster Automated with ArgoCD](#chapter-5--vks-01-cluster-automated-with-argocd-pg-229292)
- [Quick Reference](#quick-reference)

---

## Contexts You'll Use

| Context | What it targets |
|---------|-----------------|
| `vcfa:dev-xxxxx` | Dev namespace via VCFA |
| `vks-01` | The vks-01 guest cluster |
| `supervisor:test-xxxxx` | Test namespace on Supervisor |
| `terminal` | Plain shell (no VCF context needed) |
| `argocd` | ArgoCD CLI session |

---

# Module 2: Enabling VCF Cloud Services

## Chapter 2 — VM Service Setup (Pg 18–51)

**Goal:** Create VM Class, Content Library, namespace, then set up VCF CLI.

### GUI: vCenter — Create VM Class (Pg 22–25)

> Menu → Supervisor Management → Services → VM Service: Manage → VM Classes

| Step | Action |
|------|--------|
| 1 | Create New VM Class |
| 2 | Name: `custom-small` |
| 3 | Leave hardware defaults → Next → Finish |

### GUI: VCFA — Create Content Library (Pg 29–36)

> Region A → VCF Automation → Login as broadcomadmin

| Step | Action |
|------|--------|
| 1 | Build & Deploy → Content Libraries → Create Content Library |
| 2 | Name: `vm-images`, keep "Assign to all namespaces" checked → Next |
| 3 | Region: `us-west`, Storage Class: `cluster-wld01-01a-storage-policy` → Next → Confirm |
| 4 | Click `vm-images` → VM Images → Upload |
| 5 | Upload `noble-server-cloudimg-amd64.ova` from Downloads → Submit |

### GUI: VCFA — Increase Namespace Storage Quota (Pg 38–39)

> Manage & Govern → Namespace Class → Medium

| Step | Action |
|------|--------|
| 1 | VM & Storage Class tab |
| 2 | Edit `cluster-wld01-01a-storage-policy` → **500 GB** (not MB!) |
| 3 | Save → Save |

### GUI: VCFA — Create Dev Namespace (Pg 42–44)

> Projects → default-project → Namespaces → New Namespace

| Field | Value |
|-------|-------|
| Name | `dev` |
| Namespace class | `medium` |
| Region | `us-west` |
| VPC | `us-west-Default-VPC` |
| Zone | ✓ `z-wld-a` |

→ Wait for **Active** status. Note the unique namespace name (e.g., `dev-xxxxx`).

> ⚠️ **WAIT** — The namespace needs time to fully initialize after showing Active. If you proceed to `vcf context create vcfa` too quickly, the dev-xxxxx sub-context will not be auto-discovered and you'll need to re-create the context.

### CLI: Set Up VCF CLI (Pg 48–51)

```bash
# Pg 48 — Create the vcfa context
vcf context create vcfa \
  --endpoint auto-a.site-a.vcf.lab \
  --api-token 0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3 \
  --tenant-name broadcom \
  --ca-certificate vcfa-cert-chain.pem

# Pg 49 — Switch to dev namespace (interactive menu)
vcf context use
# → Select: vcfa:dev-xxxxx:default-project
```

> [!WARNING]
> **CONTEXT: `vcfa:dev-xxxxx`** — All commands below run against the dev namespace via VCFA.

```bash
# Pg 50-51 — Verify VMs
kubectl get vm
kubectl get vmi
```

---

## Chapter 3 — Add Services (Pg 62–70)

**Goal:** Register ArgoCD and Local Consumption Interface services on Supervisor.

### GUI: vCenter — Add ArgoCD Service (Pg 62–66)

> Menu → Supervisor Management → Services → Add

| Step | Action |
|------|--------|
| 1 | Upload → `1.0.1-24896502.yml` from Downloads → Finish |
| 2 | ArgoCD tile → Actions → Manage Service |
| 3 | Select `supervisor` → Next → Next → Finish |

### GUI: vCenter — Add LCI Service (Pg 67–70)

> Services → Add

| Step | Action |
|------|--------|
| 1 | Upload → `lci-svs-9.0.1.yaml` from Downloads → Finish |
| 2 | Local Consumption Interface tile → Actions → Manage Service |
| 3 | Select `supervisor` → Next → Next → Finish |

---

## Chapter 4 — VKS Update (Pg 79–84)

**Goal:** Upload and install VKS 3.4.0 on Supervisor.

### GUI: vCenter — Upload & Install VKS Package (Pg 79–84)

> Menu → Supervisor Management → Services → Kubernetes Service

| Step | Action |
|------|--------|
| 1 | Actions → Add New Version |
| 2 | Upload → `3.4.0-package.yaml` from Downloads → Finish |
| 3 | Wait for Active versions: **3** |
| 4 | Actions → Manage Service |
| 5 | Select version `3.4.0+v1.33`, select `supervisor` → Next → Next → CANCEL IT DONT PROGRESS to Finish as this will take 1hr and impact LAB |
| 6 | Wait for Service Status: **Configured** |

---

# Module 3: Building Cloud Topology

## Chapter 2 — Org Setup (Pg 121–122)

**Goal:** Add custom VM Class to Broadcom org entitlements.

### GUI: VCFA Provider — Add VM Class to Org (Pg 121–122)

> Region A → VCF Automation - Provider → Login as admin

| Step | Action |
|------|--------|
| 1 | Organizations → Broadcom → Region Quota |
| 2 | Edit under VM Classes |
| 3 | Page 2 → ✓ check `custom-small` → Save |

---

# Module 4: Consuming VCF Cloud Services

## Chapter 2 — Deploy MySQL VM (Pg 139–154)

**Goal:** Create the oc-mysql backend VM with load balancer.

### GUI: VCFA — Create oc-mysql VM (Pg 139–152)

> Region A → VCF Automation → Login as broadcomadmin → Services (dev-xxxxx) → Virtual Machine → Create VM

| Step | Action |
|------|--------|
| 1 | Deploy from OVF → Next |
| 2 | Name: `oc-mysql`, Zone: `z-wld-a` |
| 3 | Image: `noble-server-cloudimg-amd64` |
| 4 | VM Class: `best-effort-small`, Power State: Powered On → Next |
| 5 | Load Balancer → Add → New |
| 6 | Port 1: Name `ssh`, Port `22`, Target `22` → Add |
| 7 | Port 2: Name `mysql`, Port `3306`, Target `3306` → Add → Save |
| 8 | Guest Customization → Raw Configuration |
| 9 | Open VS Code → `oc-mysql-cloud-config.yaml` → Ctrl+A, Ctrl+C |
| 10 | Paste into Raw Configuration (Ctrl+V) → Next |
| 11 | Hostname: `oc-mysql`, Domain: `vcf.lab`, Nameservers: `8.8.8.8` → Add → Next |
| **12** | **⚠️ DOWNLOAD YAMLs** (click download arrow) — needed for ArgoCD! |
| 13 | Deploy VM → Wait for completion |

→ Note the **External IP** from Network Service for the MySQL load balancer.

---

## Chapter 3 — Harbor (Pg 159–164)

**Goal:** Create Harbor project and push OpenCart image.

### GUI: Harbor — Create Project (Pg 159)

> https://harbor-01a.site-a.vcf.lab → Login: admin / Harbor12345

| Step | Action |
|------|--------|
| 1 | New Project |
| 2 | Name: `opencart`, Access: ✓ Public → OK |

### CLI: Push Image to Harbor (Pg 160–164)

> [!WARNING]
> **CONTEXT: `terminal`** — No VCF context needed. Doesn't matter which context you're currently in, just stay there.

```bash
# Pg 160 — Login to Harbor (admin / Harbor12345)
docker login harbor-01a.site-a.vcf.lab

# Pg 162 — Tag for Harbor
docker tag \
  vcf-automation-docker-dev-local.usw5.packages.broadcom.com/bitnami/opencart:4.0.1-1-debian-11-r66 \
  harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66

# Pg 163 — Push to Harbor
docker push harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66
```

---

## Chapter 4 — vks-01 Cluster Manually (Pg 169–222)

**Goal:** Create VKS cluster, configure CLI, install packages, deploy OpenCart.

### GUI: VCFA — Create vks-01 Cluster (Pg 173–181)

> VCF Automation → Services (dev-xxxxx) → Kubernetes → Create

| Step | Action |
|------|--------|
| 1 | Custom Configuration → Next |
| 2 | Name: `vks-01`, latest Kubernetes release |
| 3 | Control Plane: 1 replica, `best-effort-xsmall` |
| 4 | Storage: `cluster-wld01-01a-storage-policy`, OS: `Photon` → Next |
| 5 | Add Nodepool (keep defaults) → Next → Finish |
| **6** | **⚠️ DOWNLOAD YAML** (click download arrow) — needed for ArgoCD! |
| 7 | Finish → Wait for **Ready** status |

> ⚠️ **WAIT ~10 MINUTES** — vks-01 takes at least 10 minutes to fully deploy. Control Plane comes up first, but worker nodes take longer. Do not proceed with CLI configuration until status is **Ready** and both nodes are available.

### CLI: Configure CLI for vks-01 (Pg 184–193)

> [!WARNING]
> **CONTEXT: `vcfa:dev-xxxxx`** — Must be in the dev namespace CCI context.

```bash
# Pg 184-185 — Confirm context
Is cluster ready ?
  vcf cluster list
vcf context list
vcf context use vcfa:dev-xxxxx:default-project
# Token if prompted: 0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3

# Pg 186-188 — Register vks-01 and get kubeconfig
vcf cluster list
vcf cluster register-vcfa-jwt-authenticator vks-01
vcf cluster kubeconfig get vks-01 --export-file ~/.kube/config

# Pg 189 — Verify kubeconfig has vks-01
cat ~/.kube/config | grep vks-01

# Pg 190 — Create context (does NOT auto-switch!)
vcf context create vks-01 \
  --kubeconfig ~/.kube/config \
  --kubecontext vcf-cli-vks-01-dev-xxxxx@vks-01-dev-xxxxx
# → Select: cloud-consumption-interface

# Pg 191-192 — Refresh and verify
vcf context refresh
vcf context list

# Pg 193 — NOW switch to vks-01
vcf context use vks-01
```

> [!WARNING]
> **CONTEXT: `vks-01`** — All commands below run against the vks-01 guest cluster.

### CLI: Install Packages on vks-01 (Pg 194–204)

```bash
# Pg 194 — Verify nodes are Ready
kubectl get node

# Pg 195 — Add package repo
vcf package repository add default-repo \
  --url projects.packages.broadcom.com/vsphere/supervisor/packages/2025.8.19/vks-standard-packages:v2025.8.19 \
  -n tkg-system

# Pg 196 — List available packages
vcf package available list -n tkg-system

# Pg 197 — Change to Lab directory
cd Documents/Lab

# Pg 198-200 — Install Prometheus
kubectl create ns prometheus-installed
vcf package install prometheus \
  -p prometheus.kubernetes.vmware.com \
  --values-file prometheus-data-values.yaml \
  -n prometheus-installed \
  -v 3.5.0+vmware.1-vks.1

# Pg 201 — Verify Prometheus pods
kubectl get pods -n tanzu-system-monitoring

# Pg 202-203 — Install Telegraf
kubectl create ns telegraf-installed
vcf package install telegraf \
  -p telegraf.kubernetes.vmware.com \
  --values-file telegraf-data-values.yaml \
  -n telegraf-installed \
  -v 1.34.4+vmware.2-vks.1

# Pg 204 — Verify Telegraf pods
kubectl get pods -n tanzu-system-telegraf
```

### GUI: Edit opencart.yaml with IPs (Pg 211–213)

> Open `opencart.yaml` in VS Code

| Field | Replace with |
|-------|--------------|
| `OPENCART_DATABASE_HOST` | MySQL LB External IP (from Chapter 2) |
| `OPENCART_HOST` | OpenCart LB External IP (from step below) |
| `livenessProbe.httpHeaders` | OpenCart LB External IP |
| `readinessProbe.httpHeaders` | OpenCart LB External IP |

→ Save the file.

### CLI: Deploy OpenCart on vks-01 (Pg 205–222)

> [!WARNING]
> **CONTEXT: `vks-01`** — Must be in the vks-01 cluster CCI context.

```bash
# Pg 205-206 — Create and label namespace
kubectl create namespace opencart
kubectl label ns opencart pod-security.kubernetes.io/enforce=privileged

# Pg 208-209 — Deploy LB and get External IP
kubectl apply -f opencart-lb.yaml -n opencart
kubectl get service -n opencart -w
# → Wait for EXTERNAL-IP, then Ctrl+C
# → Use this IP to update opencart.yaml (see GUI step above)

# Pg 214-215 — Deploy app (after editing opencart.yaml with IPs)
kubectl apply -f opencart.yaml -n opencart
kubectl get all -n opencart
```

> ⚠️ **WAIT ~5 MINUTES** — OpenCart takes around 5 minutes to become Ready due to its readiness probes. `kubectl get all -n opencart` will show pods not yet Ready during this time — this is normal.

### GUI: VCFA — Scale vks-01 Nodepool (Pg 219–220)

> VCF Automation → Kubernetes → vks-01

| Step | Action |
|------|--------|
| 1 | Scroll to Nodepool → Edit |
| 2 | Replicas: **2** → Save |

```bash
# Pg 222 — Verify new node
kubectl get nodes
```

---

## Chapter 5 — vks-01 Cluster Automated with ArgoCD (Pg 229–292)

**Goal:** Create test namespace, deploy ArgoCD, set up GitOps workflow.

### GUI: VCFA — Create Test Namespace (Pg 232–234)

> VCF Automation → Manage & Govern → Projects → default-project → Namespaces → New Namespace

| Field | Value |
|-------|-------|
| Name | `test` |
| Namespace class | `medium` |
| Region | `us-west` |
| VPC | `us-west-Default-VPC` |
| Zone | ✓ `z-wld-a` |

→ Wait for **Active** status. Note the unique namespace name (e.g., `test-xxxxx`).

### CLI: Create Supervisor Context (Pg 235–236)

> [!WARNING]
> **CONTEXT: `vks-01`** — Still in the vks-01 cluster. `create` below does NOT auto-switch.

```bash
# Pg 235 — Create supervisor context (does NOT auto-switch!)
vcf context create supervisor \
  --endpoint 10.1.0.6 \
  --username administrator@wld.sso \
  --insecure-skip-tls-verify \
  --auth-type basic
# Password: VMware123!VMware123!

# Pg 236 — Switch to test namespace (interactive menu)
vcf context use
# → Select: supervisor:test-xxxxx
```

> [!WARNING]
> **CONTEXT: `supervisor:test-xxxxx`** — All commands below run against the test namespace on Supervisor.

### CLI: Deploy ArgoCD Instance (Pg 237–245)

```bash
# Pg 239-240 — Deploy ArgoCD
kubectl apply -f argocd-instance.yaml
kubectl get pod
# → Pods may be Pending...
```

### GUI: vCenter — Increase CPU Limit (Pg 241–242)

> vc-wld01-a → Menu → Supervisor Management → Namespaces → test-xxxxx

| Step | Action |
|------|--------|
| 1 | Summary tab → Capacity and Usage → Edit Limits |
| 2 | CPU: **25 GHz** → OK |

```bash
# Pg 243 — Verify pods now running
kubectl get pod

# Pg 244 — Get admin password
kubectl get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
# → Copy this password!

# Pg 245 — Get ArgoCD external IP
kubectl get service
# → Note the EXTERNAL-IP for argocd-server
```

### CLI: Log Into ArgoCD & Register Clusters (Pg 246–250)

```bash
# Pg 246 — Login to ArgoCD CLI
argocd login 10.1.11.x
# → Username: admin
# → Password: (from secret above)

# Pg 247 — Change password to VMware123!VMware123!
argocd account update-password

# Pg 249 — Register Supervisor as ArgoCD destination
argocd cluster add supervisor \
  --namespace test-xxxxx \
  --namespace dev-xxxxx \
  --kubeconfig ~/.kube/config
```

### GUI: Prepare YAMLs & Upload to Gitea (Pg 254–265)

#### Edit Downloaded YAMLs (Pg 254–257)

| Step | Action |
|------|--------|
| 1 | Extract `create-tkg-cluster-yaml-files.zip` |
| 2 | Extract `create-vm-yaml-files.zip` |
| 3 | Open each file (4 total), **remove the `namespace:` line**, save |

#### Upload to Gitea (Pg 258–261)

> http://10.1.10.130:3000 → Login: holuser / VMware123!VMware123! → argocd repo

| Step | Action |
|------|--------|
| 1 | Open `opencart-infra` folder |
| 2 | Add File → Upload File |
| 3 | Upload all 4 files (3 VM + 1 VKS) → Commit |
| 4 | Click `argocd` root → Code → Copy git URL: `http://10.1.10.130:3000/holuser/argocd.git` |

#### Create ArgoCD App in UI (Pg 262–265)

> ArgoCD UI (External IP from earlier) → Login: admin

| Step | Action |
|------|--------|
| 1 | Create Application |
| 2 | Name: `opencart-infra` |
| 3 | Project: `default` |
| 4 | Sync Policy: `Automatic` |
| 5 | Repository URL: `http://10.1.10.130:3000/holuser/argocd.git` |
| 6 | Path: `opencart-infra` |
| 7 | Cluster URL: `https://10.1.0.6:443` |
| 8 | Namespace: `test-xxxxx` → Create |

→ Wait for App Health: **Healthy**

> ⚠️ **WAIT ~10 MINUTES** — ArgoCD is deploying vks-01 in `test-xxxxx` via GitOps. The cluster takes at least 10 minutes to provision. Wait for `opencart-infra` App Health to show **Healthy** before proceeding.

### GUI: VCFA — Download vks-01 Kubeconfig (Pg 270)

> ⚠️ **IMPORTANT** — Download the kubeconfig from the **test-xxxxx** namespace (not dev-xxxxx). Both namespaces have a vks-01 cluster. You need the one ArgoCD just created in test.

> VCF Automation → Kubernetes (test-xxxxx) → vks-01 → ⋮ → Download kubeconfig file

### CLI: Register vks-01 in ArgoCD (Pg 271–273)

```bash
# Pg 271 — Find downloaded kubeconfig
cd ~/Downloads
ls | grep vks-01-kubeconfig.yaml

# Pg 272 — Get context name
kubectl --kubeconfig vks-01-kubeconfig.yaml config current-context

# Pg 273 — Register vks-01 with ArgoCD
argocd cluster add vks-01-admin@vks-01 vks-01 \
  --kubeconfig vks-01-kubeconfig.yaml
# → Note the cluster IP — needed for YAML verification below
```

### Deploy OpenCart via ArgoCD (Pg 274–289)

This section follows the exact lab page order — check LB yaml, create LB app, get IPs, edit opencart.yaml in Gitea, check app yaml, create app, verify.

#### Step 1: Verify argo-opencart-lb.yaml (Pg 274)

> Open `argo-opencart-lb.yaml` in VS Code (in `~/Documents/Lab`)

| Check | Action |
|-------|--------|
| Server IP | Must match vks-01 cluster IP from Pg 273 |
| If different | Update the IP and **Save** |

#### Step 2: Create opencart-lb App (Pg 275–277)

```bash
# Pg 275 — Go to Lab directory
cd ~/Documents/Lab

# Pg 276 — Create LB app
argocd app create opencart-lb --file argo-opencart-lb.yaml

# Pg 277 — Check status
argocd app get opencart-lb
```

#### Step 3: Get the Two IPs You Need (Pg 278–279)

```bash
# Pg 278 — Get DB VM External IP (MySQL LB)
kubectl get service
```

> [!WARNING]
> **CONTEXT: `supervisor:test-xxxxx`** — You must be in the test namespace for this command. If not, run `vcf context use` and select `supervisor:test-xxxxx`.

```bash
# Pg 279 — Get OpenCart LB External IP (from inside vks-01)
kubectl get service -n opencart --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml
```

→ You now have two IPs:
- **MySQL LB IP** — from `kubectl get service` (the oc-mysql load balancer in test-xxxxx)
- **OpenCart LB IP** — from `kubectl get service -n opencart --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml` (the opencart LB inside vks-01)

#### Step 4: Edit opencart.yaml in Gitea (Pg 280–282)

> Gitea → argocd repo → `opencart-app` folder → `opencart.yaml` → **Edit**

| # | Field to find | Replace with |
|---|---------------|--------------|
| 1 | `OPENCART_DATABASE_HOST` | **MySQL LB IP** (from Pg 278) |
| 2 | `OPENCART_HOST` | **OpenCart LB IP** (from Pg 279) |
| 3 | `livenessProbe` → `httpHeaders` value | **OpenCart LB IP** |
| 4 | `readinessProbe` → `httpHeaders` value | **OpenCart LB IP** |

> ⚠️ **WARNING** — All **4** IPs must be changed to correct values, otherwise the application will not work.

→ Scroll down → Add commit message → **Commit Changes**

#### Step 5: Verify argo-opencart-app.yaml (Pg 283)

> Open `argo-opencart-app.yaml` in VS Code (in `~/Documents/Lab`)

| Check | Action |
|-------|--------|
| Server IP | Must match vks-01 cluster IP from Pg 273 |
| If different | Update the IP and **Save** |

#### Step 6: Create opencart-app & Verify (Pg 284–289)

```bash
# Pg 284 — Create app (from ~/Documents/Lab)
argocd app create opencart-app --file argo-opencart-app.yaml

# Pg 285 — Check status
argocd app get opencart-app
```

**GUI verification (Pg 286–289):**

| Pg | Action |
|----|--------|
| 286 | Return to ArgoCD UI → Verify all **3** applications are **Healthy** |
| 287 | Click into `opencart-lb` |
| 288 | Click on `my-open-cart-lb` service → note the External IP |
| 289 | Browse to that IP → verify OpenCart application is available |

### GUI: GitOps Demo — Scale via Git (Pg 290–292)

> Gitea → argocd → opencart-infra → `vks-01.yaml` → Edit

| Change | Value |
|--------|-------|
| Worker node replicas | `2` |

→ Commit Changes

**Verify in ArgoCD (Pg 291–292):**

| Step | Action |
|------|--------|
| 1 | Return to ArgoCD UI → Click `opencart-infra` |
| 2 | App Health changes to **Progressing** (hit Refresh if needed) |
| 3 | Click **Details** → **Events** to see what triggered the sync |
| 4 | Wait for **Healthy** — new node visible in VCF Automation and vSphere under test namespace |

---

## Quick Reference

### Context Switching

| To get here... | Run... |
|----------------|--------|
| `vcfa:dev-xxxxx` | `vcf context use vcfa:dev-xxxxx:default-project` |
| `vks-01` | `vcf context use vks-01` |
| `supervisor:test-xxxxx` | `vcf context use supervisor:test-xxxxx` |
| ArgoCD CLI | `argocd login <IP>` |

### Critical "Don't Forget" Items

| Pg | Item |
|----|------|
| 39 | Namespace storage: **500 GB** (not MB!) |
| 152 | Download VM YAMLs |
| 180 | Download vks-01.yaml |
| 242 | Test namespace CPU: **25 GHz** |
| 254-257 | Remove `namespace:` lines from YAMLs |
| 211-213 | Edit `opencart.yaml` with correct IPs (manual deploy — VS Code) |
| 274, 283 | Verify Server IP in `argo-opencart-lb.yaml` and `argo-opencart-app.yaml` |
| 278 | Context must be `test-xxxxx` when getting DB VM IP |
| 280-282 | Edit `opencart.yaml` with correct IPs (ArgoCD deploy — Gitea) |

### Credentials

| System | Username | Password |
|--------|----------|----------|
| vCenter | administrator@wld.sso | VMware123!VMware123! |
| VCFA | broadcomadmin | VMware123!VMware123! |
| VCFA Provider | admin | VMware123!VMware123! |
| Harbor | admin | Harbor12345 |
| Gitea | holuser | VMware123!VMware123! |
| ArgoCD | admin | (from secret, then VMware123!VMware123!) |
| API Token | — | 0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3 |
