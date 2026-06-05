---
title: "Kubernetes Lab"
draft: false
showDate: false
highlight: true
highlightWeight: 10
weight: 1
slug: "kubernetes-lab"
translationKey: "kubernetes-lab"
description: "Käytännön Kubernetes- ja GitOps-ympäristö Oracle Kubernetes Enginen päällä."
summary: "OKE-pohjainen Kubernetes- ja GitOps-lab, jossa on Gateway API -pohjainen HTTPS-reititys, TLS, observability ja julkinen tilaseuranta."
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

Tämä on oma Kubernetes-labini [Oracle Cloudissa](https://www.oracle.com/cloud/free/). Se ei ole pelkkä paikallinen kokeilu, vaan oikeasti ajossa oleva ympäristö, jossa harjoittelen pilvi-infraa, GitOpsia, sovellusjulkaisua, salaisuuksien hallintaa ja observabilityä.

Klusterin infra rakennetaan OpenTofulla, ja Kubernetes-resurssit hallitaan Gitistä FluxCD:n avulla. Julkinen HTTPS-liikenne kulkee OCI Network Load Balancerin, Envoy Gatewayn ja Gateway API:n kautta. Mukana ovat myös TLS, DNS, tallennus, mittarit, lokit ja ulkoinen tilaseuranta.

## Linkit

{{< overview-table >}}

| Osa | Linkki | Kuvaus |
|---|---|---|
| Klusterirepo | [oke-gitops-cluster](https://github.com/antief/oke-gitops-cluster) | Ajossa olevan OKE-labin infra- ja GitOps-rakenne. |
| Template | [oke-gitops-template](https://github.com/antief/oke-gitops-template) | Yleiskäyttöisempi pohja vastaavan klusterin rakentamiseen. |
| Grafana | [public dashboard](https://grafana.hanhela.org/public-dashboards/63d97cbd15c246c69ee103278182685e) | Rajattu julkinen näkymä klusterin mittareihin. |
| Status | [status.hanhela.org](https://status.hanhela.org/) | Ulkoinen saatavuusseuranta valituille palveluille. |

{{< /overview-table >}}

## Miksi tämä lab on olemassa?

Halusin ympäristön, jossa Kubernetesia ei tarvitse opetella vain yksittäisinä komentoina tai paikallisina testeinä. Tavoitteena on pitää yllä pientä mutta todellista kokonaisuutta, jossa samat perusasiat tulevat vastaan kuin isommissakin ympäristöissä: verkko, julkaisu, sertifikaatit, salaisuudet, tallennus, valvonta ja dokumentointi.

Oracle Kubernetes Engine sopii tähän hyvin, koska Oracle Cloudin Ampere A1 -resursseilla labia voi ajaa pitkäaikaisesti pienillä kustannuksilla. Samalla ympäristö pysyy riittävän oikeana, koska kyseessä on hallittu Kubernetes-palvelu eikä pelkkä paikallinen harjoitusklusteri.

## Mitä tässä harjoitellaan?

{{< overview-table >}}

| Osa | Kuvaus |
|---|---|
| Pilvi-infra | OKE-klusteri, VCN-verkko, subnetit, load balancerit ja tukiresurssit rakennetaan OpenTofulla. |
| GitOps | Klusterin tavoitetila elää GitHubissa, ja FluxCD sovittaa muutokset klusteriin. |
| Julkinen julkaisu | HTTPS-liikenne kulkee OCI Network Load Balancerin, Envoy Gatewayn ja Gateway API:n kautta. |
| TLS ja DNS | cert-manager hakee sertifikaatit ja ExternalDNS hallitsee DNS-tietueita Cloudflaren kautta. |
| Salaisuudet | Salaisuudet säilytetään OCI Vaultissa ja synkronoidaan Kubernetesiin External Secrets Operatorilla. |
| Tallennus | Longhorn tarjoaa persistent storage -kerroksen klusterin sisällä. |
| Observability | Prometheus, Grafana, Loki ja Alloy keräävät mittareita ja lokeja. |
| Saatavuusseuranta | Better Stack seuraa valittujen palveluiden saavutettavuutta klusterin ulkopuolelta. |

{{< /overview-table >}}

## Miten kokonaisuus toimii?

Klusterin perusidea on yksinkertainen: infra rakennetaan koodina, sovellukset kuvataan manifesteina ja muutokset viedään sisään Gitin kautta.

```text
GitHub
  → FluxCD
    → OKE
      → Envoy Gateway / Gateway API
        → Kubernetes-palvelut
```

Julkinen liikenne kulkee ensin OCI Network Load Balancerille. Sen jälkeen Envoy Gateway ja Gateway API -reitit ohjaavat HTTPS-liikenteen oikeille Kubernetes-palveluille.

## Keskeiset komponentit

{{< overview-table >}}

| Osa | Komponentit | Kuvaus |
|---|---|---|
| Kubernetes | [OKE](https://www.oracle.com/cloud/cloud-native/kubernetes-engine/) | Hallittu Kubernetes-klusteri Oracle Cloudissa. |
| Infra | [OpenTofu](https://opentofu.org/) | Rakentaa OCI-verkon, OKE-klusterin ja tukiresurssit. |
| GitOps | [FluxCD](https://fluxcd.io/) | Sovittaa klusterin tilan Git-repon mukaiseksi. |
| Julkinen liikenne | [OCI Network Load Balancer](https://docs.oracle.com/en-us/iaas/Content/NetworkLoadBalancer/home.htm), [Envoy Gateway](https://gateway.envoyproxy.io/), [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/) | Reitittää julkisen HTTPS-liikenteen palveluille ilman perinteisiä Ingress-resursseja. |
| TLS ja DNS | [cert-manager](https://cert-manager.io/), [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/), [Cloudflare DNS-01](https://cloudflare.com/) | Luo TLS-sertifikaatit ja hallitsee DNS-tietueita automaattisesti. |
| Salaisuudet | [OCI Vault](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm), [External Secrets Operator](https://external-secrets.io/) | Säilyttää salaisuudet OCI Vaultissa ja synkronoi ne Kubernetesiin. |
| Tallennus | [Longhorn](https://longhorn.io/) | Tarjoaa persistent storage -kerroksen klusterin sisällä. |
| Observability | [Prometheus](https://prometheus.io/), [Grafana](https://grafana.com/), [Loki](https://grafana.com/oss/loki/), [Alloy](https://grafana.com/oss/alloy) | Kerää mittarit ja lokit sekä näyttää ne dashboardeissa. |
| Tilaseuranta | [Better Stack](https://betterstack.com/) | Valvoo palveluiden saatavuutta klusterin ulkopuolelta. |

{{< /overview-table >}}

## GitOps-työnkulku

Muutokset tehdään ensin GitHubiin. FluxCD seuraa repoa ja sovittaa klusterin kohti siellä kuvattua tavoitetilaa.

Repossa Kubernetes-puoli on jaettu kerroksiin:

{{< overview-table >}}

| Osa | Kuvaus |
|---|---|
| Controllers | Klusteriin asennettavat kontrollerit, kuten cert-manager, Envoy Gateway, External Secrets Operator, Longhorn ja metrics-server. |
| Configs | Kontrollerien käyttämät asetukset, kuten Gatewayt, ClusterIssuerit, ExternalSecretit ja StorageClassit. |
| Addons | Ympäristöä tukevat lisäosat, kuten ExternalDNS, kube-prometheus-stack, Loki, Alloy ja Better Stack heartbeat. |
| Apps | Varsinaiset sovellukset ja testipalvelut. |

{{< /overview-table >}}

Tämä rakenne pitää riippuvuudet melko selkeinä. Ensin asennetaan kontrollerit, sitten niiden tarvitsemat asetukset, sen jälkeen lisäosat ja lopuksi sovellukset.

## Mitä tämä kertoo osaamisesta?

Sen tarkoitus on näyttää, että ymmärrän Kubernetes-ympäristön kokonaisuutta käytännön tasolla.

{{< overview-table >}}

| Osa | Kuvaus |
|---|---|
| Kubernetes | Klusterissa on käytössä oikeita Kubernetes-resursseja, palveluiden julkaisua, persistent storagea ja operointiin liittyviä komponentteja. |
| Pilvi-infra | OCI-resurssit rakennetaan OpenTofulla eikä käsin klikkailemalla. |
| GitOps | Muutokset kulkevat GitHubin kautta ja FluxCD huolehtii klusterin tilan sovittamisesta. |
| Verkko ja julkaisu | Julkinen HTTPS-liikenne on rakennettu OCI NLB:n, Envoy Gatewayn ja Gateway API:n varaan. |
| Salaisuuksien hallinta | Salaisuuksia ei säilytetä suoraan Gitissä, vaan ne tuodaan klusteriin OCI Vaultista. |
| Observability | Mittarit, lokit, dashboardit ja ulkoinen saatavuusseuranta ovat mukana osana ympäristöä. |
| Dokumentointi | Repo ja blogikirjoitukset kuvaavat, miten ympäristö on rakennettu ja miksi tietyt ratkaisut on valittu. |

{{< /overview-table >}}

## Template-repo

Varsinainen klusterirepo kuvaa omaa ajossa olevaa ympäristöäni. Sen rinnalle tein erillisen [OKE GitOps -templaten](https://github.com/antief/oke-gitops-template), joka toimii siistimpänä lähtöpisteenä vastaavan klusterin rakentamiseen.

Template ei yritä piilottaa kaikkea taikuuden taakse. Tarkoitus on, että rakenteesta näkee mitä ollaan tekemässä: mitä rakennetaan OpenTofulla, mitä FluxCD asentaa klusteriin ja miten eri kerrokset liittyvät toisiinsa.

## Rajaus

Tämä on henkilökohtainen lab, ei valmis tuotantoalusta. Pidän ympäristön tarkoituksella rajattuna, jotta se pysyy ylläpidettävänä ja hyödyllisenä oppimisympäristönä.

Tärkeintä ei ole ajaa mahdollisimman montaa palvelua, vaan rakentaa kokonaisuus, jossa pilvi-infra, Kubernetes, GitOps, julkaisu, observability ja dokumentointi tukevat toisiaan.
