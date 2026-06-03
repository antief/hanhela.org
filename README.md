# hanhela.org

A personal Hugo + Blowfish site for posts and practical writeups about Kubernetes, GitOps, Linux and cloud native infrastructure.

The site is built with **Hugo**, **Blowfish**, **Docker**, **Helm** and **Kubernetes**. It is intended to run as a lightweight static site in an Oracle Kubernetes Engine based GitOps environment.

The public site has a compact structure: **About**, **Posts** and **CV**. The Kubernetes Lab is kept visible as a featured post on the landing page instead of using a separate Projects section. Detailed technical documentation and manifests belong in separate GitHub repositories.

## Purpose

This repository supports four goals:

- provide a compact personal site at `hanhela.org`
- publish technical posts and notes in a simple Blowfish layout
- keep the Kubernetes Lab visible as the main featured technical example
- keep detailed implementation notes and cluster manifests in GitHub repositories

## Main sections

```text
About
Posts
CV
```

The landing page uses a small custom Blowfish home partial: it keeps the normal profile hero and renders selected `highlight: true` posts below it with Blowfish's own article card partial. This avoids custom card markup while still keeping a dedicated Highlights/Nostot section.

## Languages

English is the primary language and is served from the site root.

```text
/       English
/fi/    Finnish
```

The site uses filename-based multilingual Hugo content:

```text
content/_index.en.md
content/_index.fi.md
content/posts/.../index.en.md
content/posts/.../index.fi.md
```

Translations are connected with matching `translationKey` values.

## Repository structure

```text
.
├── Dockerfile
├── Makefile
├── README.md
├── docker-compose.yaml
├── go.mod
├── go.sum
├── archetypes/
│   └── post-bundle/
├── assets/
│   ├── css/
│   └── img/
├── config/
│   └── _default/
├── content/
│   ├── _index.en.md
│   ├── _index.fi.md
│   ├── about/
│   ├── cv/
│   └── posts/
├── data/
├── i18n/
├── layouts/
├── nginx/
├── scripts/
├── static/
└── helm/
    └── personal-blog/
```

## Local development

Install locally:

- Hugo extended `0.160.1`
- Go
- Docker
- Helm
- kubectl

Download Hugo module dependencies:

```bash
make mod
```

Start the local Hugo development server:

```bash
make dev
```

Build the static site:

```bash
make build
```

Clean generated Hugo output:

```bash
make clean
```

Create a new bilingual post bundle:

```bash
make new-post NAME=my-post
```

`make new-note` still works as a compatibility alias, but new writing should use posts.

## Featured posts

The landing page highlight cards are selected from posts with front matter like this:

```yaml
highlight: true
highlightWeight: 10
```

Lower `highlightWeight` values are shown first. When no highlighted posts exist, the home partial falls back to normal posts.

## Runtime model

The runtime model is intentionally simple:

1. Hugo builds the site into static files.
2. A small nginx-unprivileged image serves the generated content on port `8080`.
3. The Helm chart can expose the service through Service-only, Ingress or Gateway API HTTPRoute mode.

This keeps the site stateless, easy to rebuild and suitable for GitOps-based deployment.

## Kubernetes Lab repositories

The public site introduces the lab as a featured post. There is intentionally no separate projects page in the navigation. The detailed implementation should live in the cluster repositories:

- `oke-gitops-cluster` - the GitOps repository for the running OKE cluster
- `oke-gitops-template` - a reusable template for similar OKE/GitOps environments

## Generated files

These files should not be committed:

- `public/`
- `resources/`
- `.hugo_build.lock`

`go.mod` and `go.sum` should be committed because Hugo Modules use them to lock the Blowfish theme dependency.
