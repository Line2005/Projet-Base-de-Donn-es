/*
============================================================================== A
TS_imm.sql
------------------------------------------------------------------------------ A
Produit : Base de données SSQA
Résumé : script d'interface machine machine de la base de données
Projet : SSQA_v2022.3a
Responsable: wilfried.djegue@2022.ucac-icam.com
Version : 2022-12-11
Statut : en vigueur
Encodage : UTF-8 sans BOM, fin de ligne Unix (LF)
Plateforme : PostgreSQL 9.4.4 à 10.4
============================================================================== A
*/




R01.	Combien y a-t-il de variables mesurées avec l’unité ppb ?
--      Donner le nombre.
--
select count(*)
from Variable
where unite = 'ppb' ;

-- R02. Quelles sont les stations situées à une altitude supérieure à 175 mètres ?
--      Donner les identifiants de station.
--
select code
from Station
where altitude >= 175 ;

-- R03. Quelles sont les stations ayant fourni des mesures de la variable CO ?
--      Donner les identifiants de station.
--
select distinct station
from Mesure
where variable = 'CO';

-- R04. Quels sont les intervalles de validation dont l’écart est d’au moins 400 unités?
--      Donner la norme, la variable, le min, le max et l’unité.
--
-- Clarifications :
--  * L’intervalle de validation est défini par la table Seuils.
--  * L’unité n’est pas présente dans la table Seuils, nous l’omettrons dans un premier temps.

select norme, variable, min, max
from Seuils
where max-min >= 400;

-- Il serait aussi possible d’ajouter l’écart...
select distinct norme, variable, min, max, max-min as ecart
from Seuils
where max-min >= 400;

-- et de présenter le tout sous la forme d’un «rapport».
select distinct
  variable                        as "Variable dont l’écart de validation est d’au moins 400",
  norme                           as "Norme d’origine",
  '[' || min || '..' || max ||']' as "Intervalle de validation",
  max-min                         as "Ecart effectif"
from Seuils join Variable on (code=variable)
where max-min >= 400;

-- Finalement, pour ajouter l’unité, il faut une jointure.
select distinct norme, variable, min, max, unite
from Seuils join Variable on (code=variable)
where max-min >= 400;

-- R05. Quelles sont les stations de la région de Sherbrooke capable de mesurer la variable O3 ?
--      Donner les identifiants de station.
--
select station
from Distribution natural join Capacite
where territoire = 'Sherbrooke' and variable = 'O3';

-- Pourquoi le «distinct» est-il superflu dans la solution de R05 ?

-- R06. Quelles sont les unités dont la valeur de référence n’est pas comprise
--      dans au moins un intervalle de validation applicable ?
--      Donner l’unité, sa valeur de référence, l’intervalle de validation et la norme dont il provient.
--
-- Clarification :
--   Les valeurs de références sont associées aux variables, non aux unités;
--   il faut corriger le libellé de la requête en conséquence.
--
select code, valref, min, max, norme
from Variable join Seuils on (code=variable)
where not (valref between min and max) ;

-- R07. Quels sont les territoires ayant au moins une station à plus de 800 mètres d’altitude?
--      Donner les identifiants de territoire.
--
select distinct Territoire.code, Territoire.nom
from Station
  join Distribution on (station.code=station)
  join Territoire on (territoire.code=territoire)
where altitude >= 800;

-- R08. Quelles sont les stations n’ayant aucune mesure ?
--      Donner l’identifiant, le nom, la longitude, la latitude et l’altitude de chaque station.
--
with
  StationSansMesure as
    (
    select code
    from Station
    except
    select station as code
    from mesure
    )
select code, nom, longitude, latitude, altitude
from StationSansMesure
  join Station using (code);

-- R09a. Quelles sont les stations pouvant mesurer au moins UNE des variables mesurées par la station 12000 ?
--      Donner l’identifiant, le nom, la longitude, la latitude et l’altitude de chaque station.
--
with
  M12000 as
    (
    select distinct variable from Capacite where station = '12000'
    )
select distinct station from Capacite where variable in (select * from M12000);

-- R09b. Quelles sont les stations pouvant mesurer au moins TOUTES les variables mesurées par la station 12000 ?
--      Donner l’identifiant, le nom, la longitude, la latitude et l’altitude de chaque station.
--
with
  M12000 as
    (
    select distinct variable from Capacite where station = '12000'
    )
select *
from Station
where not exists (
  select 1
  from M12000
  where variable not in (select variable from Capacite where station=code)
  );

-- R10a. Selon la norme NCQAA_2020, quelles sont les stations qui ont ponctuellement
--       dépassé durant UN MÊME MOMENT les exigences B1 et C1 ?
--       Présenter le résultat de façon appropriée.
--
-- Clarification
--   * Par «dépasser une exigence» on signifie «enfreindre cette exigence»
--
-- TODO 2022-11-26 (LL01) Reformuler les requêtes à l’aide de fonctions paramétriques
--  * De telle sorte à éviter les jointures.
--
with
  B1 as (
    select distinct station, moment
    from mesure join exigence using(variable)
    where norme='NCQAA_2020' and code='B1' and valeur not between min and max
    ),

  C1 as (
    select distinct station, moment
    from mesure join exigence using(variable)
    where norme='NCQAA_2020' and code='C1' and valeur not between min and max
    )
select *
from B1 natural join C1;

-- R10b. Selon la norme NCQAA_2020, quelles sont les stations qui ont ponctuellement
--       dépassé durant UNE MÊME JOURNÉE les exigences B1 et C1 ?
--       Présenter le résultat de façon appropriée.
--
with
  B1 as (
    select distinct station, cast (moment as Date)
    from mesure join exigence using(variable)
    where norme='NCQAA_2020' and code='B1' and valeur not between min and max
    ),

  C1 as (
    select distinct station, cast (moment as Date)
    from mesure join exigence using(variable)
    where norme='NCQAA_2020' and code='C1' and valeur not between min and max
    )
select *
from B1 natural join C1;

/*











S01. Combien y a-t-il eu de mesures par jour en janvier 2016?
--      Présenter les résultats en ordre décroissant de date.

select cast(moment as Date) as date, count(*) AS nbMesures
from Mesure
where extract(YEAR from moment) = 2016 and extract(MONTH from moment) = 1
group by cast(moment as Date)
order by date desc;

-- S02.	Quelles sont les stations capables de plus de 4 variables?
--      Présenter les identifiants de station en ordre croissant.

-- V1. En termes de capacité.
select station, count(distinct variable) as nbVariables
from Capacite
group by station
having count(distinct variable) > 4
order by station asc;

-- V2. En termes de mesures effectives.
select station, count(distinct variable) as nbVariables
from Mesure
group by station
having count(distinct variable) > 4
order by station asc;

-- S03.	Combien de fois une variable a-t-elle été mesurée par chacune des stations?
--      Afficher '0' si la variable n’a jamais été mesurée.

with MesuresPS as -- Calculer le nombre de mesures des variables par stations.
  (
    select station, variable, count(*) as nbMPS
    from mesure
    group by station, variable
    )
select S.code as station, V.code as variable, coalesce(nbMPS, 0)
from Station as S
  cross join Variable as V
  left join MesuresPS on (S.code=station and V.code=variable)
order by station, variable;

--
-- S04.	Quelles sont les stations qui mesurent toutes les variables?
--      Faire cette requête sans décompte (count) ni regroupement (group by).
--      Présenter les résultats adéquatement.

-- V1. En termes de capacité.
with
  S1 as (
    select distinct station, variable
    from Capacite
    )
select S2.code
from Station as S2
where not exists (
  select 1
  from Variable as V
  where V.code not in (
       select variable
       from S1
       where S1.station = S2.code and S1.variable = V.code
       )
  );

-- V2. En termes de mesures effectives.
with
  S1 as (
    select distinct station, variable
    from Mesure
    )
select S2.code
from Station as S2
where not exists (
  select 1
  from Variable as V
  where V.code not in (
       select variable
       from S1
       where S1.station = S2.code and S1.variable = V.code
       )
  );

--
-- S05.	Quelles sont les paires de stations qui mesurent les mêmes variables?
--      Présenter chacune des paires une seule fois.

-- V1. En termes de capacité.
with PS as (
  select distinct station, variable
  from Capacite
  )
select distinct P1.station, P2.station
from PS as P1, PS as P2
where P1.station < P2.station
  and not exists (
    select 1
    from PS
    where station = P1.station
      and variable not in (
        select variable
        from PS
        where station = P2.station
        )
  )
  and not exists (
    select 1
    from PS
    where station = P2.station
      and variable not in (
        select variable
        from PS
        where station = P1.station
        )
  )
order by P1.station, P2.station;

-- V2. En termes de mesures.
with PS as (
  select distinct station, variable
  from Mesure
  )
select distinct P1.station, P2.station
from PS as P1, PS as P2
where P1.station < P2.station
  and not exists (
    select 1
    from PS
    where station = P1.station
      and variable not in (
        select variable
        from PS
        where station = P2.station
        )
  )
  and not exists (
    select 1
    from PS
    where station = P2.station
      and variable not in (
        select variable
        from PS
        where station = P1.station
        )
  )
order by P1.station, P2.station;


-- S06.	Quelles sont les stations qui n’ont pas rapporté de mesures d’une variable bien qu’elles en aient la capacité?
--      Présenter les stations et les variables en question.

with
  CS as (
    select distinct station, variable
    from Capacite
    ),
  MS as (
    select distinct station, variable
    from Mesure
    )
select CS.station, CS.variable
from CS left join MS using (station, variable)
where MS.station is NULL
order by CS.station, CS.variable;

-- S07.	Calculer l’IQA de l’Estrie par mois.
--      Présenter la valeur de l’IQA et la qualification.
--  Clarification 1
-- 	 Pour chaque variable mesurée, un sous-indice est calculé selon la formule suivante:
-- 		  (valeur de la mesure/valeur de référence) * 50, arrondi à l’unité près.
-- 	  L’IQA d’une station correspond au plus élevé des sous-indices.
-- 	  L’IQA d’un territoire correspond au plus élevé des IQA mesurés aux stations représentatives du territoire.
--  Clarification 2
-- 	  Il n’est pas nécessaire que toutes les variables soient mesurées à une station pour calculer l’IQA.
--  Clarification 3
-- 	  Il existe trois qualifications de la qualité de l’air, chacune associée à un intervalle d’IQA:
-- 		  «bon» (IQA entre 0 et 25),
-- 		  «acceptable» (IQA entre 26 et 50) et
-- 		  «mauvais» (IQA supérieur à 50).

with
  SousIndice as (
    select
      variable,
      station,
      extract(year from moment) as annee,
      extract(month from moment) as mois,
      round((valeur/valref)*50.0) as valSousIndice
    from Variable join Mesure on (code=variable)
    ),
  IQAStation as (
      select station, annee, mois, max(valSousIndice) as valIQAStation
      from SousIndice
      group by station, annee, mois
      ),
  IQAMois as (
      select territoire, annee, mois, max(valIQAStation) as IQA
      from IQAStation join Distribution using (station)
      group by territoire, annee, mois
      )
select *,
  (case
     when IQA < 25 then 'Bon'
     when IQA between 26 and 50 then 'Acceptable'
     when IQA > 51 then 'Mauvais'
    end) as qualification
from IQAMois
order by annee, mois, territoire;

-- S08. Quelles sont les deux paires de stations dont les mesures sont les plus proches?
--      Pour chacune des paires, donner les indicateurs des variables en cause.
--      Clarifier, proposer et définir le concept de proximité.
--      Présenter le résultat de façon appropriée.
-- Astuce
--  Il faut combiner une technique de S05 (paires symétriques) et à la technique de S07.

-- Numéro laissé à votre ingéniosité. :-)
-- TODO 2022-11-29 (LL01) : Insérer ici les meilleures réponses étudiantes.

-- S09. Quelles sont les stations pouvant mesurer au moins TOUTES les variables mesurées par la station 12000 ?
--      Donner l’identifiant, le nom, la longitude, la latitude et l’altitude de chaque station.
--      Comparer avec R09a du LAB2.
--
with
  M12000 as (
    select distinct variable from Capacite where station = '12000'
    )
select *
from Station
where not exists (
  select 1
  from M12000
  where variable not in (select variable from Capacite where station=code)
  );

-- S10. Selon la norme NCQAA_2020, quelles sont les stations qui ont ponctuellement
--      dépassé durant UNE MÊME JOURNÉE les exigences B1 et C1 ?
--      Présenter le résultat de façon appropriée.
--      Comparer avec R10a du LAB2.
--
with
  B1 as (
    select distinct station, cast (moment as Date)
    from mesure join exigence using(variable)
    where norme='NCQAA_2020' and code='B1' and valeur not between min and max
    ),

  C1 as (
    select distinct station, cast (moment as Date)
    from mesure join exigence using(variable)
    where norme='NCQAA_2020' and code='C1' and valeur not between min and max
    )
select *
from B1 natural join C1;

/*














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




--Combien de fois chaque station a été indisponible jusqu'à une certaine date --

CREATE OR REPLACE FUNCTON station_indisponible(d date) 
RETURNS table(stations station_code, nbIndisponibilite Bigint)
LANGUAGE SQL AS
$$
SELECT station 	AS stations, count(station) AS nbIndisponibilite
FROM  indisponibilite
WHERE debut < d
GROUP BY station
ORDER BY station






--Combien de fois chaque station a été déplacée jusqu'à une certaine date --

CREATE OR REPLACE FUNCTON station_deplacee(dd date) 
RETURNS table(stations station_code, nbDeplacement Bigint)
LANGUAGE SQL AS
$$
SELECT station 	AS stations, count(station) AS nbDeplacement
FROM  mobilite
WHERE debut < dd
GROUP BY station
ORDER BY station





-- Vue servant à verififier  que les min et max de l'exigence sont compris dans l'intervalle de validation

CREATE VIEW validation_min_max AS
	 SELECT exigence_variable.min AS mine,exigence_variable.max AS maxe, validation.min AS minv, validation.max AS minv

	FROM Exigence_variable join validation using (variable)

	WHERE (exigence_variable.min BETWEEN validation.min AND validation.max

 	AND exigence_variable.max BETWEEN validation.min AND validation.max);





--VUE pour la valeur de référene d'une variable et selection des variables dont la valeur de référence n'appartiennent pas à l'intervalle de validation 

Create view validat°_valref  as
select code, valref, min, max, norme
  from Variable join Validation on (code=variable)
   where (valref NOT BETWEEN between min and max);

SELECT *
FROM validation_valref
 



--VUE pour les valeurs de référence  et la valeur de référence des variables 


CREATE VIEW validation_valref AS
SELECT code, valref, min, max
FROM variable join validation on code=variable;




--Fonction pour vérifier que la valeur de référence de la variable est comprise dans l'intervalle de validation 


CREATE FUNCTION verif_validat°(code_variable variable_code)
RETURNS text
LANGUAGE SQL AS 
$$
SELECT 'la valeur de référence de la variable n est pas comprise dans lintervalle de validation'
WHERE NOT EXISTS( SELECT valref
	    from validation_valref
	    WHERE code= code_variable AND valref BETWEEN min AND max)
$$




-- Procédure pour ajouter directement des unités dans la table  

CREATE OR REPLACE PROCEDURE Ajout_unite( symx Unite_sym, nomx Unite_nom, symgrandeurx Unite_sym, nomgrandeurx Unite_nom symdimensionx Unite_sym)
LANUAGE SQL AS
$$
INSERT INTO Unite(sym, nom, dimension, symgrandeur, nomgrandeur, symdimension) VALUES 
('symx', 'nomx', 'dimensionx', 'symgrandeurx', 'nomgrandeurx', 'symdimensionx')
$$
;

--Combien de fois chaque station a été indisponible jusqu'à une certaine date --

CREATE OR REPLACE FUNCTON station_indisponible(d date) 
RETURNS table(stations station_code, nbIndisponibilite Bigint)
LANGUAGE SQL AS
$$
SELECT station 	AS stations, count(station) AS nbIndisponibilite
FROM  indisponibilite
WHERE debut < d
GROUP BY station
ORDER BY station
;








-- Procédure pour ajouter directement des unités dans la table  
CREATE OR REPLACE PROCEDURE Ajout_unite( symx Unite_sym, nomx Unite_nom, symgrandeurx Unite_sym, nomgrandeurx Unite_nom symdimensionx Unite_sym)
LANUAGE SQL AS
$$
INSERT INTO Unite(sym, nom, dimension, symgrandeur, nomgrandeur, symdimension) VALUES 
('symx', 'nomx', 'dimensionx', 'symgrandeurx', 'nomgrandeurx', 'symdimensionx');






--automatisme et triigger  qui affichent un message lorsque la valeur de la mesure pour un tuple dans la table mesure est nulle


create or replace function mesure_valeur_absente ()
returns trigger
language plpgsql as
$$
begin 
  if not exists(select valeur
			from mesure
			where valeur is null )
  then
  return new; -- proceed
  else
  raise info 'Entre les cause dans la table cause_echec';
  return new; 
  end if;
end
 $$
  
  create trigger cause_echec
  after insert or update on mesure
  execute procedure mesure_valeur_absente();






/*
============================================================================== Z
TS_imm.sql
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
 2013-09-09 (LL01) : * définir une interface machine-machine (IMM) pour la base de données reprenant l’essentiel des fonctions, 
procédures et requêtes déjà réalisées;
		     * ajouter à l’IMM des procédures et fonctions permettant d’exploiter les nouvelles possibilités offertes par la nouvelle
BD 
.Tâches réalisées
 2013-09-03 (LL01) : *création de vues , de fonctions, de requêtes d'automartismes et déclencheurs
 
 [mod] http://info.usherbrooke.ca/llavoie/enseignement/Modules/
============================================================================== Z
*/
