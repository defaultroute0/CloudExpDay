# VCF 9.1 Field Demo Lab — Student Worksheet

Write down these values as you go. Fill in the 🔴 fields as you progress through the lab.

---

## Environment Constants

| # | What | Value |
|---|------|-------|
| 1 | Supervisor IP (Argo CD chapter endpoint / cluster URL) | `10.1.8.132` |
| 2 | VCFA endpoint | `auto-a.site-a.vcf.lab` |
| 3 | Harbor | `harbor-01a.vcf.lab` (admin / Harbor123!) |
| 4 | GitLab | `https://gitlab.vcf.lab` (root / VMware123!VMware123!) |
| 5 | API Token | `cat ~/Downloads/my-token.txt` — do NOT delete it in VCFA |

---

## Namespaces (unique per pod — note yours!)

| # | What | Your Value | How to Get It |
|---|------|------------|---------------|
| 6 | Dev namespace | 🔴 `dev-_____` | VCFA UI → Projects → default-project → Namespaces (you create it, Module 2 Ch 2) |
| 7 | Prod namespace (pre-created — vks-01 goes here) | 🔴 `prod-_____` | vCenter → Supervisor Management → Namespaces, or `vcf context list` |
| 8 | Test namespace (Argo CD chapter) | 🔴 `test-_____` | VCFA UI → Projects → default-project → Namespaces (you create it, Module 3 Ch 6) |

---

## Module 3 Ch 2–3 — VM + Containers (dev namespace)

| # | What | Your Value | How to Get It |
|---|------|------------|---------------|
| 9 | cli-vm SSH LB External IP (ssh devops / DevOps123) | 🔴 `_._._._` | VCFA UI → dev-xxxxx → Network Service → Services |
| 10 | nginx LB External IP | 🔴 `_._._._` | VCFA UI → dev-xxxxx → Container → nginx (browse http://IP) |
| 11 | postgres LB External IP (psql -U db_admin -d my_database) | 🔴 `_._._._` | VCFA UI → dev-xxxxx → Container → postgres |

---

## Module 3 Ch 4 — vks-01 + Bookstore via Helm (prod namespace)

| # | What | Your Value | How to Get It |
|---|------|------------|---------------|
| 12 | vks-01 kubecontext name (for `vcf context create vks-01`) | 🔴 `vcf-cli-vks-01-prod-_____@vks-01-prod-_____` | `cat ~/.kube/config \| grep vks-01` |
| 13 | Bookstore Istio gateway External IP → DNS record `bookstore.vcf.lab` | 🔴 `_._._._` | Context `vks-01`: `kubectl get all -n bookstore` (demo-gateway-istio service) |

⚠️ **CRITICAL:** Download the vks-01 cluster YAML at the Review step of the Create Cluster wizard (Pg 155) — the Argo CD chapter needs it.

---

## Module 3 Ch 6 — Argo CD (test namespace)

| # | What | Your Value | How to Get It |
|---|------|------------|---------------|
| 14 | Argo CD initial admin password (then changed to VMware123!VMware123!) | 🔴 | Context `supervisor:test-xxxxx`: `kubectl get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' \| base64 -d` |
| 15 | Argo CD server External IP (login + UI) | 🔴 `_._._._` | Context `supervisor:test-xxxxx`: `kubectl get service` |
| 16 | vks-argo cluster IP (for `argocd app create --dest-server`) | 🔴 `_._._._` | Output of `argocd cluster add vks-argo-admin@vks-argo vks-argo --kubeconfig vks-argo-kubeconfig.yaml` |
| 17 | Bookstore-test Istio gateway External IP → DNS record `bookstore-test.vcf.lab` | 🔴 `_._._._` | `kubectl get service -n bookstore --kubeconfig=~/Downloads/vks-argo-kubeconfig.yaml` (demo-gateway-istio) |

**Remember the vks-argo.yaml edits before uploading to GitLab:** remove the `namespace:` line · vmClass `best-effort-medium` → `best-effort-large` · save as `vks-argo.yaml` · and in both addoninstall YAMLs replace `<SUPERVISOR_NAMESPACE>` with your `test-xxxxx`.
