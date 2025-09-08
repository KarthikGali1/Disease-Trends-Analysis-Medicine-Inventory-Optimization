with daily_cases as (
    select
        DISEASE_ID,
        count(distinct surveillance_id) as new_cases_daily,
        sum(count(distinct surveillance_id)) over (partition by DISEASE_ID order by DISEASE_ID) as cumulative_cases
    from TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE
    where DISEASE_ID is not null
    group by DISEASE_ID
),
incidence_rates as (
    select
        T1.REGION_ID,
        (sum(T1.case_count) / nullif(T2.state_population, 0)) * 100000 as incidence_rate_per_100k
    from TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE T1
    join TRANSFORMED_DB_DEV.GEOGRAPHIC.DIM_GEOGRAPHIC T2
        on T1.REGION_ID = T2.REGION_ID
    where T1.case_count is not null
      and T2.state_population > 0
    group by T1.REGION_ID, T2.state_population
),
avg_los as (
    select
        DISEASE_ID,
        avg(length_of_stay_days) as average_length_of_stay
    from TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE
    where length_of_stay_days is not null
      and length_of_stay_days > 0
      and DISEASE_ID is not null
    group by DISEASE_ID
),
disease_summary as (
    select
        DISEASE_ID,
        sum(case_count) as total_cases,
        row_number() over (order by sum(case_count) desc) as disease_rank
    from TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE
    where case_count is not null 
      and case_count > 0
      and DISEASE_ID is not null
    group by DISEASE_ID
),
severity_breakdown as (
    select
        DISEASE_ID,
        severity_level,
        count(surveillance_id) as severity_case_count
    from TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE
    where surveillance_id is not null
      and DISEASE_ID is not null
      and severity_level is not null
    group by DISEASE_ID, severity_level
),
readmission_data as (
    select distinct r1.patient_id as readmitted_patient
    from TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE r1
    join TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE r2
      on r1.patient_id = r2.patient_id
     and r1.surveillance_id != r2.surveillance_id  -- Ensure different admissions
     and r2.admit_date > r1.discharge_date
     and r2.admit_date <= dateadd(day, 30, r1.discharge_date)
    where r1.discharge_date is not null
      and r2.admit_date is not null
      and r1.patient_id is not null
),
readmission_rates as (
    select
        count(distinct r.patient_id) as total_discharged,
        count(distinct re.readmitted_patient) as readmitted_patients,
        round((count(distinct re.readmitted_patient) * 100.0 / nullif(count(distinct r.patient_id), 0)), 2) as readmission_rate_percent
    from TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE r
    left join readmission_data re
        on r.patient_id = re.readmitted_patient
    where r.discharge_date is not null
),
weekly_cases as (
    select
        REGION_ID,
        date_trunc('week', admit_date) as week_start,
        count(surveillance_id) as weekly_case_count
    from TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE
    where surveillance_id is not null
      and admit_date is not null
      and REGION_ID is not null
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
    from TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE T1
    join TRANSFORMED_DB_DEV.HOSPITALS.DIM_HOSPITALS T2
        on T1.hospital_id = T2.hospital_id
    where T1.admit_date is not null
      and (T1.discharge_date is null or T1.discharge_date >= current_date)
      and T1.admit_date <= current_date
      and T2.bed_capacity > 0
      and T1.patient_id is not null
    group by T2.CITY_ID
),
treatment_costs as (
    select
        T1.DISEASE_ID,
        avg(T2.total_amount) as average_treatment_cost,
        count(distinct T1.patient_id) as treatment_case_count
    from TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE T1
    join TRANSFORMED_DB_DEV.PRESCRIPTIONS.FACT_PRESCRIPTIONS T2
      on T1.patient_id = T2.patient_id
     and T1.disease_id = T2.disease_id
    where T1.DISEASE_ID is not null
      and T2.total_amount is not null
      and T2.total_amount > 0
    group by T1.DISEASE_ID
),
cases_per_facility as (
    select
        T1.REGION_ID,
        T1.state,
        T1.city,
        sum(T2.case_count) as total_cases,
        T1.healthcare_facilities_count as facilities,
        round(sum(T2.case_count) / nullif(T1.healthcare_facilities_count, 0), 2) as cases_per_facility_ratio
    from TRANSFORMED_DB_DEV.GEOGRAPHIC.DIM_GEOGRAPHIC T1
    join TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE T2
        on T1.REGION_ID = T2.REGION_ID
    where T1.healthcare_facilities_count > 0
      and T2.case_count is not null
      and T2.case_count > 0
    group by T1.REGION_ID, T1.state, T1.city, T1.healthcare_facilities_count
)
select
    -- Disease Information
    dd.disease_name,
    fds.disease_id,
    -- Hospital Information
    dh.hospital_name,
    -- Corrected latitude and longitude column names (choose the correct option based on your schema):
    -- Option 1: If columns are named latitude/longitude
    dh.latitude as hospital_latitude,
    dh.longitude as hospital_longitude,
    -- Option 2: If columns are named hospital_latitude/hospital_longitude (uncomment if this is correct)
    -- dh.hospital_latitude,
    -- dh.hospital_longitude,
    -- Option 3: If columns are named lat/lng (uncomment if this is correct)  
    -- dh.lat as hospital_latitude,
    -- dh.lng as hospital_longitude,
    -- Geographic Information
    dg.state,
    dg.city,
    dg.district,
    ir.region_id,
    dg.state_population,
    -- Patient Information
    dp.patient_id,
    dp.patient_age,
    dp.patient_gender,
    dp.registration_date,
    -- Date Information
    fds.admit_date as patient_admit_date,
    fds.discharge_date as patient_discharge_date,
   
    fds.admit_date as date_column,
    -- Seasonal Classification
    case
        when extract(month from fds.admit_date) in (6,7,8,9) then 'Monsoon'
        when extract(month from fds.admit_date) in (12,1,2) then 'Winter'
        when extract(month from fds.admit_date) in (3,4,5) then 'Summer'
        when extract(month from fds.admit_date) in (10,11) then 'Post-Monsoon'
        else 'Unknown'
    end as monsoon_season_column,
    case
        when extract(month from fds.admit_date) in (6,7,8,9) then 'Monsoon'
        when extract(month from fds.admit_date) in (12,1,2) then 'Winter'
        when extract(month from fds.admit_date) in (3,4,5) then 'Summer'
        when extract(month from fds.admit_date) in (10,11) then 'Post-Monsoon'
        else 'Unknown'
    end as season,
    case
        when extract(month from fds.admit_date) in (6,7,8,9) then 'High Disease Activity'
        when extract(month from fds.admit_date) in (12,1,2) then 'Respiratory Issues Peak'
        when extract(month from fds.admit_date) in (3,4,5) then 'Moderate Activity'
        when extract(month from fds.admit_date) in (10,11) then 'Post-Monsoon Recovery'
        else 'Unknown'
    end as seasonal_pattern,
    extract(year from fds.admit_date) as admission_year,
    -- Case Information
    fds.case_count,
    fds.severity_level,
    fds.length_of_stay_days,
    -- Aggregated Metrics
    dc.new_cases_daily,
    dc.cumulative_cases,
    ds.disease_rank,
    ds.total_cases,
    al.average_length_of_stay,
    tc.average_treatment_cost,
    tc.treatment_case_count,
    ir.incidence_rate_per_100k,
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
    fp.city_id,
    fp.active_patients,
    fp.total_bed_capacity,
    fp.healthcare_facility_pressure_percent,
    -- Resource Distribution
    cpf.facilities,
    cpf.cases_per_facility_ratio
from TRANSFORMED_DB_DEV.DISEASE_SURVEILLANCE.FACT_DISEASE_SURVEILLANCE fds
-- Joins
left join TRANSFORMED_DB_DEV.DISEASES.DIM_DISEASES dd
    on fds.disease_id = dd.disease_id
left join TRANSFORMED_DB_DEV.HOSPITALS.DIM_HOSPITALS dh
    on fds.hospital_id = dh.hospital_id
left join TRANSFORMED_DB_DEV.GEOGRAPHIC.DIM_GEOGRAPHIC dg
    on fds.region_id = dg.region_id
left join TRANSFORMED_DB_DEV.PATIENTS.DIM_PATIENTS dp
    on fds.patient_id = dp.patient_id
left join daily_cases dc
    on fds.disease_id = dc.disease_id
left join disease_summary ds
    on fds.disease_id = ds.disease_id
left join avg_los al
    on fds.disease_id = al.disease_id
left join treatment_costs tc
    on fds.disease_id = tc.disease_id
left join incidence_rates ir
    on fds.region_id = ir.region_id
left join severity_breakdown sb
    on fds.disease_id = sb.disease_id and fds.severity_level = sb.severity_level
left join readmission_rates rr
    on 1=1
left join growth_rates gr
    on fds.region_id = gr.region_id
left join facility_pressure fp
    on dh.city_id = fp.city_id
left join cases_per_facility cpf
    on fds.region_id = cpf.region_id
where (gr.week_start = (
        select max(week_start)
        from growth_rates gr2
        where gr2.region_id = gr.region_id
    ) or gr.week_start is null)
order by
    ds.disease_rank nulls last,
    ir.incidence_rate_per_100k desc nulls last,
    fp.healthcare_facility_pressure_percent desc nulls last,
    fds.admit_date desc nulls last