#/bin/sh

set -e
set -x

PRJ_HOME=`pwd`
CT_FILE_NAME='nyct2010_18b'
CT_URL=https://www1.nyc.gov/assets/planning/download/zip/data-maps/open-data/$CT_FILE_NAME.zip

echo '========================================================'
echo 'Fetching census tracts from the web'
wget -O data/shp_nyct2010.zip $CT_URL

echo '========================================================'
echo 'unzipping census tracts'
unzip data/shp_nyct2010.zip -d data/

echo '========================================================'
echo 'Adding census tracts to DB'
psql -d march -c 'DROP TABLE IF EXISTS public.nyct2010;'
shp2pgsql -I -s 4326 $PRJ_HOME/data/$CT_FILE_NAME/nyct2010.shp public.nyct2010 | psql -d march

echo '========================================================'
echo 'Cleaning up....'
rm data/shp_*.zip
rm -rf "$PRJ_HOME/data/$CT_FILE_NAME/"

echo "==============================================="
echo "Done!"
true;
