DROP TABLE IF EXISTS raids_by_precinct;
CREATE TABLE raids_by_precinct AS (
  SELECT
    nyc_precincts.precinct,
    nyc_precincts.geom,
    COUNT(1)
  FROM
      raid
  LEFT JOIN
      nyc_precincts
      ON ST_Contains(nyc_precincts.geom, raid.geom)
  WHERE nyc_precincts.geom IS NOT NULL
  GROUP BY 1,2
  ORDER BY 3 DESC
);