#/bin/sh

set -x
set -e

last_export_date='2018-07-03'
aws --profile gltd s3 cp s3://gltd/march/pg_dumps/$last_export_date/march.sql data/march.sql
psql march < data/march.sql
rm -rf data/march.sql
true;