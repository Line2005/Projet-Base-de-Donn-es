/*
============================================================================== A
TS_mig.sql
------------------------------------------------------------------------------ A
Produit : Base de données SSQA
Résumé : script SQL de migration de la BD — domaines, types, tables
Projet : SSQA_v2022.3a
Responsable: wilfried.djegue@2022.ucac-icam.com
Version : 2022-12-11
Statut : en vigueur
Encodage : UTF-8 sans BOM, fin de ligne Unix (LF)
Plateforme : PostgreSQL 9.4.4 à 10.4
============================================================================== A
*/



-- Unité
--

comment on table Unite is $$
predicat:L’unité de mesure définie en termes des unités fondamentales du SI est identifiée
         par le symbole «sym»,porte le nom «nom» est decrite par sa definition<<definition_unite>>,
         quantifie une grandeur identifiée par le symbole <<symgrandeur>> portant le nom <<nomhgrandeur>> et possede une dimension <<symdimension>>

df:sym -> nom,symgrandeur, nomgrandeur, symdimension, definition_unite
clé_id: {sym}
$$;

-- TODO 2022-11-24 (LL01) Ajouter les attributs requis par la définition en termes des unités fondamentales du SI.
    set schema 'SSQA';
    alter table Unite   
     add column definition_unite Text not null,
     add column symgrandeur Unite_Symbole not null,
     add column nomgrandeur Unite_Nom not null,
     add column symdimension Unite_Symbole not null;
   

-- TODO 2022-11-24 (LL01) Contraindre plus strictement les symboles.
   set schema 'SSQA';
   alter domain Unite_Symbole add check
    (
   value similar to '[a-z]{1,4}' or value similar to '[A-Z]{1,4}'
   or value similar to '[A-Z]{1,2}[a-z]{1,2}' or 
   value similar to '[a-z]{1,4}/[a-z]{1,3}[0-9]{1,2}'
     );
  alter table Unite 
  add constraint Unite_cc2 check(nom<>sym);

-- Variable
--
comment on table Variable is 
 $$ predicat : La variable associée à un phénomène mesurable par une station est identifiée
           par le code «code», se nomme «nom»; l’unité de mesure utilisée est «unite»,
           la valeur de référence est «valref» et la méthode d’échantillonnage est
           décrite par «methode».
df : code -> nom, valref, unite, methode
clé_id : {code}
clé_ref: {unite} -> Unite(sym)
$$;

-- DONE 2022-11-24 (LL01) Prendre en compte la valeur de référence et la méthode d’échantillonnage.
-- TODO 2022-11-24 (LL01) Afin de mieux valider les données, les méthodes devraient être codifiées.

   create domain Methode
   text
   check (value similar to '[A-Z]{3,10}[0-9]{1,3}');
   alter table Variable
   alter column methode type Methode;

-- Norme
--
comment on table Norme is $$
predicat: La norme identifiée par le code «code» est décrite dans le document portant le titre «titre».
df: code -> titre
clé_id: {code}
$$;

-- validation
--
comment on table Seuils is $$
predicat: L’intervalle de validation [«min»..«max»] de la variable «variable» est établi par la norme «norme».
df: norme, variable -> min, max
clé_id : {variable, norme}
clé_ref : {variable} -> Variable(code)
clé_ref : {norme} -> Norme(code)
$$;

-- DONE 2022-11-24 (LL01) Corriger le prédicat dela table Seuils en le définissant en terme d'intervalle.
-- TODO 2022-11-24 (LL01) Changer le nom de la table Seuils afin de refléter le concept d’intervalle de validation.
  
   alter table Seuils rename to Validation;

-- TODO 2022-11-24 (LL01) Vérifier que la valeur de référence de la variable est comprise dans l'intervalle de validation.

      select code, valref, min, max, norme
      from Variable join Validation on (code=variable)
      where (valref between min and max) ;

-- TODO 2022-11-24 (LL01) Vérifier que les min et max des exigences sont compris dans l'intervalle 
      set schema 'SSQA';
      select exigence.min as mine,exigence.max as maxe, validation.min as minv, validation.max as minv
      from Exigence join Validation using (variable)
      where (exigence.min between validation.min and validation.max
      and exigence.max between validation.min and validation.max);
   

-- Station
--
comment on table Station is $$
predicat: La station identifiée par «code» est située à la latitude «latitude»,
           à la longitude «longitude» et à l’altitude «altitude»; elle se nomme «nom» et
          à été en exploitation du <<mise_en_exploitation>> à <<fin_exploitation>>.
df: code -> nom, longitude, latitude, altitude
clé_id : {code}
$$;

alter table Station
alter column nom drop not null;

-- TODO 2022-11-20 (LL01) Ajout la date de mise en service, notamment à des fins de validation des temps de mesure.

alter table Station
add column mise_en_service Date not null,
add column fin_exploitation Date not null;

create table Indisponibilite (
  station Station_Code not null,
  debut Date not null,
  fin Date not null,
  constraint indisponibilite_cc0 primary key (station, debut, fin),--une station peut etre indisponible plusieur fois et deux station peuvent etre indisponible durant la meme periode
  constraint indisponibilite_cc1 foreign key(station) references Station(code)
);
comment on table Indisponibilite is $$
predicat: La station <<station>> est indisponible de la date <<debut>> à la date <<fin>>.
df:aucune
clé_id: {station,debut, fin}
clé_ref: {station} -> Station(code)
$$;

-- TODO 2022-11-20 (LL01) Modéliser la mobilité de certaines stations.

   create table Mobilite (
   station Station_Code not null,
   longitude Longitude not null,
   latitude Latitude not null,
   altitude Altitude not null,
   date_mobilite Date not null,
   constraint Mobilite_cc1 primary key (station,date_mobilite),
   constraint Mobilite_cc2 foreign key (station) references station(code)
   );
comment on table Mobilite is $$
predicat: La station <<station>> à été deplace à la date <<date_mobilite>>
          à la nouvelle position <<longitude>>,<<latitude>>, <<altitude>>.
df:aucune
clé_id: {station,date_mobilite}
clé_ref: {station} -> Station(code)
$$;

-- Capacité
--
comment on table Capacite is $$
predicat: La station «station» a la capacité de mesurer la variable «variable».
df-> aucune
clé_id: {station, variable}
clé_ref: {station} ->Station(code)
clé_ref: {variable} -> Variable(code)
$$;

-- Territoire
--
comment on table Territoire is $$
predicat:Le territoire identifié par «code» est connu sous le nom «nom» comporte 
         les region<<region>>, les municipalite<<municipalite>>, les arrondissement
        <<arrondissement>> et les quartier<<quartier>>.
df:code -> nom,region, municipalite, arrondissement, quartier
clé_id: {code}
$$;

-- TODO 2022-11-24 (LL01) Ajouter la description de l'organisation hiérarchique des territoires.

  alter table Territoire
  add column region Text not null,
  add column municipalite Text not null,
  add column arrondissement Text not null,
  add column quartier Text not null;

-- Distribution
--
comment on table Distribution is $$
predicat: La station «station» se rapporte au territoire «territoire».
df: aucune
clé_id: {territoire, station}
clé_ref: {territoire} -> Territoire(code)
$$;

-- Mesure
--
comment on table Mesure is $$
predicat:La valeur «valeur» de la mesure de la variable «variable» a été prise par la
         station «station», au temps «moment»; sa validité est «valide».
df: station,moment, variable -> valeur, valide
clé_id: {station,moment, variable}
clé_ref: {station} -> Capacite
clé_ref: {variable} -> Capacite
$$;

alter table Mesure 
add column cause_echec Text not null ;

--Pour rendre la valeur d'une mesure falcutative
Alter table Mesure
alter column valeur drop not null;

--Pour rendre la cause de l'echec facultative
alter table Mesure 
alter column cause_echec drop not null;

--Pour conserver l’information que la tentative de 
--mesure a eu lieu et de noter la cause de l’échec

ALTER TABLE mesure
ADD CONSTRAINT verif_cause CHECK (cause_echec IN ( 'le bris du capteur',
'l’instabilité du signal',
'l’erreur d’encodage de la mesure',
'la perte de la mesure suite à une erreur de stockage',
'la perte de la mesure suite à une erreur de transmission') );


-- QUESTION 2022-11-24 (LL01) La validité est-elle vraiment pertinente ? Si oui, sa représentation est-elle adéquate ?
--
-- Le modèle des Seuils est insuffisant en regard de la NCQAA, puisque les seuils
-- doivent être appliqués sur des périodes variables.
-- Bien que le «min» soit toujours égal à 0 dans les exigences actuelles de la NCQAA,
-- cela pourrait changer en regard de futures variables.
-- Le modèle de Seuils est cependant approprié pour vérifier les seuils de validité
-- des mesures elles-mêmes; enn conséquence il sera conservé également.
--
-- DONE 2022-11-24 (LL01) Les exigences normatives sont différentes des intervalles de validation.
--  * Ajouter une relation décrivant les exigences.
--

-- Exigence
--
-- TODO 2022-11-24 (LL01) Valider que «periode_unite» est une unité de temps.
--  * Ne peut être réalisé que si la définition des unités est ajoutée à la table Unite.

-- Il faut supprimer la table exigence pour en créer une autre
drop table Exigence;

create table ExigenceC (
  norme Norme_code not null,
  code Exigence_Code,
  variable Variable_Code not null,
constraint Exigence_cc0 primary key (norme, code),
constraint Exigence_cc1 unique (norme, variable),
constraint Exigence_cr0 foreign key (variable) references Variable(code),
constraint Exigence_cr1 foreign key (norme) references Norme(code)
	);
comment on table ExigenceC is $$
predicat: L’exigence identifiée par le code «code» au sein de la norme «norme» est applicable à la variable «variable».
df:norme, code -> variable
clé_id: {norme,code}
clé_ref: {norme} -> Norme(code)
$$;	
create table Exigence_variable (
  variable Variable_Code not null,
  periode_valeur Mesure_Valeur not null,
  periode_unite Unite_Symbole not null,
  min Mesure_Valeur not null,
  max Mesure_Valeur not null,
  constraint Exigence_cb1 unique (periode_unite, periode_valeur),
  constraint Exigence_cr0 foreign key (variable) references Variable(code),
  constraint Exigence_cr2 foreign key (periode_unite) references Unite (sym),
  constraint Exigence_min_max check (min <= max)
  );
comment on table Exigence_variable is $$
predicat: L’exigence est respectée si toutes les mesures de la variable «variable» sont
          comprises dans l’intervalle de validation [«min»..«max»] durant toute période
          de «periode_valeur» «periode_unite».
df: variable -> period_valeur, period_unite, min, max
clé_ref: {variable} -> Variable(code)
clé_ref: {periode_unite} -> Unite(code)
$$;



--R 08 : TODO 2022-11-24 (LL01) Valider que « periode_unite » est une unité de temps.
ALTER TABLE Exigence_variable
ADD CONSTRAINT verif_periode_unite CHECK( periode_unite IN ('s', 'h', 'min', 'jrs', 'a'))

/*
============================================================================== Z
TS_mig.sql
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
 2013-09-09 (LL01) : migrer la base de donées
.Tâches réalisées
 2013-09-03 (LL01) : 

*Ajouter les attributs requis par la définition en termes des unités fondamentales du SI
*Contraindre plus strictement les symboles.
*Afin de mieux valider les données, les méthodes devraient être codifiées.
*Changer le nom de la table Seuils afin de refléter le concept d’intervalle de validation.
*Vérifier que la valeur de référence de la variable est comprise dans l'intervalle de validation.
* Vérifier que les min et max des exigences sont compris dans l'intervalle 
*Ajout la date de mise en service, notamment à des fins de validation des temps de mesure
*Modéliser la mobilité de certaines stations
*Ajouter la description de l'organisation hiérarchique des territoires.
*Valider que «periode_unite» est une unité de temps.
*Valider que « periode_unite » est une unité de temps.

 
 [mod] http://info.usherbrooke.ca/llavoie/enseignement/Modules/
============================================================================== Z
*/