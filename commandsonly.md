# VCF Field Demo Lab - CLI Commands with Context State

Each CMD line is prefixed with the VCF/kubectl context the student should be in.
Context changes are marked with `→` to show transitions.
`[terminal]` = no VCF context needed, just a shell command.
`[argocd]` = ArgoCD CLI session (separate from VCF context).
`[UNSURE]` = context unclear, investigate if needed.

---

# Module 2: Enabling VCF Cloud Services

## Chapter 2: Managing Virtual Machines with VM Service

CMD: (Pg 48) `vcf context create vcfa --endpoint auto-a.site-a.vcf.lab --api-token 0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3 --tenant-name broadcom --ca-certificate vcfa-cert-chain.pem`
→ CREATES context: vcfa

CMD: (Pg 49) `vcf context use`
→ SELECT context: vcfa:dev-xxxxx:default-project

[vcfa:dev-xxxxx] CMD: (Pg 50) `kubectl get vm`
[vcfa:dev-xxxxx] CMD: (Pg 51) `kubectl get vmi`

# Module 4: Consuming VCF Cloud Services

## Chapter 3: Uploading containers images to Harbor

[terminal] CMD: (Pg 160) `docker login harbor-01a.site-a.vcf.lab`
[terminal] CMD: (Pg 161) `docker image ls`
[terminal] CMD: (Pg 162) `docker tag vcf-automation-docker-dev-local.usw5.packages.broadcom.com/bitnami/opencart:4.0.1-1-debian-11-r66 harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66`
[terminal] CMD: (Pg 163) `docker push harbor-01a.site-a.vcf.lab/opencart/opencart:4.0.1-1-debian-11-r66`
[terminal] CMD: (Pg 164) `docker image ls`

## Chapter 4: Managing Kubernetes clusters with vSphere Kubernetes Service (VKS)

[vcfa:dev-xxxxx] CMD: (Pg 184) `vcf context list`

[vcfa:dev-xxxxx] CMD: (Pg 185) `vcf context use vcfa:dev-xxxxx:default-project`
→ CONFIRMS context: vcfa:dev-xxxxx

[vcfa:dev-xxxxx] CMD: (Pg 185) `vcf context use`
→ (interactive select — pick vcfa:dev-xxxxx:default-project)

[vcfa:dev-xxxxx] CMD: (Pg 185) (provide token) e.g. `0lraViAN9alcyYTZ0KlAuqLqrvEqxsr3`
[vcfa:dev-xxxxx] CMD: (Pg 185) (optional) `kubectl config get-contexts`  ← verify context is correct
[vcfa:dev-xxxxx] CMD: (Pg 186) `vcf cluster list`
[vcfa:dev-xxxxx] CMD: (Pg 187) `vcf cluster register-vcfa-jwt-authenticator vks-01`
[vcfa:dev-xxxxx] CMD: (Pg 188) `vcf cluster kubeconfig get vks-01 --export-file ~/.kube/config`
[terminal] CMD: (Pg 189) `cat ~/.kube/config |grep vks-01`

[vcfa:dev-xxxxx] CMD: (Pg 190) `vcf context create vks-01 --kubeconfig ~/.kube/config --kubecontext vcf-cli-vks-01-dev-xxxxx@vks-01-dev-xxxxx`
→ CREATES context: vks-01

[vcfa:dev-xxxxx] CMD: (Pg 191) `vcf context refresh`
[vcfa:dev-xxxxx] CMD: (Pg 192) `vcf context list`

[vcfa:dev-xxxxx] CMD: (Pg 193) `vcf context use vks-01`
→ SWITCHES context to: vks-01

[vks-01] CMD: (Pg 194) `kubectl get node`
[vks-01] CMD: (Pg 195) `vcf package repository add default-repo --url projects.packages.broadcom.com/vsphere/supervisor/packages/2025.8.19/vks-standard-packages:v2025.8.19 -n tkg-system`
[vks-01] CMD: (Pg 196) `vcf package available list -n tkg-system`
[terminal] CMD: (Pg 197) `cd Documents/Lab`
[vks-01] CMD: (Pg 198) `kubectl create ns prometheus-installed`
[terminal] CMD: (Pg 199) `cat prometheus-data-values.yaml |grep storage`
[vks-01] CMD: (Pg 199) `kubectl get sc`
[vks-01] CMD: (Pg 200) `vcf package install prometheus -p prometheus.kubernetes.vmware.com --values-file prometheus-data-values.yaml -n prometheus-installed -v 3.5.0+vmware.1-vks.1`
[vks-01] CMD: (Pg 201) `kubectl get pods -n tanzu-system-monitoring`
[vks-01] CMD: (Pg 202) `kubectl create ns telegraf-installed`
[vks-01] CMD: (Pg 203) `vcf package install telegraf -p telegraf.kubernetes.vmware.com --values-file telegraf-data-values.yaml -n telegraf-installed -v 1.34.4+vmware.2-vks.1`
[vks-01] CMD: (Pg 204) `kubectl get pods -n tanzu-system-telegraf`
[vks-01] CMD: (Pg 205) `kubectl create namespace opencart`
[vks-01] CMD: (Pg 206) `kubectl label ns opencart pod-security.kubernetes.io/enforce=privileged`
[terminal] CMD: (Pg 207) `cat opencart-lb.yaml`
[vks-01] CMD: (Pg 208) `kubectl apply -f opencart-lb.yaml -n opencart`
[vks-01] CMD: (Pg 209) `kubectl get service -n opencart -w`  ← watch for external IP to appear
[vks-01] CMD: (Pg 214) `kubectl apply -f opencart.yaml -n opencart`
[vks-01] CMD: (Pg 215) `kubectl get all -n opencart`
[vks-01] CMD: (Pg 222) `kubectl get nodes`

## Chapter 5: Enabling Continuous Delivery with Argo CD

[vks-01] CMD: (Pg 235) `vcf context create supervisor --endpoint 10.1.0.6 --username administrator@wld.sso --insecure-skip-tls-verify --auth-type basic`
→ CREATES context: supervisor

[vks-01] CMD: (Pg 236) `vcf context use`
→ SELECT context: supervisor:test-xxxxx (the test namespace on supervisor)

[supervisor:test-xxxxx] CMD: (Pg 237) `kubectl explain argocd.spec.version`
[terminal] CMD: (Pg 238) `cat argocd-instance.yaml`
[supervisor:test-xxxxx] CMD: (Pg 239) `kubectl apply -f argocd-instance.yaml`
[supervisor:test-xxxxx] CMD: (Pg 240) `kubectl get pod`
[supervisor:test-xxxxx] CMD: (Pg 243) `kubectl get pod`
[supervisor:test-xxxxx] CMD: (Pg 244) `kubectl get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`
[supervisor:test-xxxxx] CMD: (Pg 245) `kubectl get service`
[argocd] CMD: (Pg 246) `argocd login 10.1.11.x`
→ ESTABLISHES ArgoCD CLI session

[argocd] CMD: (Pg 247) `argocd account update-password`
[supervisor:test-xxxxx] CMD: (Pg 248) `vcf context list`
[argocd] CMD: (Pg 249) `argocd cluster add supervisor --namespace test-xxxxx --namespace dev-xxxxx --kubeconfig ~/.kube/config`
[supervisor:test-xxxxx] CMD: (Pg 250) `kubectl get service`
CMD: (Pg 261) (copy git repo URL) `http://10.1.10.130:3000/holuser/argocd.git`
[terminal] CMD: (Pg 271) `cd ~/Downloads`
[terminal] CMD: (Pg 271) `ls |grep vks-01-kubeconfig.yaml`
[terminal] CMD: (Pg 272) `kubectl --kubeconfig vks-01-kubeconfig.yaml config current-context`
  ← uses explicit kubeconfig, not current VCF context
[argocd] CMD: (Pg 273) `argocd cluster add vks-01-admin@vks-01 vks-01 --kubeconfig vks-01-kubeconfig.yaml`
[terminal] CMD: (Pg 275) `cd ~/Documents/Lab`
[argocd] CMD: (Pg 276) `argocd app create opencart-lb --file argo-opencart-lb.yaml`
[argocd] CMD: (Pg 277) `argocd app get opencart-lb`
[supervisor:test-xxxxx] CMD: (Pg 278) `kubectl get service`
[terminal] CMD: (Pg 279) `kubectl get service -n opencart --kubeconfig ~/Downloads/vks-01-kubeconfig.yaml`
  ← uses explicit kubeconfig to target vks-01 cluster
[argocd] CMD: (Pg 284) `argocd app create opencart-app --file argo-opencart-app.yaml`
[argocd] CMD: (Pg 285) `argocd app get opencart-app`
