#!/bin/sh

set -e
set -x

PRJ_HOME=`pwd`

echo "==============================================="
echo "Creating ecb infraction code table..."
psql -d march -c "
DROP TABLE IF EXISTS public.ecb_infraction_codes;
CREATE TABLE public.ecb_infraction_codes (
    ecb_infraction_code       TEXT,
    class       TEXT,
    description       TEXT,
    cure        TEXT,
    stipulation       TEXT,
    standard_penalty        TEXT,
    mitigated_penalty       TEXT,
    default_penatly       TEXT,
    aggravated_penalty        TEXT,
    aggravated_default_penalty        TEXT,
    aggreavated_penalty_ii        TEXT,
    aggravated_penaltty_ii_max        TEXT
);
"

echo "==============================================="
echo "Loading ecb infraction code  table..."

psql -d march -c "
  COPY public.ecb_infraction_codes from '$PRJ_HOME/data/ecb_infraction_codes.csv'
  with csv header quote '\"'
;"

echo "==============================================="
echo "Done!"
true;
