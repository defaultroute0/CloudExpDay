# VCF Field Demo Lab — Student Worksheet

Write down these values as you go. Fill in the 🔴 fields as you progress through the lab.

---

## ⚠️ Known Issue — Creating the vks-01 Cluster (Module 4, Pg 175)

The Kubernetes release the guide tells you to select (`v1.35.0+vmware.2-vkr.4`) is missing its node image in this lab environment. If you select it, the **Review and Confirm** page shows a red error (`admission webhook "tkr-resolver-cluster-webhook..." denied the request: ... Missing compatible KR/OSImage`). Nothing deploys — nothing is broken.

**To get past it:**

1. In the terminal, make sure you are in the **`vcfa:dev-xxxxx`** context, then run:
   ```
   kubectl get osimage
   ```
2. Note the **newest version** in that list (e.g. a `v1.34.x` or `v1.33.x`).
3. Go **back one step** in the Create Cluster wizard and select **that** release instead of the one the guide names.
4. Continue with the lab **exactly as written** — every later command (packages, Prometheus, Telegraf, OpenCart, ArgoCD) works unchanged with any release from that list.

**Later, in the ArgoCD chapter:** when you edit `vks-01.yaml` for Gitea, set `version:` to the **same release you selected above** (and class to `builtin-generic-v3.6.0`) — otherwise ArgoCD hits the same error when it creates the test-namespace cluster, where it shows up as an app stuck out-of-sync instead of a red banner.

---

## Supervisor

| # | What | Your Value | How to Get It |
|---|------|------------|---------------|
| 1 | Supervisor IP | `10.1.0.6` | Already known |

---

## Dev Namespace

| # | What | Your Value | How to Get It |
|---|------|------------|---------------|
| 2 | Namespace name | 🔴 `dev-_____` | VCFA UI → Projects → default-project → Namespaces |
| 3 | vks-01 cluster IP | 🔴 `_._._._` | No context needed: `kubectl config view --kubeconfig ~/.kube/config \| grep server` — or VCFA UI → dev-xxxxx → Kubernetes → vks-01 |
| 4 | DB_HOST (oc-mysql VM LB — exists in supervisor dev-xxxxx namespace, not inside guest cluster) | 🔴 `_._._._` | VCFA UI → dev-xxxxx → Virtual Machine → oc-mysql → Network Service |
| 5 | OPENCART_HOST (opencart LB svc inside vks-01 guest cluster) | 🔴 `_._._._` | Context: `vcf context use vks-01` then `kubectl get service -n opencart` |

---

## Test Namespace

| # | What | Your Value | How to Get It |
|---|------|------------|---------------|
| 6 | Namespace name | 🔴 `test-_____` | VCFA UI → Projects → default-project → Namespaces |
| 7 | vks-01 cluster IP | 🔴 `_._._._` | No context needed: `kubectl config view --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml \| grep server` — or VCFA UI → test-xxxxx → Kubernetes → vks-01 |
| 8 | DB_HOST (oc-mysql VM LB — exists in supervisor test-xxxxx namespace, not inside guest cluster) | 🔴 `_._._._` | Context: `vcf context use supervisor:test-xxxxx` then `kubectl get service` — or VCFA UI → test-xxxxx → Virtual Machine → oc-mysql → Network Service |
| 9 | OPENCART_HOST (opencart LB svc inside vks-01 guest cluster) | 🔴 `_._._._` | No context needed: `kubectl get service -n opencart --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml` |
