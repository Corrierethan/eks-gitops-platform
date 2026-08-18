# Hardening

This is a stub for issues #12 and #13. The full hardening guide (CIS Benchmark, NSA/CISA, kube-bench) lands in issue #15.

## Network policy: default-deny + explicit allow

Every workload namespace gets a default-deny `NetworkPolicy` covering both `Ingress` and `Egress`, applied via `podSelector: {}` so it matches every pod in the namespace. On its own, this blocks all traffic in and out — including DNS.

On top of that baseline, narrow allow policies are layered in for each flow that's actually needed. NetworkPolicies are additive: a connection is permitted if *any* policy selecting the pod allows it, so the deny-all establishes the floor and each allow policy carves out one specific exception.

For `sample-app` (`policies/network/`):

- `default-deny.yaml` — denies all ingress and egress for every pod in the namespace.
- `allow-dns.yaml` — allows egress to `kube-dns` in `kube-system` on port 53 (UDP/TCP). Without this, pods can't resolve DNS at all.
- `allow-sample-app.yaml` — allows ingress from the `ingress-nginx` namespace to pods labeled `app: sample-app` on port 8080. This is the only way traffic reaches the app; nothing else in the cluster can reach it directly.

Delivered via GitOps through `gitops/apps/network-policies.yaml` (Argo CD Application, `path: policies/network`).

To add a new allowed flow for a workload, add a new `NetworkPolicy` file scoped with a specific `podSelector` (not `{}`) rather than editing `default-deny.yaml`.

## Pod Security Standards: restricted

Kubernetes' built-in Pod Security Admission (PSA) rejects non-compliant pods at the API server, before they're ever scheduled. It's driven entirely by labels on the `Namespace` object — no separate controller to install.

- `pod-security.kubernetes.io/enforce` — blocks non-compliant pods outright.
- `pod-security.kubernetes.io/audit` — logs a violation to the audit log without blocking.
- `pod-security.kubernetes.io/warn` — returns a warning to the client (`kubectl`/Argo CD) without blocking.

`sample-app` (`policies/pod-security/namespace-labels.yaml`) runs all three at `restricted`, the strictest built-in profile: non-root, no privilege escalation, all capabilities dropped, a seccomp profile required. The Deployment in `gitops/workloads/sample-app/deployment.yaml` was already written to satisfy this in #11, so nothing else needed to change to pass it.

Delivered via GitOps through `gitops/apps/pod-security.yaml`, synced one wave *before* `sample-app` itself so the namespace is already restricted by the time the workload's pods are admitted.

**`kube-system` is intentionally exempted** and left without an `enforce: restricted` label. It runs cluster-critical components (CoreDNS, kube-proxy, the AWS VPC CNI's `aws-node` daemonset) that require host networking, host PID, or elevated capabilities to function — `restricted` would reject them and break the cluster. This is an accepted, documented exception rather than an oversight; only genuine application workload namespaces are held to `restricted`.

## Verifying enforcement

```bash
# DNS should still resolve inside the namespace
kubectl -n sample-app run dns-test --rm -it --image=busybox:1.36 --restart=Never \
  -- nslookup kubernetes.default

# A pod without the ingress-nginx origin should NOT reach sample-app
kubectl -n sample-app run curl-test --rm -it --image=curlimages/curl:8.10.1 --restart=Never \
  -- curl -m 3 http://sample-app.sample-app.svc.cluster.local

# A privileged pod should be rejected by Pod Security Admission
kubectl -n sample-app run privileged-test --image=busybox:1.36 --restart=Never \
  --overrides='{"spec":{"containers":[{"name":"privileged-test","image":"busybox:1.36","securityContext":{"privileged":true}}]}}'
```

The DNS lookup should succeed; the curl should time out; the privileged pod should be rejected with a Pod Security Admission error.

## NIST mapping

- **SC-7**: Boundary protection — namespace-scoped default-deny enforces a defined network boundary per workload.
- **AC-4**: Information flow enforcement — only explicitly allowed flows (DNS, ingress-nginx → sample-app) cross that boundary.
- **CM-7**: Least functionality — Pod Security Admission at `restricted` blocks pods that request unnecessary privileges, host access, or root execution.
