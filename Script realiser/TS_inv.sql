/*
============================================================================== A
TS_inv.sql
------------------------------------------------------------------------------ A
Produit : Base de données SSQA
Résumé : script SQL ajoutant les invariants requis — vues, routines, automatismes et déclencheurs (triggers) 
Projet : SSQA_v2022.3a
Responsable: wilfried.djegue@2022.ucac-icam.com
Version : 2022-12-11
Statut : en vigueur
Encodage : UTF-8 sans BOM, fin de ligne Unix (LF)
Plateforme : PostgreSQL 9.4.4 à 10.4
============================================================================== A
*/



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









-- Procédure pour ajouter directement des unités dans la table  
CREATE OR REPLACE PROCEDURE Ajout_unite( symx Unite_sym, nomx Unite_nom, symgrandeurx Unite_sym, nomgrandeurx Unite_nom symdimensionx Unite_sym)
LANUAGE SQL AS
$$
INSERT INTO Unite(sym, nom, dimension, symgrandeur, nomgrandeur, symdimension) VALUES 
('symx', 'nomx', 'dimensionx', 'symgrandeurx', 'nomgrandeurx', 'symdimensionx')






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
TS_inv.sql
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
 2013-09-09 (LL01) :  ajouter les invariants requis
.Tâches réalisées
 2013-09-03 (LL01) : *création de vues , de fonctions, de requêtes d'automartismes et déclencheurs
 
 [mod] http://info.usherbrooke.ca/llavoie/enseignement/Modules/
============================================================================== Z