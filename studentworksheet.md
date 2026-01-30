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
| 3 | vks-01 cluster IP | `_._._._` | No context needed: `kubectl config view --kubeconfig ~/.kube/config \| grep server` — or VCFA UI → dev-xxxxx → Kubernetes → vks-01 |
| 4 | DB_HOST (oc-mysql VM LB — exists in supervisor namespace, not inside guest cluster) | `_._._._` | VCFA UI → dev-xxxxx → Virtual Machine → oc-mysql → Network Service |
| 5 | OPENCART_HOST (opencart LB svc inside vks-01 guest cluster) | `_._._._` | Context: `vcf context use vks-01` then `kubectl get service -n opencart` |

---

## Test Namespace

| # | What | Your Value | How to Get It |
|---|------|------------|---------------|
| 6 | Namespace name | `test-_____` | VCFA UI → Projects → default-project → Namespaces |
| 7 | vks-01 cluster IP | `_._._._` | No context needed: `kubectl config view --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml \| grep server` — or VCFA UI → test-xxxxx → Kubernetes → vks-01 |
| 8 | DB_HOST (oc-mysql VM LB — exists in supervisor namespace, not inside guest cluster) | `_._._._` | Context: `vcf context use supervisor:test-xxxxx` then `kubectl get service` — or VCFA UI → test-xxxxx → Virtual Machine → oc-mysql → Network Service |
| 9 | OPENCART_HOST (opencart LB svc inside vks-01 guest cluster) | `_._._._` | No context needed: `kubectl get service -n opencart --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml` |
