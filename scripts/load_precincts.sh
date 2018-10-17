#/bin/sh

set -e
set -x

P_URL='https://data.cityofnewyork.us/api/geospatial/78dh-3ptz?method=export&format=Shapefile'

echo '========================================================'
echo 'Fetching precincts from the web'
wget -O precincts.zip $P_URL

echo '========================================================'
echo 'unzipping precincts'
unzip precincts.zip

echo '========================================================'
echo 'Adding precincts to DB'
psql -d march -c 'DROP TABLE IF EXISTS public.nyc_precincts;'
shp=`ls geo_export_*.shp`
shp2pgsql -I -s 4326 $shp public.nyc_precincts | psql -d march

echo '========================================================'
echo 'Cleaning up....'
# rm data/shp_*.zip
rm -rf geo_export_*
rm -rf precincts.zip

echo "==============================================="
echo "Done!"
true;
