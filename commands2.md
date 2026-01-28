# VCF Field Demo Lab - CLI Commands with Context State

## Lab Overview

This lab deploys an **OpenCart hybrid application** (MySQL VM backend + containerized frontend) across two namespaces, first manually then automated via GitOps.

### Module & Chapter Summary

| Module | Chapter | What Happens | CLI? |
|--------|---------|-------------|------|
| **1** | — | Lab orientation, verify ready status | No |
| **2** | Ch1: Declarative API | Review pre-deployed vSphere Supervisor | No |
| | [Ch2: VM Service](#chapter-2-managing-virtual-machines-with-vm-service) | Create VM Class, Content Library, `dev-xxxxx` namespace. Set up VCF CLI context | **Yes** |
| | Ch3: Managing Services | Verify Harbor, register ArgoCD + LCI services on Supervisor | No |
| | Ch4: VKS Updates | Upload VKS 3.4.0 package, install on Supervisor | No |
| | Ch5: Monitoring | Review Supervisor + `prod-vks-01` in VCF Operations | No |
| **3** | Ch1: Provider Setup | Review infrastructure: vCenters, Regions, VM Classes, Networking | No |
| | Ch2: Org Setup | Review Broadcom org, add `custom-small` VM Class to entitlements | No |
| **4** | Ch1: Overview | Architecture review of OpenCart hybrid app | No |
| | Ch2: Deploy VM | Create `oc-mysql` VM + LB in `dev-xxxxx` (GUI). Download YAML manifests | No |
| | [Ch3: Harbor](#chapter-3-uploading-containers-images-to-harbor) | Docker tag + push OpenCart image to Harbor | **Yes** |
| | [Ch4: VKS](#chapter-4-managing-kubernetes-clusters-with-vsphere-kubernetes-service-vks) | **MANUAL in `dev-xxxxx`**: Create `vks-01` (GUI), configure CLI, install Prometheus + Telegraf, deploy OpenCart via `kubectl apply` | **Yes** |
| | [Ch5: Argo CD](#chapter-5-enabling-continuous-delivery-with-argo-cd) | **AUTOMATED in `test-xxxxx`**: Deploy ArgoCD, push manifests to Gitea, ArgoCD auto-deploys vks-01 + oc-mysql + OpenCart. Demo GitOps sync | **Yes** |
| **5** | — | Private AI Services (interactive simulation only) | No |

### The Manual → GitOps Pattern

The lab intentionally deploys the same stack twice to contrast manual vs automated approaches:

**`dev-xxxxx` — Manual (Chapters 2–4):**
1. `oc-mysql` VM created via GUI wizard
2. `vks-01` cluster created via GUI wizard
3. Prometheus + Telegraf installed via `vcf package install`
4. OpenCart LB + app deployed via `kubectl apply`
5. Download all YAML manifests from the GUI deployments

**`test-xxxxx` — Automated via ArgoCD (Chapter 5):**
1. Create `test-xxxxx` namespace + deploy ArgoCD instance
2. Remove namespace references from downloaded YAMLs, upload to Gitea
3. ArgoCD `opencart-infra` → auto-deploys vks-01 + oc-mysql + LBs
4. ArgoCD `opencart-lb` + `opencart-app` → auto-deploys OpenCart on test vks-01
5. Edit `vks-01.yaml` in Gitea (replicas 1→2) → ArgoCD auto-syncs

> **Not automated by ArgoCD:** Prometheus and Telegraf — only installed manually on `dev-xxxxx` vks-01.

---

## Context Legend

Each command is prefixed with the **active VCF/kubectl context** the student must be in.

| Prefix | Meaning |
|--------|---------|
| `[vcfa:dev-xxxxx]` | VCF CLI context targeting the dev namespace in VCFA (CCI type) |
| `[vks-01]` | VCF CLI context targeting the vks-01 guest cluster (K8S type) |
| `[supervisor:test-xxxxx]` | VCF CLI context targeting the test namespace on the Supervisor (K8S type) |
| `[terminal]` | No VCF context needed — shell/docker command or explicit `--kubeconfig` |
| `[argocd]` | ArgoCD CLI session (separate auth from VCF contexts) |

> **Context transitions** are called out with ⮕ annotations showing what changes.
> Commands with explicit `--kubeconfig` bypass the active VCF context entirely.

---

## Command Index

- [Module 2: Enabling VCF Cloud Services](#module-2-enabling-vcf-cloud-services)
  - [Chapter 2: Managing Virtual Machines with VM Service](#chapter-2-managing-virtual-machines-with-vm-service)
- [Module 4: Consuming VCF Cloud Services](#module-4-consuming-vcf-cloud-services)
  - [Chapter 3: Uploading containers images to Harbor](#chapter-3-uploading-containers-images-to-harbor)
  - [Chapter 4: Managing Kubernetes clusters with VKS](#chapter-4-managing-kubernetes-clusters-with-vsphere-kubernetes-service-vks)
    - [Connect to dev namespace and register vks-01](#connect-to-dev-namespace-and-register-vks-01)
    - [Create vks-01 context and switch to it](#create-vks-01-context-and-switch-to-it)
    - [Install packages and deploy OpenCart on vks-01](#install-packages-and-deploy-opencart-on-vks-01)
  - [Chapter 5: Enabling Continuous Delivery with Argo CD](#chapter-5-enabling-continuous-delivery-with-argo-cd)
    - [Create supervisor context and switch to test namespace](#create-supervisor-context-and-switch-to-test-namespace)
    - [Deploy ArgoCD instance](#deploy-argocd-instance)
    - [Log into ArgoCD CLI and register clusters](#log-into-argocd-cli-and-register-clusters)
    - [Download vks-01 kubeconfig and register in ArgoCD](#download-vks-01-kubeconfig-and-register-in-argocd)
    - [Deploy OpenCart via ArgoCD CLI](#deploy-opencart-via-argocd-cli)

---

# Module 2: Enabling VCF Cloud Services

## Chapter 2: Managing Virtual Machines with VM Service

> ⮕ **CONTEXT TRANSITION** — Creating initial VCF CLI context

**Pg 48** · `[terminal]`
```
vcf context create vcfa --endpoint auto-a.site-a.vcf.lab --api-token 0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3 --tenant-name broadcom --ca-certificate vcfa-cert-chain.pem
```
Creates context `vcfa` (CCI type — auto-discovers `dev-xxxxx` namespace sub-contexts)

**Pg 49** · `[terminal]`
```
vcf context use
```
Interactive select — pick `vcfa:dev-xxxxx:default-project`

> ⮕ **NOW IN:** `vcfa:dev-xxxxx`

**Pg 50** · `[vcfa:dev-xxxxx]`
```
kubectl get vm
```

**Pg 51** · `[vcfa:dev-xxxxx]`
```
kubectl get vmi
```

---

# Module 4: Consuming VCF Cloud Services

## Chapter 3: Uploading containers images to Harbor

**Pg 160** · `[terminal]`
```
docker login harbor-01a.site-a.vcf.lab
```

**Pg 161** · `[terminal]`
```
docker image ls
```

**Pg 162** · `[terminal]`
```
docker tag vcf-automation-docker-dev-local.usw5.packages.broadcom.com/bitnami/opencart:4.0.1-1-debian-11-r66 harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66
```

**Pg 163** · `[terminal]`
```
docker push harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66
```

**Pg 164** · `[terminal]`
```
docker image ls
```

---

## Chapter 4: Managing Kubernetes clusters with vSphere Kubernetes Service (VKS)

### Connect to dev namespace and register vks-01

**Pg 184** · `[vcfa:dev-xxxxx]`
```
vcf context list
```

**Pg 185** · `[vcfa:dev-xxxxx]`
```
vcf context use vcfa:dev-xxxxx:default-project
```
Confirms you are in the `vcfa:dev-xxxxx` context

**Pg 185** · `[vcfa:dev-xxxxx]`
```
vcf context use
```
Interactive select — pick `vcfa:dev-xxxxx:default-project`

**Pg 185** · `[vcfa:dev-xxxxx]` — Provide API token when prompted:
```
0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3
```

**Pg 185** · `[vcfa:dev-xxxxx]` *(optional)*
```
kubectl config get-contexts
```
Verify context is set correctly

**Pg 186** · `[vcfa:dev-xxxxx]`
```
vcf cluster list
```

**Pg 187** · `[vcfa:dev-xxxxx]`
```
vcf cluster register-vcfa-jwt-authenticator vks-01
```

**Pg 188** · `[vcfa:dev-xxxxx]`
```
vcf cluster kubeconfig get vks-01 --export-file ~/.kube/config
```

**Pg 189** · `[terminal]`
```
cat ~/.kube/config |grep vks-01
```

### Create vks-01 context and switch to it

> ⮕ **CONTEXT TRANSITION** — Creating vks-01 context (does NOT auto-switch)

**Pg 190** · `[vcfa:dev-xxxxx]`
```
vcf context create vks-01 --kubeconfig ~/.kube/config --kubecontext vcf-cli-vks-01-dev-xxxxx@vks-01-dev-xxxxx
```
Creates context `vks-01` — select **cloud-consumption-interface** when prompted. You are still in `vcfa:dev-xxxxx`.

**Pg 191** · `[vcfa:dev-xxxxx]`
```
vcf context refresh
```

**Pg 192** · `[vcfa:dev-xxxxx]`
```
vcf context list
```

> ⮕ **CONTEXT TRANSITION** — Switching to vks-01

**Pg 193** · `[vcfa:dev-xxxxx]`
```
vcf context use vks-01
```

> ⮕ **NOW IN:** `vks-01`

### Install packages and deploy OpenCart on vks-01

**Pg 194** · `[vks-01]`
```
kubectl get node
```

**Pg 195** · `[vks-01]`
```
vcf package repository add default-repo --url projects.packages.broadcom.com/vsphere/supervisor/packages/2025.8.19/vks-standard-packages:v2025.8.19 -n tkg-system
```

**Pg 196** · `[vks-01]`
```
vcf package available list -n tkg-system
```

**Pg 197** · `[terminal]`
```
cd Documents/Lab
```

**Pg 198** · `[vks-01]`
```
kubectl create ns prometheus-installed
```

**Pg 199** · `[terminal]`
```
cat prometheus-data-values.yaml |grep storage
```

**Pg 199** · `[vks-01]`
```
kubectl get sc
```

**Pg 200** · `[vks-01]`
```
vcf package install prometheus -p prometheus.kubernetes.vmware.com --values-file prometheus-data-values.yaml -n prometheus-installed -v 3.5.0+vmware.1-vks.1
```

**Pg 201** · `[vks-01]`
```
kubectl get pods -n tanzu-system-monitoring
```

**Pg 202** · `[vks-01]`
```
kubectl create ns telegraf-installed
```

**Pg 203** · `[vks-01]`
```
vcf package install telegraf -p telegraf.kubernetes.vmware.com --values-file telegraf-data-values.yaml -n telegraf-installed -v 1.34.4+vmware.2-vks.1
```

**Pg 204** · `[vks-01]`
```
kubectl get pods -n tanzu-system-telegraf
```

**Pg 205** · `[vks-01]`
```
kubectl create namespace opencart
```

**Pg 206** · `[vks-01]`
```
kubectl label ns opencart pod-security.kubernetes.io/enforce=privileged
```

**Pg 207** · `[terminal]`
```
cat opencart-lb.yaml
```

**Pg 208** · `[vks-01]`
```
kubectl apply -f opencart-lb.yaml -n opencart
```

**Pg 209** · `[vks-01]`
```
kubectl get service -n opencart -w
```
Watch for external IP to be assigned, then Ctrl+C

**Pg 214** · `[vks-01]`
```
kubectl apply -f opencart.yaml -n opencart
```

**Pg 215** · `[vks-01]`
```
kubectl get all -n opencart
```

**Pg 222** · `[vks-01]`
```
kubectl get nodes
```

---

## Chapter 5: Enabling Continuous Delivery with Argo CD

### Create supervisor context and switch to test namespace

> ⮕ **CONTEXT TRANSITION** — Creating supervisor context (does NOT auto-switch)

**Pg 235** · `[vks-01]`
```
vcf context create supervisor --endpoint 10.1.0.6 --username administrator@wld.sso --insecure-skip-tls-verify --auth-type basic
```
Creates context `supervisor` (K8S type — auto-discovers `test-xxxxx` namespace sub-contexts). You are still in `vks-01`.

**Pg 236** · `[vks-01]`
```
vcf context use
```
Interactive select — pick `supervisor:test-xxxxx`

> ⮕ **NOW IN:** `supervisor:test-xxxxx`

### Deploy ArgoCD instance

**Pg 237** · `[supervisor:test-xxxxx]`
```
kubectl explain argocd.spec.version
```
Verify ArgoCD CRD is available on the Supervisor

**Pg 238** · `[terminal]`
```
cat argocd-instance.yaml
```

**Pg 239** · `[supervisor:test-xxxxx]`
```
kubectl apply -f argocd-instance.yaml
```

**Pg 240** · `[supervisor:test-xxxxx]`
```
kubectl get pod
```

**Pg 243** · `[supervisor:test-xxxxx]`
```
kubectl get pod
```
Wait until all ArgoCD pods are Running

**Pg 244** · `[supervisor:test-xxxxx]`
```
kubectl get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```
Copy this password for ArgoCD login

**Pg 245** · `[supervisor:test-xxxxx]`
```
kubectl get service
```
Note the ArgoCD external IP

### Log into ArgoCD CLI and register clusters

> ⮕ **ARGOCD SESSION** — Logging into ArgoCD CLI (separate from VCF context)

**Pg 246** · `[supervisor:test-xxxxx]`
```
argocd login 10.1.11.x
```
Use the IP from `kubectl get service` above. Username: `admin`, password from the secret above.

> ⮕ **ARGOCD SESSION ACTIVE** — ArgoCD CLI commands now work alongside VCF context

**Pg 247** · `[argocd]`
```
argocd account update-password
```

**Pg 248** · `[supervisor:test-xxxxx]`
```
vcf context list
```
VCF context is unchanged by ArgoCD CLI login

**Pg 249** · `[argocd]`
```
argocd cluster add supervisor --namespace test-xxxxx --namespace dev-xxxxx --kubeconfig ~/.kube/config
```
Registers the Supervisor as an ArgoCD destination cluster

**Pg 250** · `[supervisor:test-xxxxx]`
```
kubectl get service
```
Get ArgoCD IP for web UI access

**Pg 261** — Copy the git repo URL for later use:
```
http://10.1.10.130:3000/holuser/argocd.git
```

### Download vks-01 kubeconfig and register in ArgoCD

**Pg 271** · `[terminal]`
```
cd ~/Downloads
```

**Pg 271** · `[terminal]`
```
ls |grep vks-01-kubeconfig.yaml
```

**Pg 272** · `[terminal]`
```
kubectl --kubeconfig vks-01-kubeconfig.yaml config current-context
```
Explicit `--kubeconfig` bypasses VCF context

**Pg 273** · `[argocd]`
```
argocd cluster add vks-01-admin@vks-01 vks-01 --kubeconfig vks-01-kubeconfig.yaml
```
Registers vks-01 guest cluster as an ArgoCD destination

### Deploy OpenCart via ArgoCD CLI

**Pg 275** · `[terminal]`
```
cd ~/Documents/Lab
```

**Pg 276** · `[argocd]`
```
argocd app create opencart-lb --file argo-opencart-lb.yaml
```

**Pg 277** · `[argocd]`
```
argocd app get opencart-lb
```

**Pg 278** · `[supervisor:test-xxxxx]`
```
kubectl get service
```
Get the DB VM external IP (Supervisor namespace level)

**Pg 279** · `[terminal]`
```
kubectl get service -n opencart --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml
```
Explicit `--kubeconfig` targets inside the vks-01 guest cluster

**Pg 284** · `[argocd]`
```
argocd app create opencart-app --file argo-opencart-app.yaml
```

**Pg 285** · `[argocd]`
```
argocd app get opencart-app
```
