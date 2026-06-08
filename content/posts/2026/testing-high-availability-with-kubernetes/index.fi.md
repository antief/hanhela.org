---
title: "Korkean saatavuuden testaaminen Kubernetesissa"
date: 2026-06-05T12:00:00+03:00
draft: false
highlight: true
highlightWeight: 30
weight: 30
slug: "korkean-saatavuuden-testaaminen-kubernetesissa"
translationKey: "testing-high-availability-with-kubernetes"
summary: "Yksinkertainen OKE-klusterissa tehtävä saatavuustesti, jossa tarkasteltiin noden poistumisen vaikutusta julkiseen blogipalveluun." 
description: "Kuvaus OKE-klusterissa tehdystä saatavuustestistä, jossa tarkasteltiin, miten noden poistuminen vaikuttaa Kubernetesissä ajettavaan julkiseen blogipalveluun."
tags:
  - Kubernetes
  - High Availability
  - Node Maintenance
  - OKE
  - Envoy Gateway
showTableOfContents: true
showTaxonomies: true
---

Halusin testata, mitä Kubernetes-klusterissani oikeasti tapahtuu, kun yksi worker-node vaihdetaan lennossa. Pelkkä podien lopullinen tila ei vielä kerro, miltä huolto näyttää palvelun käyttäjän näkökulmasta. Siksi ajoin testin ulkopuolelta julkista palvelua vasten.

Testi tehtiin [Kubernetes Labissä](/fi/posts/kubernetes-lab/). Julkinen liikenne kulki OCI Network Load Balancerin kautta Envoy Gatewaylle, ja sieltä edelleen [`whoami`](https://whoami.hanhela.org)-palveluun. 

Klusterissa oli siis kolme worker-nodea, Longhorn storage ja FluxCD hoitamassa manifestien sovitusta. whoami ei itsessään käytä Longhornia, mutta Longhorn oli testissä mukana siksi, että noden vaihto vaikuttaa koko klusteriin. Jos storage jää huonoon tilaan, node replacement ei ole oikeasti onnistunut, vaikka testipalvelu sattuisikin vastaamaan.

Tavoite oli yksinkertainen: vaihdetaan yksi node ja katsotaan, tuleeko julkiseen HTTP-liikenteeseen katkoksia.

## Lähtötilanne

Ennen testiä tarkistin, että klusteri oli terve:

```bash
kubectl get nodes -o wide
kubectl -n envoy-gateway-system get ds,pods -o wide
kubectl -n whoami get ds,pods -o wide
kubectl -n longhorn-system get volumes.longhorn.io
flux get kustomizations -n flux-system
```

Lähtötilassa kaikki näytti hyvältä: nodet olivat `Ready`, Envoy Gateway oli asetettu DaemonSetiksi, whoami-podeja oli kolme ja Longhorn-volyymit olivat terveitä.

Ajoin [`whoami`](https://whoami.hanhela.org)-palvelua vasten pientä shellillä tehtyä curl-looppia:

```bash
while true; do
  ts="$(date --iso-8601=seconds)"
  tmp="$(mktemp)"

  metrics="$(curl -sS -m 3 -o "$tmp" \
    -w 'code=%{http_code} time=%{time_total}' \
    https://whoami.hanhela.org/ 2>&1)"
  rc=$?

  if [ "$rc" -eq 0 ] && printf '%s' "$metrics" | grep -q 'code=200'; then
    host="$(sed -n 's/^Hostname: //p' "$tmp" | head -1)"
    echo "$ts OK $metrics host=$host"
  else
    echo "$ts FAIL rc=$rc $metrics"
  fi

  rm -f "$tmp"
  sleep 1
done | tee /tmp/whoami-ha-test.log
```

Tämän pitäisi kertoa sekunnin välein, tuliko HTTP 200 vai timeout, ja mikä `whoami`-podi vastasi.

## Node vaihtoon

Noden vaihto tehtiin omalla skriptillä, joka vaihtaa OKE-node poolista yhden noden kerrallaan. Ennen varsinaista ajoa skripti tekee dry-runin, tarkistaa tavoiteversion ja varmistaa Longhornin tilanteen. Koodi löytyy [GitHubista](https://github.com/antief/oke-gitops-cluster/tree/main/terraform/oci-oke/scripts).

Varsinainen ajo oli tämän tyyppinen:

```bash
./scripts/replace-outdated-nodes.sh --force --max-replacements 1 \
  | tee /tmp/oke-node-replacement.log
```

Skriptin osalta testi meni lopulta hyvin. Node vaihtui, uusi node liittyi klusteriin ja Longhorn palautui terveeksi. Vanhaan nodeen jääneet stale-replikat saatiin siivottua pois.

Lokin lopussa näkyi se mitä hain:

```text
Deleting stale Longhorn replica ... on removed node ...
Removing stale Longhorn node ... after Kubernetes node removal
Longhorn is healthy
Replacement completed for ocid1.instance...
Done. Replaced nodes in this run: 1
```

Klusterin sisäisen tilan näkökulmasta node replacement siis onnistui.

## Oliko se katkoton?

Ei täysin.

Testiin tuli noden vaihdon aikana muutamia timeoutteja:

```text
FAIL rc=28 curl: (28) Operation timed out after 3002 milliseconds with 0 bytes received
```

Tämä oli testin tärkein tulos. Kubernetesin näkökulmasta kaikki palautui nätisti, mutta käyttäjän näkökulmasta osa pyynnöistä epäonnistui huollon aikana.

Tarkkaa syytä en pysty todistamaan pelkästään tämän testin perusteella. Oma arvaukseni on, että katkos liittyi useamman asian ajoitukseen: vanha node poistui, uusi node liittyi mukaan, OCI Network Load Balancer päivitti backendejä ja Envoy Gatewayn podit käynnistyivät uudella nodella. Uuden noden alkuvaiheessa näkyi myös Flanneliin liittyvä virhe:

```text
plugin type="flannel" failed (add):
loadFlannelSubnetEnv failed:
open /run/flannel/subnet.env: no such file or directory
```

Tämä korjaantui itsestään, mutta se kertoo hyvin miksi pelkkä node `Ready` ei aina tarkoita, että node on heti valmis ottamaan vastaan julkista liikennettä.

## Mitä tästä jäi käteen?

Testi ei todistanut täydellistä nollakatkoista HA:ta. Se oli silti hyödyllinen testi.

Node vaihtui onnistuneesti, uusi node liittyi klusteriin ja Longhorn palautui terveeksi. Klusterin sisäinen tila näytti huollon jälkeen hyvältä. Julkisen liikenteen näkökulmasta tulos ei kuitenkaan ollut täydellinen, muutamien pyyntöjen aikakatkaisujen takia.

Se on oikeastaan koko testin opetus. Korkeaa saatavuutta ei kannata arvioida vain klusterin sisältä. `kubectl get pods` voi näyttää lopulta hyvältä, vaikka käyttäjä olisi nähnyt huollon aikana virheen. Yksinkertainen ulkopuolelta ajettu curl-looppi kertoi tässä enemmän kuin pelkkä Kubernetesin oma status.

Minulle testi oli onnistunut, vaikka tulos ei ollut täydellinen. Nyt tiedän paremmin, miten tämä klusteri käyttäytyy node-huollon aikana ja missä sen rajat tulevat vastaan.
