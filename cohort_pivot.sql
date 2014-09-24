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
define year_range = "1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014"
-- what columns should be on the left of the pivot-table?
define pivotvars = "sex_cd,race_cd,vital_status_cd,marital_status_cd,ethno,age_group";
-- how to order the pivot output?
define pivotorder = "vital_status_cd,ethno,race_cd,sex_cd,marital_status_cd,age_group";
define vnames = "&&name0 , &&name1 , &&name2 , &&name3 , &&name4 , &&name5 ";

-- create table of patients and how many distinct START_DATEs each
-- had during each year when they had visits
-- SAME FOR ALL STUDIES
drop table patient_yr_visits;
create table patient_yr_visits as
select patient_num, start_date, concept_cd, extract(year from start_date) yr
from &dataschema..observation_fact
group by patient_num, start_date, concept_cd;

-- create a table of unique concept descriptors (for filtering later on)
-- SAME FOR ALL STUDIES
drop table unique_conc;
create table unique_conc as
select concept_cd,min(concept_path) concept_path,min(name_char) name_char
from &dataschema..concept_dimension
group by concept_cd;

-- merge the two above
-- SAME FOR ALL STUDIES
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
-- total number of visits each year by patients grouped by the below criteria
select * from (select &pivotvars
  -- yr is always going to be here and will be an integer
  ,yr
  -- what to count: this can vary; for the tables as defined here 
  -- it can be one of: 
  -- visits, bmi_or_ob, exclusions_diag, cholesterol, lipid_panels
  ,visits
  from patient_counts_yr0)
pivot(
  -- can be either...
  -- count(FOO) patients
  -- ...or...
  -- sum(FOO) visits
  -- ...where FOO is whatever was chosen as "what to count" above
  count(visits) patients
FOR yr IN ( &year_range )
  -- might be nice to have dynamically settable (or even guessable) years
)
order by &pivotorder
;
