#/bin/sh

set -x
set -e

export_date=`date "+%Y-%m-%d"`
pg_dump -d march > data/march.sql
aws --profile gltd s3 cp data/march.sql s3://gltd/march/pg_dumps/$export_date/march.sql
rm -rf data/march.sql
true;