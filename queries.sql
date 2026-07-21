--------------------------------
-- 1. EXPLORATION DES DONNÉES
--------------------------------

-- Question : Quelles tables composent la base et comment sont-elles structurées ?
-- Enjeu : poser les fondations avant toute analyse

SELECT name FROM sqlite_master WHERE type = 'table';

PRAGMA table_info('riders');
PRAGMA table_info('trips');
PRAGMA table_info('drivers');
PRAGMA table_info('locations');
PRAGMA table_info('payments');
PRAGMA table_info('reviews');
PRAGMA table_info('users');
PRAGMA table_info('cancellations');

SELECT * FROM riders LIMIT 10;
SELECT * FROM cancellations LIMIT 10;
SELECT * FROM trips LIMIT 10;
SELECT * FROM drivers LIMIT 10;
SELECT * FROM users LIMIT 10;
SELECT * FROM locations LIMIT 10;
SELECT * FROM payments LIMIT 10;
SELECT * FROM reviews LIMIT 10;


--------------------------------
-- 2. KPIS GLOBAUX (VUE D'ENSEMBLE)
--------------------------------

-- Question : Quel est le volume total de courses ?
-- Enjeu : indicateur de base pour cadrer la taille de l'activité
-- Résultat clé : 20 000 courses dans la base de données

SELECT
    COUNT(*) AS "Nombre total de courses"
FROM trips;

-- Question : Comment sont réparties les courses, par statut (terminée, annulée, en cours) ?
-- Enjeu : évaluer la part de courses qui n'aboutissent pas
-- Résultat clé : 2 966 courses annulées, 16 827 complétées, 207 en cours.

SELECT
    status,
    COUNT(*) AS "Nombre de courses",
    SUM(total_fare) AS "Chiffre d'affaires"
FROM trips
GROUP BY status;

-- Question : Quel est le chiffre d'affaires total généré ?
-- Enjeu : indicateur de performance business principal
-- Résultat clé : $604,589.92 de CA pour les courses complétés, $108,201.55 perdus par les courses annulées et $7,375.43 en cours

SELECT
    status,
    SUM(total_fare) AS "Chiffre d'affaires total"
FROM trips
GROUP BY status;

-- Question : Quel est le panier moyen par course ?
-- Enjeu : comprendre la valeur unitaire d'une course pour projeter la croissance du CA
-- Résultat clé : 1 course rapporte en moyenne $36.01

SELECT
    ROUND(AVG(total_fare), 2) AS "Panier moyen par course"
FROM trips;

-- Question : Quelle est la distance moyenne parcourue par course ?
-- Enjeu : caractériser le type de trajets dominant sur la plateforme
-- Résultat clé : 18.01 km par course en moyenne 

SELECT
    ROUND(AVG(distance_km), 2) AS "Distance moyenne par course"
FROM trips;

-- Question : Quelle est la durée moyenne d'une course ?
-- Enjeu : caractériser le temps d'occupation moyen d'un chauffeur par course
-- Résultat clé : une course dure environ 31.32 minutes

SELECT
    ROUND(AVG(duration_mins), 2) AS "Durée moyenne par course"
FROM trips;


--------------------------------
-- 3. ANALYSE DE LA DEMANDE
--------------------------------

-- Question : Comment le volume de courses évolue-t-il dans le temps ?
-- Enjeu : détecter les tendances saisonnières et anticiper les pics de demande
-- Résultat clé : la demande est plutôt homogène, avec des petits pics en mars.
-- L'activité n'augmente pas considérablement, mais en Novembre 2023 et janvier 2022,
-- le nombre de courses augmente d'environ 8% par rapport aux autres mois.

SELECT
    strftime('%Y-%m', requested_at) AS "Mois",
    COUNT(*) AS "Nombre de courses"
FROM trips
GROUP BY 1
ORDER BY 1;

-- Question : Quelles sont les villes les plus fréquentées ?
-- Enjeu : identifier les zones à fort potentiel de croissance et d'expansion
-- Résultat clé : la ville la plus fréquentée est Houston (5,329 courses et $224,894.41 de CA). Los Angeles compte 4,284 course pour $190,567.26 de CA

SELECT
    locations.city AS "Ville",
    COUNT(*) AS "Nombre de courses",
    SUM(total_fare) AS "Chiffre d'affaires"
FROM trips
JOIN locations ON trips.pickup_location_id = locations.location_id
GROUP BY locations.city
ORDER BY "Chiffre d'affaires" DESC;

-- Question : Quels types de zones (commerciales, résidentielles, transitaires) sont les plus performants ?
-- Enjeu : orienter les efforts d'acquisition chauffeurs/riders vers les zones les plus rentables
-- Résultat clé : les zones les plus performantes sont : Los Angeles (résidentielle) avec 2,147 courses pour $103,707.01 de CA.
-- Le transit-hub de Chicago ne représente que 490 courses pour $10,738.09 de CA.

SELECT
    locations.city AS "Ville",
    locations.zone_type AS "Type de zone",
    COUNT(*) AS "Nombre de courses",
    SUM(total_fare) AS "Chiffre d'affaires"
FROM trips
JOIN locations ON trips.pickup_location_id = locations.location_id
GROUP BY locations.city, locations.zone_type
ORDER BY "Chiffre d'affaires" DESC;

-- Question : Quels sont les créneaux Jour / Heure les plus demandés ?
-- Enjeu : ajuster la disponibilité chauffeurs et le pricing dynamique aux pics de demande
-- Résultat clé : les créneaux les plus demandés sont le vendredi à 11h, le jeudi à 18h, le mercredi à 2h et 19h. 

WITH jour_semaine AS (
    SELECT
        strftime('%w', requested_at) AS jour,
        strftime('%H', requested_at) AS heure,
        trip_id
    FROM trips
)
SELECT
    CASE
        WHEN jour = '0' THEN 'Dimanche'
        WHEN jour = '1' THEN 'Lundi'
        WHEN jour = '2' THEN 'Mardi'
        WHEN jour = '3' THEN 'Mercredi'
        WHEN jour = '4' THEN 'Jeudi'
        WHEN jour = '5' THEN 'Vendredi'
        WHEN jour = '6' THEN 'Samedi'
    END AS "Jour de la semaine",
    heure AS "Heure de la journée",
    COUNT(trip_id) AS "Nombre de courses"
FROM jour_semaine
GROUP BY "Jour de la semaine", heure
ORDER BY "Nombre de courses" DESC
LIMIT 10;


--------------------------------
-- 4. QUALITÉ DE SERVICE & ANNULATIONS
--------------------------------

-- Question : Quel est le taux d'annulation global des courses ?
-- Enjeu : mesurer l'ampleur du problème avant d'en chercher les causes
-- Résultat clé : 14.83% des courses sont annulées. Ce niveau élevé justifie une analyse des causes en priorité

SELECT
    100.0 * COUNT(cancellations.trip_id) / COUNT(trips.trip_id) AS "Taux d'annulation"
FROM trips
LEFT JOIN cancellations ON trips.trip_id = cancellations.trip_id;

-- Question : Quelles sont les principales raisons d'annulation, et qui les déclenche ?
-- Enjeu : distinguer les causes évitables (chauffeur, rider) des causes structurelles
-- Résultat clé : Les annulations proviennent majoritairement des utilisateurs, principalement en raison d'un temps d'attente jugé trop long ou d'un changement d'avis.

SELECT
    reason AS "Raison de l'annulation",
    cancelled_by AS "Annulé par",
    ROUND(
        100.0 * COUNT(cancel_id) / SUM(COUNT(cancel_id)) OVER (),
        2) AS "Taux d'annulation de la raison"
FROM cancellations
GROUP BY reason, cancelled_by
ORDER BY "Taux d'annulation de la raison" DESC;

-- Question : Qui annule le plus souvent une course (rider, chauffeur, système) ?
-- Enjeu : cibler la partie prenante à responsabiliser en priorité
-- Résultat clé : les utilisateurs sont responsables de 69.76% des annulations. Ils sont à responsabiliser.
-- En revanche, nous pouvons responsabiliser les chauffeurs plus rapidement et efficacement que les utilisateurs.

SELECT
    cancelled_by AS "Auteur de l'annulation",
    ROUND(
        100.0 * COUNT(cancel_id) / SUM(COUNT(cancel_id)) OVER(),
        2) AS "Taux d'annulation"
FROM cancellations
GROUP BY cancelled_by
ORDER BY "Taux d'annulation" DESC;


-- Question : Quels types de courses sont les plus souvent annulés par les chauffeurs ?
-- Enjeu : identifier les types de courses qui génèrent le plus de refus côté chauffeur afin d'optimiser .
-- Résultat clé : les chauffeurs ont annulé 499 courses longue distance à très haute valeur.
-- Les chauffeurs ont tendance à annuler le plus souvent les longues distance.

WITH driver_cancellations AS (
    SELECT trip_id
    FROM cancellations
    WHERE cancelled_by = 'driver'
),
trajet_cte AS (
    SELECT
        t.trip_id,

        CASE
            WHEN duration_mins < 5 THEN 'Trajet très court'
            WHEN duration_mins < 10 THEN 'Trajet court'
            WHEN duration_mins < 15 THEN 'Trajet moyen'
            ELSE 'Trajet long'
        END AS type_duree,

        CASE
            WHEN distance_km < 5 THEN 'Distance mini'
            WHEN distance_km < 10 THEN 'Distance courte'
            WHEN distance_km < 15 THEN 'Distance standard'
            ELSE 'Distance longue'
        END AS type_distance,

        CASE
            WHEN total_fare < 5 THEN 'Faible valeur'
            WHEN total_fare < 10 THEN 'Valeur moyenne'
            WHEN total_fare < 15 THEN 'Valeur élevée'
            ELSE 'Très haute valeur'
        END AS type_prix,
        distance_km,
        total_fare

    FROM trips t
    JOIN driver_cancellations dc ON t.trip_id = dc.trip_id
)
SELECT
    type_duree AS "Durée du trajet",
    type_distance AS "Distance du trajet",
    type_prix AS "Catégorie de tarif",
    COUNT(*) AS "Nombre d'annulations"    
FROM trajet_cte
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

-- Question : Combien de chiffre d'affaires est perdu à cause des annulations ?
-- Enjeu : chiffrer l'impact financier du problème pour justifier un plan d'action
-- Résultat clé : la plateforme perd $108,201.55 de CA potentiel dû aux annulations.
-- En tête : l'urgence personnelle ($15,139.51). Mais si l'on regroupe les 2 catégories
-- liées à l'attente ("too long wait" et "waited too long"), leur impact cumulé 
-- atteint $20,428.68, la première cause de CA perdu. Comprendre pourquoi les temps
-- d'attente sont trop élevés (zones à forte demande, disponibilité des chauffeurs 
-- insuffisante à certains créneaux ?) devrait être la priorité.

WITH cancel_cte AS (
    SELECT
        cancellations.reason AS "Raison d'annulation",
        SUM(trips.total_fare) AS ca_potentiel_perdu,
        COUNT(*) AS "Nombre d'annulations",
        ROUND(AVG(trips.total_fare), 2) AS "Montant moyen des courses annulées"
    FROM cancellations
    JOIN trips ON cancellations.trip_id = trips.trip_id
    GROUP BY cancellations.reason
)
SELECT
    "Raison d'annulation",
    ca_potentiel_perdu AS "CA potentiel perdu",
    "Nombre d'annulations",
    "Montant moyen des courses annulées",
    ROUND(SUM(ca_potentiel_perdu) OVER (ORDER BY ca_potentiel_perdu DESC), 2) AS "CA cumulé"
FROM cancel_cte
ORDER BY ca_potentiel_perdu DESC;

-- Question : Quelles villes cumulent le plus d'annulations et les notes chauffeur les plus basses ?
-- Enjeu : repérer les zones où la qualité de service se dégrade, en priorité pour un plan correctif
-- Résultat clé : Houston et NYC cumulent le plus d'annulations (830 et 812), loin devant Chicago (664)
-- et Los Angeles (660). Mais les notes moyennes sont stables dans les 4 villes (4.28 à 4.38). Il n'y
-- a pas de lien entre la note du chauffeur et le volume d'annulations. Le problème à Houston et NYC
-- n'est donc pas une question de qualité de service, mais plus probablement à un facteur opérationnel
-- propre à ces villes (attente, disponibilité, densité de la demande) à creuser séparément.

SELECT
    locations.city AS "Ville",
    ROUND(AVG(drivers.rating), 2) AS "Note moyenne des chauffeurs",
    COUNT(cancellations.cancel_id) AS "Nombre total d'annulations"
FROM cancellations
JOIN trips ON cancellations.trip_id = trips.trip_id
JOIN drivers ON trips.driver_id = drivers.driver_id
JOIN locations ON trips.pickup_location_id = locations.location_id
GROUP BY locations.city
ORDER BY "Nombre total d'annulations" DESC;


--------------------------------
-- 5. RENTABILITÉ OPÉRATIONNELLE
--------------------------------

-- Question : Quelles catégories de trajets (par durée) sont les plus rentables au km et à la minute ?
-- Enjeu : identifier les types de courses à privilégier dans la stratégie de pricing et de matching
-- Résultat clé : les trajets courts sont nettement les plus rentables, aussi bien à la minute ($1.56)
-- qu'au kilomètre ($2.48), soit environ 60% de plus qu'un trajet très long à la minute ($0.97).
-- La rentabilité par minute décroît régulièrement avec la durée du trajet, ce qui suggère que le
-- temps est mieux valorisé sur des courses courtes et fréquentes que sur des longs trajets.
-- À noter que la rentabilité au km n'est pas parfaitement linéaire (les trajets très longs sont
-- légèrement plus rentable au km que les trajets longs), ce qui mériterait d'être creusé :
-- seuils tarifaires, trajets autoroutiers plus rapide qu'en ville... 

WITH courses_quartile AS (
    SELECT
        NTILE(4) OVER (ORDER BY duration_mins) AS quartile_duree,
        duration_mins,
        distance_km,
        total_fare
    FROM trips
)
SELECT
    CASE
        WHEN quartile_duree = 1 THEN 'Trajet court'
        WHEN quartile_duree = 2 THEN 'Trajet moyen'
        WHEN quartile_duree = 3 THEN 'Trajet long'
        ELSE 'Trajet très long'
    END AS "Catégorie durée",
    ROUND(SUM(total_fare) / SUM(duration_mins), 2) AS "CA par minute",
    ROUND(SUM(total_fare) / SUM(distance_km), 2) AS "CA par km",
    COUNT(*) AS "Nombre de courses",
    SUM(total_fare) AS "CA total",
    ROUND(AVG(total_fare), 2) AS "CA moyen"
FROM courses_quartile
GROUP BY quartile_duree;


--------------------------------
-- 6. PERFORMANCE CHAUFFEURS
--------------------------------

-- Question : Qui sont les 10 chauffeurs générant le plus de CA ?
-- Enjeu : identifier les profils à fidéliser en priorité
-- Résultat clé : George Gray génère le plus de CA ($4,265.13) sur 90 courses, suivi
-- d'Andrew Morales ($3,889.12 en 85 courses) et Jeffrey Ramirez ($3,854.21 en 87 courses).
-- Ce classement montre un lien logique entre volume de courses et CA généré : les écarts entre chauffeurs
-- du top 10 restent modérés, ce qui suggère une performance relativement homogène.

SELECT
    users.name AS "Chauffeur",
    COUNT(*) AS "Nombre de courses",
    ROUND(SUM(trips.total_fare), 2) AS "Chiffre d'affaires total généré"
FROM trips
JOIN drivers ON trips.driver_id = drivers.driver_id
JOIN users ON drivers.user_id = users.user_id
GROUP BY users.user_id
ORDER BY "Chiffre d'affaires total généré" DESC
LIMIT 10;


-- Question : Quels chauffeurs génèrent le plus de CA par heure travaillée ?
-- Enjeu : identifier les profils les plus efficaces, indépendamment du volume de courses
-- Résultat clé : Sarah Hall génère le + de revenus avec $88.85 par heure, suivie de Benjamin Carter,
-- avec $87.17 par heure. Le top 10 s'étend jusqu'à $81.02 par heure. Le nombre de courses total
-- n'affecte pas le revenus par heure.

SELECT
    users.name AS "Chauffeur",
    ROUND((SUM(trips.total_fare) / SUM(trips.duration_mins)) * 60, 2) AS "CA par heure",
    COUNT(*) AS "Nombre de courses",
    SUM(trips.total_fare) AS "CA total"
FROM trips
JOIN drivers ON trips.driver_id = drivers.driver_id
JOIN users ON drivers.user_id = users.user_id
GROUP BY users.user_id
ORDER BY "CA par heure" DESC
LIMIT 10;

-- Question : Quels chauffeurs génèrent le moins de CA par heure travaillée ?
-- Enjeu : repérer les profils à accompagner ou former pour améliorer leur rendement
-- Résultat clé : les 10 chauffeurs les moins performants génèrent en moyenne $56.38/h
-- soit 17.8% de moins que la moyenne globale des chauffeurs actifs ($68.57).
-- L'écart va jusqu'à -23.4% pour la pire performeuse (Emma Gray, $52.52/h). Tous ont
-- un volume suffisant (24 à 61 courses).

SELECT
    users.name AS "Chauffeur",
    ROUND((SUM(trips.total_fare) / NULLIF(SUM(trips.duration_mins), 0)) * 60, 2) AS "CA par heure",
    COUNT(*) AS "Nombre de courses",
    ROUND(SUM(trips.total_fare), 2) AS "CA total",
    ROUND(AVG((SUM(trips.total_fare) / NULLIF(SUM(trips.duration_mins), 0)) * 60) OVER (), 2) AS "CA par heure moyen (global)"
FROM trips
JOIN drivers ON trips.driver_id = drivers.driver_id
JOIN users ON drivers.user_id = users.user_id
WHERE trips.status = 'completed'
GROUP BY users.user_id
HAVING COUNT(*) >= 20
ORDER BY "CA par heure" ASC
LIMIT 10;

-- Question : Quels chauffeurs contribuent le plus aux annulations, en proportion de leur activité ?
-- Enjeu : distinguer un chauffeur qui annule beaucoup parce qu'il roule beaucoup d'un chauffeur
-- réellement problématique, pour cibler les actions correctives (formation, avertissement)
-- Résultat clé : le taux d'annulation du TOP 20 s'étale de 22.73% à 30.3%, sans décrochage isolé.
-- Le volume de courses varie fortement (33 à 74), et les taux élevés touchent aussi bien les 
-- petits volumes (Ryan Hall, 33 courses) que les gros (Susan Cook, 74 courses).

WITH trips_cte AS (
    SELECT
        driver_id,
        COUNT(*) AS total_courses
    FROM trips
    GROUP BY driver_id
)
SELECT
    users.name AS "Chauffeur",
    COUNT(trips.trip_id) AS "Nombre de courses",
    COUNT(cancellations.cancel_id) AS "Nombre d'annulations",
    ROUND(100.0 * COUNT(cancellations.cancel_id) / COUNT(trips.trip_id), 2) AS "Taux d'annulation"
FROM trips
JOIN drivers ON trips.driver_id = drivers.driver_id
JOIN users ON drivers.user_id = users.user_id
LEFT JOIN cancellations ON trips.trip_id = cancellations.trip_id
GROUP BY users.user_id
HAVING COUNT(trips.trip_id) >= 10
ORDER BY "Taux d'annulation" DESC;
