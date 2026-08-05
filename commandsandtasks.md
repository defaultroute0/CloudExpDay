# VCF 9.1 Field Demo Lab — Complete Instructor Reference

> **What this lab does:** Deploy the **Bookstore** application (Go frontend + PostgreSQL + Redis + MinIO + Elasticsearch, fronted by an Istio Gateway) on a VKS cluster — first manually with Helm in `prod-xxxxx`, then automated via Argo CD GitOps in `test-xxxxx`. Along the way: VM Service (cli-vm), Container Service (nginx + postgres), VKS 3.6.2 update, add-ons via VCF Automation, Day 2 ops in VCF Operations.

> ⚠️ **Status: generated from the Aug 2026 scrape of the 9.1 lab guide (265 pages), cross-checked against the guide's screenshots (PDF). Not yet lab-validated** — remaining *(verify in lab)* items are noted inline. Timing/wait notes are only the ones the 9.1 guide itself states.

---

## Table of Contents

- [Module 2: Enabling VCF Cloud Services](#module-2-enabling-vcf-cloud-services)
  - [Chapter 1 — Verify Supervisor](#chapter-1--verify-supervisor-pg-914)
  - [Chapter 2 — VM Service Setup + VCF CLI](#chapter-2--vm-service-setup--vcf-cli-pg-1847)
  - [Chapter 3 — Harbor, ArgoCD Service, LCI](#chapter-3--harbor-argocd-service-lci-pg-5162)
  - [Chapter 4 — VKS Update to 3.6.2](#chapter-4--vks-update-to-362-pg-6677)
- [Module 3: Consuming VCF Cloud Services](#module-3-consuming-vcf-cloud-services)
  - [Chapter 1 — Bookstore App Overview](#chapter-1--bookstore-app-overview-pg-82)
  - [Chapter 2 — Deploy cli-vm with VM Service](#chapter-2--deploy-cli-vm-with-vm-service-pg-86102)
  - [Chapter 3 — Container Service: nginx + postgres](#chapter-3--container-service-nginx--postgres-pg-105141)
  - [Chapter 4 — vks-01 Cluster + Bookstore via Helm](#chapter-4--vks-01-cluster--bookstore-via-helm-pg-144182)
  - [Chapter 5 — Day 2 Operations](#chapter-5--day-2-operations-pg-186200)
  - [Chapter 6 — Continuous Delivery with Argo CD](#chapter-6--continuous-delivery-with-argo-cd-pg-204264)
- [Quick Reference](#quick-reference)

---

## Contexts You'll Use

| Context | What it targets |
|---------|-----------------|
| `vcfa:dev-xxxxx` | Dev namespace via VCFA (CCI) |
| `vcfa:prod-xxxxx` | Prod namespace via VCFA (CCI) — vks-01 lives here |
| `vks-01` | The vks-01 guest cluster (CCI type) |
| `supervisor:test-xxxxx` | Test namespace on Supervisor (K8S/basic auth) |
| `terminal` | Plain shell / ssh to cli-vm (no VCF context needed) |
| `argocd` | Argo CD CLI session (`argocd login`) |
| `--kubeconfig vks-argo-kubeconfig.yaml` | vks-argo guest cluster, addressed directly by file — never a named context |

**9.1 environment constants:** Org `acme-east-a` · Region `us-east-a` · Zone `z-wld-a` · VPC `default-us-east-a` (Shared VPC) · Storage class `vsan-default-storage-policy` · Supervisor endpoint `10.1.8.132` · Git = **GitLab** (`https://gitlab.vcf.lab`) · API token pre-created in `~/Downloads/my-token.txt`

---

# Module 2: Enabling VCF Cloud Services

## Chapter 1 — Verify Supervisor (Pg 9–14)

**Goal:** Confirm Supervisor is running and HA. Read-only, no CLI.

> vc-wld01-a Client (Region A bookmark) → Login `administrator@wld.sso` / `VMware123!VMware123!` → Menu → Supervisor Management

| Step | Action |
|------|--------|
| 1 | Supervisors tab → scroll right → **Config Status** and **Host Config Status** = `Running` for `supervisor-wld-a` |
| 2 | Click `supervisor-wld-a` → Configure → General → expand Control Plane → confirm **3 CP VMs** (HA pre-enabled in lab) |

---

## Chapter 2 — VM Service Setup + VCF CLI (Pg 18–47)

**Goal:** Review storage policies, create VM Class, walk the Content Library wizard (cancel — pre-created), bump namespace class storage, create dev namespace, set up VCF CLI.

### GUI: vCenter — Storage Policies (Pg 18)

> Menu → Policies and Profiles → VM Storage Policies → `vSAN Default Storage Policy`

Note the **K8s Compliant Name**: `vsan-default-storage-policy` — this is the name used in all manifests.

### GUI: vCenter — Create VM Class (Pg 19–25)

> Menu → Supervisor Management → Services → VM Service: Manage → VM Classes tab

| Step | Action |
|------|--------|
| 1 | Create New VM Class |
| 2 | Name: `custom-small` |
| 3 | Defaults through Virtual Hardware / VM Options / Advanced → Next → Finish |

*(Demonstration only — this class is not used later.)*

### GUI: VCFA — Content Library Walkthrough (Pg 26–32)

> Region A → VCF Automation → login `acme-east-a` → Build & Deploy → Content Libraries → New

| Step | Action |
|------|--------|
| 1 | Name `vm-images`, Organization Content Library, keep "Assign to all current and future namespaces", **Subscribe to a library** → Next |
| 2 | Canonical → Next |
| 3 | Region `us-east-a`, Storage Class `vSAN Default Storage Policy` → Next |
| 4 | **Cancel** — the library already exists in the lab (walkthrough only!) |

### GUI: VCFA — Namespace Class Storage (Pg 33–34)

> Manage & Govern → Namespace Class → Medium → VM & Storage Class tab

| Step | Action |
|------|--------|
| 1 | Select `vsan-default-storage-policy` → Edit |
| 2 | Limit **400 GB** — **change MB to GB!** |
| 3 | Save → Save |

### GUI: VCFA — Project Users + Dev Namespace (Pg 35–40)

> Manage & Govern → Projects → default-project

| Step | Action |
|------|--------|
| 1 | Users → + ADD USERS → type `acme-east-a`, roles **Project Administrator** + **Project Advanced User** → **Cancel** (already assigned in lab — walkthrough only) |
| 2 | Namespaces → New Namespace |
| 3 | Name `dev`, Project `default-project`, Namespace class **`small-reserved`**, Region `us-east-a`, Zone `z-wld-a`, Networking **Shared VPC**, VPC `default-us-east-a` → Create |
| 4 | Wait for **Active** (refresh page). **Note the unique name `dev-xxxxx`** |

### GUI: VCFA — API Token (Pg 41–42)

> User menu → My Account → API Tokens

Token is **pre-created** and saved at `~/Downloads/my-token.txt`. Do NOT delete it — it cannot be re-displayed. (Pod-example value: `1FasL1HLOqRefVuEepZFqEkYrT28ZGus` — always use the one from the file.)

### CLI: Set Up VCF CLI (Pg 43–47)

```bash
# Pg 44 — Create the vcfa context (token from ~/Downloads/my-token.txt)
vcf context create vcfa \
  --endpoint auto-a.site-a.vcf.lab \
  --api-token <token from ~/Downloads/my-token.txt> \
  --tenant-name acme-east-a \
  --ca-certificate vcfa-cert-chain.pem

# Pg 45 — Switch to dev namespace (interactive menu)
vcf context use
# → Select: vcfa:dev-xxxxx:default-project
```

> [!WARNING]
> **CONTEXT: `vcfa:dev-xxxxx`** — Commands below run against the dev namespace via VCFA.

```bash
# Pg 46 — No VMs yet
kubectl get vm

# Pg 47 — Verify image from Content Library is visible
kubectl get vmi
# → expect noble-server-cloudimg-amd64
```

---

## Chapter 3 — Harbor, ArgoCD Service, LCI (Pg 51–62)

**Goal:** Verify regional Harbor, register the Argo CD Supervisor Service, verify the Local Consumption Interface (LCI — enabled by default in 9.1, no install needed).

### GUI: VCFA Provider — Verify Harbor (Pg 51–55)

> Region A → VCF Automation - Provider → login `admin` (organization = system) → Service Management → Harbor → Details

| Step | Action |
|------|--------|
| 1 | Status = **Healthy** |
| 2 | Open Region A → Harbor bookmark → login `admin` / `Harbor123!` → leave tab open |

### GUI: vCenter — Add ArgoCD Service (Pg 56–61)

> Menu → Supervisor Management → Services → Add

| Step | Action |
|------|--------|
| 1 | Upload → **`supervisor-service-argocd-legacy-1.1.0-25100889.yml`** from Downloads → Finish |
| 2 | ArgoCD tile → Actions → Manage Service |
| 3 | Select `supervisor-wld-a` → Next → (compat validation) Next → Finish |
| 4 | Wait for **Configured** — check Supervisors → Overview under Supervisor Services |

> 💡 9.1 ships TWO Supervisor Service YAML flavours; the lab uses the **legacy** flavour (pulls from `projects.packages.broadcom.com`). The standard flavour pulls from the new on-prem Software Depot.

### GUI: vCenter — Verify LCI (Pg 62)

> Menu → Supervisor Management → Namespaces tab → `dev-xxxxx` → Resources tab

LCI is **enabled by default in VCF 9.1**. If Resources tab doesn't load, refresh the browser.

---

## Chapter 4 — VKS Update to 3.6.2 (Pg 66–77)

**Goal:** Upload and install VKS 3.6.2 on the Supervisor.

### GUI: vCenter — Upload & Install VKS Package (Pg 69–74)

> Menu → Supervisor Management → Services → Kubernetes Service

| Step | Action |
|------|--------|
| 1 | Actions → Add New Version |
| 2 | Upload → `/home/holuser/Downloads/3.6.2-package.yaml` → Finish |
| 3 | Wait for Active versions: **2** |
| 4 | Actions → Manage Service |
| 5 | Install version **`3.6.2+v1.35`**, select `supervisor-wld-a` → Next → Next → Finish |
| 6 | Actions → Manage Service → wait for Service Status **Configured** (guide: ~2–3 min; may transiently show **Error** — normal, config is still ongoing; close/reopen the window or refresh browser to see the updated status) |

### GUI: Verify (Pg 75–77)

| Step | Action |
|------|--------|
| 1 | Namespaces → `dev-xxxxx` → Resources → Kubernetes tile → Create Cluster → Next → confirm latest release is **v1.35.x** → **Cancel** (do NOT deploy here) |
| 2 | Menu → Content Libraries → **Kubernetes Service Content Library** → view distributed VKrs (auto-subscribed library; images pull on first use) |

---

# Module 3: Consuming VCF Cloud Services

## Chapter 1 — Bookstore App Overview (Pg 82)

No actions. Architecture: Go web frontend + PostgreSQL + Redis + MinIO (+ optional Elasticsearch for search), images from regional Harbor, ingress via **Istio Gateway** (Network Service LB), stateful services on Volume Service PVs. Deployed first with **Helm**, then with **Argo CD**.

---

## Chapter 2 — Deploy cli-vm with VM Service (Pg 86–102)

**Goal:** As a consumer, deploy the `cli-vm` Ubuntu VM (docker + kubectl via cloud-init) with an SSH load balancer.

### GUI: VCFA — Create cli-vm (Pg 86–100)

> Region A → VCF Automation → login `acme-east-a` → Services tile: namespace `dev-xxxxx` → Virtual Machine → Create VM

| Step | Action |
|------|--------|
| 1 | Deploy from OVF → Next |
| 2 | Name: `cli-vm`, Zone: `z-wld-a` |
| 3 | Image: `ubuntu-24.04-noble-server-cloudimg-amd64` |
| 4 | VM Class: `best-effort-small`, Storage Class as-is, Power State: Powered On → Next |
| 5 | Load Balancer → Add → New: Name `ssh`, Port `22`, Target `22` → Add → Save |
| 6 | Guest Customization → Cloud-init → **Raw Configuration** |
| 7 | Open `~/Downloads/cli-vm-cloudinit-config.yaml` → Ctrl+A, Ctrl+C → paste (Ctrl+V) → Next. (Mac: Intercept Paste OFF; Windows: Intercept Paste + Remap cmd OFF) |
| 8 | Global Network Settings: Host Name `cli-vm`, Domain `vcf.lab`, Nameservers `8.8.8.8` → **Add** → Next (ignore the 192.0.2.1 example row) |
| **9** | **⚠️ DOWNLOAD the YAML manifests** (down-arrow) and confirm downloaded |
| 10 | Deploy VM (takes a few minutes) |
| 11 | Network Service → Services → note the **External IP** of the new LB |

### CLI: Verify cli-vm (Pg 102)

> [!WARNING]
> **CONTEXT: `terminal`** — plain shell, no VCF context needed.

```bash
# Pg 102 — ssh in (devops / DevOps123, set by cloud-init)
ssh devops@<cli-vm-LB-external-IP>
docker --version
exit
```

> ⚠️ Guide: cloud-init can take up to **5 minutes** — docker may not be installed yet if you ssh in too early.

---

## Chapter 3 — Container Service: nginx + postgres (Pg 105–141)

**Goal:** Push nginx to Harbor, deploy it via the new **Container Service** (vSphere Pods under the hood), then deploy a postgres StatefulSet with a persistent volume.

### CLI: Push nginx to Harbor (Pg 106)

> [!WARNING]
> **CONTEXT: `terminal`** — runs on the **console VM directly** (`holuser@console`, confirmed by the guide's screenshot) — docker is on the console with the ghcr.io image pre-pulled. No ssh to cli-vm needed.

```bash
# Pg 106
docker tag ghcr.io/tmm-demo-apps/nginx:latest harbor-01a.vcf.lab/library/nginx:latest
docker push harbor-01a.vcf.lab/library/nginx:latest
# (docker login harbor-01a.vcf.lab as admin/Harbor123! if prompted)
```

### GUI: Harbor — Verify Image (Pg 107–110)

> Region A → Harbor → login `admin` / `Harbor123!` → `library` project → confirm `nginx` present

### GUI: VCFA — Deploy nginx Container (Pg 111–124)

> VCF Automation (acme-east-a) → Build & Deploy → namespace `dev-xxxxx` → Container → Create New Instance

| Step | Action |
|------|--------|
| 1 | Name: `nginx`, Primary Container Image: `harbor-01a.vcf.lab/library/nginx:latest` |
| 2 | CPU/Memory/Replicas: defaults → Next |
| 3 | Load Balancer dropdown → Attach Load Balancer: Name `nginx-lb`, Port Name `http-80`, TCP, Port `80`, Target `80`, ✓ Attach to Primary Container → Add → Save → Next |
| 4 | Review auto-generated YAML → **Save/download the YAML** → Create Container Instance |
| 5 | Wait for **Ready** → click `nginx` → note LB **External IP** |
| 6 | Browse `http://<nginx-LB-IP>` → nginx page |

### GUI: VCFA — Deploy postgres StatefulSet (Pg 125–139)

> Same place → Create New Instance

| Step | Action |
|------|--------|
| 1 | Name: `postgres`, Image: `harbor-01a.vcf.lab/library/postgres:14-alpine` |
| 2 | CPU `1000` millicores, Memory `512 MB`, Replicas `2` → Next |
| 3 | Persistent Volume → Attach Volume: Name `storage`, Storage Class `vsan-default-storage-policy`, Capacity `5 GB`, ✓ Mount to Primary Container, Mount path `/var/lib/postgresql/data`, Sub Path `pgdata` → Save |
| 4 | Runtime Configuration → env vars: `POSTGRES_DB=my_database`, `POSTGRES_USER=db_admin`, `POSTGRES_PASSWORD=VMware123!VMware123!`, `PGDATA=/var/lib/postgresql/data/pgdata` |
| 5 | Load Balancer → Attach: Name `postgres-lb`, Port Name `tcp-5432`, TCP, Port `5432`, Target `5432`, ✓ Attach to Primary Container → Add → Save → Next |
| 6 | **Download the YAML** → Create Container Instance |
| 7 | Wait for **Ready** (guide: up to 5 min) → click `postgres` → 2 pods running → note LB **External IP** |

### CLI: Verify postgres (Pg 140)

```bash
# Pg 140 — password: VMware123!VMware123!
psql -h <postgres-LB-external-IP> -p 5432 -U db_admin -d my_database
exit
```

---

## Chapter 4 — vks-01 Cluster + Bookstore via Helm (Pg 144–182)

**Goal:** Create vks-01 in the **prod** namespace via the LCI, configure CLI, install cert-manager + Istio add-ons via VCFA, deploy Bookstore with Helm.

### GUI: vCenter LCI — Create vks-01 (Pg 144–156)

> vc-wld01-a → Menu → Supervisor Management → Namespaces → **prod-xxxxx** → Resources tab → Kubernetes tile: Go To Service → Create

| Step | Action |
|------|--------|
| 1 | Custom Configuration → Next |
| 2 | Name: `vks-01`; **latest Kubernetes release auto-selected** (v1.35.x); VM Class `best-effort-medium` |
| 3 | Storage: Default Storage Class `vsan-default-storage-policy` → Next |
| 4 | OS Image: **Ubuntu 24.04** → Next |
| 5 | Nodepool → ⋮ edit → ✓ **Use Cluster Autoscaler**, Min `2`, Max `3`, OS Image **Ubuntu 24.04** → Next → Finish |
| 6 | Next → review full YAML |
| **7** | **⚠️ DOWNLOAD the manifest — CRITICAL**, needed for the Argo CD chapter |
| 8 | Finish → wait for **Available** (guide: ~5 min; Ready = CP up, workers may still be configuring — worker must be up before app deploy) |

### CLI: Configure CLI for vks-01 (Pg 157–167)

> [!WARNING]
> **CONTEXT: `vcfa:prod-xxxxx`** — vks-01 lives in **prod**, not dev.

```bash
# Pg 157 — List contexts
vcf context list

# Pg 158 — Switch to prod namespace (token: ~/Downloads/my-token.txt if prompted)
vcf context use vcfa:prod-xxxxx:default-project

# Pg 159 — Only proceed when CP shows 1/1
vcf cluster list

# Pg 160 — Register JWT authenticator (Pinniped/SSO login for the cluster)
vcf cluster register-vcfa-jwt-authenticator vks-01

# Pg 161 — Export kubeconfig
vcf cluster kubeconfig get vks-01 --export-file ~/.kube/config

# Pg 162 — Find the exact context name
cat ~/.kube/config | grep vks-01

# Pg 163 — Create context (does NOT auto-switch!) — type: cloud-consumption-interface
vcf context create vks-01 \
  --kubeconfig ~/.kube/config \
  --kubecontext vcf-cli-vks-01-prod-xxxxx@vks-01-prod-xxxxx
# API token again from ~/Downloads/my-token.txt

# Pg 164-165 — Refresh and list
vcf context refresh
vcf context list

# Pg 166 — NOW switch to vks-01
vcf context use vks-01
# ("failed to discover plugin sources" log is safe to ignore)
```

> [!WARNING]
> **CONTEXT: `vks-01`** — All commands below run against the vks-01 guest cluster.

```bash
# Pg 167 — Only proceed when all nodes Ready
kubectl get nodes
```

### GUI: VCFA — Install Add-ons (Pg 168–175)

> VCF Automation (acme-east-a) → Manage & Govern → Kubernetes Management → `vks-01` → **Add-ons** tab → Available Add-ons

| Step | Action |
|------|--------|
| 1 | **cert-manager** card → Install Add-on → latest compatible version → Install Add-on → wait for complete |
| 2 | **Istio** card → Install Add-on → Package name `vks-01-istio`, latest compatible version → Install Add-on → wait for complete |

> 💡 This is the new **VKS Add-ons** flow (replaces `vcf package repository add` + `vcf package install` from the 9.0 lab).

### CLI: Deploy Bookstore with Helm (Pg 176–180)

```bash
# Pg 176
cd ~/Desktop/bookstore-app/

# Pg 177 — Namespace + Helm ownership labels
kubectl create namespace bookstore
kubectl label namespace bookstore app.kubernetes.io/managed-by=Helm
kubectl annotate namespace bookstore meta.helm.sh/release-name=demo
kubectl annotate namespace bookstore meta.helm.sh/release-namespace=bookstore

# Pg 178 — Harbor pull secret
kubectl create secret docker-registry harbor-registry-secret \
  --docker-server=harbor-01a.vcf.lab \
  --docker-username=admin \
  --docker-password=Harbor123! \
  -n bookstore

# Pg 179 — Deploy
helm install demo ./helm/demo-suite -f ./helm/demo-suite/values-lab.yaml -n bookstore

# Pg 180 — Verify; note the istio gateway EXTERNAL-IP for the DNS step
kubectl get all -n bookstore
```

### GUI: DNS Record + Verify (Pg 181–182)

> Firefox → HOL Admin bookmarks → **Technitium DNS Server** → login `admin` / `VMware123!VMware123!`

| Step | Action |
|------|--------|
| 1 | Edit/Add record: Name `bookstore`, IPv4 = istio gateway External IP from Pg 180 |
| 2 | Browse `https://bookstore.vcf.lab` → Advanced → Proceed (self-signed) → app up |

---

## Chapter 5 — Day 2 Operations (Pg 186–200)

**Goal:** Manually scale the pre-existing `vks-prod` cluster, review monitoring in VCFA and VCF Operations. GUI only.

### GUI: VCFA — Scale vks-prod (Pg 186–192)

> VCF Automation (acme-east-a) → Build & Deploy → namespace `prod-xxxxx` → Kubernetes → **vks-prod**

| Step | Action |
|------|--------|
| 1 | Node pools → expand → Edit → Replicas **2** → Save (guide: ~3 min) |
| 2 | Build & Deploy → Kubernetes → `vks-01` → **Monitor** tab → review charts |

### GUI: VCF Operations (Pg 193–200)

> Region A → VMware Cloud Foundation Operations → Local Account `admin` / `VMware123!VMware123!`

| Step | Action |
|------|--------|
| 1 | Search `supervisor` → `supervisor-wld-a` (vSphere Supervisor) → Topology tab → Metrics tab: add CPU Usage (Cores) + Memory Usage (GB) |
| 2 | Search `vks-01` → (VKS Cluster) → Topology tab → Metrics tab: same two charts |

---

## Chapter 6 — Continuous Delivery with Argo CD (Pg 204–264)

**Goal:** Create test namespace, deploy an Argo CD instance, GitOps-deploy the infra (vks-argo cluster + add-ons) and the Bookstore app from GitLab, then demo auto-sync by enabling Elasticsearch.

### GUI: VCFA — Create Test Namespace (Pg 204–208)

> VCF Automation (acme-east-a) → Manage & Govern → Projects → default-project → Namespaces → New Namespace

| Field | Value |
|-------|-------|
| Name | `test` |
| Namespace class | `medium` |
| Region | `us-east-a` |
| Zone | `z-wld-a` |
| Networking | Shared VPC, VPC `default-us-east-a` |

→ Wait for **Active**. Note the unique name `test-xxxxx`.

### CLI: Supervisor Context + Argo CD Instance (Pg 209–217)

> [!WARNING]
> `vcf context create` does NOT auto-switch — you stay in your current context until `vcf context use`.

```bash
# Pg 209 — Create supervisor context (password: VMware123!VMware123!)
vcf context create supervisor \
  --endpoint 10.1.8.132 \
  --username administrator@wld.sso \
  --insecure-skip-tls-verify \
  --auth-type basic

# Pg 210 — Switch (interactive) → select supervisor:test-xxxxx
vcf context use
```

> [!WARNING]
> **CONTEXT: `supervisor:test-xxxxx`** — All commands below run against the test namespace on Supervisor.

```bash
# Pg 211 — Check available Argo CD version
kubectl explain argocd.spec.version

# Pg 212 — Create instance manifest (edit test-xxxxx!)
nano ~/Downloads/argocd-instance.yaml
```

```yaml
apiVersion: argocd-service.vsphere.vmware.com/v1alpha1
kind: ArgoCD
metadata:
  name: argocd-instance-01
  namespace: test-xxxxx
spec:
  version: 3.0.19+vmware.1-vks.1
```

```bash
# Pg 213 — Deploy
kubectl apply -f ~/Downloads/argocd-instance.yaml

# Pg 214 — Watch until Running/Completed + 1/1 (guide: ~1 min), Ctrl+C to exit
watch kubectl get pods

# Pg 216 — Initial admin password — copy it!
kubectl get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Pg 217 — External IP of argocd-server
kubectl get service
```

> 💡 Unlike the 9.0 lab, the 9.1 guide has **no CPU-limit bump** on the test namespace — pods are expected to schedule directly. *(verify in lab: if Argo CD pods stay Pending, check namespace CPU limits in vCenter as per the old lab)*

### CLI: Argo CD Login + Register Supervisor (Pg 218–221)

```bash
# Pg 218 — Login (admin / password from secret; y to accept cert)
argocd login 10.1.x.x

# Pg 219 — Change password to VMware123!VMware123!
argocd account update-password

# Pg 220 — Confirm your namespace names
vcf context list

# Pg 221 — Register Supervisor as destination (test namespace only; y to create SA)
argocd cluster add supervisor --namespace test-xxxxx --kubeconfig ~/.kube/config
```

### GUI: Verify in Argo CD UI (Pg 222–223)

> `https://<argocd-external-IP>` → login `admin` / `VMware123!VMware123!` → Settings → Clusters → `supervisor` shows test namespace

### GUI: Prepare YAMLs & Upload to GitLab (Pg 224–236)

> HOL Admin bookmarks → **Gitlab** → login `root` / `VMware123!VMware123!` → Projects → `argocd` repo, `bookstore-infra` folder

| Step | Action |
|------|--------|
| 1 | Files app: extract `create-tkg-cluster-yaml-files` zip (downloaded in Ch. 4) |
| 2 | Open `vks-01.yaml` in Mousepad (or VS Code) |
| 3 | Search → Find and Replace: Search for `vks-01`, Replace with `vks-argo`, ✓ Replace all in Document (**2 matches**) → Replace All (confirmed by guide screenshot) |
| 4 | **Remove the `namespace: prod-xxxxx` line** (line 5, under `metadata:`) |
| 5 | Replace vmClass `best-effort-medium` → **`best-effort-large`** |
| 6 | File → Save As → **`vks-argo.yaml`** |

> 💡 Sanity-check values in the downloaded YAML (from the guide's screenshots): `apiVersion: cluster.x-k8s.io/v1beta2`, topology classRef `builtin-generic-v3.6.0` (namespace `vmware-system-vks-public`), `version: v1.35.5---vmware.1-vkr.1`, storageClass `vsan-default-storage-policy`. If ArgoCD later sticks out-of-sync on the cluster, compare these fields first (the 9.0 lab's equivalent failure mode was a stale class/version here).
| 7 | GitLab → `bookstore-infra` → + → Upload File → `vks-argo.yaml` → commit to main |
| 8 | Edit `Desktop/bookstore-infra/addoninstall-cert-manager.yaml`: replace `<SUPERVISOR_NAMESPACE>` with `test-xxxxx` → Save |
| 9 | Edit `Desktop/bookstore-infra/addoninstall-istio.yaml`: replace `<SUPERVISOR_NAMESPACE>` with `test-xxxxx` → Save |
| 10 | Upload both addon YAMLs to `bookstore-infra` in GitLab → commit |
| 11 | Repo root → Code → copy HTTPS URL: `https://gitlab.vcf.lab/root/argocd.git` |

### CLI + GUI: bookstore-infra App (Pg 237–244)

```bash
# Pg 237 — Add repo to Argo CD
argocd repo add https://gitlab.vcf.lab/root/argocd.git \
  --name bookstore-infra --project default --upsert --insecure-skip-server-verification
```

> Argo CD UI → Settings → Repositories: verify → Applications → Create Application

| Field | Value |
|-------|-------|
| Application Name | `bookstore-infra` |
| Project | `default` |
| Sync Policy | `Automatic` |
| Repository URL | `https://gitlab.vcf.lab/root/argocd.git` |
| Path | `bookstore-infra` |
| Cluster URL | `https://10.1.8.132:443` (Supervisor) |
| Namespace | `test-xxxxx` |

→ Create → click the tile → wait for **Healthy**.

> ⚠️ **WAIT ~10 MINUTES** (per guide) — this replays chapter 4 via GitOps: full VKS cluster (`vks-argo`) + cert-manager + Istio add-ons. Use Refresh to check sync status.

### CLI: Register vks-argo in Argo CD (Pg 245–249)

> VCF Automation → Build & Deploy → namespace **test-xxxxx** → Kubernetes → ⋮ next to cluster → **Download kubeconfig file**

```bash
# Pg 247
cd ~/Downloads
ls | grep vks-argo-kubeconfig.yaml

# Pg 248 — Get context name
kubectl --kubeconfig vks-argo-kubeconfig.yaml config current-context

# Pg 249 — Register with Argo CD (y to create SA) — NOTE THE CLUSTER IP in the output!
argocd cluster add vks-argo-admin@vks-argo vks-argo --kubeconfig vks-argo-kubeconfig.yaml
```

### CLI: Deploy Bookstore App via Argo CD (Pg 251–254)

```bash
# Pg 251 — Add app repo
argocd repo add https://gitlab.vcf.lab/root/bookstore-app.git \
  --name bookstore-app --project default --upsert --insecure-skip-server-verification

# Pg 252 — Create app — replace 10.1.9.10 with YOUR vks-argo cluster IP from Pg 249
argocd app create bookstore-lab \
  --repo https://gitlab.vcf.lab/root/bookstore-app.git \
  --path kubernetes/overlays/lab \
  --dest-server https://10.1.9.10:6443 \
  --dest-namespace bookstore \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Pg 253 — Status
argocd app get bookstore-lab
```

> [!WARNING]
> **CONTEXT: `supervisor:test-xxxxx`** for the next command (run `vcf context use` if unsure) — the kubeconfig flag targets vks-argo directly.

```bash
# Pg 254 — Wait Healthy, then note demo-gateway-istio EXTERNAL-IP
kubectl get service -n bookstore --kubeconfig=vks-argo-kubeconfig.yaml
```

### GUI: DNS + Verify + GitOps Demo (Pg 255–264)

| Pg | Action |
|----|--------|
| 255 | Technitium → Zones → `vcf.lab` → Add Record: Name `bookstore-test`, IPv4 = gateway IP → Save |
| 256 | Browse `https://bookstore-test.vcf.lab` → accept risk → app up |
| 257 | Search Products → `shakespere` → **no results** (Elasticsearch off) |
| 258–259 | GitLab → `bookstore-app/kubernetes/overlays/lab/configmap-patch.yaml` → Edit single file → **uncomment line 11 (`ES_URL: "http://..."`)**, match indentation → Commit |
| 260–261 | Same folder → `kustomization.yaml` → Edit: **delete/comment the two patch sections (rows 48–59)**, **uncomment `- path: elasticsearch-patch.yaml` (row 61)**, match indentation → Commit |
| 262–263 | Argo CD UI → `bookstore-lab` → Health **Progressing** (Refresh if needed) → Details → Events shows the sync trigger |
| 264 | Back to app → search `shakespere` again → **results returned** |

---

## Quick Reference

### Context Switching

| To get here... | Run... |
|----------------|--------|
| `vcfa:dev-xxxxx` | `vcf context use vcfa:dev-xxxxx:default-project` |
| `vcfa:prod-xxxxx` | `vcf context use vcfa:prod-xxxxx:default-project` |
| `vks-01` | `vcf context use vks-01` |
| `supervisor:test-xxxxx` | `vcf context use` → select `supervisor:test-xxxxx` |
| Argo CD CLI | `argocd login <argocd-external-IP>` |
| vks-argo | no context — always `--kubeconfig ~/Downloads/vks-argo-kubeconfig.yaml` |

### Critical "Don't Forget" Items

| Pg | Item |
|----|------|
| 34 | Namespace class storage: **400 GB — GB not MB!** |
| 42 | Don't delete the API token — value only in `~/Downloads/my-token.txt` |
| 99 | Download cli-vm YAMLs |
| 155 | **Download vks-01 cluster YAML — needed for Argo CD chapter** |
| 158 | vks-01 lives in **prod-xxxxx**, not dev |
| 229–230 | vks-argo.yaml: remove `namespace:` line, vmClass → `best-effort-large`, rename → vks-argo |
| 232–233 | addoninstall YAMLs: `<SUPERVISOR_NAMESPACE>` → `test-xxxxx` |
| 249 | Note vks-argo cluster IP from `argocd cluster add` output |
| 252 | Replace `10.1.9.10` with your vks-argo IP |
| 254 | Context must be `supervisor:test-xxxxx` when getting the gateway IP |
| 258–261 | Elasticsearch enable: 2 GitLab edits (configmap-patch.yaml + kustomization.yaml) |

### Credentials

| System | Username | Password |
|--------|----------|----------|
| vCenter (vc-wld01-a) | administrator@wld.sso | VMware123!VMware123! |
| VCFA org | acme-east-a | VMware123!VMware123! |
| VCFA Provider | admin | VMware123!VMware123! |
| Harbor | admin | **Harbor123!** |
| GitLab | root | VMware123!VMware123! |
| VCF Operations | admin (Local Account) | VMware123!VMware123! |
| Technitium DNS | admin | VMware123!VMware123! |
| Argo CD | admin | (from secret, then VMware123!VMware123!) |
| cli-vm (ssh) | devops | DevOps123 |
| postgres | db_admin | VMware123!VMware123! |
| API Token | — | `cat ~/Downloads/my-token.txt` |

### 9.0 → 9.1 Lab Differences (for instructors who taught the old lab)

| Area | 9.0 lab | 9.1 lab |
|------|---------|---------|
| Org / login | broadcom / broadcomadmin | **acme-east-a** |
| Region / VPC | us-west / us-west-Default-VPC | **us-east-a / default-us-east-a (Shared VPC)** |
| Storage class | cluster-wld01-01a-storage-policy | **vsan-default-storage-policy** |
| App | OpenCart (MySQL VM + container) | **Bookstore** (Helm, Istio, Postgres/Redis/MinIO/Elasticsearch) |
| Utility VM | oc-mysql (DB) | **cli-vm** (docker/kubectl toolbox) |
| Container deploy | — | **new Container Service chapter (nginx + postgres via VCFA UI)** |
| VKS update | 3.6.0 (`3.6.0+v1.35`) | **3.6.2 (`3.6.2+v1.35`)** |
| Cluster creation | VCFA UI, dev namespace | **vCenter LCI, prod namespace**, Ubuntu 24.04, autoscaler 2–3 |
| Packages | vcf package repository/install (Prometheus, Telegraf) | **VCFA Add-ons tab (cert-manager, Istio)** |
| LCI | installed as a service | **enabled by default** |
| ArgoCD service YAML | 1.0.1-24896502.yml | **supervisor-service-argocd-legacy-1.1.0-25100889.yml** (legacy flavour) |
| ArgoCD instance | (unversioned in guide) | **spec.version 3.0.19+vmware.1-vks.1** |
| Git server | Gitea (10.1.10.130:3000, holuser) | **GitLab (gitlab.vcf.lab, root)** |
| Supervisor endpoint | 10.1.0.6 | **10.1.8.132** |
| GitOps cluster | vks-01 (test ns) | **vks-argo** (test ns) |
| GitOps demo change | scale worker replicas | **enable Elasticsearch via kustomize patches** |
| Day 2 / monitoring | — | **new chapter: scale vks-prod + VCF Operations** |
| Harbor password | Harbor12345 | **Harbor123!** |

### 9.0 Warnings That Do NOT Carry Over (removed deliberately)

- **No "skip the VKS install" trap** — 9.1 guide installs 3.6.2 and the cluster wizard auto-selects the latest release; the 9.0 issue of a missing 1.35 OS image in the content library has not been observed on 9.1 yet *(re-check on first lab run)*.
- **No test-namespace CPU limit bump (25 GHz)** — not in the 9.1 guide.
- **No 10-minute vks-01 wait** — 9.1 guide says ~5 min with autoscaler; workers may trail the CP.
- **No opencart.yaml IP editing** — Bookstore uses Istio gateway + DNS records instead of baked-in IPs.
