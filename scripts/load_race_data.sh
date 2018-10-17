#/bin/sh

set -e
set -x

R_URL='https://api.censusreporter.org/1.0/data/download/latest?table_ids=B02001&geo_ids=16000US3651000,140|16000US3651000&format=shp'

echo '========================================================'
echo 'Fetching race data from the web'
wget -O race-data.zip $R_URL

echo '========================================================'
echo 'unzipping race data'
unzip race-data.zip -d race-data

echo '========================================================'
echo 'Adding race data to DB'
psql -d march -c 'DROP TABLE IF EXISTS public.nyc_race;'
shp=`ls race-data/*/*.shp`
shp2pgsql -I -s 4326 $shp public.nyc_race | psql -d march

echo '========================================================'
echo 'Cleaning up....'
rm -rf race-data*

echo "==============================================="
echo "Done!"
true;
