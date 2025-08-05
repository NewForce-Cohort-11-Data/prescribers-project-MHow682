-- Q1

SELECT 
	p.specialty_description, SUM(rx.total_claim_count) AS total_claims
FROM prescriber AS p
LEFT JOIN prescription AS rx
USING (npi)
WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY p.specialty_description;

-- Q2

-- Combine specialty totals with total row (blank specialty_description)
(
  SELECT 
    p.specialty_description, 
    SUM(rx.total_claim_count) AS total_claims
  FROM prescriber AS p
  LEFT JOIN prescription AS rx USING (npi)
  WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
  GROUP BY p.specialty_description
)
UNION ALL
(
  SELECT 
    '' AS specialty_description, 
    SUM(rx.total_claim_count) AS total_claims
  FROM prescriber AS p
  LEFT JOIN prescription AS rx USING (npi)
  WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
);

-- Q3

SELECT 
    p.specialty_description, 
    SUM(rx.total_claim_count) AS total_claims
  FROM prescriber AS p
  LEFT JOIN prescription AS rx USING (npi)
  WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
  GROUP BY GROUPING SETS ((),(p.specialty_description));

-- Q4

SELECT 
    p.specialty_description, d.opioid_drug_flag,
    SUM(rx.total_claim_count) AS total_claims
  FROM prescriber AS p
  LEFT JOIN prescription AS rx USING (npi)
  LEFT JOIN drug AS d USING (drug_name)
  WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
  GROUP BY GROUPING SETS ((d.opioid_drug_flag),(p.specialty_description),());

-- Q5

SELECT 
    p.specialty_description, d.opioid_drug_flag,
    SUM(rx.total_claim_count) AS total_claims
  FROM prescriber AS p
  LEFT JOIN prescription AS rx USING (npi)
  LEFT JOIN drug AS d USING (drug_name)
  WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
  GROUP BY ROLLUP (d.opioid_drug_flag, p.specialty_description);

-- Q6

SELECT 
    p.specialty_description, d.opioid_drug_flag,
    SUM(rx.total_claim_count) AS total_claims
  FROM prescriber AS p
  LEFT JOIN prescription AS rx USING (npi)
  LEFT JOIN drug AS d USING (drug_name)
  WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
  GROUP BY ROLLUP (p.specialty_description, d.opioid_drug_flag);

-- Q7

SELECT 
    p.specialty_description, d.opioid_drug_flag,
    SUM(rx.total_claim_count) AS total_claims
  FROM prescriber AS p
  LEFT JOIN prescription AS rx USING (npi)
  LEFT JOIN drug AS d USING (drug_name)
  WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
  GROUP BY CUBE (p.specialty_description, d.opioid_drug_flag);

-- Q8

SELECT TRIM(TRAILING ',' FROM TRIM(p.nppes_provider_city)) AS city, 
	   CASE
	   	   WHEN d.generic_name ILIKE '%codeine%' THEN 'codeine'
		   WHEN d.generic_name ILIKE '%fentanyl%' THEN 'fentanyl'
		   WHEN d.generic_name ILIKE '%hydrocodone%' THEN 'hydrocodone'
		   WHEN d.generic_name ILIKE '%morphine%' THEN 'morphine'
		   WHEN d.generic_name ILIKE '%oxycodone%' THEN 'oxycodone'
		   WHEN d.generic_name ILIKE '%oxymorphone%' THEN 'oxymorphone'
	   END AS drug_category,
	   SUM(rx.total_claim_count) AS total_claims
FROM drug AS d
LEFT JOIN prescription AS rx
USING (drug_name)
LEFT JOIN prescriber AS p
USING (npi)
WHERE
    (d.generic_name ILIKE '%codeine%' OR
    d.generic_name ILIKE '%fentanyl%' OR
    d.generic_name ILIKE '%hydrocodone%' OR
    d.generic_name ILIKE '%morphine%' OR
    d.generic_name ILIKE '%oxycodone%' OR
    d.generic_name ILIKE '%oxymorphone%')
AND 
	(p.nppes_provider_city ILIKE '%Memphis' OR
	p.nppes_provider_city ILIKE '%Nashville' OR
	p.nppes_provider_city ILIKE '%Knoxville' OR
	p.nppes_provider_city ILIKE '%Chattanooga')
GROUP BY city, drug_category
ORDER BY city, drug_category;


CREATE EXTENSION tablefunc;

SELECT *
FROM crosstab($$ SELECT TRIM(TRAILING ',' FROM TRIM(p.nppes_provider_city)) AS city, 
	   CASE
	   	   WHEN d.generic_name ILIKE '%codeine%' THEN 'codeine'
		   WHEN d.generic_name ILIKE '%fentanyl%' THEN 'fentanyl'
		   WHEN d.generic_name ILIKE '%hydrocodone%' THEN 'hydrocodone'
		   WHEN d.generic_name ILIKE '%morphine%' THEN 'morphine'
		   WHEN d.generic_name ILIKE '%oxycodone%' THEN 'oxycodone'
		   WHEN d.generic_name ILIKE '%oxymorphone%' THEN 'oxymorphone'
	   END AS drug_category,
	   SUM(rx.total_claim_count) AS total_claims
FROM drug AS d
LEFT JOIN prescription AS rx
USING (drug_name)
LEFT JOIN prescriber AS p
USING (npi)
WHERE 
    (d.generic_name ILIKE '%codeine%' OR
    d.generic_name ILIKE '%fentanyl%' OR
    d.generic_name ILIKE '%hydrocodone%' OR
    d.generic_name ILIKE '%morphine%' OR
    d.generic_name ILIKE '%oxycodone%' OR
    d.generic_name ILIKE '%oxymorphone%')
AND 
	(p.nppes_provider_city ILIKE '%Memphis' OR
	p.nppes_provider_city ILIKE '%Nashville' OR
	p.nppes_provider_city ILIKE '%Knoxville' OR
	p.nppes_provider_city ILIKE '%Chattanooga')
GROUP BY city, drug_category
ORDER BY 1
$$,
$$VALUES ('codeine'), ('fentanyl'), ('hydrocodone'), ('morphine'), ('oxycodone'), ('oxymorphone')$$)
	AS (city text, codeine numeric, fentanyl numeric, hydrocodone numeric, morphine numeric, oxycodone numeric, oxymorphone numeric)
