import re
import os
import csv
import string
import json
import time
from pprint import pprint
from datetime import datetime

import requests
import pandas as pd
from bs4 import BeautifulSoup

MARCH_DATA = 'data/march_raids_with_lat.csv'
ECB_DATA = 'data/ecb_data.csv'
ECB_URL = 'http://a810-bisweb.nyc.gov/bisweb/ECBQueryByNumberServlet?ecbin=%s'
ECB_DATA_DIR = 'data/ecb/'
ECB_THROTTLE_MSG = b"Due to the high demand it may take a little longer."
ECG_ERROR_MSG = b"Building Information System Error"
PRINTABLE_CHARACTERS = set(string.printable)
ECB_DATE_FORMAT = '%m/%d/%Y'
SLEEP = 10

def clean_string(s):
    """
    replace all white spaces / unprintable characters
    with tabs for easier parsing.
    """
    s = s.replace("\n", "\t")
    s = s.replace("\t", "\t")
    s = s.replace("\r", "\t")
    s = re.sub("\t+", "\t", s)
    clean_s = ""
    for c in s:
      if c in PRINTABLE_CHARACTERS:
        clean_s += c
      else:
        clean_s += "\t"
    return clean_s.strip()

def clean_date(s):
    """

    """
    if s.strip() == '': return None
    return datetime.strptime(s.strip(), ECB_DATE_FORMAT).strftime('%Y-%m-%d')

def clean_amount(s):
    """
    """
    if s.strip() == '': return None
    return float(s.strip().replace('$', '').replace(',', ''))

def clean_int(s):
    """
    """
    if s.strip() == '': return None
    return int(s)

def clean_bool(s):
    """
    """
    if s.strip() == '': return None
    if s.strip().upper() == 'NO':
        return False
    return True

def search_for_ecb_violation(ecb_violation_number):
    """
    Fetch an HTML page for an ECB violation number
    """
    while True:
        url = ECB_URL % ecb_violation_number
        print("Fetching: %s from %s" % (ecb_violation_number, url))
        r = requests.get(url)
        html = r.content
        if ECB_THROTTLE_MSG in html:
            print('Retrying...')
            time.sleep(SLEEP)

        elif ECG_ERROR_MSG in html:
            print('Not found!')
            return None

        else:
            break
    return html


def parse_ecb_violation(ecb_html):
    """
    """
    soup = BeautifulSoup(ecb_html, 'html.parser')
    lines = soup.text.split("\n\n")
    data = {}

    # iterate through each line of page and manually parse out fields
    for idx, l in enumerate(lines):
        l = clean_string(l)
        if l == "": continue

        #  ECB Violation Details

        if l.startswith('Premises:'):
            data['premises'] = l.split('Premises:')[1].strip()

        if l.startswith('Filed At:'):
            data['filed_at'] = l.split('Filed At:')[1].strip()

        if l.startswith('BIN:'):
            for f in l.split('\t'):
                f = f.strip()
                if f.startswith('BIN:'):
                    data['bin'] = clean_int(f.split('BIN:')[1].strip())

                if f.startswith('Block:'):
                    data['block'] = clean_int(f.split('Block:')[1].strip())

                if f.startswith('Lot:'):
                    data['block'] = clean_int(f.split('Lot:')[1].strip())

                if f.startswith('Community Board:'):
                    data['community_board'] = clean_int(f.split('Community Board:')[1].strip())

        if l.startswith('ECB Violation Summary'):
            data['violation_summary'] = l.split('ECB Violation Summary')[1].strip()

        if l.startswith('ECB Violation Number:'):
            data['violation_number'] = l.split('ECB Violation Number:')[1].strip()

        if l.startswith('Severity:'):
            data['severity'] = l.split('Severity:')[1].split('\t')[0].strip()
            data['certification_status'] = l.split('Certification Status:')[1].strip()

        if l.startswith('Penalty Balance Due:'):
            data['penalty_balance_due'] = clean_amount(l.split('Penalty Balance Due:')[1].strip().split('\t')[0])

        #  Respondent Information

        if l.startswith('Name:'):
            data['respondent_name'] = l.split('Name:')[1].strip()

        if l.startswith('Mailing Address:'):
            data['respondent_mailing_address'] = l.split('Mailing Address:')[1].strip()

        # Violation Details
        if l.startswith('Violation Date:'):
            data['violation_date'] = clean_date(l.split('Violation Date:')[1])

        if l.startswith('Violation Type:'):
            data['violation_type'] = l.split('Violation Type:')[1].strip()

        if l.startswith('Served Date:'):
            data['served_date'] = clean_date(l.split('Served Date:')[1])

        if l.startswith('Inspection Unit:'):
            data['inspection_unit'] = l.split('Inspection Unit:')[1].strip()

        if l.startswith('Infraction Codes'):
            infraction = lines[idx+1]
            fields = clean_string(lines[idx+1]).split('\t')
            data['infraction_codes'] = fields[0].strip()
            data['section_of_law'] = fields[1].strip()
            if len(fields) == 3:
                data['standard_description'] = re.sub('\s+', ' ', fields[2].strip())

        if l.startswith('Specific Violation Condition(s) and Remedy:'):
            fields = clean_string(lines[idx+2])
            if 'REMEDY:' in fields:
                data['specific_violation_conditions'] = fields.split('REMEDY:')[0].strip()
                data['specific_violation_remedy'] = fields.split('REMEDY:')[1].strip()

            elif 'RMDY:' in fields:
                data['specific_violation_conditions'] = fields.split('RMDY:')[0].strip()
                data['specific_violation_remedy'] = fields.split('RMDY:')[1].strip()

            elif 'REM:' in fields:
                data['specific_violation_conditions'] = fields.split('REM:')[0].strip()
                data['specific_violation_remedy'] = fields.split('REM:')[1].strip()

            else:
                data['specific_violation_conditions'] = fields

        if l.startswith('Issuing Inspector ID:'):
            data['issuing_inspector_id'] = l.split('Issuing Inspector ID:')[1].strip().split('\t')[0].strip()
            if 'DOB Violation Number' in l:
                data['dob_violation_number'] = l.split('DOB Violation Number:')[1].strip()

        if l.startswith('DOB Violation Number:'):
            data['dob_violation_number'] = l.split('DOB Violation Number:')[1].strip()

        if l.startswith('Issued as Aggravated Level:'):
            data['issued_as_aggravated_level'] = clean_bool(l.split('Issued as Aggravated Level:')[1].strip())

        #  Dept. of Buildings Compliance History and Events

        if l.startswith('Certification Status:'):
            data['certification_status'] = l.split('Certification Status:')[1].strip().split('\t')[0].strip()
            data['compilance_on'] = clean_date(l.split('Compliance On:')[1])

        if l.startswith('Certification Submission Date:'):
            data['certification_submission_date'] = clean_date(l.split('Certification Submission Date:')[1].split('\t')[0].strip())
            if 'Certification Disapproval Date:' in l:
                data['certification_disapproval_date'] = clean_date(l.split('Certification Disapproval Date:')[1].strip())

        #  ECB Hearing Information

        if l.startswith('Scheduled Hearing Date/Time:'):
            data['hearing_date'] = clean_date(l.split('Scheduled Hearing Date/Time:')[1].strip().split('\t')[0])

        if l.startswith('Hearing Status:'):
            data['hearing_status'] = l.split('Hearing Status:')[1].strip()

        # ECB Penalty Information
        if l.startswith('Penalty Imposed:'):
            data['penalty_imposed'] = clean_amount(l.split('Penalty Imposed:')[1])

        if l.startswith('Adjustments:'):
            data['penalty_adjustments'] = clean_amount(l.split('Adjustments:')[1])

        if l.startswith('Amount Paid:'):
            data['penalty_amount_paid'] = clean_amount(l.split('Amount Paid:')[1])

        if l.startswith('Court Docket Date:'):
            data['court_docket_date'] = clean_date(l.split('Court Docket Date:')[1])

    if len(data.keys()) == 0:
        print(ecb_html)
        raise Exception('Something went wrong, check the raw html above!')

    return data


def fetch_ecb_data(ecb_violation_number, ignore_missing=False):
    """
    """
    json_path = os.path.join(ECB_DATA_DIR, ecb_violation_number + '.json')
    if os.path.exists(json_path):
        return json.load(open(json_path)), True

    if non ignore_missing:
        ecb_html = search_for_ecb_violation(ecb_violation_number)
        if not ecb_html:
            return None, True
        data = parse_ecb_violation(ecb_html)
        with open(json_path, 'wb') as f:
            f.write(json.dumps(data).encode('utf-8'))
        return data, False


def scrape_ecb_violations_for_march_data(ignore_missing=False):
    """
    """
    seen = set()
    for row in csv.DictReader(open(MARCH_DATA)):
        ecb_violation_number = row['ecb_violation_number'].strip()
        if ecb_violation_number != '' and ecb_violation_number not in seen:
            seen.add(ecb_violation_number)
            items = fetch_ecb_data(ecb_violation_number, ignore_missing)
            if not items:
                continue
            data, cached = items
            if data:
                yield data
                if not cached:
                    time.sleep(SLEEP)

def main():
    data = []
    data_keys = set()
    # flatten dicts
    for row in scrape_ecb_violations_for_march_data():
        data.append(row)
    df = pd.DataFrame(data)
    df.to_csv(open(ECB_DATA, 'w'), index=False)

if __name__ == '__main__':
    main()

