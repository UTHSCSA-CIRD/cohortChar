-- where deidentified data is stored; on the demo image this would be 
-- set to I2B2DEMODATA
define dataschema = BLUEHERONDATA;
-- how to identify ethnicity facts in OBSERVATION_FACT
define ethfiltr = "where concept_cd like 'DEM|ETHNICITY:%'";
-- what age ranges do we want to group patients into?
define agebins = "case when age_in_years_num is NULL then 'Unknown' when age_in_years_num < 0 then 'Negative age' when age_in_years_num <= 1 then '0-1 year' when age_in_years_num <= 12 then '1-12 years' when age_in_years_num <= 18 then '12-18 years' when age_in_years_num <= 65 then '18-65 years' when age_in_years_num <= 85 then '65-85 years' else '85+ years' end";
-- criteria and column names
-- total # BMI measurements or obesity diagnoses for each patient each year
define name0 = bmiob; 
define crit0 = "where concept_cd like 'ICD9:278%' or concept_path like '%\278.%' or concept_cd like '%FLO_MEAS_ID:301070%' or concept_cd like '%PAT_ENC:BMI%'";
-- total # of exclusion diagnoses recorded for each patient each year
define name1 = exclusions; 
define crit1 = "where concept_cd in (select concept_cd from concepts_obesity)";
-- number of cholesterol lab tests
define name2 = cholesterol; 
define crit2 = "where concept_cd like '%COMPONENT_ID:%' and (concept_path like '%LIPID%' or concept_path like '%CHOLESTEROL%')";
-- number of lipid profiles ordered
define name3 = lipid_panels; 
define crit3 = "where concept_cd like '%PROC_ID:684'";
-- number of diet consults ordered
define name4 = diet_consults; 
define crit4 = "where concept_cd like '%PROC_ID:385'";
-- number of amphetamine prescriptions (including ritalin and adderall)
define name5 = rx_amphet; 
define crit5 = "where (concept_cd like 'RXCUI:%' or concept_cd like '%MEDICATION_ID:%') and concept_path like '%\3257561\3257589%'";
/*
define name6 = ;
define crit6 = ;
define name7 = ;
define crit7 = ;
*/
-- which years to do counts for?
-- might be nice to have dynamically settable (or even guessable) years
define year_range = "1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014"
define vnames = "&&name0 , &&name1 , &&name2 , &&name3 , &&name4 , &&name5 ";

/*** exclusion diagnoses specific to obesity cohort ***/
drop table concepts_obesity;
create table concepts_obesity as
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:042%' or (concept_cd like '%DX_ID:%' and concept_path like '%\042.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:242.9%' or (concept_cd like '%DX_ID:%' and concept_path like '%\242.9_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:243%' or (concept_cd like '%DX_ID:%' and concept_path like '%\243.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:262%' or (concept_cd like '%DX_ID:%' and concept_path like '%\262.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:263.2%' or (concept_cd like '%DX_ID:%' and concept_path like '%\263.2_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:263.8%' or (concept_cd like '%DX_ID:%' and concept_path like '%\263.8_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:275.49%' or (concept_cd like '%DX_ID:%' and concept_path like '%\275.49\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:281.4%' or (concept_cd like '%DX_ID:%' and concept_path like '%\281.4_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:307.1%' or (concept_cd like '%DX_ID:%' and concept_path like '%\307.1_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:530.13%' or (concept_cd like '%DX_ID:%' and concept_path like '%\530.13\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:755.24%' or (concept_cd like '%DX_ID:%' and concept_path like '%\755.24\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:755.34%' or (concept_cd like '%DX_ID:%' and concept_path like '%\755.34\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:755.69%' or (concept_cd like '%DX_ID:%' and concept_path like '%\755.69\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:756%' or (concept_cd like '%DX_ID:%' and concept_path like '%\756.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:756.4%' or (concept_cd like '%DX_ID:%' and concept_path like '%\756.4_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:756.9%' or (concept_cd like '%DX_ID:%' and concept_path like '%\756.9_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:757.2%' or (concept_cd like '%DX_ID:%' and concept_path like '%\757.2_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:759.82%' or (concept_cd like '%DX_ID:%' and concept_path like '%\759.82\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:759.89%' or (concept_cd like '%DX_ID:%' and concept_path like '%\759.89\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:795.71%' or (concept_cd like '%DX_ID:%' and concept_path like '%\795.71\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:277%' or (concept_cd like '%DX_ID:%' and concept_path like '%\277.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:307.5%' or (concept_cd like '%DX_ID:%' and concept_path like '%\307.5_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:756.5%' or (concept_cd like '%DX_ID:%' and concept_path like '%\756.5_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:783%' or (concept_cd like '%DX_ID:%' and concept_path like '%\783.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:V08%' or (concept_cd like '%DX_ID:%' and concept_path like '%\V08.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:V69.1%' or (concept_cd like '%DX_ID:%' and concept_path like '%\V69.1_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:758%' or (concept_cd like '%DX_ID:%' and concept_path like '%\758.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:191.1%' or (concept_cd like '%DX_ID:%' and concept_path like '%\191.1_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:244.9%' or (concept_cd like '%DX_ID:%' and concept_path like '%\244.9_\%') union all
-- select * from &dataschema..concept_dimension where concept_cd like 'ICD9:250.01%' or (concept_cd like '%DX_ID:%' and concept_path like '%\250.01%') union all
-- select * from &dataschema..concept_dimension where concept_cd like 'ICD9:250.03%' or (concept_cd like '%DX_ID:%' and concept_path like '%\250.03%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:253.2%' or (concept_cd like '%DX_ID:%' and concept_path like '%\253.2_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:253.3%' or (concept_cd like '%DX_ID:%' and concept_path like '%\253.3_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:255%' or (concept_cd like '%DX_ID:%' and concept_path like '%\255.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:255.41%' or (concept_cd like '%DX_ID:%' and concept_path like '%\255.41\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:259.1%' or (concept_cd like '%DX_ID:%' and concept_path like '%\259.1_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:259.8%' or (concept_cd like '%DX_ID:%' and concept_path like '%\259.8_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:277.89%' or (concept_cd like '%DX_ID:%' and concept_path like '%\277.89\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:428%' or (concept_cd like '%DX_ID:%' and concept_path like '%\428.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:530.13%' or (concept_cd like '%DX_ID:%' and concept_path like '%\530.13\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:555.9%' or (concept_cd like '%DX_ID:%' and concept_path like '%\555.9_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:556.9%' or (concept_cd like '%DX_ID:%' and concept_path like '%\556.9_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:581.9%' or (concept_cd like '%DX_ID:%' and concept_path like '%\581.9_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:585.6%' or (concept_cd like '%DX_ID:%' and concept_path like '%\585.6_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:756.59%' or (concept_cd like '%DX_ID:%' and concept_path like '%\756.59\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:758.6%' or (concept_cd like '%DX_ID:%' and concept_path like '%\758.6_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:759.81%' or (concept_cd like '%DX_ID:%' and concept_path like '%\759.81\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:759.89%' or (concept_cd like '%DX_ID:%' and concept_path like '%\759.89\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:782.3%' or (concept_cd like '%DX_ID:%' and concept_path like '%\782.3_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:191%' or (concept_cd like '%DX_ID:%' and concept_path like '%\191.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:201%' or (concept_cd like '%DX_ID:%' and concept_path like '%\201.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:202%' or (concept_cd like '%DX_ID:%' and concept_path like '%\202.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:203%' or (concept_cd like '%DX_ID:%' and concept_path like '%\203.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:204%' or (concept_cd like '%DX_ID:%' and concept_path like '%\204.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:205%' or (concept_cd like '%DX_ID:%' and concept_path like '%\205.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:206%' or (concept_cd like '%DX_ID:%' and concept_path like '%\206.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:207%' or (concept_cd like '%DX_ID:%' and concept_path like '%\207.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:208%' or (concept_cd like '%DX_ID:%' and concept_path like '%\208.__\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:714.3%' or (concept_cd like '%DX_ID:%' and concept_path like '%\714.3_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:996.8%' or (concept_cd like '%DX_ID:%' and concept_path like '%\996.8_\%') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:V42.0%' or (concept_cd like '%DX_ID:%' and concept_path like '%\V42.0%\') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:V42.1%' or (concept_cd like '%DX_ID:%' and concept_path like '%\V42.1%\') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:V42.7%' or (concept_cd like '%DX_ID:%' and concept_path like '%\V42.7%\') union all
select * from &dataschema..concept_dimension where concept_cd like 'ICD9:V42.81%' or (concept_cd like '%DX_ID:%' and concept_path like '%\V42.81\%')
;

alter table concepts_obesity add (
  icd9 varchar(50) );
  
update concepts_obesity set icd9 = concept_cd where concept_cd like 'ICD9:%';
update concepts_obesity 
set icd9 = 'ICD9:'||regexp_substr(concept_path,'E{0,1}[V0-9]{3}\.[0-9]{1,2}')
where concept_cd like '%DX_ID:%';
/***** end obesity exclusion diagnoses ****/

-- create table of patients and how many distinct START_DATEs each
-- had during each year when they had visits
drop table patient_yr_visits;
create table patient_yr_visits as
select patient_num, start_date, concept_cd, extract(year from start_date) yr
from &dataschema..observation_fact
group by patient_num, start_date, concept_cd;

-- create a table of unique concept descriptors (for filtering later on)
drop table unique_conc;
create table unique_conc as
select concept_cd,min(concept_path) concept_path,min(name_char) name_char
from &dataschema..concept_dimension
group by concept_cd;

-- merge the two above
drop table patient_yr_conc;
create table patient_yr_conc as
select py.*, concept_path, name_char
from patient_yr_visits py 
join unique_conc uc
on py.concept_cd = uc.concept_cd
;

-- this is the table on which pivots will be run
drop table patient_counts_yr0;
create table patient_counts_yr0 as
with
-- ethnicity (might as well use always, in case needed)
eth as (select distinct patient_num,concept_cd ethno
from &dataschema..observation_fact &ethfiltr ),
-- age group (might as well use always, in case needed)
ages as (select patient_num, &agebins age_group 
from &dataschema..patient_dimension),
-- total # visits that year (needed for all studies)
tot as (select patient_num,yr,count(*) visits 
  from (select distinct patient_num,yr,start_date from patient_yr_conc)
  group by patient_num,yr),
/*** BEGIN STUDY-SPECIFIC ALIASED SUBQUERIES ***/
-- there may be some way to read the names and corresponding criteria 
-- from a table and dynamically write the rather repetitious SQL below
&name0 as (select patient_num,yr,count(*) &name0
  from (select distinct patient_num,yr,start_date from patient_yr_conc
  &crit0) group by patient_num,yr),
&name1 as (select patient_num,yr,count(*) &name1
  from (select distinct patient_num,yr,start_date from patient_yr_conc
  &crit1) group by patient_num,yr),
&name2 as (select patient_num,yr,count(*) &name2
  from (select distinct patient_num,yr,start_date from patient_yr_conc
  &crit2) group by patient_num,yr),
&name3 as (select patient_num,yr,count(*) &name3
  from (select distinct patient_num,yr,start_date from patient_yr_conc
  &crit3) group by patient_num,yr),
&name4 as (select patient_num,yr,count(*) &name4
  from (select distinct patient_num,yr,start_date from patient_yr_conc
  &crit4) group by patient_num,yr),
&name5 as (select patient_num,yr,count(*) &name5
  from (select distinct patient_num,yr,start_date from patient_yr_conc
  &crit5) group by patient_num,yr)
/*** END STUDY-SPECIFIC ALIASED SUBQUERIES ***/
select pd.patient_num, sex_cd,race_cd,vital_status_cd,marital_status_cd,
ethno, age_group, tot.yr, visits, &vnames
from tot 
left join &name0
on tot.patient_num = &name0..patient_num and tot.yr = &name0..yr
left join &name1
on tot.patient_num = &name1..patient_num and tot.yr = &name1..yr
left join &name2
on tot.patient_num = &name2..patient_num and tot.yr = &name2..yr
left join &name3
on tot.patient_num = &name3..patient_num and tot.yr = &name3..yr
left join &name4
on tot.patient_num = &name4..patient_num and tot.yr = &name4..yr
left join &name5
on tot.patient_num = &name5..patient_num and tot.yr = &name5..yr
join eth
on tot.patient_num = eth.patient_num
join ages
on tot.patient_num = ages.patient_num
left join &dataschema..patient_dimension pd
on tot.patient_num = pd.patient_num
;

-- The Pivot:
-- what to count this can vary; for the tables as defined here it can be one of: 
--   visits, bmi_or_ob, exclusions_diag, cholesterol, lipid_panels
define pivoton = visits;
-- what to do with the counts: sum them or count them? summation gives number 
-- of visits, counting the values give number of patients
-- choose one of the two valid definitions of pivotbody below:
-- define pivotbody = "count( &pivoton ) &pivoton._patients";
define pivotbody = "sum( &pivoton ) &pivoton._visits";
-- what are the cohort inclusion criteria?
define pivotcrit = "where sex_cd != '@' ";
-- what columns should be on the left of the pivot-table?
define pivotvars = "sex_cd,race_cd,vital_status_cd,marital_status_cd,ethno,age_group";
-- how to order the pivot output?
define pivotorder = "vital_status_cd,ethno,race_cd,sex_cd,marital_status_cd,age_group";

-- total number of visits each year by patients grouped by the below criteria
select * from (select &pivotvars, yr, &pivoton
  -- yr is always going to be here and will be an integer
  from patient_counts_yr0 &pivotcrit )
pivot( &pivotbody FOR yr IN ( &year_range ))
order by &pivotorder
;
