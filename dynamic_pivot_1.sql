CREATE OR REPLACE procedure dynamic_pivot(minvisits in number)
AUTHID CURRENT_USER
as
-- starting with first year where a patient had minvisits+
-- concatenate the years into comma-separated string
min_year_visits int := minvisits;
all_years_str varchar2(4000);
-- base pivot_data query
pivot_data varchar2(4000) :=
'select wc.patient_num, sex_cd, ethno, race_cd, vital_status_cd,
marital_status_cd, age_group, yr, n
from weightcohort wc
join patient_yr_visits pyv
on pyv.patient_num = wc.patient_num
where N > 0 and BMI_OR_OBESITY > 0';
-- dynamic query
sql_query varchar2(4000);
-- aggregate function, field to pivot
agg_func varchar(100) := 'sum';
agg_field varchar(100) := 'N';
agg_col varchar(100) := 'sum';
agg_for varchar(100):= 'yr';
-- output
out_table varchar(100) := 'pivot_out';
begin
select
listagg( yr, ',' ) within group( order by yr ) as
into all_years_str
from (
select distinct yr from patient_yr_visits
where yr >= (select min(yr) from patient_yr_visits where n >= min_year_visits)
and yr <= to_char(sysdate,'YYYY')
order by yr
);
sql_query :=
'CREATE TABLE ' || out_table ||
' AS (SELECT * FROM (' || pivot_data || ')' ||
' PIVOT ('|| agg_func || '(' || agg_field || ') ' || agg_col ||
' FOR ' || agg_for ||
' IN (' || all_years_str || ')
))';
begin -- sub block
execute immediate 'DROP TABLE ' || out_table;
EXCEPTION
WHEN OTHERS THEN
IF SQLCODE != -942 THEN
RAISE;
END IF;
end; -- sub block
execute immediate sql_query;
end;
/
execute dynamic_pivot(5);
