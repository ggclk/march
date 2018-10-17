#!/bin/sh

set -e
set -x

PRJ_HOME=`pwd`

echo "==============================================="
echo "Creating raid table..."

psql -d march -c "
DROP TABLE IF EXISTS public.raid;
CREATE TABLE public.raid (
    address character varying,
    borough_name character varying,
    borough_abbrev character varying,
    bin_number character varying,
    block character varying,
    lot character varying,
    inspection_date character varying,
    access_1 character varying,
    ecb_violation_number character varying,
    dob_violation_number character varying,
    longitude numeric,
    latitude numeric
);
"

echo "==============================================="
echo "Loading raid table..."

psql -d march -c "
COPY public.raid
FROM '$PRJ_HOME/data/march_raids_with_lat.csv'
with csv header quote '\"';
"

echo "==============================================="
echo "Adding geom to raid table..."

psql -d march -c "
ALTER TABLE public.raid ADD COLUMN geom geometry;
UPDATE public.raid SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326);
CREATE INDEX raid_geom_idx ON public.raid USING GIST (geom gist_geometry_ops_2d);
"

echo "==============================================="
echo "Done!"
true;
