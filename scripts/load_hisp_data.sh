#/bin/sh

set -e
set -x

H_URL='https://api.censusreporter.org/1.0/data/download/latest?table_ids=B03003&geo_ids=16000US3651000,140|16000US3651000&format=shp'

echo '========================================================'
echo 'Fetching race data from the web'
wget -O hisp-data.zip $H_URL

echo '========================================================'
echo 'unzipping race data'
unzip hisp-data.zip -d hisp-data

echo '========================================================'
echo 'Adding race data to DB'
psql -d march -c 'DROP TABLE IF EXISTS public.nyc_hisp;'
shp=`ls hisp-data/*/*.shp`
shp2pgsql -I -s 4326 $shp public.nyc_hisp | psql -d march

echo '========================================================'
echo 'Cleaning up....'
rm -rf hisp-data*

echo "==============================================="
echo "Done!"
true;
