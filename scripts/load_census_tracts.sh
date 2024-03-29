#/bin/sh

set -e
set -x

CT_URL='https://data.cityofnewyork.us/api/geospatial/hag7-mz5k?method=export&format=Shapefile'

echo '========================================================'
echo 'Fetching census_tracts from the web'
wget -O census_tracts.zip $CT_URL

echo '========================================================'
echo 'unzipping census_tracts'
unzip census_tracts.zip

echo '========================================================'
echo 'Adding census_tracts to DB'
psql -d march -c 'DROP TABLE IF EXISTS public.nyc_census_tracts;'
shp=`ls geo_export_*.shp`
shp2pgsql -I -s 4326 $shp public.nyc_census_tracts | psql -d march

echo '========================================================'
echo 'Cleaning up....'
rm -rf geo_export_*
rm -rf census_tracts.zip

echo "==============================================="
echo "Done!"
true;
