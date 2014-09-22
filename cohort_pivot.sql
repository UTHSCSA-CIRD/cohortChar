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
end age_group from blueherondata.patient_dimension)

select pd.*,bmi_or_obesity,visits,eth.ethno,ages.age_group 
from blueherondata.patient_dimension pd 
left join bmiob on pd.patient_num = bmiob.patient_num
left join last2yrs on pd.patient_num = last2yrs.patient_num
left join eth on pd.patient_num = eth.patient_num
left join ages on pd.patient_num = ages.patient_num
;


-- create table of patients and how many distinct START_DATEs each
-- had during each year when they had visits
-- NOT SPECIFIC TO ANY GIVEN COHORT OR SELECTION CRITERIA
create table patient_yr_visits as
select patient_num,yr,count(*) N from (
select distinct patient_num,start_date,to_char(start_date,'YYYY')+0 yr from BLUEHERONDATA.observation_fact
) group by patient_num,yr;


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
  where N>0 and BMI_OR_OBESITY>0)
pivot(
  sum(n) cnt
FOR yr IN (
  1986,1987,1989,1996,1997,1998,1999, 2000, 2001, 2002, 2003, 2004, 
  2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014)
);

