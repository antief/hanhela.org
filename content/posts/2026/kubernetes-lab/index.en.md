---
title: "Kubernetes Lab"
date: 2026-06-02T20:00:00+03:00
draft: false
highlight: true
highlightWeight: 10
weight: 1
slug: "kubernetes-lab"
translationKey: "kubernetes-lab"
description: "A practical Kubernetes and GitOps lab running on Oracle Kubernetes Engine."
summary: "OKE-based Kubernetes and GitOps lab with ingress, TLS, observability and public status monitoring."
tags:
  - Kubernetes
  - OKE
  - GitOps
  - Flux
  - Observability
showTableOfContents: true
showTaxonomies: true
---

This post is the starting point for documenting my Kubernetes lab. The environment runs on Oracle Kubernetes Engine and is managed with a GitOps workflow. The goal is to keep the public site lightweight while keeping the deeper technical documentation in GitHub.

## What this lab is

The lab is a small, practical Kubernetes environment built for learning and demonstrating cloud native infrastructure work. It is not meant to be a large production platform, but it uses the same kinds of tools and patterns that are common in real environments.

The focus areas are:

- Kubernetes fundamentals in a managed cloud environment
- GitOps-based cluster management
- application delivery through declarative manifests
- ingress, DNS and TLS certificate automation
- monitoring, dashboards and uptime visibility
- documenting technical decisions in a reusable way

## Cluster overview

The cluster runs on Oracle Kubernetes Engine. The main reason for using OKE is that it provides a realistic managed Kubernetes environment with a generous free tier, which makes it useful for long-term learning and experimentation.

At a high level, the lab includes:

- Oracle Kubernetes Engine as the Kubernetes platform
- GitHub as the source of truth for manifests and documentation
- Flux for GitOps reconciliation
- Helm/Kustomize-based application definitions
- cert-manager for TLS certificates
- external DNS automation where applicable
- monitoring and uptime checks for selected services

## GitOps workflow

The cluster is managed declaratively. Changes are made in Git, reviewed locally and then reconciled into the cluster by the GitOps controller.

The workflow is intentionally simple:

1. update manifests or Helm values in Git
2. commit and push the change
3. let Flux reconcile the desired state
4. verify the result from Kubernetes and monitoring tools

This makes the cluster easier to understand, rebuild and document. It also keeps the running environment close to what is described in the repository.

## Live services

The site can later link to selected public views of the environment, such as:

- public status page
- selected Grafana dashboard or screenshots
- GitHub repository
- technical documentation

Only safe, read-only and intentionally public views should be linked here. Administrative interfaces and sensitive infrastructure details should stay private.

## Repositories

The lab is split into two GitHub repositories:

- `oke-gitops-cluster`: the live GitOps repository for the running OKE cluster
- `oke-gitops-template`: a reusable starting point for building a similar OKE GitOps environment

This split keeps the real cluster configuration separate from the reusable template.

## What this demonstrates

This lab is meant to show practical experience with cloud native infrastructure rather than just listing technologies on a CV. The important part is the full workflow: building the cluster, running real services, keeping the configuration in Git and documenting the decisions clearly.

## Next steps

The next version of this post should add:

- a simple architecture diagram or table
- links to the public status page and repository
- a short explanation of the OKE free tier setup
- selected screenshots or read-only dashboards
- links to deeper documentation in GitHub
