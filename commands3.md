# VCF Field Demo Lab — CLI Quick Reference

> **What this lab does:** Deploy OpenCart (MySQL VM + containerized frontend) twice — first manually in `dev-xxxxx`, then automated via ArgoCD in `test-xxxxx`.

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

## Module 2, Chapter 2 — Set Up VCF CLI (Pg 48–51)

**Goal:** Create the initial VCF CLI context and connect to dev namespace.

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

**Now in: `vcfa:dev-xxxxx`**

```bash
# Pg 50-51 — Verify VMs
kubectl get vm
kubectl get vmi
```

---

## Module 4, Chapter 3 — Push Image to Harbor (Pg 160–164)

**Goal:** Tag and push the OpenCart container image to Harbor.

**Context:** `terminal` (no VCF context needed)

```bash
# Pg 160 — Login to Harbor
docker login harbor-01a.site-a.vcf.lab

# Pg 161 — Check local images
docker image ls

# Pg 162 — Tag for Harbor
docker tag \
  vcf-automation-docker-dev-local.usw5.packages.broadcom.com/bitnami/opencart:4.0.1-1-debian-11-r66 \
  harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66

# Pg 163 — Push to Harbor
docker push harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66

# Pg 164 — Verify
docker image ls
```

---

## Module 4, Chapter 4 — Configure CLI for vks-01 (Pg 184–193)

**Goal:** Register vks-01 cluster with VCF CLI and create a context for it.

**Context:** `vcfa:dev-xxxxx`

```bash
# Pg 184-185 — Confirm context
vcf context list
vcf context use vcfa:dev-xxxxx:default-project
# (or interactive: vcf context use → select vcfa:dev-xxxxx:default-project)
# Token if prompted: 0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3

# Pg 185 — (Optional) Verify kubectl context
kubectl config get-contexts

# Pg 186-188 — Register vks-01 and get kubeconfig
vcf cluster list
vcf cluster register-vcfa-jwt-authenticator vks-01
vcf cluster kubeconfig get vks-01 --export-file ~/.kube/config

# Pg 189 — Verify kubeconfig has vks-01
cat ~/.kube/config | grep vks-01
```

### Create vks-01 Context (Pg 190–193)

```bash
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

**Now in: `vks-01`**

---

## Module 4, Chapter 4 — Deploy OpenCart on vks-01 (Pg 194–222)

**Goal:** Install Prometheus + Telegraf packages, then deploy OpenCart.

**Context:** `vks-01`

### Add Package Repository (Pg 194–197)

```bash
# Pg 194 — Verify nodes
kubectl get node

# Pg 195 — Add package repo
vcf package repository add default-repo \
  --url projects.packages.broadcom.com/vsphere/supervisor/packages/2025.8.19/vks-standard-packages:v2025.8.19 \
  -n tkg-system

# Pg 196 — List available packages
vcf package available list -n tkg-system

# Pg 197 — Change to Lab directory
cd Documents/Lab
```

### Install Prometheus (Pg 198–201)

```bash
# Pg 198 — Create namespace
kubectl create ns prometheus-installed

# Pg 199 — Check storage class
cat prometheus-data-values.yaml | grep storage
kubectl get sc

# Pg 200 — Install Prometheus
vcf package install prometheus \
  -p prometheus.kubernetes.vmware.com \
  --values-file prometheus-data-values.yaml \
  -n prometheus-installed \
  -v 3.5.0+vmware.1-vks.1

# Pg 201 — Verify pods
kubectl get pods -n tanzu-system-monitoring
```

### Install Telegraf (Pg 202–204)

```bash
# Pg 202 — Create namespace
kubectl create ns telegraf-installed

# Pg 203 — Install Telegraf
vcf package install telegraf \
  -p telegraf.kubernetes.vmware.com \
  --values-file telegraf-data-values.yaml \
  -n telegraf-installed \
  -v 1.34.4+vmware.2-vks.1

# Pg 204 — Verify pods
kubectl get pods -n tanzu-system-telegraf
```

### Deploy OpenCart App (Pg 205–222)

```bash
# Pg 205-206 — Create and label namespace
kubectl create namespace opencart
kubectl label ns opencart pod-security.kubernetes.io/enforce=privileged

# Pg 207 — Review LB manifest
cat opencart-lb.yaml

# Pg 208-209 — Deploy LB and wait for IP
kubectl apply -f opencart-lb.yaml -n opencart
kubectl get service -n opencart -w
# → Wait for EXTERNAL-IP, then Ctrl+C

# Pg 214-215 — Deploy app
kubectl apply -f opencart.yaml -n opencart
kubectl get all -n opencart

# Pg 222 — Final node check
kubectl get nodes
```

---

## Module 4, Chapter 5 — Set Up ArgoCD (Pg 235–250)

**Goal:** Create supervisor context, deploy ArgoCD, and log in.

### Create Supervisor Context (Pg 235–236)

**Context:** Still in `vks-01`

```bash
# Pg 235 — Create supervisor context (does NOT auto-switch!)
vcf context create supervisor \
  --endpoint 10.1.0.6 \
  --username administrator@wld.sso \
  --insecure-skip-tls-verify \
  --auth-type basic

# Pg 236 — Switch to test namespace (interactive menu)
vcf context use
# → Select: supervisor:test-xxxxx
```

**Now in: `supervisor:test-xxxxx`**

### Deploy ArgoCD Instance (Pg 237–245)

```bash
# Pg 237 — Verify ArgoCD CRD exists
kubectl explain argocd.spec.version

# Pg 238 — Review manifest
cat argocd-instance.yaml

# Pg 239-240 — Deploy and check pods
kubectl apply -f argocd-instance.yaml
kubectl get pod

# Pg 243 — Wait for pods to be Running
kubectl get pod

# Pg 244 — Get admin password
kubectl get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
# → Copy this password!

# Pg 245 — Get ArgoCD external IP
kubectl get service
# → Note the EXTERNAL-IP for argocd-server
```

### Log Into ArgoCD CLI (Pg 246–250)

```bash
# Pg 246 — Login to ArgoCD (use IP from above)
argocd login 10.1.11.x
# → Username: admin
# → Password: (from secret above)

# Pg 247 — Change password
argocd account update-password

# Pg 248 — VCF context is unchanged
vcf context list

# Pg 249 — Register Supervisor as ArgoCD destination
argocd cluster add supervisor \
  --namespace test-xxxxx \
  --namespace dev-xxxxx \
  --kubeconfig ~/.kube/config

# Pg 250 — Get ArgoCD IP for web UI
kubectl get service
```

**Pg 261 — Git repo URL (copy for later):**
```
http://10.1.10.130:3000/holuser/argocd.git
```

---

## Module 4, Chapter 5 — Register vks-01 in ArgoCD (Pg 271–273)

**Goal:** Download vks-01 kubeconfig from GUI and register it with ArgoCD.

**Context:** `terminal` + `argocd`

```bash
# Pg 271 — Find downloaded kubeconfig
cd ~/Downloads
ls | grep vks-01-kubeconfig.yaml

# Pg 272 — Verify kubeconfig works (bypasses VCF context)
kubectl --kubeconfig vks-01-kubeconfig.yaml config current-context

# Pg 273 — Register vks-01 with ArgoCD
argocd cluster add vks-01-admin@vks-01 vks-01 \
  --kubeconfig vks-01-kubeconfig.yaml
```

---

## Module 4, Chapter 5 — Deploy OpenCart via ArgoCD (Pg 275–285)

**Goal:** Create ArgoCD apps to deploy OpenCart infrastructure and application.

**Context:** `argocd` + `supervisor:test-xxxxx`

```bash
# Pg 275 — Go to Lab directory
cd ~/Documents/Lab

# Pg 276-277 — Create and verify LB app
argocd app create opencart-lb --file argo-opencart-lb.yaml
argocd app get opencart-lb

# Pg 278 — Get DB VM external IP (from Supervisor)
kubectl get service

# Pg 279 — Get service from inside vks-01 (bypasses VCF context)
kubectl get service -n opencart --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml

# Pg 284-285 — Create and verify app
argocd app create opencart-app --file argo-opencart-app.yaml
argocd app get opencart-app
```

---

## Quick Context Reference

| When you're here... | To get here, run... |
|---------------------|---------------------|
| `terminal` (fresh start) | `vcf context create vcfa --endpoint auto-a.site-a.vcf.lab --api-token ... --tenant-name broadcom --ca-certificate vcfa-cert-chain.pem` |
| `vcfa:dev-xxxxx` | `vcf context use vcfa:dev-xxxxx:default-project` |
| `vks-01` | `vcf context use vks-01` |
| `supervisor:test-xxxxx` | `vcf context use supervisor:test-xxxxx` |
| ArgoCD CLI | `argocd login <IP>` (separate from VCF context) |
