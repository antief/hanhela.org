---
title: "Kubernetes Lab"
draft: false
showDate: false
highlight: true
highlightWeight: 10
weight: 1
slug: "kubernetes-lab"
translationKey: "kubernetes-lab"
description: "A practical Kubernetes and GitOps environment running on Oracle Kubernetes Engine."
summary: "An OKE-based Kubernetes and GitOps lab with Gateway API-based HTTPS routing, TLS, observability and public status monitoring."
tags:
  - Kubernetes
  - OKE
  - GitOps
  - Flux
  - Observability
showTableOfContents: true
showTaxonomies: true
---

## TL;DR

This is my personal Kubernetes lab running on [Oracle Cloud](https://www.oracle.com/cloud/free/). It is not just a local test setup, but a small live environment where I practice cloud infrastructure, GitOps, application delivery, secrets management and observability.

The infrastructure is built with OpenTofu, and Kubernetes resources are managed from Git with FluxCD. Public HTTPS traffic goes through an OCI Network Load Balancer, Envoy Gateway and Gateway API. TLS, DNS, storage, metrics, logs and external status monitoring are part of the same Git-managed setup.

## Links

{{< overview-table >}}

| Part | Link | Description |
|---|---|---|
| Cluster repository | [oke-gitops-cluster](https://github.com/antief/oke-gitops-cluster) | The infrastructure and GitOps structure of the running OKE lab. |
| Template | [oke-gitops-template](https://github.com/antief/oke-gitops-template) | A more reusable starting point for building a similar cluster. |
| Grafana | [public dashboard](https://grafana.hanhela.org/public-dashboards/63d97cbd15c246c69ee103278182685e) | A limited public view into selected cluster metrics. |
| Status | [status.hanhela.org](https://status.hanhela.org/) | External availability monitoring for selected services. |

{{< /overview-table >}}

## Why this lab exists

I wanted an environment where Kubernetes is not just a set of isolated commands or local examples. The goal is to keep a small but real setup running, with the same basic concerns that appear in larger environments: networking, application delivery, certificates, secrets, storage, monitoring and documentation.

Oracle Kubernetes Engine is a good fit for this because Oracle Cloud's Ampere A1 resources make it possible to run the lab for a long time at very low cost. At the same time, the setup is still close enough to a normal cloud environment, because it runs on a managed Kubernetes service instead of a local test cluster.

## What I use it for

{{< overview-table >}}

| Part | Description |
|---|---|
| Cloud infrastructure | The OKE cluster, VCN network, subnets, load balancers and supporting resources are built with OpenTofu. |
| GitOps | The desired cluster state lives in GitHub, and FluxCD reconciles changes into the cluster. |
| Public application delivery | HTTPS traffic goes through an OCI Network Load Balancer, Envoy Gateway and Gateway API. |
| TLS and DNS | cert-manager requests certificates, and ExternalDNS manages DNS records through Cloudflare. |
| Secrets | Secrets are stored in OCI Vault and synced into Kubernetes with External Secrets Operator. |
| Storage | Longhorn provides the persistent storage layer inside the cluster. |
| Observability | Prometheus, Grafana, Loki and Alloy collect metrics and logs. |
| Availability monitoring | Better Stack monitors selected services from outside the cluster. |

{{< /overview-table >}}

## How it fits together

The basic idea is simple: infrastructure is built as code, applications are described as manifests, and changes are applied through Git.

```text
GitHub
  → FluxCD
    → OKE
      → Envoy Gateway / Gateway API
        → Kubernetes services
```

Public traffic first reaches the OCI Network Load Balancer. From there, Envoy Gateway and Gateway API routes direct HTTPS traffic to the right Kubernetes services.

## Core components

{{< overview-table >}}

| Part | Components | Description |
|---|---|---|
| Kubernetes | [OKE](https://www.oracle.com/cloud/cloud-native/kubernetes-engine/) | Managed Kubernetes cluster in Oracle Cloud. |
| Infrastructure | [OpenTofu](https://opentofu.org/) | Builds the OCI network, OKE cluster and supporting resources. |
| GitOps | [FluxCD](https://fluxcd.io/) | Reconciles the cluster state from the Git repository. |
| Public traffic | [OCI Network Load Balancer](https://docs.oracle.com/en-us/iaas/Content/NetworkLoadBalancer/home.htm), [Envoy Gateway](https://gateway.envoyproxy.io/), [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/) | Routes public HTTPS traffic to services without traditional Ingress resources. |
| TLS and DNS | [cert-manager](https://cert-manager.io/), [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/), [Cloudflare DNS-01](https://cloudflare.com/) | Creates TLS certificates and manages DNS records automatically. |
| Secrets | [OCI Vault](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm), [External Secrets Operator](https://external-secrets.io/) | Stores secrets in OCI Vault and syncs them into Kubernetes. |
| Storage | [Longhorn](https://longhorn.io/) | Provides the persistent storage layer inside the cluster. |
| Observability | [Prometheus](https://prometheus.io/), [Grafana](https://grafana.com/), [Loki](https://grafana.com/oss/loki/), [Alloy](https://grafana.com/oss/alloy) | Collects metrics and logs and makes them visible in dashboards. |
| Status monitoring | [Better Stack](https://betterstack.com/) | Monitors service availability from outside the cluster. |

{{< /overview-table >}}

## GitOps workflow

Changes are made in GitHub first. FluxCD watches the repository and reconciles the cluster towards the desired state described there.

The Kubernetes side of the repository is split into layers:

{{< overview-table >}}

| Part | Description |
|---|---|
| Controllers | Cluster controllers such as cert-manager, Envoy Gateway, External Secrets Operator, Longhorn and metrics-server. |
| Configs | Configuration used by those controllers, such as Gateways, ClusterIssuers, ExternalSecrets and StorageClasses. |
| Addons | Supporting components such as ExternalDNS, kube-prometheus-stack, Loki, Alloy and the Better Stack heartbeat. |
| Apps | The actual applications and test services. |

{{< /overview-table >}}

This keeps the dependencies fairly clear. Controllers are installed first, then their configuration, then supporting add-ons and finally the applications.

## What this demonstrates

Its purpose is to show that I understand the moving parts around a Kubernetes environment at a practical level.

{{< overview-table >}}

| Part | Description |
|---|---|
| Kubernetes | The cluster uses real Kubernetes resources, public service routing, storage and operational components. |
| Cloud infrastructure | OCI resources are built with OpenTofu instead of being clicked together manually. |
| GitOps | Changes go through GitHub, and FluxCD handles reconciliation inside the cluster. |
| Networking and delivery | Public HTTPS traffic is built around OCI NLB, Envoy Gateway and Gateway API. |
| Secrets management | Secrets are not stored directly in Git, but synced into the cluster from OCI Vault. |
| Observability | Metrics, logs, dashboards and external availability monitoring are part of the environment. |
| Documentation | The repository and blog posts describe how the environment is built and why certain choices were made. |

{{< /overview-table >}}

## Template repository

The main cluster repository describes my own running environment. Alongside it, I created a separate [OKE GitOps template](https://github.com/antief/oke-gitops-template), which is a cleaner starting point for building a similar cluster.

The template does not try to hide everything behind automation. The point is that the structure remains understandable: what OpenTofu builds, what FluxCD installs into the cluster and how the different layers fit together.

## Scope

This is a personal lab, not a finished production platform. I keep it intentionally limited so that it stays maintainable and useful as a learning environment.

The goal is not to run as many services as possible. The goal is to keep a setup where cloud infrastructure, Kubernetes, GitOps, application delivery, observability and documentation support each other.
