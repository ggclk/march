#/bin/sh

set -x
set -e

aws --profile gltd s3 cp s3://gltd/march/pg_dumps/2018-06-07/march.sql data/march.sql
psql march < data/march.sql
rm -rf data/march.sql
true;