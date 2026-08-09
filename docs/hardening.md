# Hardening

This is a stub for issue #12. The full hardening guide (CIS Benchmark, NSA/CISA, kube-bench) lands in issue #15.

## Network policy: default-deny + explicit allow

Every workload namespace gets a default-deny `NetworkPolicy` covering both `Ingress` and `Egress`, applied via `podSelector: {}` so it matches every pod in the namespace. On its own, this blocks all traffic in and out — including DNS.

On top of that baseline, narrow allow policies are layered in for each flow that's actually needed. NetworkPolicies are additive: a connection is permitted if *any* policy selecting the pod allows it, so the deny-all establishes the floor and each allow policy carves out one specific exception.

For `sample-app` (`policies/network/`):

- `default-deny.yaml` — denies all ingress and egress for every pod in the namespace.
- `allow-dns.yaml` — allows egress to `kube-dns` in `kube-system` on port 53 (UDP/TCP). Without this, pods can't resolve DNS at all.
- `allow-sample-app.yaml` — allows ingress from the `ingress-nginx` namespace to pods labeled `app: sample-app` on port 8080. This is the only way traffic reaches the app; nothing else in the cluster can reach it directly.

Delivered via GitOps through `gitops/apps/network-policies.yaml` (Argo CD Application, `path: policies/network`).

To add a new allowed flow for a workload, add a new `NetworkPolicy` file scoped with a specific `podSelector` (not `{}`) rather than editing `default-deny.yaml`.

## Verifying enforcement

```bash
# DNS should still resolve inside the namespace
kubectl -n sample-app run dns-test --rm -it --image=busybox:1.36 --restart=Never \
  -- nslookup kubernetes.default

# A pod without the ingress-nginx origin should NOT reach sample-app
kubectl -n sample-app run curl-test --rm -it --image=curlimages/curl:8.10.1 --restart=Never \
  -- curl -m 3 http://sample-app.sample-app.svc.cluster.local
```

The DNS lookup should succeed; the curl should time out.

## NIST mapping

- **SC-7**: Boundary protection — namespace-scoped default-deny enforces a defined network boundary per workload.
- **AC-4**: Information flow enforcement — only explicitly allowed flows (DNS, ingress-nginx → sample-app) cross that boundary.
