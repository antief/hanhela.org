---
title: "Hugo-blogin ajaminen Kubernetesissä Helmillä ja GitOpsilla"
date: 2026-06-06T21:00:00+03:00
draft: false
highlight: true
highlightWeight: 40
weight: 20
slug: "hugo-blogin-julkaisu-kubernetesiin-helmilla-ja-gitopsilla"
translationKey: "deploying-simple-hugo-blog-with-helm"
description: "Yksinkertainen kuvaus siitä, miten tämä Hugo-blogi rakennetaan kontti-imageksi ja ajetaan Kubernetesissä Helmin ja Fluxin avulla."
summary: "Miten Hugo-blogi kulkee lähdekoodista kontti-imageksi, Helm-chartiksi ja lopulta Fluxin hallitsemaksi sovellukseksi Kubernetes-klusteriin."
tags:
  - Hugo
  - Helm
  - GitOps
  - Kubernetes
  - Flux
showTableOfContents: true
showTaxonomies: true
---

Tämän blogin voisi julkaista paljon helpomminkin. Hugo sopii hyvin esimerkiksi GitHub Pagesiin tai Cloudflare Pagesiin, eikä staattinen sivusto tarvitse Kubernetes-klusteria ollakseen verkossa.

Tässä tapauksessa tarkoitus oli kuitenkin ajaa blogia samalla tavalla kuin muitakin klusterin pieniä palveluita. Sivusto rakennetaan kontti-imageksi, image julkaistaan GitHub Container Registryyn ja Flux asentaa sovelluksen Kubernetes-klusteriin Helm-chartin avulla.

Koodi löytyy kahdesta reposta:

- [hanhela.org](https://github.com/antief/hanhela.org)
- [oke-gitops-cluster](https://github.com/antief/oke-gitops-cluster)

Ensimmäinen repo sisältää itse blogin: Hugo-sisällön, teeman asetukset, Dockerfile-tiedoston, GitHub Actions -workflow'n ja Helm-chartin. Toinen repo sisältää klusterin GitOps-konfiguraation, eli sen miten sovellus ajetaan OKE-klusterissa.

En käy tässä postauksessa läpi jokaista YAML-tiedostoa. Ne löytyvät repoista. Tämä on lyhyt kuvaus siitä, miten kokonaisuus toimii ja miksi osat on jaettu näin.

## Kokonaisuus lyhyesti

Julkaisuketju on melko suoraviivainen:

```text
Hugo source -> GitHub Actions -> GHCR -> Flux -> HelmRelease -> Kubernetes
```

Kun blogin lähdekoodi muuttuu, GitHub Actions rakentaa uuden image-version ja julkaisee sen GitHub Container Registryyn. Koska klusteri käyttää Oracle Cloudin Ampere A1 -nodeja, image rakennetaan myös `linux/arm64`-arkkitehtuurille.

Klusterin puolella Flux seuraa GitOps-repoa. Kun blogin HelmRelease tai sen arvot muuttuvat, Flux sovittaa klusterin tilan vastaamaan repossa olevaa määrittelyä. Käytännössä en siis asenna blogia käsin omalta koneeltani, vaan muutos kulkee Gitin kautta.

## Hugosta ajettavaksi imageksi

Hugo rakentaa sivuston staattisiksi tiedostoiksi. Ajossa blogi ei tarvitse Hugoa, Go-työkaluja tai lähdekoodia. Se tarvitsee vain web-palvelimen, joka tarjoilee valmiin `public/`-hakemiston.

Siksi image rakennetaan kahdessa vaiheessa. Ensin Hugo tekee staattisen sivuston. Sen jälkeen valmis sivusto kopioidaan nginxin tarjoiltavaksi. Runtime-vaiheessa kontti on vain nginx ja staattiset tiedostot.

Tämä pitää ajettavan imagen yksinkertaisena. Kubernetesin näkökulmasta blogi on tavallinen HTTP-palvelu: podi kuuntelee porttia 8080, Service ohjaa liikenteen podille ja Gateway hoitaa julkisen sisääntulon.

## Helm-chart sovelluksen mukana

Blogin Helm-chart on samassa repossa kuin itse sovellus. Se kuvaa sovelluksen perusrakenteen: Deploymentin, Servicen, probet, resurssipyynnöt ja PodDisruptionBudgetin.

Klusterikohtaiset asetukset ovat GitOps-repossa. Siellä määritellään esimerkiksi imagen repository, tagi, replikamäärä, resurssirajat ja julkinen hostname. Tämä jako on selkeä: sovellusrepo kertoo, millainen sovellus on, ja GitOps-repo kertoo, miten juuri tämä klusteri ajaa sitä.

Chart voi luoda blogille myös HTTPRouten. GitOps-repossa HelmReleaselle annetaan tämän klusterin arvot: käytettävä Gateway, hostname ja imagen asetukset.

Yksinkertaisen `blog.example.com`-julkaisun olennaiset HelmRelease-arvot voisivat näyttää tältä:

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

Sama mekanismi taipuu tarvittaessa myös apex-domainiin. Chart tukee useampaa routea, joten yksi route voi ohjata `example.com`-osoitteen Serviceen ja toinen route voi uudelleenohjata `blog.example.com`- tai `www.example.com`-osoitteet takaisin apex-domainiin. Nämä valinnat pysyvät HelmReleasen arvoissa, koska ne kuuluvat tähän klusteriin eivätkä itse sovellukseen.

Tällaiselle blogille Helm ei ole teknisesti pakollinen. Yksinkertainen Deployment ja Service riittäisivät. Käytän sitä silti, koska sama malli sopii myöhemmin muihinkin sovelluksiin. Pieni blogi on hyvä paikka pitää julkaisutapa kunnossa ilman, että itse sovellus monimutkaistaa asiaa.

## Reititys ja DNS

Blogin kontti tarjoilee HTTP:tä vain klusterin sisällä. TLS, julkiset hostnamet ja sisääntuleva liikenne hoidetaan Gateway API:n kautta.

Yksinkertaisessa tapauksessa liikenne kulkee näin:

```text
blog.example.com -> Cloudflare DNS -> OCI Load Balancer -> Envoy Gateway -> Service -> Pod
```

Gateway itse kuuluu klusterille. Blogin chart luo vain sovelluksen oman reitin silloin, kun GitOps-repo kytkee sen päälle Helm-arvoilla. Silloin blogikerros pysyy pienenä: namespace, Fluxin GitRepository, HelmRelease ja Kustomization riittävät.

ExternalDNS tekee Cloudflareen tarvittavan DNS-recordin Kubernetes-resurssien perusteella. Tämä on mukavaa arjessa, koska hostname ei jää käsin kliksutelluksi asetukseksi Cloudflaren käyttöliittymään. Se elää samassa GitOps-prosessissa kuin muukin klusterin reititys.

## Mitä tästä jäi käteen

Tämän blogin ajaminen Kubernetesissä ei ole yritys väittää, että staattinen sivusto tarvitsee klusterin. Ei tarvitse. GitHub Pages tai Cloudflare Pages olisi monelle Hugo-blogille järkevämpi ja kevyempi ratkaisu.

Tässä projektissa blogi toimii pienenä, julkisena sovelluksena, jolla voin harjoitella ja testata koko julkaisuputkea. Muutos lähtee Gitistä, image rakentuu automaattisesti, Flux vie sen klusteriin ja liikenne ohjautuu Gatewayn kautta ulos.

Hyödyllisin osa on vastuiden jako. Blogirepo sisältää sovelluksen. GitOps-repo sisältää klusterin tavan ajaa sitä. Helm-chart antaa sovellukselle toistettavan muodon, tarvittaessa myös reitityksen. Gateway ja ExternalDNS hoitavat julkaisun ulospäin.

Kun tämä toimii yksinkertaisella Hugo-blogilla, samaa mallia voi käyttää myös muissa pienissä palveluissa. Blogi on tässä hyvä harjoituskohde juuri siksi, että se on teknisesti yksinkertainen ja sen toimivuus on helppo tarkistaa selaimella.
