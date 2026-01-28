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

> **Context transitions** are called out with `→` annotations showing what changes.
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

```
[terminal] CMD: (Pg 48)  vcf context create vcfa --endpoint auto-a.site-a.vcf.lab --api-token 0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3 --tenant-name broadcom --ca-certificate vcfa-cert-chain.pem
```
> → **CREATES** context: `vcfa` (CCI type — auto-discovers dev-xxxxx namespace sub-contexts)

```
[terminal] CMD: (Pg 49)  vcf context use
```
> → **SELECT** context: `vcfa:dev-xxxxx:default-project`

| Context | Pg | Command |
|---------|----|---------|
| `vcfa:dev-xxxxx` | 50 | `kubectl get vm` |
| `vcfa:dev-xxxxx` | 51 | `kubectl get vmi` |

---

# Module 4: Consuming VCF Cloud Services

## Chapter 3: Uploading containers images to Harbor

| Context | Pg | Command |
|---------|----|---------|
| `terminal` | 160 | `docker login harbor-01a.site-a.vcf.lab` |
| `terminal` | 161 | `docker image ls` |
| `terminal` | 162 | `docker tag vcf-automation-docker-dev-local.usw5.packages.broadcom.com/bitnami/opencart:4.0.1-1-debian-11-r66 harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66` |
| `terminal` | 163 | `docker push harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66` |
| `terminal` | 164 | `docker image ls` |

---

## Chapter 4: Managing Kubernetes clusters with vSphere Kubernetes Service (VKS)

### Connect to dev namespace and register vks-01

| Context | Pg | Command |
|---------|----|---------|
| `vcfa:dev-xxxxx` | 184 | `vcf context list` |

```
[vcfa:dev-xxxxx] CMD: (Pg 185)  vcf context use vcfa:dev-xxxxx:default-project
```
> → **CONFIRMS** context: `vcfa:dev-xxxxx`

```
[vcfa:dev-xxxxx] CMD: (Pg 185)  vcf context use
```
> → (interactive select — pick `vcfa:dev-xxxxx:default-project`)

| Context | Pg | Command | Notes |
|---------|----|---------|-------|
| `vcfa:dev-xxxxx` | 185 | (provide token) e.g. `0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3` | |
| `vcfa:dev-xxxxx` | 185 | `kubectl config get-contexts` | *(optional)* verify context |
| `vcfa:dev-xxxxx` | 186 | `vcf cluster list` | |
| `vcfa:dev-xxxxx` | 187 | `vcf cluster register-vcfa-jwt-authenticator vks-01` | |
| `vcfa:dev-xxxxx` | 188 | `vcf cluster kubeconfig get vks-01 --export-file ~/.kube/config` | |
| `terminal` | 189 | `cat ~/.kube/config \|grep vks-01` | |

### Create vks-01 context and switch to it

```
[vcfa:dev-xxxxx] CMD: (Pg 190)  vcf context create vks-01 --kubeconfig ~/.kube/config --kubecontext vcf-cli-vks-01-dev-xxxxx@vks-01-dev-xxxxx
```
> → **CREATES** context: `vks-01` (lab guide says select **cloud-consumption-interface** context type — still in `vcfa:dev-xxxxx`)

| Context | Pg | Command |
|---------|----|---------|
| `vcfa:dev-xxxxx` | 191 | `vcf context refresh` |
| `vcfa:dev-xxxxx` | 192 | `vcf context list` |

```
[vcfa:dev-xxxxx] CMD: (Pg 193)  vcf context use vks-01
```
> → **SWITCHES** context to: `vks-01`

### Install packages and deploy OpenCart on vks-01

| Context | Pg | Command | Notes |
|---------|----|---------|-------|
| `vks-01` | 194 | `kubectl get node` | |
| `vks-01` | 195 | `vcf package repository add default-repo --url projects.packages.broadcom.com/vsphere/supervisor/packages/2025.8.19/vks-standard-packages:v2025.8.19 -n tkg-system` | |
| `vks-01` | 196 | `vcf package available list -n tkg-system` | |
| `terminal` | 197 | `cd Documents/Lab` | |
| `vks-01` | 198 | `kubectl create ns prometheus-installed` | |
| `terminal` | 199 | `cat prometheus-data-values.yaml \|grep storage` | |
| `vks-01` | 199 | `kubectl get sc` | |
| `vks-01` | 200 | `vcf package install prometheus -p prometheus.kubernetes.vmware.com --values-file prometheus-data-values.yaml -n prometheus-installed -v 3.5.0+vmware.1-vks.1` | |
| `vks-01` | 201 | `kubectl get pods -n tanzu-system-monitoring` | |
| `vks-01` | 202 | `kubectl create ns telegraf-installed` | |
| `vks-01` | 203 | `vcf package install telegraf -p telegraf.kubernetes.vmware.com --values-file telegraf-data-values.yaml -n telegraf-installed -v 1.34.4+vmware.2-vks.1` | |
| `vks-01` | 204 | `kubectl get pods -n tanzu-system-telegraf` | |
| `vks-01` | 205 | `kubectl create namespace opencart` | |
| `vks-01` | 206 | `kubectl label ns opencart pod-security.kubernetes.io/enforce=privileged` | |
| `terminal` | 207 | `cat opencart-lb.yaml` | |
| `vks-01` | 208 | `kubectl apply -f opencart-lb.yaml -n opencart` | |
| `vks-01` | 209 | `kubectl get service -n opencart -w` | watch for external IP |
| `vks-01` | 214 | `kubectl apply -f opencart.yaml -n opencart` | |
| `vks-01` | 215 | `kubectl get all -n opencart` | |
| `vks-01` | 222 | `kubectl get nodes` | |

---

## Chapter 5: Enabling Continuous Delivery with Argo CD

### Create supervisor context and switch to test namespace

```
[vks-01] CMD: (Pg 235)  vcf context create supervisor --endpoint 10.1.0.6 --username administrator@wld.sso --insecure-skip-tls-verify --auth-type basic
```
> → **CREATES** context: `supervisor` (K8S type — auto-discovers test-xxxxx namespace sub-contexts, still in `vks-01`)

```
[vks-01] CMD: (Pg 236)  vcf context use
```
> → **SELECT** context: `supervisor:test-xxxxx` (the test namespace on the Supervisor)

### Deploy ArgoCD instance

| Context | Pg | Command | Notes |
|---------|----|---------|-------|
| `supervisor:test-xxxxx` | 237 | `kubectl explain argocd.spec.version` | ArgoCD CRD is on Supervisor |
| `terminal` | 238 | `cat argocd-instance.yaml` | |
| `supervisor:test-xxxxx` | 239 | `kubectl apply -f argocd-instance.yaml` | |
| `supervisor:test-xxxxx` | 240 | `kubectl get pod` | |
| `supervisor:test-xxxxx` | 243 | `kubectl get pod` | |
| `supervisor:test-xxxxx` | 244 | `kubectl get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' \| base64 -d` | |
| `supervisor:test-xxxxx` | 245 | `kubectl get service` | get ArgoCD external IP |

### Log into ArgoCD CLI and register clusters

```
[supervisor:test-xxxxx] CMD: (Pg 246)  argocd login 10.1.11.x
```
> → **ESTABLISHES** ArgoCD CLI session (separate from VCF context)

| Context | Pg | Command | Notes |
|---------|----|---------|-------|
| `argocd` | 247 | `argocd account update-password` | |
| `supervisor:test-xxxxx` | 248 | `vcf context list` | VCF context unchanged by argocd CLI |
| `argocd` | 249 | `argocd cluster add supervisor --namespace test-xxxxx --namespace dev-xxxxx --kubeconfig ~/.kube/config` | registers Supervisor as ArgoCD destination |
| `supervisor:test-xxxxx` | 250 | `kubectl get service` | get ArgoCD IP for web UI |
| | 261 | *(copy git repo URL)* `http://10.1.10.130:3000/holuser/argocd.git` | |

### Download vks-01 kubeconfig and register in ArgoCD

| Context | Pg | Command | Notes |
|---------|----|---------|-------|
| `terminal` | 271 | `cd ~/Downloads` | |
| `terminal` | 271 | `ls \|grep vks-01-kubeconfig.yaml` | |
| `terminal` | 272 | `kubectl --kubeconfig vks-01-kubeconfig.yaml config current-context` | explicit kubeconfig — bypasses VCF context |
| `argocd` | 273 | `argocd cluster add vks-01-admin@vks-01 vks-01 --kubeconfig vks-01-kubeconfig.yaml` | registers vks-01 guest cluster as ArgoCD destination |

### Deploy OpenCart via ArgoCD CLI

| Context | Pg | Command | Notes |
|---------|----|---------|-------|
| `terminal` | 275 | `cd ~/Documents/Lab` | |
| `argocd` | 276 | `argocd app create opencart-lb --file argo-opencart-lb.yaml` | |
| `argocd` | 277 | `argocd app get opencart-lb` | |
| `supervisor:test-xxxxx` | 278 | `kubectl get service` | get DB VM external IP (Supervisor namespace level) |
| `terminal` | 279 | `kubectl get service -n opencart --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml` | explicit kubeconfig — targets **inside** vks-01 guest cluster |
| `argocd` | 284 | `argocd app create opencart-app --file argo-opencart-app.yaml` | |
| `argocd` | 285 | `argocd app get opencart-app` | |
