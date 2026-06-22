# =====================================================================
#  seed-issues.ps1  —  eks-gitops-platform
#  Creates the full ticket backlog as GitHub issues.
#  All tickets assigned to andyvn1 (Andy).
#
#  Usage:
#    pwsh ./scripts/seed-issues.ps1
#  Requires: gh CLI authenticated as a repo collaborator,
#            and andyvn1 added as a collaborator on the repo.
#  Note: running twice creates duplicate issues.
# =====================================================================

$ErrorActionPreference = 'Stop'
$env:Path += ";C:\Program Files\GitHub CLI"

$Repo     = 'Corrierethan/eks-gitops-platform'
$Assignee = 'andyvn1'

Write-Host "Seeding issues into $Repo ..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# Labels
# ---------------------------------------------------------------------
$labels = @(
    @{ name = 'type:skeleton';   color = 'c5def5'; desc = 'Repo scaffolding / structure' },
    @{ name = 'type:terraform';  color = '623ce4'; desc = 'Terraform / infrastructure' },
    @{ name = 'type:gitops';     color = '0e8a16'; desc = 'Argo CD / GitOps' },
    @{ name = 'type:security';   color = 'b60205'; desc = 'Hardening / policy' },
    @{ name = 'type:ci';         color = '5319e7'; desc = 'CI / pipeline plumbing' },
    @{ name = 'type:docs';       color = '1d76db'; desc = 'Documentation' },
    @{ name = 'type:chore';      color = 'ededed'; desc = 'Maintenance / finishing touches' },
    @{ name = 'size:S';          color = 'c2e0c6'; desc = 'Small (<= half day)' },
    @{ name = 'size:M';          color = 'fef2c0'; desc = 'Medium (~1 day)' },
    @{ name = 'size:L';          color = 'f9d0c4'; desc = 'Large (multi-day)' }
)

foreach ($l in $labels) {
    gh label create $l.name --repo $Repo --color $l.color --description $l.desc --force | Out-Null
}
Write-Host "Labels ready." -ForegroundColor Green

# ---------------------------------------------------------------------
# Issues
# ---------------------------------------------------------------------
$issues = @()

# ---- #0 Skeleton ----------------------------------------------------
$issues += @{
title  = '#0 Initialize repository skeleton'
labels = 'type:skeleton,size:S'
body   = @'
Stand up the empty repo structure so every later ticket has a home. **No real logic yet** — just files, folders, and placeholders.

### Files / folders to create
- [ ] `.gitignore` (Terraform: `.terraform/`, `*.tfstate*`, `.terraform.lock.hcl` kept; plus OS noise)
- [ ] `.editorconfig` (LF, 2-space YAML/HCL)
- [ ] `.tflint.hcl` (enable terraform + aws rulesets)
- [ ] `LICENSE` (MIT)
- [ ] `CHANGELOG.md` (Keep a Changelog, `## [Unreleased]`)
- [ ] `terraform/` (with `.gitkeep`)
- [ ] `gitops/` (with `.gitkeep`)
- [ ] `policies/` (with `.gitkeep`)
- [ ] `docs/` (with `.gitkeep`)
- [ ] `.github/workflows/` (with `.gitkeep`)

### Acceptance criteria
- Repo clones clean; `tree` matches the README layout.
- `main` is protected (1 approval, no force-push) — coordinate with repo admin.

### Out of scope
- Any Terraform resources, manifests, or policies (later tickets).
'@
}

# ---- #1 TF backend/providers ---------------------------------------
$issues += @{
title  = '#1 Terraform backend, providers, and version pins'
labels = 'type:terraform,size:M'
body   = @'
Lay the Terraform foundation so all later infra code shares one backend and provider config.

### Files to create
- [ ] `terraform/versions.tf` — `required_version` + pinned `aws`, `kubernetes`, `helm` providers
- [ ] `terraform/providers.tf` — AWS provider with `region` + `partition` wired from variables
- [ ] `terraform/backend.tf` — S3 backend + DynamoDB lock (bucket/table as partial config)
- [ ] `terraform/variables.tf` — `region`, `partition`, `cluster_name`, `tags`
- [ ] `terraform/outputs.tf` — empty placeholder

### Requirements
- [ ] `partition` defaults to `aws-us-gov`, `region` to `us-gov-west-1`
- [ ] Provider config must work in both `aws` and `aws-us-gov` partitions
- [ ] Backend uses encryption + state locking

### Acceptance criteria
- `terraform init` + `terraform validate` succeed.
- `terraform fmt -check` is clean.
'@
}

# ---- #2 Networking inputs ------------------------------------------
$issues += @{
title  = '#2 Networking inputs (consume existing VPC / subnets)'
labels = 'type:terraform,size:M'
body   = @'
The cluster lands in an existing VPC (e.g. from the landing-zone project). Wire networking via data sources / variables — do **not** create a VPC here.

### Files to create
- [ ] `terraform/network.tf` — `data "aws_vpc"` + `data "aws_subnets"` (private)
- [ ] Extend `terraform/variables.tf` — `vpc_id`, `private_subnet_ids`, `cluster_name`

### Requirements
- [ ] Look up private subnets by tag
- [ ] Validate at least 2 AZs are present (precondition block)
- [ ] Output the resolved subnet IDs

### Acceptance criteria
- `terraform plan` resolves the VPC + subnets with no resource creation.
- Fails fast with a clear message if fewer than 2 AZs.
'@
}

# ---- #3 KMS ---------------------------------------------------------
$issues += @{
title  = '#3 KMS key for EKS secrets encryption'
labels = 'type:security,size:S'
body   = @'
Provision a customer-managed KMS key so EKS envelope-encrypts Kubernetes secrets in etcd. Maps to NIST **SC-28**.

### Files to create
- [ ] `terraform/kms.tf` — `aws_kms_key` + `aws_kms_alias` (rotation enabled)

### Requirements
- [ ] Key policy scoped to the account + EKS service
- [ ] `enable_key_rotation = true`
- [ ] Alias like `alias/eks-<cluster_name>-secrets`
- [ ] Output the key ARN for the cluster module

### Acceptance criteria
- `terraform plan` shows the key + alias.
- Key ARN is exposed as an output.
'@
}

# ---- #4 EKS control plane ------------------------------------------
$issues += @{
title  = '#4 EKS control plane (private endpoint + audit logging)'
labels = 'type:terraform,size:L'
body   = @'
Provision the EKS control plane, hardened. Maps to NIST **SC-7** (private endpoint) and **AU-2** (logging).

### Files to create
- [ ] `terraform/eks.tf` — `aws_eks_cluster`
- [ ] Extend `terraform/variables.tf` — `kubernetes_version`, `endpoint_public_access` (default `false`)

### Requirements
- [ ] **Private** API endpoint; public access disabled (or CIDR-restricted)
- [ ] Secrets encryption using the KMS key from #3
- [ ] Enable control-plane logs: `api, audit, authenticator, controllerManager, scheduler`
- [ ] Cluster security group + least-privilege cluster IAM role
- [ ] Pin `kubernetes_version`

### Acceptance criteria
- Cluster reaches `ACTIVE`.
- `aws eks describe-cluster` shows encryption config + all log types enabled.
- API endpoint is private.
'@
}

# ---- #5 IRSA --------------------------------------------------------
$issues += @{
title  = '#5 OIDC provider + IRSA foundation'
labels = 'type:security,size:M'
body   = @'
Enable IAM Roles for Service Accounts so pods get scoped IAM with no long-lived keys. Maps to NIST **AC-6, IA-5**.

### Files to create
- [ ] `terraform/irsa.tf` — `aws_iam_openid_connect_provider` for the cluster
- [ ] A reusable IRSA role module/helper (e.g. `terraform/modules/irsa-role/`)

### Requirements
- [ ] Derive the OIDC issuer/thumbprint from the cluster (#4)
- [ ] Helper accepts: namespace, service account name, policy ARN(s)
- [ ] Output the OIDC provider ARN

### Acceptance criteria
- `terraform plan` shows the OIDC provider.
- A sample IRSA role can be created by passing namespace+SA+policy.
'@
}

# ---- #6 Node groups -------------------------------------------------
$issues += @{
title  = '#6 Managed node groups (hardened)'
labels = 'type:terraform,size:L'
body   = @'
Provision managed worker nodes with hardened settings. Maps to NIST **CM-6, CM-7**.

### Files to create
- [ ] `terraform/nodegroups.tf` — `aws_eks_node_group`(s)
- [ ] `terraform/node-iam.tf` — node role with minimum managed policies
- [ ] Extend variables — `node_instance_types`, `desired/min/max_size`, `disk_size`

### Hardening requirements
- [ ] Nodes in **private** subnets only
- [ ] IMDSv2 required (hop limit 1, tokens required)
- [ ] EBS volumes encrypted (KMS)
- [ ] Latest EKS-optimized AMI, pinned by release version
- [ ] Labels/taints for workload scheduling
- [ ] Node IAM role = only `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`

### Acceptance criteria
- Nodes join the cluster and are `Ready`.
- IMDSv2 enforced (verify via instance metadata options).
- Root/EBS volumes encrypted.
'@
}

# ---- #7 Core add-ons + ECR -----------------------------------------
$issues += @{
title  = '#7 Core EKS add-ons + ECR repository'
labels = 'type:terraform,size:M'
body   = @'
Manage the core cluster add-ons via Terraform and create an ECR repo for workload images (no public registries).

### Files to create
- [ ] `terraform/addons.tf` — `aws_eks_addon` for `vpc-cni`, `coredns`, `kube-proxy` (pinned versions)
- [ ] `terraform/ecr.tf` — private ECR repo with scan-on-push + immutable tags + lifecycle policy

### Requirements
- [ ] Pin every add-on version (no `latest`)
- [ ] vpc-cni configured for IRSA (uses role from #5)
- [ ] ECR: `image_tag_mutability = IMMUTABLE`, `scan_on_push = true`, encryption with KMS

### Acceptance criteria
- `kubectl get pods -n kube-system` shows healthy add-ons.
- ECR repo exists with scan-on-push enabled.
'@
}

# ---- #8 Argo CD bootstrap ------------------------------------------
$issues += @{
title  = '#8 Bootstrap Argo CD into the cluster'
labels = 'type:gitops,size:M'
body   = @'
Install Argo CD — the GitOps engine that reconciles everything else from Git. Maps to NIST **CM-3, CM-5**.

### Files to create
- [ ] `gitops/bootstrap/argocd-namespace.yaml`
- [ ] `gitops/bootstrap/argocd-install.yaml` (pinned Argo CD manifest/Helm values) **or** a Terraform `helm_release`
- [ ] `docs/deploy.md` (stub; full walkthrough in #17)

### Requirements
- [ ] Pin the Argo CD version
- [ ] Disable the public LoadBalancer (ClusterIP + port-forward, or internal ingress later)
- [ ] Admin password rotated / SSO noted as follow-up
- [ ] RBAC: default policy = read-only

### Acceptance criteria
- Argo CD pods are `Running`.
- `argocd` UI reachable via port-forward.
'@
}

# ---- #9 app-of-apps -------------------------------------------------
$issues += @{
title  = '#9 app-of-apps root Application'
labels = 'type:gitops,size:M'
body   = @'
Create the root Application that points Argo CD at `gitops/` so add-ons, policies, and workloads reconcile from Git automatically.

### Files to create
- [ ] `gitops/root-app.yaml` — Argo CD `Application` (app-of-apps) targeting `gitops/apps/`
- [ ] `gitops/apps/.gitkeep` (child Applications added in #10/#11)
- [ ] `gitops/projects/platform.yaml` — Argo CD `AppProject` scoping allowed repos/destinations

### Requirements
- [ ] `syncPolicy.automated` with `prune` + `selfHeal`
- [ ] AppProject restricts source repos + destination namespaces
- [ ] Document the sync wave ordering convention

### Acceptance criteria
- Applying `root-app.yaml` makes Argo CD manage child apps.
- Root app shows `Synced` / `Healthy`.
'@
}

# ---- #10 Platform add-ons via GitOps -------------------------------
$issues += @{
title  = '#10 Platform add-ons via GitOps (ingress-nginx, cert-manager, metrics-server, external-secrets)'
labels = 'type:gitops,size:L'
body   = @'
Deliver the platform layer through Argo CD child Applications (not Terraform) so day-2 changes are GitOps-driven.

### Files to create (one Application each, under `gitops/apps/`)
- [ ] `gitops/apps/ingress-nginx.yaml` (internal NLB)
- [ ] `gitops/apps/cert-manager.yaml`
- [ ] `gitops/apps/metrics-server.yaml`
- [ ] `gitops/apps/external-secrets.yaml` (IRSA role from #5, reads from AWS Secrets Manager)
- [ ] `gitops/values/` — pinned Helm chart + app versions per add-on

### Requirements
- [ ] Pin chart versions
- [ ] Sync waves so cert-manager/CRDs land before dependents
- [ ] ingress-nginx uses an **internal** load balancer
- [ ] external-secrets authenticates via IRSA (no static keys)

### Acceptance criteria
- All four Applications are `Synced`/`Healthy`.
- A test ExternalSecret materializes a Kubernetes secret.
'@
}

# ---- #11 Sample workload -------------------------------------------
$issues += @{
title  = '#11 Sample workload deployed via GitOps'
labels = 'type:gitops,size:M'
body   = @'
Prove the end-to-end path: commit -> Argo CD -> running pod, pulling from ECR.

### Files to create
- [ ] `gitops/apps/sample-app.yaml` — Argo CD Application
- [ ] `gitops/workloads/sample-app/` — Deployment, Service, (optional Ingress)
- [ ] Reference the ECR image from #7

### Requirements
- [ ] Image pulled from ECR (digest-pinned)
- [ ] Resource requests/limits set
- [ ] `securityContext`: non-root, read-only root FS, drop all caps (so #13 passes)
- [ ] Liveness/readiness probes

### Acceptance criteria
- App reconciles to `Healthy` via Argo CD.
- Pod runs non-root and pulls from ECR.
'@
}

# ---- #12 Network policies ------------------------------------------
$issues += @{
title  = '#12 Default-deny network policies'
labels = 'type:security,size:M'
body   = @'
Micro-segment the cluster: deny all traffic by default, then allow only what is needed. Maps to NIST **SC-7, AC-4**.

### Files to create
- [ ] `policies/network/default-deny.yaml` — deny all ingress+egress per app namespace
- [ ] `policies/network/allow-dns.yaml` — allow egress to kube-dns
- [ ] `policies/network/allow-sample-app.yaml` — explicit allows for the #11 workload
- [ ] `gitops/apps/network-policies.yaml` — Argo CD Application to deliver them

### Requirements
- [ ] Default-deny applied to every workload namespace
- [ ] DNS egress explicitly allowed (otherwise pods break)
- [ ] Document the allow-list pattern in `docs/hardening.md` (stub)

### Acceptance criteria
- A test pod cannot reach the sample app without an explicit allow.
- DNS still resolves.
'@
}

# ---- #13 Pod Security -----------------------------------------------
$issues += @{
title  = '#13 Enforce Pod Security Standards (restricted)'
labels = 'type:security,size:S'
body   = @'
Block privileged/unsafe pods using Pod Security Admission. Maps to NIST **CM-7**.

### Files to create
- [ ] `policies/pod-security/namespace-labels.yaml` — `pod-security.kubernetes.io/enforce: restricted` on workload namespaces
- [ ] `gitops/apps/pod-security.yaml` — Argo CD Application

### Requirements
- [ ] `restricted` enforced on all workload namespaces
- [ ] `kube-system` left at a documented baseline (exempted with justification)
- [ ] Verify the sample workload (#11) complies

### Acceptance criteria
- A privileged test pod is rejected.
- The sample app still deploys (it was hardened in #11).
'@
}

# ---- #14 RBAC -------------------------------------------------------
$issues += @{
title  = '#14 Least-privilege RBAC'
labels = 'type:security,size:M'
body   = @'
Define scoped RBAC roles so humans/CI get only the access they need. Maps to NIST **AC-6**.

### Files to create
- [ ] `policies/rbac/readonly-clusterrole.yaml`
- [ ] `policies/rbac/namespace-admin-role.yaml` (per-namespace, not cluster-admin)
- [ ] `policies/rbac/aws-auth-mapping.md` — how IAM roles map to k8s groups (EKS access entries)
- [ ] `gitops/apps/rbac.yaml` — Argo CD Application

### Requirements
- [ ] No additional bindings to `cluster-admin`
- [ ] Map an IAM "platform-admin" role -> namespace-admin only
- [ ] Map a "viewer" IAM role -> read-only ClusterRole

### Acceptance criteria
- A viewer identity cannot mutate resources.
- Namespace-admin cannot touch other namespaces.
'@
}

# ---- #15 Hardening doc ---------------------------------------------
$issues += @{
title  = '#15 Hardening documentation (CIS Benchmark + NSA/CISA + kube-bench)'
labels = 'type:docs,size:M'
body   = @'
Document the security posture and verify it against the CIS Kubernetes Benchmark.

### Files to create / complete
- [ ] Run `kube-bench` against the cluster; capture results
- [ ] `docs/hardening.md` — map each control (private endpoint, KMS, IMDSv2, network policy, Pod Security, RBAC) to CIS / NSA-CISA items
- [ ] `docs/kube-bench-results.md` — captured output + remediation notes for any FAIL

### Acceptance criteria
- Every hardening control implemented in earlier tickets is cross-referenced to a CIS item.
- Known kube-bench FAILs have a remediation or documented exception.
'@
}

# ---- #16 CI ---------------------------------------------------------
$issues += @{
title  = '#16 CI workflow: Terraform + manifest validation'
labels = 'type:ci,size:M'
body   = @'
Add a GitHub Actions pipeline that validates IaC and Kubernetes manifests on every PR.

### Files to create
- [ ] `.github/workflows/ci.yml`

### Jobs
- [ ] `terraform` — `fmt -check`, `init -backend=false`, `validate`, `tflint`, `tfsec` (or `trivy config`)
- [ ] `manifests` — `kubeconform` (or `kubeval`) over `gitops/` and `policies/`
- [ ] `permissions: contents: read`; pin actions by SHA

### Acceptance criteria
- PR runs green; a `terraform fmt` violation fails the job.
- An invalid manifest fails the `manifests` job.
- CI badge in README turns green.
'@
}

# ---- #17 Docs -------------------------------------------------------
$issues += @{
title  = '#17 Documentation: deploy walkthrough + architecture + NIST mapping'
labels = 'type:docs,size:M'
body   = @'
Complete the docs stubbed by earlier tickets so the repo is portfolio- and reviewer-ready.

### Files to create / complete
- [ ] `docs/deploy.md` — end-to-end: `terraform apply` -> bootstrap Argo CD -> apply root-app -> verify
- [ ] `docs/nist-control-mapping.md` — table mapping components to NIST 800-53 controls
- [ ] Architecture diagram (Mermaid in README or `docs/architecture.md`)

### Acceptance criteria
- A new engineer can stand up the platform following `deploy.md` only.
- No remaining "stub" placeholders; all README links resolve.
'@
}

# ---- #18 Finishing touches -----------------------------------------
$issues += @{
title  = '#18 Finishing touches: badges, branch protection, release tag'
labels = 'type:chore,size:S'
body   = @'
Polish for handoff.

### Tasks
- [ ] Confirm README badges render (CI, license)
- [ ] Verify branch protection on `main` (1 review, required checks, linear history)
- [ ] Required status checks = the CI jobs from #16
- [ ] Tag `v0.1.0` + CHANGELOG entry
- [ ] Add `SECURITY.md` (how to report a vuln)

### Acceptance criteria
- A PR cannot merge with failing Terraform/manifest checks.
- `v0.1.0` release exists with notes.
'@
}

# ---------------------------------------------------------------------
# Create issues
# ---------------------------------------------------------------------
$created = 0
foreach ($i in $issues) {
    $tmp = New-TemporaryFile
    Set-Content -Path $tmp.FullName -Value $i.body -Encoding utf8
    gh issue create --repo $Repo --title $i.title --body-file $tmp.FullName --assignee $Assignee --label $i.labels
    Remove-Item $tmp.FullName -Force
    $created++
}

Write-Host "Done. Created $created issues in $Repo." -ForegroundColor Green
