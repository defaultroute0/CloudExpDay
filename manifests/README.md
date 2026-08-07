# 9.1 Lab Manifests

Actual YAMLs downloaded from the lab wizards (pod run, Aug 2026):

- `create-vm-yaml-files/` — cli-vm VM, SSH load balancer, bootstrap secret (Module 3 Ch 2)
- `create-pod-yaml-files/` — nginx Container Service instance + LB (Module 3 Ch 3)
- `create-postgrespod-yaml-files/` — postgres StatefulSet + LB (Module 3 Ch 3)
- `create-tkg-cluster-yaml/` — vks-01 cluster (Module 3 Ch 4; `namespace:` line pre-commented for the Argo CD chapter edits)

Still to add after a full Argo CD chapter run: `vks-argo.yaml` (renamed/edited copy), `addoninstall-cert-manager.yaml`, `addoninstall-istio.yaml`, `argocd-instance.yaml`.

The 9.0 manifests (oc-mysql, opencart LB, etc.) live on the `9.0` branch.
