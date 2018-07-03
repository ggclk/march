#!/bin/sh

set -e
set -x

PRJ_HOME=`pwd`

echo "==============================================="
echo "Creating ecb table..."
psql -d march -c "DROP TABLE IF EXISTS public.ecb;"
psql -d march -c "CREATE TABLE public.ecb (
  bin NUMERIC,
  block NUMERIC,
  certification_disapproval_date  DATE,
  certification_status  TEXT,
  certification_submission_date DATE,
  community_board NUMERIC,
  compilance_on DATE,
  court_docket_date DATE,
  dob_violation_number  TEXT,
  filed_at  TEXT,
  hearing_date  DATE,
  hearing_status  TEXT,
  infraction_codes  TEXT,
  inspection_unit TEXT,
  issued_as_aggravated_level  BOOLEAN,
  issuing_inspector_id  NUMERIC,
  penalty_adjustments NUMERIC,
  penalty_amount_paid NUMERIC,
  penalty_balance_due NUMERIC,
  penalty_imposed NUMERIC,
  premises  TEXT,
  respondent_mailing_address  TEXT,
  respondent_name TEXT,
  section_of_law  TEXT,
  served_date DATE,
  severity  TEXT,
  specific_violation_conditions TEXT,
  specific_violation_remedy TEXT,
  standard_description  TEXT,
  violation_date  DATE,
  violation_number  TEXT,
  violation_summary TEXT,
  violation_type  TEXT
);"

echo "==============================================="
echo "Loading ecb table..."

psql -d march -c "
  COPY public.ecb from '$PRJ_HOME/data/ecb_data.csv'
  with csv header quote '\"'
;"

echo "==============================================="
echo "Done!"
true;
