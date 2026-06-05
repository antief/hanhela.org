---
title: "Deploying a simple Hugo blog with Helm"
date: 2026-06-03T09:00:00+03:00
draft: true
highlight: false
highlightWeight: 20
weight: 20
slug: "deploying-simple-hugo-blog-with-helm"
translationKey: "deploying-simple-hugo-blog-with-helm"
description: "Draft notes for a future writeup about packaging this Hugo blog with Helm and deploying it to Kubernetes."
summary: "Packaging a simple Hugo blog with Helm and deploying it to Kubernetes."
tags:
  - Hugo
  - Helm
  - GitOps
  - Kubernetes
showTableOfContents: true
showTaxonomies: true
---

This draft is kept out of the published site until the deployment has been tested end to end.

The post will document how this Hugo site is packaged with Helm and deployed to Kubernetes through a GitOps workflow.

## Planned topics

- Hugo static site build
- container image and nginx runtime
- Helm chart structure
- GitOps deployment flow
- production values and environment-specific configuration
- practical notes from running the site in Kubernetes
