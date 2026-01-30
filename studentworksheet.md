# VCF Field Demo Lab — Student Worksheet

Write down these values as you go. You'll need them for YAML edits later.

---

## Supervisor

| # | What | Your Value | How to Get It |
|---|------|:----------:|---------------|
| 1 | Supervisor IP | `10.1.0.6:6443` | Already known |

---

## Dev Namespace

| # | What | Your Value | How to Get It |
|---|------|:----------:|---------------|
| 2 | Namespace name | dev-_____________ | Check VCFA UI after creating namespace (Pg 44) |
| 3 | vks-01 cluster IP | ___.___.___.___:6443 | Shown in output of `vcf context create vks-01` (Pg 190) |
| 4 | DB_HOST (oc-mysql VM LB) | ___.___.___.___  | VCFA UI → oc-mysql → Network Service → External IP (Pg 152) |
| 5 | OPENCART_HOST (opencart LB) | ___.___.___.___ | Switch to vks-01 context, then `kubectl get service -n opencart -w` (Pg 209) |

---

## Test Namespace

| # | What | Your Value | How to Get It |
|---|------|:----------:|---------------|
| 6 | Namespace name | test-_____________ | Check VCFA UI after creating namespace (Pg 234) |
| 7 | vks-01 cluster IP | ___.___.___.___:6443 | Shown in output of `argocd cluster add vks-01-admin@vks-01 vks-01 --kubeconfig vks-01-kubeconfig.yaml` (Pg 273) |
| 8 | DB_HOST (oc-mysql VM LB) | ___.___.___.___  | Switch to supervisor:test-xxxxx context, then `kubectl get service` (Pg 278) |
| 9 | OPENCART_HOST (opencart LB) | ___.___.___.___ | `kubectl get service -n opencart --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml` — works from any context (Pg 279) |
