# VCF Field Demo Lab — Student Worksheet

Write down these values as you go. You'll need them for YAML edits later.

---

## Supervisor

| # | What | Your Value | How to Get It |
|---|------|------------|---------------|
| 1 | Supervisor IP | `10.1.0.6` | Already known |

---

## Dev Namespace

| # | What | Your Value | How to Get It |
|---|------|------------|---------------|
| 2 | Namespace name | `dev-_____` | VCFA UI → Projects → default-project → Namespaces |
| 3 | vks-01 cluster IP | `_._._._` | Run: `vcf context use vks-01` → `kubectl cluster-info` |
| 4 | DB_HOST (oc-mysql VM LB) | `_._._._` | VCFA UI → dev-xxxxx → Virtual Machine → oc-mysql → Network Service |
| 5 | OPENCART_HOST (opencart LB) | `_._._._` | Run: `vcf context use vks-01` → `kubectl get service -n opencart` |

---

## Test Namespace

| # | What | Your Value | How to Get It |
|---|------|------------|---------------|
| 6 | Namespace name | `test-_____` | VCFA UI → Projects → default-project → Namespaces |
| 7 | vks-01 cluster IP | `_._._._` | Run: `argocd login <argocd-server-ip>` → `argocd cluster list` |
| 8 | DB_HOST (oc-mysql VM LB) | `_._._._` | Run: `vcf context use supervisor:test-xxxxx` → `kubectl get service` |
| 9 | OPENCART_HOST (opencart LB) | `_._._._` | Run: `kubectl get service -n opencart --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml` (any context) |
