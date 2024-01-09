/*
-- =========================================================================== A
-- SSQA_req_lab4_min.sql
-- ---------------------------------------------------------------------------
Activité : IFT187_2022-3
Encodage : UTF-8, sans BOM; fin de ligne Unix (LF)
Plateforme : PostgreSQL 12 à 15
Responsable : Luc.Lavoie@USherbrooke.ca
Version : 0.1.0a
Statut : en vigueur
Résumé : Troisième jeu de requêtes sur le schéma SSQA (LAB4)
-- =========================================================================== A
*/

/*
== Objectifs

Ne conserver que les éléments essentiels du solutionnaire sous leur forme la plus
transportable (e.a.: pas de corps de la forme «begin atomic ... end» en raison
des erreurs toujours non corrigées de DataGrip, DBeaver, DBVisualizer).
*/

/*
T1.	Définir trois nouvelles unités de température: Kelvin, Celsius et Fahrenheit
    ainsi que les fonctions de conversion requises.
*/

-- Définir les types
create domain Celsius as
  mesure_valeur
  check (value >= -273.15);
create domain Kelvin as
  mesure_valeur
  check (value >= 0);
create domain Fahrenheit as
  mesure_valeur
  check (value >= -459.67);

-- Insérer les unités
insert into unite values
  ('°C', 'degré Celsius'),
  ('°F', 'degré Fahrenheit'),
  ('K', 'Kelvin');

-- Définir les fonctions

create or replace function convTempCK (c Celsius) returns Kelvin
return c + 273.15;
create or replace function convTempKC (k Kelvin) returns Celsius
return k - 273.15;
create or replace function convTempFC (f Fahrenheit) returns Celsius
return (f - 32) / 1.8;
create or replace function convTempCF (c Celsius) returns Fahrenheit
return (c * 1.8) + 32;
create or replace function convTempFK (f Fahrenheit) returns Kelvin
return (f - 459.67) * 1.8;
create or replace function convTempKF (k Kelvin) returns Fahrenheit
return (k * 1.8) + 459.67;

/*
T2.	L’attribut valide de la table Mesure n’étant pas utilisé, le retirer.
*/

alter table Mesure drop column valide ;

/*
T3.	Définir une procédure qui corrige les mesures d’une station s, pour la variable v,
    entre les dates d et f en ajoutant la quantité q à la mesure existante.
*/

create or replace procedure Corriger
  (s Station_code, v Variable_code, d Date, f Date, q Mesure_valeur)
language sql as
$$
  update mesure
  set valeur = valeur + q
  where station = s and variable = v and moment between d and f ;
$$;

/*
== Forme préférée, mais moins transportable au sein des ateliers intégrant PostgreSQL

create or replace procedure Corriger
  (s Station_code, v Variable_code, d Date, f Date, q Mesure_valeur)
begin atomic
  update mesure
  set valeur = valeur + q
  where station = s and variable = v and moment between d and f ;
end;
*/

/*
T4.	Ajouter les coordonnées minimales et maximales (longitude, latitude, altitude)
    au territoire. Utiliser ces attributs afin de définir une fonction de validation
    de l’association de stations aux territoires.
*/

-- Insérer les colonnes temporairement annulables avec valeur par défaut null
alter table Territoire
  add column longitude_min Longitude null,
  add column longitude_max Longitude null,
  add column latitude_min Latitude null,
  add column latitude_max Latitude null,
  add column altitude_min Altitude null,
  add column altitude_max Altitude null;

-- Ajuster les coordonnées des territoires présents
update Territoire
  set
    longitude_min =  45.0,
    longitude_max =  45.6,
    latitude_min  = -73.0,
    latitude_max  = -72.0,
    altitude_min  =  80,
    altitude_max  = 950
where code = 'Magog';
update Territoire
  set
    longitude_min =  45.2,
    longitude_max =  45.5,
    latitude_min  = -72.1,
    latitude_max  = -71.7,
    altitude_min  = 100,
    altitude_max  = 400
where code = 'Sherbrooke';

-- Retirer la valeur par défaut et le marqueur annulable
alter table Territoire
  alter column longitude_min drop default,
  alter column longitude_max drop default,
  alter column latitude_min drop default,
  alter column latitude_max drop default,
  alter column altitude_min drop default,
  alter column altitude_max drop default,
  alter column longitude_min set not null,
  alter column longitude_max set not null,
  alter column latitude_min set not null,
  alter column latitude_max set not null,
  alter column altitude_min set not null,
  alter column altitude_max set not null;

-- Définir la fonction qui repère les stations extra-territoriales

create function Detection_extra_territoriale ()
  returns table (
    station Station_Code,
    longitude Longitude,
    latitude Latitude,
    altitude Altitude
    )
language sql as
$$
select station, longitude, latitude, altitude
from territoire
  join distribution on (territoire.code=territoire)
  join station on (station.code=station)
where (longitude not between longitude_min and longitude_max)
   or (latitude not between latitude_min and latitude_max)
   or (altitude not between altitude_min and altitude_max);
$$;

/*
== Forme préférée, mais moins transportable au sein des ateliers intégrant PostgreSQL

create function Detection_extra_territoriale ()
  returns table (
    station Station_Code,
    longitude Longitude,
    latitude Latitude,
    altitude Altitude
    )
begin atomic
  select station, longitude, latitude, altitude
  from territoire
    join distribution on (territoire.code=territoire)
    join station on (station.code=station)
  where (longitude not between longitude_min and longitude_max)
     or (latitude not between latitude_min and latitude_max)
     or (altitude not between altitude_min and altitude_max);
end;
*/

/*
== Tests

update Territoire
  set longitude_min = 45.4 -- mauvaise valeur, aux fins de test
where code = 'Sherbrooke' ;
select * from Detection_extra_territoriale () as T ;

update Territoire
  set longitude_min = 45.2 -- bonne valeur
where code = 'Sherbrooke' ;
select * from Detection_extra_territoriale () as T ;
*/


/*
T5.	Choisir trois requêtes des laboratoires précédents pouvant faire l’objet d’un
    paramétrage et définir les fonctions associées.
*/

-- S01. Combien y a-t-il eu de mesures par jour au mois m de l'année a?
--      Présenter les résultats en ordre décroissant de date.
--      Le mois est représenter par son rang : 1=janvier ... 12=décembre

create or replace function mesure_par_mois (m Integer, a Integer) returns
  table (date Date, nbMesures Bigint)
language sql as
$$
  select cast(moment as Date) as date, count(*) AS nbMesures
  from Mesure
  where extract(YEAR from moment) = a and extract(MONTH from moment) = m
  group by cast(moment as Date)
  order by date desc;
$$;

/*
== Forme préférée, mais moins transportable au sein des ateliers intégrant PostgreSQL

create or replace function mesure_par_mois (m Integer, a Integer) returns
  table (date Date, nbMesures Bigint)
begin atomic
  select cast(moment as Date) as date, count(*) AS nbMesures
  from Mesure
  where extract(YEAR from moment) = a and extract(MONTH from moment) = m
  group by cast(moment as Date)
  order by date desc;
end;
*/

/*
== Tests

select *
from mesure_par_mois (2, 2016) as toto ;
*/

/*
-- =========================================================================== Z
Contributeurs :
  (CK01) Christina.Khnaisser@USherbrooke.ca,
  (LL01) Luc.Lavoie@USherbrooke.ca

Adresse, droits d’auteur et copyright :
  Groupe Metis
  Département d’informatique
  Faculté des sciences
  Université de Sherbrooke
  Sherbrooke (Québec)  J1K 2R1
  Canada
  http://info.usherbrooke.ca/llavoie/
  [CC-BY-NC-4.0 (http://creativecommons.org/licenses/by-nc/4.0)]

Tâches projetées :
  NIL

Tâches réalisées :
  2022-11-26 (LL01) : Création initiale.

Références :
  [epp] http://info.usherbrooke.ca/llavoie/enseignement/Modules/SSQA_EPP_2022-3b.pdf

-- -----------------------------------------------------------------------------
-- SSQA_req_lab4_min.sql
-- =========================================================================== Z
*/
