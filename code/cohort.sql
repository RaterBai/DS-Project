use ds;
/*
Define cohort, patients with/without Diabetes
Extract demographics information for other patients
Figure out the first onset (diagnosis) time for Diabetes, as I assume all the medication dispensed
and other diagnoses would be before this time.
*/

create table temp_cohort as
select 
    derived.person_id,
    sum(derived.dia_flag) as count_dia,
    case
        when sum(derived.dia_flag) > 0 then 1
        else 0
    end as diabetes
from
    (select 
        co.person_id,
            co.condition_concept_id,
            dia_code.concept_name,
            case
                when dia_code.concept_name != '' then 1
                else 0
            end as dia_flag
    from
        condition_occurrence as co
    left join (select distinct
        condition_concept_id, concept_name, count(*) as ct
    from
        condition_occurrence, concept
    where
        condition_concept_id = concept.concept_id
            and concept_name like '%diabete%'
    group by condition_concept_id
    order by ct desc) as dia_code on co.condition_concept_id = dia_code.condition_concept_id) as derived
group by person_id;

select 
    count(person_id)
from
    temp_cohort
where
    diabetes = 0;/* 159*/
select 
    count(person_id)
from
    temp_cohort
where
    diabetes = 1;/* 771 --- 930 = 159+771*/  
select 
    count(distinct person_id)
from
    condition_occurrence;    /* 930 in total, but 1000 patients*/

/* Patients Demographics */
create table temp_demographics as 
select p.person_id,
	   co1.concept_name as gender,
       co2.concept_name as race,
       co3.concept_name as ethnicity,
       p.year_of_birth,
       p.month_of_birth,
       p.day_of_birth
       from person as p
left join concept as co1 
on p.gender_concept_id = co1.concept_id
left join concept as co2
on p.race_concept_id = co2.concept_id
left join concept as co3
on p.ethnicity_concept_id = co3.concept_id;

/* Ways to determine medicine and diagnoses
--- Drugs used before Diabetes diagnosis date
--- Other diagnoses happened before Diabetes date
*/

/* Find earliest date of diagnosis of Diabetes */
create table temp_diabetes_onset_time as  
select person_id,
       min(condition_start_date) as onset_time
       from
(select co.person_id,
       co.condition_concept_id,
	   dia_code.concept_name,
       co.condition_start_date,
       co.condition_end_date 
       from condition_occurrence as co
	   inner join (select distinct
        condition_concept_id, concept_name, count(*) as ct
    from
        condition_occurrence, concept
    where
        condition_concept_id = concept.concept_id
            and concept_name like '%diabete%'
    group by condition_concept_id
    order by ct desc) as dia_code
    on co.condition_concept_id = dia_code.condition_concept_id) as derived
    group by person_id;

select * from temp_cohort;
select * from temp_diabetes_onset_time;
select * from temp_demographics;

/*capture the first visit date of each patients in the cohort*/
create table temp_first_visit as 
select tc.person_id,
	   min(vo.visit_start_date) as first_visit_date from temp_cohort as tc
inner join visit_occurrence as vo
on tc.person_id = vo.person_id
group by person_id;

select * from temp_first_visit;

/* Merge this with cohort */
create table temp_merged as 
select tc.person_id,
       tc.diabetes,
       td.onset_time,
       tdemo.gender,
       tdemo.race, 
       tdemo.ethnicity,
       tdemo.year_of_birth,
       tdemo.month_of_birth,
       tdemo.day_of_birth,
       tfv.first_visit_date
       from temp_cohort as tc
left join temp_diabetes_onset_time as td
on tc.person_id = td.person_id
inner join temp_demographics as tdemo
on tc.person_id = tdemo.person_id
inner join temp_first_visit as tfv 
on tfv.person_id = tc.person_id
order by tc.person_id;

create table temp_drug_category as 
SELECT person_id, 
	   drug_concept_id,
       drug_era_start_date,
       case
	       when drug_concept_id in (1335471,1340128,1341927,1342001,1363749,1308216,1310756,1373225,1331235,1334456,1342439) then "drug_1"
           when drug_concept_id in (1518148) then "drug_2"
           when drug_concept_id in (1363053,1350489,1341238) then "drug_3"
           when drug_concept_id in (1344965,1305447) then "drug_4"
           when drug_concept_id in (1510202) then "drug_5"
           when drug_concept_id in (1517998) then "drug_6"
           when drug_concept_id in (1351557,1346686,1347384,1367500,40226742,1317640,1308842) then "drug_7"
           when drug_concept_id in (1309204,1309944,1335606,1354860,1307542,1351461,1353256,1360421) then "drug_8"
           when drug_concept_id in (1301065,19047423,1367571) then "drug_9"
           when drug_concept_id in (1526475,19095309) then "drug_10"
           when drug_concept_id in (1322184) then "drug_11"
           when drug_concept_id in (1112807) then "drug_12"
           when drug_concept_id in (1370109,1319998,1314002,1322081,1338005,1346823,19063575,1386957,1307046,1313200,1314577,1345858,1353766,902427) then "drug_13"
           when drug_concept_id in (1337720) then "drug_14"
           when drug_concept_id in (1503297) then "drug_15"
           when drug_concept_id in (19084670) then "drug_16"
           when drug_concept_id in (1332418,1328165,1353776,1326012,1318137,1318853,1319880,1307863) then "drug_17"
           when drug_concept_id in (1326303) then "drug_18"
           when drug_concept_id in (19052447) then "drug_19"
           when drug_concept_id in (19090761) then "drug_20"
           when drug_concept_id in (19026343) then "drug_21"
           when drug_concept_id in (19022003) then "drug_22"
           when drug_concept_id in (1523280) then "drug_23"
           when drug_concept_id in (19026180) then "drug_24"
           when drug_concept_id in (1580747) then "drug_25"
           when drug_concept_id in (929435,991382,1316354,932745,992590,1395058,1309799,956874,974166,1376289,978555,994058,904250,905273,907013,1172206,948787,970250,942350,904542,904639,19082886,19081320) then "drug_26"
           when drug_concept_id in (1502905,1588986,1550023,1531601,1567198,1544838,46221581,19090249,1513876,19091621,1590165,1586346,1513849,1596977,19090226) then "drug_27"
           when drug_concept_id in (19050087) then "drug_28"
           when drug_concept_id in (19017805) then "drug_29"
           when drug_concept_id in (19092139) then "drug_30"
           when drug_concept_id in (1516766) then "drug_31"
           when drug_concept_id in (1383815,1383925) then "drug_32"
           when drug_concept_id in (1183554) then "drug_33"
           when drug_concept_id in (1331270) then "drug_34"
           when drug_concept_id in (19051463) then "drug_35"
           when drug_concept_id in (1362225) then "drug_36"
           when drug_concept_id in (1317967) then "drug_37"
           when drug_concept_id in (1592180,1549686,1510813,1545958,1592085,1551860,1539403) then "drug_38"
           when drug_concept_id in (1530014,1594973,1597756,1560171,1559684,1502809,1502855) then "drug_39"
           when drug_concept_id in (1525215,1547504) then "drug_40"
           when drug_concept_id in (1302398) then "drug_41"
           when drug_concept_id in (19005658) then "drug_42"
           when drug_concept_id in (1373928,1309068) then "drug_43"
           else "other" end as drug_category
       FROM ds.drug_era;

/* create drug categories, export to csv*/
create table temp_patient_drug as   
select td.person_id, 
	   onset_time,
       diabetes,
       drug_concept_id,
       drug_era_start_date,
       drug_category
       from temp_merged as tm
	   inner join temp_drug_category as td
       on tm.person_id = td.person_id;

select count(distinct person_id) from person;
