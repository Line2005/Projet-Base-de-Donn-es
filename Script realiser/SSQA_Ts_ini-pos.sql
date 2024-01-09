/*
============================================================================== A
TS_ini-pos.sql
------------------------------------------------------------------------------ A
Produit : Base de données SSQA
Résumé : script d'insertion des données positives
Projet : SSQA_v2022.3a
Responsable: wilfried.djegue@2022.ucac-icam.com
Version : 2022-12-11
Statut : en vigueur
Encodage : UTF-8 sans BOM, fin de ligne Unix (LF)
Plateforme : PostgreSQL 9.4.4 à 10.4
============================================================================== A
*/

/*
Insertion des données valides à des fins de tests unitaires pour les tables
du schéma SSQA (système de surveillance de la qualité de l'air). Les données
ne sont pas nécessairement conforme à la réalité, bien que représentatives.
*/

-- Localisation du schéma
set schema 'SSQA';
  
-- Unite
insert into Unite (sym, nom, nomgrandeur, symgrandeur,symdimension,definition_unite) values
  ('s', 'seconde', 'temps', 't', 'T','mesure de l évolution des phénomènes'),
  ('h', 'heure', 'temps', 't', 'T','mesure de l évolution des phénomènes'),
  ('a', 'année', 'temps', 't', 'T','mesure de l évolution des phénomènes'),
  ('ug/m3', 'microgramme par mètre cube', 'masse volumique', 'P', 'ML','quantité de matière se trouvant dans un espace'),
  ('ppm', 'parties par million', 'masse', 'm', 'M','quotient sans dimension représentant un rapport de 10^-6'),
  ('ppb', 'parties par milliard', 'masse', 'm', 'M','quotient sans dimension représentant un rapport de 10^-9');
  
-- Variable
insert into Variable (code, nom, unite, valref, methode) values
  ('NO2', 'Dioxyde d’azote', 'ppb', 213, 'ACQ256'),
  ('SO2', 'Dioxyde de soufre', 'ppb', 200, 'GSJ582'),
  ('CO', 'Monoxyde de carbone', 'ppm', 30, 'DDF558'),
  ('PM25', 'Particules fines', 'ug/m3', 35, 'DDQ477'),
  ('O3', 'Ozone', 'ppb', 82, 'ASU855');

-- Norme
insert into Norme (code, titre) values
  ('NQMAA_2014', 'Normes québécoises de mesure de l’air ambiant, édition 2014'),
  ('NCQAA_2015', 'Normes canadiennes de qualité de l’air ambiant, édition 2015'),
  ('NCQAA_2020', 'Normes canadiennes de qualité de l’air ambiant, édition 2020'),
  ('NCQAA_2025', 'Normes canadiennes de qualité de l’air ambiant, édition 2025');

-- validation
insert into validation (variable, norme, min, max) values
  ('NO2', 'NQMAA_2014', 0, 600),
  ('SO2', 'NQMAA_2014', 0, 700),
  ('CO', 'NQMAA_2014', 0, 100),
  ('PM25', 'NQMAA_2014', 0, 200),
  ('O3', 'NQMAA_2014', 0, 800);

-- Station
insert into Station (code, nom, longitude, latitude, altitude, mise_en_service, fin_exploitation) values
  -- Territoire de Sherbrooke (données fictives)
      ('10000', 'Arr. Brompton', '45.4738', '-71.9437', '170', '2000-01-01', '2000-12-31'),
      ('12000', 'Arr. Fleurimont', '45.4037', '-71.8678', '180', '2001-01-01', '2001-12-31'),
      ('13000', 'Arr. Lennoxville', '45.3675', '-71.8564', '160', '2002-01-01', '2002-12-31'),
      ('14000', 'Arr. Mont-Bellevue', '45.3787', '-71.9054', '200', '2003-01-01', '2003-12-31'),
      ('15000', 'Arr. de Rock-Forest-Saint-Élie-Deauville', '45.3703', '-71.9900', '151', '2004-01-01', '2004-12-31'),
      ('16000', 'Arr. de Jacques-Cartier', '45.4018', '-71.9248', '130', '2005-01-01', '2005-12-31');
  -- Territoire de Memprémagog (à venir)
  -- autres territoires...


-- Capacité
insert into Capacite (station, variable) values
  -- Territoire de Sherbrooke (données fictives)
  -- Noter que la station 16000 n'a pas la capcité de retourner des mesures de la variable O3.
    ('10000', 'NO2'), ('10000', 'SO2'), ('10000', 'CO'), ('10000', 'PM25'), ('10000', 'O3'),
    ('12000', 'NO2'), ('12000', 'SO2'), ('12000', 'CO'), ('12000', 'PM25'), ('12000', 'O3'),
    ('13000', 'NO2'), ('13000', 'SO2'), ('13000', 'CO'), ('13000', 'PM25'), ('13000', 'O3'),
    ('14000', 'NO2'), ('14000', 'SO2'), ('14000', 'CO'), ('14000', 'PM25'), ('14000', 'O3'),
    ('15000', 'NO2'), ('15000', 'SO2'), ('15000', 'CO'), ('15000', 'PM25'), ('15000', 'O3'),
    ('16000', 'NO2'), ('16000', 'SO2'), ('16000', 'CO'), ('16000', 'PM25');
  -- Territoire de Memprémagog (à venir)
  -- autres territoires

-- Territoire
insert into Territoire (code, nom, region, municipalite, arrondissement, quartier) values
  ('Magog', 'Canton de Memprémagog', 'Magog', '0 habitants', 'sud-QUEBEC','gamma'),
  ('Sherbrooke', 'Ville de Sherbrooke', 'Estrie', '16 700 habitants', 'Brompton',  'gamma');

-- Distribution
insert into Distribution (territoire, station) values
  ('Sherbrooke', '10000'),
  ('Sherbrooke', '12000'),
  ('Sherbrooke', '13000'),
  ('Sherbrooke', '14000'),
  ('Sherbrooke', '15000'),
  ('Sherbrooke', '16000');

-- ExigenceC
insert into ExigenceC (norme, code, variable) values
  -- Diaoxyde d'azote
    ('NCQAA_2020', 'A1', 'NO2'),
    ('NQMAA_2014', 'A1', 'NO2'),
    ('NCQAA_2015', 'A2', 'NO2'),
    ('NCQAA_2025', 'A2', 'NO2'),
  -- Diaoxyde de soufre
    ('NCQAA_2020', 'B1', 'SO2'),
    ('NCQAA_2025', 'B1', 'SO2'),
    ('NQMAA_2014', 'B2', 'SO2'),
    ('NCQAA_2015', 'B2', 'SO2'),
  -- Particules fines
    ('NQMAA_2014', 'C1', 'PM25'),
    ('NCQAA_2020', 'C1', 'PM25'),
    ('NCQAA_2015', 'C2', 'PM25'),
    ('NCQAA_2025', 'C2', 'PM25'),
  -- Ozone
    ('NCQAA_2015', 'D1', 'O3'),
    ('NCQAA_2020', 'D1', 'O3'),
    ('NCQAA_2025', 'D1', 'O3');
--Exigence_variable

insert into Exigence_variable(variable, periode_valeur, periode_unite, min, max) values
  -- Diaoxyde d'azote
    ( 'NO2', 1, 'h', 0, 60),
    ( 'NO2', 2, 'h', 0, 42),
    ( 'NO2', 1, 'a', 0, 17.0),
    ( 'NO2', 2, 'a', 0, 12.0),
  -- Diaoxyde de soufre
    ( 'SO2', 3, 'h', 0, 70),
    ( 'SO2', 5, 'h', 0, 65),
    ( 'SO2', 3, 'a', 0, 5.0),
    ( 'SO2', 4, 'a', 0, 4.0),
  -- Particules fines
    ( 'PM25', 24, 'h', 0, 20),
    ('PM25', 25, 'h', 0, 27),
    ( 'PM25', 5, 'a', 0, 10.0),
    ( 'PM25', 6, 'a', 0, 8.8),
  -- Ozone
    ( 'O3', 8, 'h', 0, 63),
    ( 'O3', 10, 'h', 0, 62),
    ( 'O3', 9, 'h', 0, 60);

-- Indisponibilité
insert into indisponibilite (station, debut, fin) values
    ('10000', '2000-05-01', '2000-05-31'),
    ('12000', '2001-03-01', '2001-03-31'),
    ('13000', '2002-07-01', '2002-07-30'),
    ('14000', '2003-06-01', '2003-06-30');

--mobilité
insert into mobilite (station, longitude, latitude, altitude, date_mobilite) values
    ('15000', '45.3703', '-71.9900', '151', '2004-02-29'),
    ('16000', '45.4018', '-71.9248', '130', '2005-10-02');

-- Mesure
--
-- Les mesures peuvent être importées séparément, à raison d'un fichier par
-- territoire, par exemple : SSQ_ins_mesure_Sherbrooke.sql pour le territoire
-- de Sherbrooke.

/*
============================================================================== Z
TS_ini-pos.sql
------------------------------------------------------------------------------ Z
.Contributeurs
 (CK01) wilfried.djegue@2027.ucac-icam.com
 (LL01) line.ndientieng@2027.ucac-icam.com
 (LL02)charles.dikoume@2027.ucac-icam.com
 (LL03)valerdy.nguimbi@2027.ucac-icam.com
.Droits, licences et adresses
 Copyright 2016-2022, GRIIS
 Le code est sous licence
 LILIQ-R 1.1 (https://forge.gouv.qc.ca/licence/liliq-v1-1/).
 La documentation est sous licence
 CC-BY 4.0 (https://creativecommons.org/licenses/by/4.0/).
 GRIIS (Groupe de recherche interdisciplinaire en informatique de la santé)
 Faculté des sciences et Faculté de médecine et sciences de la santé
 Université de Sherbrooke (Québec) J1K 2R1 CANADA
 http://griis.ca
.Tâches projetées
 2013-09-09 (LL01) : insérer des données valides 
.Tâches réalisées
 2013-09-03 (LL01) : insertion des données valides
 
 [mod] http://info.usherbrooke.ca/llavoie/enseignement/Modules/
============================================================================== Z
*/