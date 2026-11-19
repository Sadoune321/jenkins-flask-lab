# Rapport — Lab No. 07 : Building a CI/CD Pipeline with Jenkins and Docker

## 1. Architecture et pipeline

Architecture du lab : **GitHub → Jenkins Pipeline → Docker Image → Docker Container → Flask Application**

Jenkins récupère le code source et le `Jenkinsfile` depuis le dépôt GitHub, puis exécute cinq étages :

| Étage | Rôle | Résultat attendu |
|---|---|---|
| Checkout | Le code est déjà disponible dans le workspace via « Pipeline script from SCM » | Sources présentes |
| Build | `docker build -t jenkins-flask-lab:${BUILD_NUMBER} .` | Image taguée avec le numéro de build |
| Test | `docker run --rm jenkins-flask-lab:${BUILD_NUMBER} pytest -v` | 2 tests passent, sinon le pipeline s'arrête |
| Deploy | Suppression de l'ancien conteneur, puis `docker run -d --network jenkins-net -p 8081:8000 -e APP_VERSION=${BUILD_NUMBER} ...` | Nouvelle version démarrée |
| Verify | `curl --fail --retry 10 --retry-delay 2 http://jenkins-flask-app:8000/health`, puis la page d'accueil, puis `http://host.docker.internal:8081/health` | L'application répond `{"status":"ok"}` et affiche le numéro de build |

L'application est disponible sur `http://localhost:8081`, Jenkins sur `http://localhost:8080`.

---

## 2. Partie F — Blue-Green Deployment and Rollback (questions §19)

### 19.1 Différence entre deployment et release
Le **deployment** est l'opération technique qui installe et démarre une nouvelle version dans un environnement (par exemple l'environnement Green). La **release** est le moment où cette version est réellement exposée aux utilisateurs (bascule du trafic). On peut donc déployer sans publier : la nouvelle version tourne en Green mais aucun utilisateur n'y accède tant que la bascule n'a pas eu lieu. La release est une décision métier/produit, le deployment est une décision technique.

### 19.2 Pourquoi déployer d'abord sur Green ?
Green est un environnement de production identique à Blue, mais isolé du trafic réel. On peut ainsi valider la nouvelle version (tests, health checks, monitoring) dans des conditions proches de la production sans risquer de perturber les utilisateurs, qui continuent d'utiliser Blue. Si un problème est détecté, il suffit de ne pas basculer : le trafic reste sur la version stable.

### 19.3 Composant qui route les requêtes vers Blue ou Green
Un **reverse proxy / load balancer**, par exemple **NGINX** (ou HAProxy, un load balancer cloud, ou DNS avec faible TTL). Il configure l'upstream vers Blue ou Green et la bascule se fait en modifiant cette configuration puis en rechargeant le proxy.

### 19.4 Pourquoi Blue doit rester disponible après la bascule ?
Blue est le filet de sécurité : si un défaut apparaît sur Green après la bascule (erreurs, performance, régression métier), on peut immédiatement reconfigurer le proxy pour renvoyer le trafic vers Blue, qui exécute encore la dernière version connue comme fonctionnelle. On garde Blue pendant une période d'observation, puis on peut le recycler pour la prochaine itération.

### 19.5 Comment Jenkins peut automatiser deployment, test et approbation ?
Un pipeline Jenkins étendu peut : construire l'image, déployer automatiquement le conteneur Green, exécuter les tests et les health checks sur Green, puis utiliser une étape d'approbation manuelle (`input` dans le Jenkinsfile, ou plugin "Manual Approval") avant de modifier la configuration NGINX et de recharger le proxy pour basculer le trafic. Jenkins peut ensuite lancer un monitoring/post-check, envoyer une notification, et en cas d'échec interrompre le pipeline : Blue continue de servir les utilisateurs et la bascule n'a pas lieu. Toutes ces étapes sont versionnées dans le Jenkinsfile et reproductibles.

### 19.6 Principal bénéfice du rollback
Réduire le temps d'indisponibilité et l'impact d'une mauvaise version : le retour à la dernière version stable est quasi immédiat (simple bascule du proxy), sans reconstruction ni redéploiement long. Cela diminue le MTTR (Mean Time To Restore) et le risque métier.

---

## 3. Partie G — Questions générales (§20)

### 20.1 Qu'est-ce que Jenkins et quel problème résout-il ?
Jenkins est un serveur d'automatisation qui implémente des workflows CI/CD. Il orchestrer des tâches répétitives : récupération du code, compilation/build, tests, analyse qualité et déploiement. Il remplace les opérations manuelles, lentes et sources d'erreurs par des pipelines automatiques, traçables et reproductibles, avec un retour rapide sur chaque commit.

### 20.2 Rôle d'un Jenkinsfile
Le Jenkinsfile définit le pipeline « as code » : environnement, stages et étapes (`sh`, `echo`, `post`...). Stocké à la racine du dépôt, il est versionné avec le code source, relisible et modifiable via Git. Jenkins le lit et exécute les étapes dans l'ordre.

### 20.3 CI vs CD
La **Continuous Integration** consiste à intégrer fréquemment le code des développeurs dans une branche principale ; chaque commit déclenche build et tests automatisés pour détecter les erreurs tôt. La **Continuous Delivery** va plus loin : toute version qui passe les tests est déployée automatiquement dans un environnement de type production et reste toujours « prête à être publiée » (la mise en production peut nécessiter une validation manuelle). La **Continuous Deployment** publie automatiquement en production.

### 20.4 Rôle de GitHub dans ce lab
GitHub héberge le code source et le Jenkinsfile. Jenkins est configuré en « Pipeline script from SCM » avec l'URL du dépôt public et la branche `*/main` : il fait un `git fetch`/`checkout` à chaque build. Un webhook peut optionnellement déclencher le pipeline à chaque push (si Jenkins est joignable depuis GitHub).

### 20.5 Pourquoi Docker dans le pipeline ?
Docker empaquette l'application et toutes ses dépendances dans une image immuable. La **même image** est utilisée pour les tests et pour le démarrage de l'application, ce qui garantit que l'environnement de test est identique à l'environnement déployé. Les conteneurs sont légers, isolés et faciles à créer/supprimer (conteneur de test `--rm`, conteneur de déploiement remplacé à chaque build).

### 20.6 Pourquoi exécuter les tests avant le déploiement ?
Les tests vérifient automatiquement que la nouvelle version respecte le comportement attendu (page d'accueil et endpoint `/health`). S'ils échouent, le pipeline s'arrête immédiatement : une version défectueuse n'est jamais déployée et l'application en cours de fonctionnement n'est pas remplacée. C'est le filet de sécurité de la livraison continue.

### 20.7 Que se passe-t-il si un étage échoue ?
Le pipeline s'arrête à l'étage en échec ; les étages suivants sont marqués « skipped » (le bloc `post { failure { ... } }` s'exécute) et le build est `FAILURE`. Dans le build 8 du lab, le test `test_health` a échoué : **Deploy** et **Verify** ont été ignorés et le conteneur `jenkins-flask-app` de la version précédente est resté en place.

### 20.8 Rôle de l'étage Verify
Il confirme que le déploiement a réellement réussi, au-delà du simple démarrage du conteneur : des requêtes HTTP avec réessais (`curl --fail --retry 10 --retry-delay 2`) vérifient que `/health` renvoie `{"status":"ok"}` et que la page d'accueil répond. C'est la vérification fonctionnelle de bout en bout.

### 20.9 Pourquoi ne pas stocker des credentials dans le Jenkinsfile ?
Le Jenkinsfile est versionné dans le dépôt (souvent public dans ce lab) et visible par toute personne ayant accès au code. Des mots de passe ou tokens y seraient exposés et impossibles à révoquer proprement. Il faut utiliser le magasin de credentials de Jenkins (`credentials`, `withCredentials`, `usernamePassword`, etc.) et référencer un identifiant dans le Jenkinsfile.

---

## 4. Livrables à joindre

- URL du dépôt : https://github.com/Sadoune321/jenkins-flask-lab
- Capture du pipeline réussi (5 étages verts).
- Capture de l'application dans le navigateur (`http://localhost:8081`).
- Capture de l'étage **Test** en échec (build 8) et explication : le test a échoué, le pipeline s'est arrêté, donc Deploy et Verify n'ont pas été exécutés et la version précédente est restée active.
- Réponses aux sections 19 et 20 ci-dessus.

*Extension optionnelle non réalisée : webhook GitHub pour déclencher automatiquement le pipeline (Jenkins n'est pas joignable publiquement ici, builds manuels utilisés).*
