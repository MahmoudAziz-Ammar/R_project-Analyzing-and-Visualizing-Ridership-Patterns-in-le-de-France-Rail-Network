# Projet de Visualisation et d'Analyse des Données de Transport

Ce dépôt contient une application Shiny et les scripts nécessaires pour analyser et visualiser les données de transport en Île-de-France. L'application permet d'explorer des tendances sur plusieurs années (2018-2023), de détecter des anomalies, et de visualiser les données sur des cartes interactives.

## Structure du Projet

```
📂 shiny-transport-analysis
├── 📁 QuartoR_files          # Fichiers associés au rapport Quarto
├── 📁 deployment             # Application Shiny pour la visualisation
│   ├── app.R                # Script principal de l'application
├── QuartoR.qmd              # Rapport Quarto documentant le projet
├── README.md                # Fichier README explicatif
├── cleaning.R               # Script de nettoyage des données
├── QuartoR.html             # Rapport en version HTML
├── .Rhistory                # Historique des commandes R
```

## Fonctionnalités Principales

- **Nettoyage des données** :
  - Fusion des fichiers de données de transport (2018-2023).
  - Suppression des valeurs manquantes et des doublons.
  - Conversion des formats de colonnes et traitement des anomalies.

- **Exploration des données** :
  - Visualisation des tendances quotidiennes, mensuelles et annuelles.
  - Analyse de l'impact des jours fériés et des périodes de vacances sur la fréquentation.

- **Visualisation géographique** :
  - Cartes interactives utilisant `leaflet` et `sf`.
  - Création de cartes de chaleur pour la fréquentation des arrêts.

## Prérequis

- **R** : Version 4.0+
- **Packages R** :
  - `shiny`, `dplyr`, `data.table`, `sf`, `leaflet`, `ggplot2`, `lubridate`, `leaflet.extras`

## Installation

1. Clonez le dépôt :
   ```bash
   git clone https://github.com/votre-utilisateur/shiny-transport-analysis.git
   cd shiny-transport-analysis
   ```
2. Installez les dépendances R nécessaires :
   ```R
   install.packages(c("shiny", "dplyr", "data.table", "sf", "leaflet", "ggplot2", "lubridate", "leaflet.extras"))
   ```

## Utilisation

1. Lancez l'application Shiny :
   ```R
   shiny::runApp("deployment/app.R")
   ```
2. Visualisez les résultats dans votre navigateur.

3. Pour générer le rapport Quarto :
   ```bash
   quarto render QuartoR.qmd
   ```

## Données

- Les données proviennent des fichiers TXT/CSV des validations de transport en Île-de-France de 2018 à 2023.
- Les colonnes principales incluent :
  - `JOUR` : Date
  - `LIBELLE_ARRET` : Nom de l'arrêt
  - `NB_VALD` : Nombre de validations

## Contributions

- **Réalisé par** :
  - Siwar Najjar
  - Karim Damak
  - Mahmoud Aziz Ammar

## Licence

Ce projet est sous licence MIT. Consultez le fichier `LICENSE` pour plus d'informations.
