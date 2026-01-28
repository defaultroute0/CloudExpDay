# VCF Field Demo Lab - CLI Commands with Context State

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

# Module 2: Enabling VCF Cloud Services

## Chapter 2: Managing Virtual Machines with VM Service

```
CMD: (Pg 48)  vcf context create vcfa --endpoint auto-a.site-a.vcf.lab --api-token 0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3 --tenant-name broadcom --ca-certificate vcfa-cert-chain.pem
```
> → **CREATES** context: `vcfa` (CCI type — auto-discovers dev-xxxxx namespace sub-contexts)

```
CMD: (Pg 49)  vcf context use
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
CMD: (Pg 185)  vcf context use vcfa:dev-xxxxx:default-project
```
> → **CONFIRMS** context: `vcfa:dev-xxxxx`

```
CMD: (Pg 185)  vcf context use
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
CMD: (Pg 190)  vcf context create vks-01 --kubeconfig ~/.kube/config --kubecontext vcf-cli-vks-01-dev-xxxxx@vks-01-dev-xxxxx
```
> → **CREATES** context: `vks-01` (K8S type — still in `vcfa:dev-xxxxx`)

| Context | Pg | Command |
|---------|----|---------|
| `vcfa:dev-xxxxx` | 191 | `vcf context refresh` |
| `vcfa:dev-xxxxx` | 192 | `vcf context list` |

```
CMD: (Pg 193)  vcf context use vks-01
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
CMD: (Pg 235)  vcf context create supervisor --endpoint 10.1.0.6 --username administrator@wld.sso --insecure-skip-tls-verify --auth-type basic
```
> → **CREATES** context: `supervisor` (K8S type — auto-discovers test-xxxxx namespace sub-contexts, still in `vks-01`)

```
CMD: (Pg 236)  vcf context use
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
CMD: (Pg 246)  argocd login 10.1.11.x
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
