# 🚖 Analyse de courses VTC (SQL)

Projet d'analyse exploratoire réalisé en SQL à partir d'une base de données simulant l'activité d'une plateforme de VTC.

L'objectif est d'identifier les principaux leviers d'amélioration de la performance opérationnelle grâce à des analyses orientées métier.

---

## 📊 Objectifs du projet

Cette étude répond notamment aux questions suivantes :

- Quel est le chiffre d'affaires généré ?
- Quels sont les taux d'annulation des courses ?
- Qui annule le plus souvent (client, chauffeur ou système) ?
- Quelles sont les principales raisons des annulations ?
- Quel chiffre d'affaires est perdu à cause des annulations ?
- Quels sont les chauffeurs les plus performants ?
- Quels créneaux horaires génèrent le plus de revenus ?
- Les trajets courts ou longs sont-ils les plus rentables ?
- Les zones géographiques présentent-elles des différences de performance ?

---

## 🛠️ Technologies utilisées

- SQL
- SQLite
- SQLTools (VS Code)
- Git
- GitHub

---

## 📈 Analyses réalisées

Le fichier `queries.sql` regroupe plusieurs analyses métier, notamment :

- KPI globaux
- Analyse du chiffre d'affaires
- Analyse des annulations
- Analyse des performances des chauffeurs
- Analyse des créneaux horaires
- Analyse des trajets (distance et durée)
- Analyse des zones géographiques
- Calcul de différents indicateurs de performance

Chaque requête est documentée avec :

- la question métier
- l'enjeu
- le résultat clé

---

## ⚡ Optimisation

Le fichier `indexes.sql` contient les index utilisés afin d'améliorer les performances des requêtes les plus coûteuses.

---

## ▶️ Utilisation

1. Cloner le dépôt :

```bash
git clone https://github.com/AlexandreLoumi/uber_analysis.git
```

2. Ouvrir `data/rideshare.db` avec SQLite ou SQLTools.

3. Exécuter les requêtes présentes dans `queries.sql`.

---

## 📚 Source des données

Les données utilisées dans ce projet proviennent du jeu de données **Uber SQL Database** disponible sur Kaggle.

https://www.kaggle.com/datasets/rockyt07/uber-sql-database

---

## 👤 Auteur

**Alexandre Loumi**

Data Analyst

GitHub : https://github.com/AlexandreLoumi