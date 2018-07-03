 WITH licenses AS (

    SELECT
        license_serial_number as liq_serial_num,
        license_class_code as liq_class,
        license_type_name as liq_type,
        premises_name as liq_name,
        doing_business_as_dba as liq_dba,
        regexp_replace(actual_address_of_premises_address1, '[^0-9]+', '', 'g') as liq_address_num,
        regexp_replace(regexp_replace(regexp_replace(regexp_replace(upper(actual_address_of_premises_address1),
            ' AVE$', ' AVENUE'), ' ST$', ' STREET'), ' BLVD$', ' BOULEVARD'), ' RD$', ' ROAD')
            as liq_address,
        geom as liq_geom

    FROM
        liquor

), raids AS (

    SELECT
        bin_number as raid_bin_num,
        ecb_violation_number as raid_ecb_violation_number,
        regexp_replace(address, '[^0-9]+', '', 'g')  as raid_address_num,
        regexp_replace(regexp_replace(regexp_replace(regexp_replace(upper(address),
            ' AVE$', ' AVENUE'), ' ST$', ' STREET'), ' BLVD$', ' BOULEVARD'), ' RD$', ' ROAD')
            as raid_address,
        geom as raid_geom
    FROM
        raid

), joined AS (

    SELECT
        *,
        ROUND(st_distance(liq_geom, raid_geom)::numeric, 6) as dist_geo
    FROM
        raids, licenses
    WHERE
        st_dwithin(liq_geom, raid_geom, 0.0008::double precision)

), features AS (

SELECT
    *,
    levenshtein(raid_address, liq_address) as dist_address,
    levenshtein(regexp_replace(raid_address, '[^A-Z]+', '', 'g'),
                regexp_replace(liq_address, '[^A-Z]+', '', 'g'))  as dist_address_alpha,
    CASE
        WHEN liq_address_num = raid_address_num
        THEN 0.0
        WHEN liq_address_num = '' or raid_address_num = ''
        THEN 100000.0
        ELSE abs(liq_address_num::float - raid_address_num::float)
    END as dist_address_num
FROM
    joined
)

SELECT
    *
FROM
    features
WHERE
    dist_address_num = 0
    AND dist_address_alpha < 10
ORDER BY raid_address ASC





