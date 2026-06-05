---
title: "Testing high availability in Kubernetes"
date: 2026-06-05T12:00:00+03:00
draft: false
highlight: true
highlightWeight: 30
weight: 30
slug: "testing-high-availability-in-kubernetes"
translationKey: "testing-high-availability-with-kubernetes"
description: "A practical test of how a small OKE cluster handles replacing a worker node from the point of view of public traffic."
summary: "A realistic HA test in Oracle Kubernetes Engine: the node replacement worked, but fully uninterrupted public traffic was harder than it first looked."
tags:
  - Kubernetes
  - High Availability
  - Node Maintenance
  - OKE
  - Envoy Gateway
showTableOfContents: true
showTaxonomies: true
---

I wanted to test what actually happens in my Kubernetes cluster when one worker node is replaced while the cluster is running. The final pod status alone does not tell what the maintenance looks like from the user's point of view. That is why I tested it from the outside, against a public service.

The test was done in my [Kubernetes Lab](/posts/kubernetes-lab/). Public traffic came through an OCI Network Load Balancer to Envoy Gateway, and from there to a small [`whoami`](https://whoami.hanhela.org) service.

The cluster had three worker nodes, Longhorn storage and FluxCD reconciling the manifests. The `whoami` service itself does not use Longhorn, but Longhorn mattered for this test because replacing a node affects the whole cluster. If storage is left in a bad state, the node replacement has not really succeeded, even if the small test service happens to answer.

The goal was simple: replace one node and see whether public HTTP traffic gets interrupted.

## Starting point

Before the test I checked that the cluster was healthy:

```bash
kubectl get nodes -o wide
kubectl -n envoy-gateway-system get ds,pods -o wide
kubectl -n whoami get ds,pods -o wide
kubectl -n longhorn-system get volumes.longhorn.io
flux get kustomizations -n flux-system
```

Everything looked as expected. The nodes were `Ready`, Envoy Gateway was running as a DaemonSet, there were three `whoami` pods, and the Longhorn volumes were healthy.

Against the [`whoami`](https://whoami.hanhela.org) service I ran a small, vibe-coded curl loop:

```bash
while true; do
  ts="$(date --iso-8601=seconds)"
  tmp="$(mktemp)"

  metrics="$(curl -sS -m 3 -o "$tmp" \
    -w 'code=%{http_code} time=%{time_total}' \
    https://whoami.hanhela.org/ 2>&1)"
  rc=$?

  if [ "$rc" -eq 0 ] && printf '%s' "$metrics" | grep -q 'code=200'; then
    host="$(sed -n 's/^Hostname: //p' "$tmp" | head -1)"
    echo "$ts OK $metrics host=$host"
  else
    echo "$ts FAIL rc=$rc $metrics"
  fi

  rm -f "$tmp"
  sleep 1
done | tee /tmp/whoami-ha-test.log
```

This should show once per second whether the request returned HTTP 200 or timed out, and which `whoami` pod responded.

## Replacing the node

The node replacement was done with a small script that replaces one OKE node pool node at a time. Before doing anything, the script runs a dry-run, checks the target version and verifies the Longhorn state. The code is on [GitHub](https://github.com/antief/oke-gitops-cluster/tree/main/terraform/oci-oke/scripts).

The actual run looked like this:

```bash
./scripts/replace-outdated-nodes.sh --force --max-replacements 1 \
  | tee /tmp/oke-node-replacement.log
```

From the script's point of view the test eventually went well. The old node was replaced, the new node joined the cluster, and Longhorn returned to a healthy state. Stale replicas left behind by the removed node were cleaned up.

The end of the log showed what I was looking for:

```text
Deleting stale Longhorn replica ... on removed node ...
Removing stale Longhorn node ... after Kubernetes node removal
Longhorn is healthy
Replacement completed for ocid1.instance...
Done. Replaced nodes in this run: 1
```

So from the cluster's internal point of view, the node replacement succeeded.

## Was it uninterrupted?

Not completely.

During the node replacement the test saw a few timeouts:

```text
FAIL rc=28 curl: (28) Operation timed out after 3002 milliseconds with 0 bytes received
```

That was the most important result of the test. From Kubernetes' point of view everything recovered cleanly, but from the user's point of view some requests failed during the maintenance window.

I cannot prove the exact cause from this test alone. My best guess is that the short interruption was caused by timing between several moving parts: the old node leaving, the new node joining, the OCI Network Load Balancer updating its backends, and Envoy Gateway pods starting on the new node. Early in the new node's lifecycle I also saw a Flannel-related error:

```text
plugin type="flannel" failed (add):
loadFlannelSubnetEnv failed:
open /run/flannel/subnet.env: no such file or directory
```

That fixed itself, but it is a useful reminder that a node being `Ready` does not always mean it is immediately ready to receive public traffic.

## What did I learn?

The test did not prove perfect zero-downtime HA. It was still a useful test.

The node was replaced successfully, the new node joined the cluster and Longhorn returned to a healthy state. After the maintenance the internal cluster state looked good. From the public traffic point of view the result was not perfect, because a few requests timed out.

That is the main lesson. High availability should not be judged only from inside the cluster. `kubectl get pods` can look good in the end, while a user may still have seen an error during maintenance. A simple curl loop from the outside told me more here than Kubernetes status alone.

For me, the test was successful even though the result was not perfect. I now have a better idea of how this cluster behaves during node maintenance, and where its limits start to show.
