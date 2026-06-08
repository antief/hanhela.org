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
summary: "OKE-pohjainen Kubernetes- ja GitOps-lab, jossa on Gateway API -pohjainen HTTPS-reititys, TLS, mittarit, lokit ja julkinen tilaseuranta."
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

Tämä on oma Kubernetes-labini [Oracle Cloudissa](https://www.oracle.com/cloud/free/). Se ei ole pelkkä paikallinen kokeilu, vaan oikeasti ajossa oleva pieni pilviympäristö, jossa harjoittelen kaikkea Kubernetesiin liittyvää.

Klusterin infra rakennetaan OpenTofun avulla, ja Kubernetes-resurssit hallitaan Gitistä FluxCD:llä. Julkinen HTTPS-liikenne kulkee OCI Network Load Balancerin ja Envoy Gatewayn kautta. Mukana ovat myös TLS, DNS, tallennus, mittarit, lokit ja ulkoinen saatavuusseuranta.

Käytännössä labin tarkoitus on näyttää, miten pilvessä ajettava Kubernetes-ympäristö voidaan rakentaa toistettavasti, pitää hallinnassa GitOpsilla ja valvoa ulkopuolelta. Samalla se toimii omana harjoitusympäristönäni, jossa voin testata päivityksiä, julkaisutapoja ja inframuutoksia turvallisesti mutta realistisesti.

## Linkit

Jos haluat tutustua ympäristöön tarkemmin, tärkeimmät linkit ovat tässä. Koodi kertoo miten ympäristö on rakennettu, Grafana näyttää valittuja mittareita ja status-sivu näyttää ulkoisen saatavuusseurannan.

{{< overview-table >}}

| Osa | Linkki | Kuvaus |
|---|---|---|
| Klusterirepo | [oke-gitops-cluster](https://github.com/antief/oke-gitops-cluster) | Ajossa olevan OKE-labin infra- ja GitOps-rakenne. |
| Mallipohja | [oke-gitops-template](https://github.com/antief/oke-gitops-template) | Yleiskäyttöisempi lähtöpiste vastaavan klusterin rakentamiseen. |
| Grafana | [public dashboard](https://grafana.hanhela.org/public-dashboards/63d97cbd15c246c69ee103278182685e) | Rajattu julkinen näkymä klusterin mittareihin. |
| Status | [status.hanhela.org](https://status.hanhela.org/) | Ulkoinen saatavuusseuranta valituille palveluille. |

{{< /overview-table >}}

## Miksi tämä lab on olemassa?

Halusin ympäristön, jossa Kubernetesiä ei tarvitse opetella vain yksittäisinä komentoina tai paikallisina testeinä. Tavoitteena on pitää yllä pientä mutta todellista kokonaisuutta, jossa samat perusasiat tulevat vastaan kuin isommissakin ympäristöissä: verkko, julkaisu, sertifikaatit, salaisuudet, tallennus, valvonta ja dokumentointi.

Oracle Kubernetes Engine sopii tähän hyvin, koska labia voi ajaa edullisesti ja joissain tapauksissa jopa ilmaiseksi. Samalla ympäristö vastaa melko hyvin tuotantoympäristöä, koska kyseessä on hallittu Kubernetes-palvelu eikä pelkkä paikallinen harjoitusklusteri.

Halusin myös, että labia käytetään pääosin komentoriviltä eikä yksittäisinä klikkauksina pilven käyttöliittymässä. Pilven käyttöliittymä on toki hyödyllinen tarkistamiseen ja hallintaan, mutta tämän labin pääasiallinen työnkulku on koodin, komentorivin ja Gitin ympärillä. Klusterin voi alustaa, validoida, ajaa ylös, purkaa ja rakentaa uudelleen toistettavasti. Myös nodejen päivitys hoituu erillisellä skriptillä.

## Mitä tämä osoittaa?

Tämän labin kautta olen harjoitellut erityisesti:

- pilvi-infran rakentamista koodina
- Kubernetes-resurssien hallintaa GitOps-mallilla
- HTTPS-reititystä Gateway API:n avulla
- sertifikaattien, DNS:n ja salaisuuksien automatisointia
- pysyvän tallennuksen käyttöä Kubernetesissä
- mittareiden, lokien ja ulkoisen saatavuusseurannan rakentamista
- ympäristön dokumentointia niin, että sen voi ymmärtää ja rakentaa uudelleen

Tärkeintä ei ole yksittäinen työkalu, vaan se että eri osat muodostavat toimivan kokonaisuuden. Infra, GitOps, julkaisu, valvonta ja dokumentaatio tukevat samaa ympäristöä eivätkä jää irrallisiksi kokeiluiksi.

## Miten kokonaisuus toimii?

Klusterin perusidea on yksinkertainen: infra rakennetaan koodina, sovellukset kuvataan manifesteina ja muutokset viedään sisään Gitin kautta.

```text
Muutokset:
GitHub → FluxCD → Kubernetes-resurssit

Julkinen liikenne:
Internet → OCI Network Load Balancer → Envoy Gateway → Kubernetes Service → Pod
```

Muutokset tehdään ensin Git-repoon. FluxCD seuraa repoa ja vie klusteria kohti siellä kuvattua tavoitetilaa. Julkinen liikenne taas saapuu ensin OCI Network Load Balancerille, jonka jälkeen Envoy Gateway reitittää HTTPS-liikenteen oikeille Kubernetes-palveluille.

Näin sovellusten julkaisu ja liikenteen reititys pysyvät erillisinä, mutta hallittavina osina samaa kokonaisuutta.

## Keskeiset komponentit

{{< overview-table >}}

| Osa | Komponentit | Kuvaus |
|---|---|---|
| Kubernetes-alusta | [OKE](https://www.oracle.com/cloud/cloud-native/kubernetes-engine/) | Hallittu Kubernetes-klusteri Oracle Cloudissa. |
| IaC | [OpenTofu](https://opentofu.org/) | Rakentaa OCI-verkon, OKE-klusterin ja tukiresurssit. |
| GitOps | [FluxCD](https://fluxcd.io/) | Pitää klusterin tilan Git-repon mukaisena. |
| Julkinen liikenne | [OCI Network Load Balancer](https://docs.oracle.com/en-us/iaas/Content/NetworkLoadBalancer/home.htm), [Envoy Gateway](https://gateway.envoyproxy.io/), [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/) | Reitittää julkisen HTTPS-liikenteen palveluille ilman perinteisiä Ingress-resursseja. |
| TLS ja DNS | [cert-manager](https://cert-manager.io/), [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/), [Cloudflare DNS-01](https://cloudflare.com/) | Luo TLS-sertifikaatit ja hallitsee DNS-tietueita automaattisesti. |
| Salaisuudet | [OCI Vault](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm), [External Secrets Operator](https://external-secrets.io/) | Säilyttää salaisuudet OCI Vaultissa ja synkronoi ne Kubernetesiin. |
| Tallennus | [Longhorn](https://longhorn.io/) | Tarjoaa pysyvän tallennuskerroksen klusterin sisällä. |
| Mittarit ja lokit | [Prometheus](https://prometheus.io/), [Grafana](https://grafana.com/), [Loki](https://grafana.com/oss/loki/), [Alloy](https://grafana.com/oss/alloy) | Kerää mittarit ja lokit sekä näyttää ne dashboardeissa. |
| Uptime-seuranta | [Better Stack](https://betterstack.com/) | Valvoo palveluiden saatavuutta klusterin ulkopuolelta. |

{{< /overview-table >}}

## GitOps-työnkulku

Muutokset tehdään ensin [GitHubiin](https://github.com/antief/oke-gitops-cluster). Flux seuraa repoa ja pitää klusterin tilan siellä kuvatun tavoitetilan mukaisena.

Käytännössä uusi palvelu lisätään tekemällä sille manifestit repoon ja viemällä muutos Gitin kautta päähaaraan. Kun muutos on yhdistetty, Flux havaitsee sen ja alkaa sovittaa klusteria uuteen tilaan. Jos jokin menee pieleen, se näkyy sekä Fluxin tilassa että valvontatyökaluissa.

Repo jakautuu pääosin kahteen osaan. `terraform/` sisältää labin infran: peruspilviresurssit, OKE-klusterin ja Fluxin käyttöönoton. `gitops/` sisältää Kubernetes-puolen: klusterikohtaiset asetukset, infrakontrollerit, lisäosat ja sovellusten manifestit.

Fluxin kanssa repositorion rakenne on valittavissa, kunhan Fluxin Kustomizationit osoittavat oikeisiin polkuihin (lue lisää Fluxin [dokumentaatiosta](https://fluxcd.io/flux/guides/repository-structure/)). Tässä repossa klusterikohtainen `clusters`-hakemisto kokoaa ympäristön Kustomizationit, ja varsinainen klusterin sisältö on jaettu neljään kerrokseen.

{{< overview-table >}}

| Osa | Kuvaus |
|---|---|
| Controllers | Klusterin kontrollerit, kuten cert-manager, Envoy Gateway, External Secrets Operator, Longhorn ja metrics-server. |
| Configs | Kontrollerien käyttämät asetukset, kuten Gatewayt, ClusterIssuerit, ExternalSecretit ja StorageClassit. |
| Addons | Avustavat komponentit, kuten ExternalDNS, kube-prometheus-stack, Loki, Alloy ja Better Stack heartbeat. |
| Apps | Varsinaiset sovellukset ja testipalvelut. |

{{< /overview-table >}}

Tämä pitää riippuvuudet selkeinä. Ensin asennetaan kontrollerit, sitten niiden asetukset, sen jälkeen tukevat lisäosat ja lopuksi sovellukset.

## Mallipohjarepo

Varsinainen klusterirepo kuvaa omaa ajossa olevaa ympäristöäni. Sen rinnalle tein erillisen [OKE GitOps -mallipohjan](https://github.com/antief/oke-gitops-template), joka toimii siistimpänä lähtöpisteenä vastaavan klusterin rakentamiseen.

Mallipohja ei yritä olla musta laatikko. Rakenteesta pitää nähdä, mitä rakennetaan OpenTofun avulla, mitä Flux asentaa klusteriin ja miten eri kerrokset liittyvät toisiinsa.

## Rajaus

Tämä on henkilökohtainen labra, ei valmis tuotantoalusta. Pidän ympäristön tarkoituksella pienenä, jotta pystyn ymmärtämään, ylläpitämään ja dokumentoimaan sen kunnolla.

Repo voi toimia hyödyllisenä esimerkkinä, mutta sitä ei ole tarkoitettu kopioitavaksi sellaisenaan tuotantoon. Se heijastaa omaa oppimisympäristöäni, valintojani ja rajoitteitani. Ideoita saa käyttää, mutta kokonaisuutta ei kannata kopioida sokeasti.
