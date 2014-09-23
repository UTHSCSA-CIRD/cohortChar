-- create table of patients and how many distinct START_DATEs each
-- had during each year when they had visits
-- NOT SPECIFIC TO ANY GIVEN COHORT OR SELECTION CRITERIA

drop table patient_yr_visits;
create table patient_yr_visits as
select patient_num, start_date, concept_cd, extract(year from start_date) yr
from blueherondata.observation_fact
group by patient_num, start_date, concept_cd;

drop table unique_conc;
create table unique_conc as
select concept_cd,min(concept_path) concept_path,min(name_char) name_char
from blueherondata.concept_dimension
group by concept_cd;

drop table patient_yr_conc;
create table patient_yr_conc as
select py.*, concept_path, name_char
from patient_yr_visits py 
join unique_conc uc
on py.concept_cd = uc.concept_cd
left join blueherondata.patient_dimension pd
on py.patient_num = pd.patient_num
;

-- this is the table on which pivots will be run
drop table patient_counts_yr0;
create table patient_counts_yr0 as
with
-- ethnicity
eth as (select distinct patient_num,concept_cd ethno
from blueherondata.observation_fact
where concept_cd like 'DEM|ETHNICITY:%'),
-- age group
ages as (select distinct patient_num,
case 
 when age_in_years_num is NULL then 'Unknown'
 when age_in_years_num < 0 then 'Negative age'
 when age_in_years_num <= 1 then '0-1 year'
 when age_in_years_num <= 12 then '1-12 years'
 when age_in_years_num <= 18 then '12-18 years'
 when age_in_years_num <= 65 then '18-65 years'
 when age_in_years_num <= 85 then '65-85 years'
 else '85+ years'
end age_group from blueherondata.patient_dimension),
-- total # visits that year
tot as (select patient_num,yr,count(*) visits 
  from (select distinct patient_num,yr,start_date from patient_yr_conc)
  group by patient_num,yr),
-- total # BMI measurements or obesity diagnoses for each patient each year
bmiob as (select patient_num,yr,count(*) bmi_or_ob 
  from (select distinct patient_num,yr,start_date from patient_yr_conc
    where concept_cd like 'ICD9:278%'
    or concept_path like '%\278.%'
    or concept_cd like '%FLO_MEAS_ID:301070%'
    or concept_cd like '%PAT_ENC:BMI%')
  group by patient_num,yr),
-- total # of exclusion diagnoses recorded for each patient each year
exc as (select patient_num,yr,count(*) exclusions_diag 
  from (select distinct patient_num,yr,start_date from patient_yr_conc
    where concept_cd in (select concept_cd from concepts_obesity))
  group by patient_num,yr),
-- number of cholesterol lab tests
chol as (select patient_num,yr,count(*) cholesterol 
  from (select distinct patient_num,yr,start_date from patient_yr_conc
    where concept_cd like '%COMPONENT_ID:%' 
    and (concept_path like '%LIPID%'
    or concept_path like '%CHOLESTEROL%'))
  group by patient_num,yr),
-- number of lipid profiles ordered
lp as (select patient_num,yr,count(*) lipid_panels
  from (select distinct patient_num,yr,start_date from patient_yr_conc
  where concept_cd like '%PROC_ID:684')
  group by patient_num,yr),
-- number of diet consults ordered
dc as (
  select patient_num,yr,count(*) diet_consults
  from (select distinct patient_num,yr,start_date from patient_yr_conc
  where concept_cd like '%PROC_ID:385')
  group by patient_num,yr),
-- number of amphetamine prescriptions
-- (including ritalin and adderall)
amph as(
  select patient_num,yr,count(*) rx_amphet 
  from (select distinct patient_num,yr,start_date from patient_yr_conc
  where (concept_cd like 'RXCUI:%' or concept_cd like '%MEDICATION_ID:%')
  and concept_path like '%\3257561\3257589%')
  group by patient_num,yr)

select pd.patient_num, sex_cd,race_cd,vital_status_cd,marital_status_cd,
ethno, age_group, tot.yr, visits, bmi_or_ob, exclusions_diag, cholesterol, lipid_panels
from tot 
left join bmiob
on tot.patient_num = bmiob.patient_num and tot.yr = bmiob.yr
left join exc
on tot.patient_num = exc.patient_num and tot.yr = exc.yr
left join chol
on tot.patient_num = chol.patient_num and tot.yr = chol.yr
left join lp
on tot.patient_num = lp.patient_num and tot.yr = lp.yr
left join dc
on tot.patient_num = dc.patient_num and tot.yr = dc.yr
left join amph
on tot.patient_num = amph.patient_num and tot.yr = amph.yr
join eth
on tot.patient_num = eth.patient_num
join ages
on tot.patient_num = ages.patient_num
left join blueherondata.patient_dimension pd
on tot.patient_num = pd.patient_num
;

-- The Pivot:
-- total number of visits each year by patients grouped by the below criteria
select *
from patient_counts_yr0
pivot(
  -- bmi_or_ob, exclusions_diag, cholesterol, lipid_panels
  count(bmi_or_ob) visits
FOR yr IN (
  1999, 2000, 2001, 2002, 2003, 2004, 
  2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014)
);
