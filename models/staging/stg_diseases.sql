select
    cast(disease_id as string) as disease_id,
    initcap(trim(disease)) as disease_name,
    initcap(trim(disease_category)) as disease_category,
    initcap(trim(severity_levels)) as severity_level,
    initcap(trim(transmission_type)) as transmission_type,
    initcap(trim(seasonal_pattern)) as seasonal_pattern,
    initcap(trim(example_drugs)) as example_drugs
from {{ source('raw', 'RAW_DISEASES_WITH_IDS') }}
