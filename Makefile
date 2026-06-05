HUGO ?= hugo
IMAGE ?= ghcr.io/antief/blog
TAG ?= latest
HUGO_BASEURL ?= http://localhost:8080/
NAMESPACE ?= blog
RELEASE ?= personal-blog
CHART ?= helm/personal-blog
YEAR ?= $(shell date +%Y)

.PHONY: help mod dev build clean new-post new-note docker-build docker-run helm-lint helm-template helm-install

help:
	@echo "Available targets:"
	@echo "  mod          - Download Hugo modules"
	@echo "  dev          - Start Hugo development server"
	@echo "  build        - Build static site into ./public"
	@echo "  clean        - Remove Hugo build output"
	@echo "  new-post     - Create a bilingual post bundle (NAME=my-post [YEAR=2026])"
	@echo "  new-note     - Backwards-compatible alias for new-post"
	@echo "  docker-build - Build production Docker image (supports HUGO_BASEURL=...)"
	@echo "  docker-run   - Run production image locally on :8080"
	@echo "  helm-lint    - Lint Helm chart"
	@echo "  helm-template - Render Helm chart locally"
	@echo "  helm-install - Install/upgrade release"

mod:
	$(HUGO) mod tidy

dev:
	$(HUGO) server --bind 127.0.0.1 --disableFastRender --baseURL http://localhost:1313/

build:
	$(HUGO) --minify

clean:
	rm -rf public resources .hugo_build.lock

new-post:
	@test -n "$(NAME)" || (echo "Usage: make new-post NAME=my-post [YEAR=2026]" && exit 1)
	YEAR=$(YEAR) sh scripts/new-post-bundle.sh "$(NAME)"

new-note: new-post

docker-build:
	docker build --build-arg HUGO_BASEURL=$(HUGO_BASEURL) -t $(IMAGE):$(TAG) .

docker-run:
	docker run --rm -p 8080:8080 --read-only --tmpfs /tmp $(IMAGE):$(TAG)

helm-lint:
	helm lint $(CHART)

helm-template:
	helm template $(RELEASE) $(CHART) --namespace $(NAMESPACE)

helm-install:
	helm upgrade --install $(RELEASE) $(CHART) --namespace $(NAMESPACE) --create-namespace
