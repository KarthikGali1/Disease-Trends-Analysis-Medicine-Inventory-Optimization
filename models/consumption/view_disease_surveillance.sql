with daily_cases as (
    select
        DISEASE_ID,
        count(distinct surveillance_id) as new_cases_daily,
        sum(count(distinct surveillance_id)) over (order by DISEASE_ID) as cumulative_cases
    from TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE
    group by DISEASE_ID
),
incidence_rates as (
    select
        T1.REGION_ID,
        (sum(T1.case_count) / T2.state_population) * 100000 as incidence_rate_per_100k
    from TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE T1
    join TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.DIM_GEOGRAPHIC T2 on T1.REGION_ID = T2.REGION_ID
    group by T1.REGION_ID, T2.state_population
),
avg_los as (
    select
        DISEASE_ID,
        avg(length_of_stay_days) as average_length_of_stay
    from TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE
    where length_of_stay_days is not null
    group by DISEASE_ID
),
disease_summary as (
    select
        DISEASE_ID,
        sum(case_count) as total_cases,
        row_number() over (order by sum(case_count) desc) as disease_rank
    from TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE
    where case_count is not null and DISEASE_ID is not null
    group by DISEASE_ID
),
severity_breakdown as (
    select
        DISEASE_ID,
        severity_level,
        count(surveillance_id) as severity_case_count
    from TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE
    where surveillance_id is not null and DISEASE_ID is not null and severity_level is not null
    group by DISEASE_ID, severity_level
),
readmission_data as (
    select distinct r1.patient_id as readmitted_patient
    from TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE r1
    join TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE r2
      on r1.patient_id = r2.patient_id
     and r2.admit_date > r1.discharge_date
     and r2.admit_date <= r1.discharge_date + 30
    where r1.discharge_date is not null
),
readmission_rates as (
    select
        count(distinct r.patient_id) as total_discharged,
        count(distinct re.readmitted_patient) as readmitted_patients,
        round((count(distinct re.readmitted_patient) * 100.0 / count(distinct r.patient_id)), 2) as readmission_rate_percent
    from TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE r
    left join readmission_data re on r.patient_id = re.readmitted_patient
    where r.discharge_date is not null
),
weekly_cases as (
    select
        REGION_ID,
        date_trunc('week', admit_date) as week_start,
        count(surveillance_id) as weekly_case_count
    from TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE
    where surveillance_id is not null and admit_date is not null and REGION_ID is not null
    group by REGION_ID, date_trunc('week', admit_date)
),
growth_rates as (
    select
        REGION_ID,
        week_start,
        weekly_case_count,
        lag(weekly_case_count) over (partition by REGION_ID order by week_start) as previous_week_cases,
        case
            when lag(weekly_case_count) over (partition by REGION_ID order by week_start) > 0 then
                round(((weekly_case_count - lag(weekly_case_count) over (partition by REGION_ID order by week_start)) * 100.0 /
                       lag(weekly_case_count) over (partition by REGION_ID order by week_start)), 2)
            else null
        end as growth_rate_percent
    from weekly_cases
),
facility_pressure as (
    select
        T2.CITY_ID,
        count(T1.patient_id) as Active_Patients,
        sum(T2.bed_capacity) as total_bed_capacity,
        round((count(T1.patient_id) * 100.0 / nullif(sum(T2.bed_capacity), 0)), 2) as healthcare_facility_pressure_percent
    from TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE T1
    join TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.DIM_HOSPITALS T2 on T1.hospital_id = T2.hospital_id
    where T1.admit_date is not null
      and (T1.discharge_date is null or T1.discharge_date >= current_date)
      and T1.admit_date <= current_date
      and T2.bed_capacity > 0
    group by T2.CITY_ID
),
treatment_costs as (
    select
        T1.DISEASE_ID,
        avg(T2.total_amount) as average_treatment_cost,
        count(T1.patient_id) as treatment_case_count
    from TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE T1
    join TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_PRESCRIPTIONS T2
      on T1.patient_id = T2.patient_id and T1.disease_id = T2.disease_id
    where T1.DISEASE_ID is not null and T2.total_amount is not null
    group by T1.DISEASE_ID
),
cases_per_facility as (
    select
        T1.REGION_ID,
        T1.state,
        T1.city,
        sum(T2.case_count) as total_cases,
        T1.healthcare_facilities_count as facilities,
        round(sum(T2.case_count) / T1.healthcare_facilities_count, 2) as cases_per_facility_ratio
    from TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.DIM_GEOGRAPHIC T1
    join TRANSFORMED_DB_DEV.DBT_MSATHYANARAYANA.FACT_DISEASE_SURVEILLANCE T2 on T1.REGION_ID = T2.REGION_ID
    where T1.healthcare_facilities_count > 0 and T2.case_count is not null
    group by T1.REGION_ID, T1.state, T1.city, T1.healthcare_facilities_count
)
select
    -- Disease Overview
    dc.DISEASE_ID,
    dc.new_cases_daily,
    dc.cumulative_cases,
    -- Disease Ranking
    ds.disease_rank,
    ds.total_cases,
    -- Clinical Metrics
    al.average_length_of_stay,
    tc.average_treatment_cost,
    tc.treatment_case_count,
    -- Geographic Metrics
    ir.REGION_ID,
    ir.incidence_rate_per_100k,
    -- Severity Distribution
    sb.severity_level,
    sb.severity_case_count,
    -- System Performance
    rr.total_discharged,
    rr.readmitted_patients,
    rr.readmission_rate_percent,
    -- Growth Analysis
    gr.week_start as latest_week,
    gr.weekly_case_count as current_week_cases,
    gr.previous_week_cases,
    gr.growth_rate_percent,
    -- Facility Utilization
    fp.CITY_ID,
    fp.Active_Patients,
    fp.total_bed_capacity,
    fp.healthcare_facility_pressure_percent,
    -- Resource Distribution
    cpf.state,
    cpf.city,
    cpf.facilities,
    cpf.cases_per_facility_ratio
from daily_cases dc
left join disease_summary ds on dc.DISEASE_ID = ds.DISEASE_ID
left join avg_los al on dc.DISEASE_ID = al.DISEASE_ID
left join treatment_costs tc on dc.DISEASE_ID = tc.DISEASE_ID
left join incidence_rates ir on 1=1
left join severity_breakdown sb on dc.DISEASE_ID = sb.DISEASE_ID
left join readmission_rates rr on 1=1
left join growth_rates gr on ir.REGION_ID = gr.REGION_ID
left join facility_pressure fp on 1=1
left join cases_per_facility cpf on ir.REGION_ID = cpf.REGION_ID
where gr.week_start = (
        select max(week_start)
        from growth_rates
        where REGION_ID = gr.REGION_ID
  )
order by
    ds.disease_rank,
    ir.incidence_rate_per_100k desc,
    fp.healthcare_facility_pressure_percent desc