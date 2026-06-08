---
title: "Running a Hugo blog on Kubernetes with Helm and GitOps"
date: 2026-06-06T21:00:00+03:00
draft: false
highlight: true
highlightWeight: 40
weight: 20
slug: "deploying-a-hugo-blog-to-kubernetes-with-helm-and-gitops"
translationKey: "deploying-simple-hugo-blog-with-helm"
summary: "A description of how this Hugo blog is packaged as a container image, published with a Helm chart and run in Kubernetes as a Flux-managed application." 
description: "A description of packaging this Hugo blog as a container image, publishing it with a Helm chart and running it in a Kubernetes cluster as a Flux-managed application."
tags:
  - Hugo
  - Helm
  - GitOps
  - Kubernetes
  - Flux
showTableOfContents: true
showTaxonomies: true
---

This blog could be published in a much simpler way. Hugo works well with GitHub Pages or Cloudflare Pages, and a static site does not need a Kubernetes cluster just to be online.

In this case, I wanted to run the blog the same way I run other small services in the cluster. The site is built into a container image, the image is published to GitHub Container Registry, and Flux installs the application into Kubernetes through a Helm chart.

The code lives in two repositories:

- [hanhela.org](https://github.com/antief/hanhela.org)
- [oke-gitops-cluster](https://github.com/antief/oke-gitops-cluster)

The first repository contains the blog itself: Hugo content, theme configuration, Dockerfile, GitHub Actions workflow and the Helm chart. The second repository contains the cluster GitOps configuration, meaning how the application is actually run in my OKE cluster.

I am not going through every YAML file in this post. The exact implementation is in the repositories. This is a short explanation of how the setup works and why the pieces are split this way.

## The basic flow

The deployment path is straightforward:

```text
Hugo source -> GitHub Actions -> GHCR -> Flux -> HelmRelease -> Kubernetes
```

When the blog source changes, GitHub Actions builds a new image and publishes it to GitHub Container Registry. My cluster runs on Oracle Cloud Ampere A1 nodes, so the image is also built for `linux/arm64`.

On the cluster side, Flux watches the GitOps repository. When the HelmRelease or its values change, Flux reconciles the cluster toward that state. In practice, I do not install the blog manually from my laptop. The change goes through Git.

## From Hugo to a runnable image

Hugo builds the site into static files. At runtime, the blog does not need Hugo, Go tooling or the source tree. It only needs a web server that can serve the generated `public/` directory.

That is why the image is built in two stages. Hugo builds the static site first. Then the finished site is copied into an nginx image. At runtime, the container is just nginx and static files.

This keeps the running image simple. From Kubernetes' point of view, the blog is a normal HTTP service: a pod listens on port 8080, a Service points traffic to the pod, and the Gateway handles public ingress.

## The Helm chart lives with the application

The blog's Helm chart is stored in the same repository as the application. It describes the basic shape of the app: Deployment, Service, probes, resource requests and a PodDisruptionBudget.

Cluster-specific values live in the GitOps repository. That is where I set things like the image repository, tag, replica count, resource limits and public hostname. The split is clean: the application repository describes what the application is, and the GitOps repository describes how this cluster runs it.

The chart can also create the HTTPRoute for the blog. In the GitOps repository I only need to give the HelmRelease the values that belong to this cluster: the Gateway, the hostname and the image settings.

The relevant HelmRelease values for a simple `blog.example.com` setup could look like this:

```yaml
values:
  fullnameOverride: blog

  image:
    repository: ghcr.io/example/blog
    tag: main
    pullPolicy: Always

  gateway:
    enabled: true
    routes:
      - name: public
        parentRefs:
          - name: public
            namespace: envoy-gateway-system
            sectionName: https
        hostnames:
          - blog.example.com
```

The same mechanism can also handle an apex domain. In my setup, one route can point the apex domain to the blog Service, while another route redirects `blog.example.com` or `www.example.com` back to the apex domain.

Helm is not strictly required for a blog like this. A simple Deployment and Service would work. I still use it because the same pattern is useful for other applications later. A small blog is a good place to keep the deployment model in shape without the application itself getting in the way.

## Routing and DNS

The blog container only serves HTTP inside the cluster. TLS, public hostnames and incoming traffic are handled through Gateway API.

The traffic path for a simple setup looks like this:

```text
blog.example.com -> Cloudflare DNS -> OCI Load Balancer -> Envoy Gateway -> Service -> Pod
```

The Gateway itself belongs to the cluster. The blog chart only creates the application route when the GitOps repository enables it through Helm values. That keeps the blog layer small: namespace, Flux GitRepository, HelmRelease and Kustomization are enough.

ExternalDNS creates the required DNS record in Cloudflare based on Kubernetes resources. That is useful in everyday use because the hostname is not a manual setting hidden in the Cloudflare UI. It follows the same GitOps process as the rest of the routing.

## What I got out of it

A static site does not need a Kubernetes cluster, and this post is not trying to argue otherwise. For many Hugo blogs, GitHub Pages or Cloudflare Pages would be a simpler and lighter option.

In this project, the blog is a small public application that lets me test the whole deployment path. A change starts in Git, the image builds automatically, Flux applies it to the cluster, and traffic is routed out through the Gateway.

The useful part is the separation of responsibilities. The blog repository contains the application. The GitOps repository contains the cluster's way of running it. The Helm chart gives the application a repeatable shape, including optional routing. Gateway and ExternalDNS handle publishing it to the outside world.

Once this works with a simple Hugo blog, the same model can be reused for other small services. The blog is a good target exactly because it is simple and easy to verify in a browser.
