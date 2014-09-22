/***
patients eligible for weight cohort and their demographic data
(specific to cohort)
***/
drop table weightcohort; 
create table weightcohort as
-- within last 2 years, BMI recorded or ICD9 of 278.XX
with bmiob as (
select patient_num, count(*) bmi_or_obesity from blueherondata.observation_fact obs
join blueherondata.concept_dimension con 
on obs.concept_cd = con.concept_cd
where start_date >= to_date('jan 2012','MON YYYY')
and (obs.concept_cd like 'ICD9:278%'
or con.concept_path like '%\278.%'
or obs.concept_cd like '%FLO_MEAS_ID:301070%'
or obs.concept_cd like '%PAT_ENC:BMI%')
group by patient_num),
-- # times seen in last two years
last2yrs as (
select patient_num,count(*) visits from(
select distinct patient_num,start_date from blueherondata.observation_fact
where start_date >= to_date('jan 2012','MON YYYY')
) group by patient_num),
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
-- number of diagnoses that exclude a patient
exc as (
  select patient_num,count(*) exclusions_diag 
  from blueherondata.observation_fact 
  where concept_cd in (select concept_cd from concepts_obesity)
  group by patient_num),
-- number of cholesterol lab tests
chol as (
  select patient_num,count(*) cholesterol
  from blueherondata.observation_fact
  where concept_cd in (
    select distinct concept_cd from blueherondata.concept_dimension 
    where concept_cd like '%COMPONENT_ID:%' 
    and (concept_path like '%LIPID%'
    or concept_path like '%CHOLESTEROL%'))
  group by patient_num),
-- number of lipid profiles ordered
lp as (
  select patient_num,count(*) lipid_panels
  from blueherondata.observation_fact
  where concept_cd like '%PROC_ID:684'
  group by patient_num),
-- number of diet consults ordered
dc as (
  select patient_num,count(*) diet_consults
  from blueherondata.observation_fact
  where concept_cd like '%PROC_ID:385'
  group by patient_num),
-- number of amphetamine prescriptions
-- (including ritalin and adderall)
amph as(
  select patient_num,count(*) rx_amphet from blueherondata.observation_fact
  where concept_cd in (select concept_cd from blueherondata.concept_dimension
  where (concept_cd like 'RXCUI:%' or concept_cd like '%MEDICATION_ID:%')
  and concept_path like '%\3257561\3257589%')
  group by patient_num)

select pd.*,bmi_or_obesity,visits
, eth.ethno, ages.age_group, exc.exclusions_diag
, chol.cholesterol, lp.lipid_panels, dc.diet_consults
, amph.rx_amphet
from blueherondata.patient_dimension pd 
left join bmiob on pd.patient_num = bmiob.patient_num -- can change over years
left join last2yrs on pd.patient_num = last2yrs.patient_num
left join eth on pd.patient_num = eth.patient_num
left join ages on pd.patient_num = ages.patient_num
left join exc on pd.patient_num = exc.patient_num -- can change over years
left join chol on pd.patient_num = chol.patient_num -- can change over years
left join lp on pd.patient_num = lp.patient_num -- can change over years
left join dc on pd.patient_num = dc.patient_num -- can change over years
left join amph on pd.patient_num = amph.patient_num -- can change over years
;

-- create table of patients and how many distinct START_DATEs each
-- had during each year when they had visits
-- NOT SPECIFIC TO ANY GIVEN COHORT OR SELECTION CRITERIA
/*create table patient_yr_visits as
select patient_num,yr,count(*) N from (
select distinct patient_num,start_date,to_char(start_date,'YYYY')+0 yr from BLUEHERONDATA.observation_fact
) group by patient_num,yr;
*/

drop table patient_yr_visits;

--explain plan for
create table patient_yr_visits as
with obs as (select distinct patient_num, start_date, concept_cd, modifier_cd
    from blueherondata.observation_fact)    
  select obs.*, 
  extract(year from obs.start_date) yr,
  con.concept_path, con.name_char
  from  obs
  join blueherondata.concept_dimension con
  on obs.concept_cd = con.concept_cd
  where 0 = 1
;

--explain plan for
insert into patient_yr_visits 
with obs as (select distinct patient_num, start_date, concept_cd, modifier_cd
    from blueherondata.observation_fact)    
  select obs.*, 
  extract(year from obs.start_date) yr,
  --1900 yr,
  con.concept_path, con.name_char
  from  obs
  join blueherondata.concept_dimension con
  on obs.concept_cd = con.concept_cd
;

    
-- SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());
/*create table patient_yr_visits as (
  select obs.patient_num,obs.start_date
  ,extract(year from obs.start_date) yr,obs.concept_cd,obs.modifier_cd
  ,con.concept_path,con.name_char
  from blueherondata.observation_fact obs
  join blueherondata.concept_dimension con
  on obs.concept_cd = con.concept_cd);*/

-- Once we can actually get the above patient_yr_visits table to get created, 
-- the results of the following query, joined to WEIGHTCOHORT, or maybe just 
-- PATIENT_DIMENSION, can be the input to the final pivot. That pivot can be
-- performed either on total patient counts (visits) or on various subsets of
-- those (i.e. the other columns)
with
-- total # visits that year
tot as (select patient_num,yr,count(*) visits 
  from (select distinct patient_num,yr,start_date from patient_yr_visits)
  group by patient_num,yr),
-- total # BMI measurements or obesity diagnoses for each patient each year
bmiob as (select patient_num,yr,count(*) bmi_or_ob 
  from (select distinct patient_num,yr,start_date from patient_yr_visits
    where concept_cd like 'ICD9:278%'
    or concept_path like '%\278.%'
    or concept_cd like '%FLO_MEAS_ID:301070%'
    or concept_cd like '%PAT_ENC:BMI%')
  group by patient_num,yr),
-- total # of exclusion diagnoses recorded for each patient each year
exc as (select patient_num,yr,count(*) exclusions_diag 
  from (select distinct patient_num,yr,start_date from patient_yr_visits
    where concept_cd in (select concept_cd from concepts_obesity))
  group by patient_num,yr),
-- number of cholesterol lab tests
chol as (select patient_num,yr,count(*) cholesterol 
  from (select distinct patient_num,yr,start_date from patient_yr_visits
    where concept_cd like '%COMPONENT_ID:%' 
    and (concept_path like '%LIPID%'
    or concept_path like '%CHOLESTEROL%'))
  group by patient_num,yr),
-- number of lipid profiles ordered
lp as (select patient_num,yr,count(*) lipid_panels
  from (select distinct patient_num,yr,start_date from patient_yr_visits
  where concept_cd like '%PROC_ID:684')
  group by patient_num,yr)

select tot.*, bmi_or_ob, exclusions_diag, cholesterol, lipid_panels
from tot 
left join bmiob
on tot.patient_num = bmiob.patient_num and tot.yr = bmiob.yr
left join exc
on tot.patient_num = exc.patient_num and tot.yr = exc.yr
left join chol
on tot.patient_num = chol.patient_num and tot.yr = chol.yr
left join lp
on tot.patient_num = lp.patient_num and tot.yr = lp.yr
;

/* further aliased subqueries to joint to the select statement above
-- number of diet consults ordered
dc as (
  select patient_num,count(*) diet_consults
  from blueherondata.observation_fact
  where concept_cd like '%PROC_ID:385'
  group by patient_num),
-- number of amphetamine prescriptions
-- (including ritalin and adderall)
amph as(
  select patient_num,count(*) rx_amphet from blueherondata.observation_fact
  where concept_cd in (select concept_cd from blueherondata.concept_dimension
  where (concept_cd like 'RXCUI:%' or concept_cd like '%MEDICATION_ID:%')
  and concept_path like '%\3257561\3257589%')
  group by patient_num)
*/


-- distinct years according to above table (dubious)
select distinct yr from patient_yr_visits;
-- distinct years according to VISIT_DIMENSION (less dubious?)
select distinct to_char(start_date,'YYYY')||',' yr from BLUEHERONDATA.visit_dimension order by yr asc;

-- number of patients grouped by the below criteria who had a visits each year
select * from(
-- the variables by which patients are grouped might differ WITHIN a study
-- i.e. even for the obesity query I'm already expecting to add more variables
select wc.patient_num, sex_cd,ethno,race_cd,vital_status_cd,marital_status_cd
  ,age_group,yr,n 
  -- weightcohort and patient_yr_visits might have different names
  -- (but can stay static for obesity)
  from weightcohort wc join patient_yr_visits pyv
  -- patient_num will always be the join criterion
  on wc.patient_num = pyv.patient_num
  -- the where statement may differ WITHIN a study and will definitely vary
  -- between studies but for obesity we can make do with the static one below
  where N>0 and BMI_OR_OBESITY>0)
pivot(
  -- the aggregation function can be either count() or sum()
  count(n) cnt
FOR yr IN (
  1986,1987,1989,1996,1997,1998,1999, 2000, 2001, 2002, 2003, 2004, 
  2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014)
);

-- total number of visits each year by patients grouped by the below criteria
select * from(
select wc.patient_num, sex_cd,ethno,race_cd,vital_status_cd,marital_status_cd
  ,age_group,yr,n 
  from weightcohort wc join patient_yr_visits pyv
  on wc.patient_num = pyv.patient_num
  where N>0 and BMI_OR_OBESITY>0 and EXCLUSIONS_DIAG is NULL )
pivot(
  sum(n) cnt
FOR yr IN (
  1986,1987,1989,1996,1997,1998,1999, 2000, 2001, 2002, 2003, 2004, 
  2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014)
);
