# hanhela.org blog

A public Hugo + Blowfish site for technical posts about Kubernetes, GitOps, Linux and cloud native infrastructure.

The repository is intentionally kept safe to publish: site content, theme configuration, container build files and a reusable Helm chart live here. Cluster manifests, credentials and environment-specific secrets belong in separate infrastructure repositories or secret stores.

The first Kubernetes deployment target is:

```text
https://hanhela.org/
```

The apex domain can be added later if the cluster Gateway and DNS setup are extended for it.

## What this repository contains

```text
.
├── .github/workflows/        # CI and container image publishing
├── archetypes/               # Hugo content archetypes
├── assets/                   # Blowfish custom CSS and images
├── config/_default/          # Hugo and Blowfish configuration
├── content/                  # English and Finnish content
├── helm/personal-blog/       # Reusable Kubernetes Helm chart
├── i18n/                     # UI translations
├── layouts/                  # Small theme overrides and home partials
├── nginx/                    # nginx-unprivileged runtime config
├── scripts/                  # Content helper scripts
├── static/                   # Static assets copied as-is
├── Dockerfile
├── Makefile
└── docker-compose.yaml
```

## Site structure

The public site is compact by design:

```text
About
Posts
CV
```

The Kubernetes Lab is shown as a featured post on the landing page instead of being treated as a separate projects section. Detailed cluster documentation and manifests live in separate GitHub repositories.

Draft posts may exist in `content/posts/`, but they are marked with `draft: true` until they are ready for the public site.

## Languages

English is served from the site root. Finnish content is served from `/fi/`.

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

## Local development

Required tools:

- Hugo extended `0.160.1`
- Go
- Docker or another compatible container builder
- Helm, when working on the chart

Download Hugo module dependencies:

```bash
make mod
```

Start the local development server:

```bash
make dev
```

Build the static site locally:

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

`make new-note` is kept as a compatibility alias for older local habits.

## Container image

The production image is built in two stages:

1. Hugo builds the static site.
2. `nginxinc/nginx-unprivileged` serves the generated files on port `8080`.

Build locally:

```bash
make docker-build HUGO_BASEURL=https://hanhela.org/
```

Run locally:

```bash
make docker-run
```

Open:

```text
http://localhost:8080/
```

The container includes a simple health endpoint:

```text
/healthz
```

## GitHub Actions

The workflow in `.github/workflows/container-image.yaml` does two things:

1. validates the Helm chart and renders the manifests
2. builds a multi-architecture image for `linux/amd64` and `linux/arm64`

On pull requests the image is built but not published. On pushes to `main`, tags and manual workflow runs, the image is published to GitHub Container Registry.

The published image name follows the repository name:

```text
ghcr.io/<owner>/<repo>
```

For this repository that is expected to be:

```text
ghcr.io/antief/hanhela.org
```

The workflow publishes branch, git tag and `sha-*` tags. For Kubernetes, prefer an immutable `sha-*` tag after the first test deployment works.

The workflow only needs the default `GITHUB_TOKEN` with these permissions:

```yaml
permissions:
  contents: read
  packages: write
```

No repository secrets are required for the default build and publish path.

## Helm chart

The chart is intentionally generic. It can expose the site through:

- a plain ClusterIP Service
- Ingress
- Gateway API HTTPRoute

Lint the chart:

```bash
make helm-lint
```

Render it locally:

```bash
make helm-template
```

Render with Gateway API enabled:

```bash
helm template personal-blog helm/personal-blog \
  --namespace blog \
  -f helm/personal-blog/values-gateway-example.yaml
```

The chart defaults to:

```yaml
image:
  repository: ghcr.io/antief/hanhela.org
  tag: main
```

For a real GitOps deployment, override the tag from the OKE GitOps repository instead of editing the chart for each release.

## Expected Kubernetes deployment model

This repository owns the blog source code, container build and reusable Helm chart.

The OKE GitOps repository should own the actual deployment values, namespace and Flux `HelmRelease`:

```text
blog repo
-> GitHub Actions
-> GHCR image
-> OKE GitOps repo HelmRelease
-> Envoy Gateway HTTPRoute
-> blog.hanhela.org
```

That separation keeps this repository safe to keep public while the cluster repository remains responsible for environment-specific configuration.

## Files that should not be committed

Generated Hugo output and local credentials should stay out of git.

Already ignored:

- `public/`
- `resources/`
- `.hugo_build.lock`
- `.env` and `.env.*`
- local kubeconfig and key-like files
- editor and OS noise

`go.mod` and `go.sum` should be committed because Hugo Modules use them to lock the Blowfish theme dependency.

## Public repository checklist

Before pushing this repository publicly, verify that:

- no real credentials, tokens or kubeconfigs are present
- generated `public/` and `resources/` output is not tracked
- the GHCR package is public if the cluster should pull it without an image pull secret
- the image includes `linux/arm64`, because the OKE cluster uses Ampere A1 nodes
- environment-specific Kubernetes values stay in the OKE GitOps repository
