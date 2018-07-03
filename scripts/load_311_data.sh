#!/bin/sh

PRJ_HOME=`pwd`

set -e
set -x

echo "==============================================="
echo "Creating 311 table..."

psql -d march -c "
DROP TABLE IF EXISTS public.three11;
CREATE TABLE public.three11 (
    unique_key  TEXT,
    created_date  TEXT,
    closed_date TEXT,
    agency  TEXT,
    agency_name TEXT,
    complaint_type  TEXT,
    descriptor  TEXT,
    location_type TEXT,
    incident_zip  TEXT,
    incident_address  TEXT,
    street_name TEXT,
    cross_street_1  TEXT,
    cross_street_2  TEXT,
    intersection_street_1 TEXT,
    intersection_street_2 TEXT,
    address_type  TEXT,
    city  TEXT,
    landmark  TEXT,
    facility_type TEXT,
    status  TEXT,
    due_date  TEXT,
    resolution_description  TEXT,
    resolution_action_updated_date  TEXT,
    community_board TEXT,
    bbl TEXT,
    borough TEXT,
    x_coordinate_state_plane  TEXT,
    y_coordinate_state_plane  TEXT,
    open_data_channel_type  TEXT,
    park_facility_name  TEXT,
    park_borough  TEXT,
    vehicle_type  TEXT,
    taxi_company_borough  TEXT,
    taxi_pick_up_location TEXT,
    bridge_highway_name TEXT,
    bridge_highway_direction  TEXT,
    road_ramp TEXT,
    bridge_highway_segment  TEXT,
    latitude  NUMERIC,
    longitude NUMERIC,
    location  TEXT
);
"
echo "==============================================="
echo "Loading raw 311 requests..."

psql -d march -c "
COPY public.t11_tmp
FROM '$PRJ_HOME/data/311_Service_Requests_from_2010_to_Present.csv'
with csv header;
"
echo "==============================================="
echo "Cleaning up raw 311 requests..."

rm -rf "$PRJ_HOME/data/311_Service_Requests_from_2010_to_Present.csv"

echo "==============================================="
echo "Filtering 311 requests..."

psql -d march -c "
DROP TABLE IF EXISTS public.t11;
CREATE TABLE public.t11 AS (

    WITH raid_range AS (
        SELECT
            (MIN(inspection_date)::date - INTERVAL '15 days')::date as min_date,
            (MAX(inspection_date)::date + INTERVAL '1 day')::date as max_date
        FROM raid
    )

    SELECT
        unique_key AS t11_unique_key,
        to_timestamp(created_date, 'MM/DD/YYYY HH:MI:SS AM') as t11_created_date,
        to_timestamp(closed_date, 'MM/DD/YYYY HH:MI:SS AM') as t11_closed_date,
        to_timestamp(due_date, 'MM/DD/YYYY HH:MI:SS AM') as t11_due_date,
        to_timestamp(resolution_action_updated_date, 'MM/DD/YYYY HH:MI:SS AM') as t11_resolution_date,
        agency_name as t11_agency_name,
        complaint_type as t11_complaint_type,
        descriptor as t11_descriptor,
        location_type as t11_location_type,
        incident_address as t11_address,
        status as t11_status,
        ST_SetSRID(ST_MakePoint(longitude, latitude),4326) as t11_geom

    FROM
        public.t11_tmp, raid_range

    WHERE
        to_timestamp(created_date, 'MM/DD/YYYY HH:MI:SS AM')
        BETWEEN raid_range.min_date AND raid_range.max_date
);
DROP TABLE public.t11_tmp;
"

echo "==============================================="
echo "Done!"
true
