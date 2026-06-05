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
summary: "An OKE-based Kubernetes and GitOps lab with Gateway API-based HTTPS routing, TLS, metrics, logs and public status monitoring."
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

This is my personal Kubernetes lab running on [Oracle Cloud](https://www.oracle.com/cloud/free/). It is not just a local test setup, but a small live cloud environment where I practice Kubernetes, GitOps, cloud infrastructure, application delivery, secrets management, metrics and logging.

The infrastructure is built with OpenTofu, and Kubernetes resources are managed from Git with FluxCD. Public HTTPS traffic goes through an OCI Network Load Balancer and Envoy Gateway. TLS, DNS, storage, metrics, logs and external status monitoring are part of the same Git-managed setup.

In practice, the lab shows how a cloud-based Kubernetes environment can be built repeatably, managed through GitOps and monitored from the outside. It also gives me a realistic place to test upgrades, deployment patterns and infrastructure changes without treating Kubernetes as a purely local sandbox.

## Links

If you want to inspect the environment directly, these are the main entry points. The repositories show how the lab is built, Grafana exposes selected metrics and the status page shows external availability monitoring.

{{< overview-table >}}

| Part | Link | Description |
|---|---|---|
| Cluster repository | [oke-gitops-cluster](https://github.com/antief/oke-gitops-cluster) | The infrastructure and GitOps structure of the running OKE lab. |
| Template | [oke-gitops-template](https://github.com/antief/oke-gitops-template) | A more reusable starting point for building a similar cluster. |
| Grafana | [public dashboard](https://grafana.hanhela.org/public-dashboards/63d97cbd15c246c69ee103278182685e) | A limited public view into selected cluster metrics. |
| Status | [status.hanhela.org](https://status.hanhela.org/) | External uptime monitoring for selected services. |

{{< /overview-table >}}

## Why this lab exists

I wanted an environment where Kubernetes is not just a set of isolated commands or local examples. The goal is to keep a small but real setup running, with the same basic concerns that appear in larger environments: networking, application delivery, certificates, secrets, storage, monitoring and documentation.

Oracle Kubernetes Engine is a good fit for this because it makes the lab inexpensive to run, and in some cases it can even be run for free. At the same time, the setup is still close enough to a normal cloud environment, because it runs on a managed Kubernetes service instead of a local test cluster.

I also wanted the lab to be operated mostly from the command line instead of through individual clicks in a cloud console. The cloud console is still useful for inspection and management, but the main workflow for this lab is built around code, the command line and Git. The cluster can be initialized, validated, brought up, torn down and rebuilt in a repeatable way. Node updates are also handled with a separate script.

## What this demonstrates

Through this lab, I have practiced especially:

- building cloud infrastructure as code
- managing Kubernetes resources with a GitOps workflow
- routing HTTPS traffic with Gateway API
- automating certificates, DNS and secrets
- using persistent storage inside Kubernetes
- building metrics, logs and external availability monitoring
- documenting the environment so that it can be understood and rebuilt

The important part is not any single tool, but how the pieces work together. Infrastructure, GitOps, application delivery, monitoring and documentation all support the same environment instead of remaining separate experiments.

## How it fits together

The basic idea is simple: infrastructure is built as code, applications are described as manifests, and changes are applied through Git.

```go
Changes:
GitHub → FluxCD → Kubernetes resources

Public traffic:
Internet → OCI Network Load Balancer → Envoy Gateway → Kubernetes Service → Pod
```

Changes are made in Git first. FluxCD watches the repository and moves the cluster towards the desired state described there. Public traffic first reaches the OCI Network Load Balancer. From there, Envoy Gateway routes HTTPS traffic to the right Kubernetes services.

This keeps application delivery and traffic routing as separate but understandable parts of the same system.

## Core components

You do not need to know every component in advance. The main point is that each part has a clear job: infrastructure is built as code, traffic is routed in a controlled way, secrets are kept out of manifests, and the environment is monitored both from the inside and the outside.

{{< overview-table >}}

| Part | Components | Description |
|---|---|---|
| Kubernetes platform | [OKE](https://www.oracle.com/cloud/cloud-native/kubernetes-engine/) | Managed Kubernetes cluster in Oracle Cloud. |
| IaC | [OpenTofu](https://opentofu.org/) | Builds the OCI network, OKE cluster and supporting resources. |
| GitOps | [FluxCD](https://fluxcd.io/) | Keeps the cluster state aligned with the Git repository. |
| Public traffic | [OCI Network Load Balancer](https://docs.oracle.com/en-us/iaas/Content/NetworkLoadBalancer/home.htm), [Envoy Gateway](https://gateway.envoyproxy.io/), [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/) | Routes public HTTPS traffic to services without traditional Ingress resources. |
| TLS and DNS | [cert-manager](https://cert-manager.io/), [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/), [Cloudflare DNS-01](https://cloudflare.com/) | Creates TLS certificates and manages DNS records automatically. |
| Secrets | [OCI Vault](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm), [External Secrets Operator](https://external-secrets.io/) | Stores secrets in OCI Vault and syncs them into Kubernetes. |
| Storage | [Longhorn](https://longhorn.io/) | Provides the persistent storage layer inside the cluster. |
| Metrics and logs | [Prometheus](https://prometheus.io/), [Grafana](https://grafana.com/), [Loki](https://grafana.com/oss/loki/), [Alloy](https://grafana.com/oss/alloy) | Collects metrics and logs and makes them visible in dashboards. |
| Uptime monitoring | [Better Stack](https://betterstack.com/) | Monitors service availability from outside the cluster. |

{{< /overview-table >}}

## GitOps workflow

Changes are made in [GitHub](https://github.com/antief/oke-gitops-cluster) first. FluxCD watches the repository and keeps the cluster aligned with the desired state described there.

In practice, a new service is added by creating the manifests in the repository and merging the change through Git. Once the change reaches the main branch, FluxCD detects it and starts reconciling the cluster towards the new state. If something goes wrong, the issue is visible both in Flux status and in the monitoring tools.

The repository is split into two main sides. The `terraform/` directory contains the infrastructure side of the lab: base cloud resources, the OKE cluster itself and the Flux bootstrap. The `gitops/` directory contains the Kubernetes side: cluster-specific configuration, infrastructure controllers, add-ons and application manifests.

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

## Template repository

The main cluster repository describes my own running environment. Alongside it, I created a separate [OKE GitOps template](https://github.com/antief/oke-gitops-template), which is a cleaner starting point for building a similar cluster.

The template does not try to hide everything behind automation. The point is that the structure remains understandable: what OpenTofu builds, what FluxCD installs into the cluster and how the different layers fit together.

## Scope

This is a personal lab, not a finished production platform. I keep it intentionally limited so that it stays maintainable and useful as a learning environment.

The scope is intentional. A small environment is easier to keep understandable, documented and genuinely maintainable. That makes it a better learning environment than a large collection of unrelated services.

The goal is not to run as many services as possible. The goal is to keep a setup where cloud infrastructure, Kubernetes, GitOps, application delivery, metrics, logs and documentation support each other.
