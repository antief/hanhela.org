---
title: "Kubernetes Lab"
date: 2026-06-02T20:00:00+03:00
draft: false
highlight: true
highlightWeight: 10
weight: 1
slug: "kubernetes-lab"
translationKey: "kubernetes-lab"
description: "Käytännön Kubernetes- ja GitOps-ympäristö Oracle Kubernetes Enginen päällä."
summary: "OKE-pohjainen Kubernetes- ja GitOps-ympäristö, jossa on ingress, TLS, observability ja julkinen tilaseuranta."
tags:
  - Kubernetes
  - OKE
  - GitOps
  - Flux
  - Observability
showTableOfContents: true
showTaxonomies: true
---

Tämä postaus toimii lähtökohtana Kubernetes Lab -ympäristön dokumentoinnille. Ympäristö pyörii Oracle Kubernetes Enginen päällä ja sitä hallitaan GitOps-mallilla. Tavoitteena on pitää julkinen sivusto kevyenä ja siirtää tarkempi tekninen dokumentaatio GitHubiin.

## Mikä Kubernetes Lab on?

Kubernetes Lab on pieni käytännön Kubernetes-ympäristö, joka on rakennettu oppimista ja osaamisen esittelyä varten. Se ei ole suuri tuotantoalusta, mutta siinä käytetään samoja työkaluja ja toimintamalleja, joita käytetään oikeissa cloud native -ympäristöissä.

Keskeisiä teemoja ovat:

- Kubernetesin perusteet hallitussa pilviympäristössä
- GitOps-pohjainen klusterinhallinta
- sovellusten julkaisu deklaratiivisilla manifesteilla
- ingress, DNS ja TLS-sertifikaattien automatisointi
- monitorointi, dashboardit ja uptime-seuranta
- teknisten ratkaisujen dokumentointi uudelleenkäytettävällä tavalla

## Klusterin yleiskuva

Klusteri pyörii Oracle Kubernetes Enginen päällä. OKE on tähän tarkoitukseen kiinnostava alusta, koska se tarjoaa realistisen hallitun Kubernetes-ympäristön ja hyödyllisen free tier -mallin pitkäjänteiseen harjoitteluun.

Kokonaisuuteen kuuluu yleisellä tasolla:

- Oracle Kubernetes Engine Kubernetes-alustana
- GitHub manifestien ja dokumentaation lähteenä
- Flux GitOps-rekonciliaatiota varten
- Helm/Kustomize-pohjaiset sovellusmääritykset
- cert-manager TLS-sertifikaatteja varten
- tarvittaessa ulkoisen DNS:n automatisointi
- valittujen palveluiden monitorointi ja uptime-seuranta

## GitOps-työnkulku

Klusteria hallitaan deklaratiivisesti. Muutokset tehdään Gitiin, tarkistetaan paikallisesti ja GitOps-ohjain vie tavoitetilan klusteriin.

Työnkulku on tarkoituksella yksinkertainen:

1. päivitä manifestit tai Helm-arvot Gitissä
2. tee commit ja push
3. anna Fluxin sovittaa klusteri tavoitetilaan
4. tarkista lopputulos Kubernetesista ja monitorointityökaluista

Tämä tekee klusterista helpommin ymmärrettävän, uudelleenrakennettavan ja dokumentoitavan. Samalla ajossa oleva ympäristö pysyy lähellä sitä, mitä repossa kuvataan.

## Julkiset näkymät

Sivustolle voidaan myöhemmin linkittää valikoituja julkisia näkymiä ympäristöstä, esimerkiksi:

- julkinen status-sivu
- valittu Grafana-dashboard tai kuvakaappauksia
- GitHub-repo
- tekninen dokumentaatio

Linkitettävien näkymien pitää olla tarkoituksella julkisia ja mielellään vain luku -tilassa. Hallintanäkymät ja arkaluontoiset infra-yksityiskohdat pidetään yksityisinä.

## Repositoriot

Kokonaisuus on jaettu kahteen GitHub-repoon:

- `oke-gitops-cluster`: ajossa olevan OKE-klusterin GitOps-repo
- `oke-gitops-template`: uudelleenkäytettävä pohja vastaavan OKE/GitOps-ympäristön rakentamiseen

Tämä jako pitää oikean klusterin asetukset erillään yleiskäyttöisestä template-pohjasta.

## Mitä tämä osoittaa?

Tämän labin tarkoitus on näyttää käytännön kokemusta cloud native -infrasta, ei vain listata teknologioita CV:ssä. Oleellista on koko työnkulku: klusterin rakentaminen, oikeiden palveluiden ajaminen, konfiguraation pitäminen Gitissä ja teknisten päätösten selkeä dokumentointi.

## Seuraavat askeleet

Tämän postauksen seuraavaan versioon kannattaa lisätä:

- yksinkertainen arkkitehtuurikaavio tai taulukko
- linkit julkiseen status-sivuun ja repoon
- lyhyt selitys OKE free tier -asetelmasta
- valittuja kuvakaappauksia tai vain luku -dashboardeja
- linkit tarkempaan GitHub-dokumentaatioon
