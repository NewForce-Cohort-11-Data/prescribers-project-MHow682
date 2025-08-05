-- a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims. 

SELECT
  npi,
  SUM(total_claim_count) AS claim_total
FROM
  prescription
GROUP BY
  npi
ORDER BY
  claim_total DESC
LIMIT
  1;

-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims. 	

SELECT
  p.nppes_provider_first_name,
  p.nppes_provider_last_org_name,
  p.specialty_description,
  SUM(rx.total_claim_count) AS claim_total
FROM
  prescriber AS p
  INNER JOIN prescription AS rx USING (npi)
GROUP BY
  p.nppes_provider_first_name,
  p.nppes_provider_last_org_name,
  p.specialty_description
ORDER BY
  claim_total DESC
LIMIT
  1;

-- a. Which specialty had the most total number of claims (totaled over all drugs)? 

SELECT
  p.specialty_description,
  SUM(rx.total_claim_count) AS total_claims
FROM
  prescriber AS p
  INNER JOIN prescription AS rx USING (npi)
GROUP BY
  p.specialty_description
ORDER BY
  total_claims DESC;

-- b. Which specialty had the most total number of claims for opioids? 

SELECT
  p.specialty_description,
  SUM(rx.total_claim_count)
FROM
  prescriber AS p
  INNER JOIN prescription AS rx USING (npi)
  INNER JOIN drug AS d USING (drug_name)
WHERE
  opioid_drug_flag = 'Y'
GROUP BY
  p.specialty_description
ORDER BY
  SUM(rx.total_claim_count) DESC;

-- c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table? 

SELECT
  specialty_description
FROM
  prescriber
EXCEPT
SELECT
  p.specialty_description
FROM
  prescriber AS p
  JOIN prescription AS rx USING (npi);


-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
	
WITH
  total_claims AS (
    SELECT
      p.specialty_description,
      SUM(rx.total_claim_count) AS claim_sum
    FROM
      prescriber AS p
      LEFT JOIN prescription AS rx USING (npi)
    GROUP BY
      p.specialty_description
  ),
  opioid_claims AS (
    SELECT
      p.specialty_description,
      SUM(rx.total_claim_count) AS claim_sum
    FROM
      prescriber AS p
      LEFT JOIN prescription AS rx USING (npi)
      LEFT JOIN drug AS d USING (drug_name)
    WHERE
      opioid_drug_flag = 'Y'
    GROUP BY
      p.specialty_description
  )
SELECT
  tc.specialty_description,
  ROUND(oc.claim_sum * 100 / tc.claim_sum, 2) AS opioid_claim_pct
FROM
  total_claims AS tc
  JOIN opioid_claims AS oc USING (specialty_description)
GROUP BY
  tc.specialty_description,
  oc.claim_sum,
  tc.claim_sum
ORDER BY
  opioid_claim_pct DESC;

-- Tommy's query:
SELECT
  specialty_description,
  ROUND(
    (
      SUM(
        CASE
          WHEN opioid_drug_flag = 'Y' THEN total_claim_count
        END
      ) / SUM(total_claim_count)
    ),
    2
  ) * 100 AS percent_opioid
FROM
  prescriber
  LEFT JOIN prescription USING (npi)
  LEFT JOIN drug USING (drug_name)
GROUP BY
  specialty_description
ORDER BY
  percent_opioid DESC NULLS LAST;
	

-- a. Which drug (generic_name) had the highest total drug cost?

SELECT
  d.generic_name,
  SUM(total_drug_cost):: MONEY AS total_cost
FROM
  drug AS d
  INNER JOIN prescription AS rx USING (drug_name)
GROUP BY
  d.generic_name
ORDER BY
  total_cost DESC
LIMIT
  1;


-- b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT 
	d.generic_name, 
	(SUM(total_drug_cost)/SUM(total_day_supply))::MONEY AS cost_per_day
FROM 
	drug AS d
INNER JOIN 
	prescription AS rx
USING
	(drug_name)
GROUP BY 
	d.generic_name
ORDER BY 
	cost_per_day DESC
LIMIT 1;


-- a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT
  drug_name,
  CASE
    WHEN opioid_drug_flag ILIKE '%Y%' THEN 'opioid'
    WHEN antibiotic_drug_flag ILIKE '%Y%' THEN 'antibiotic'
    ELSE 'neither'
  END AS drug_type
FROM
  drug;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT
  CASE
    WHEN opioid_drug_flag = 'Y' THEN 'opioid'
    WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
    ELSE 'neither'
  END AS drug_type,
  SUM(rx.total_drug_cost)::MONEY AS total_cost
FROM
  drug AS d
  INNER JOIN prescription AS rx USING (drug_name)
WHERE
  d.antibiotic_drug_flag = 'Y'
  OR d.opioid_drug_flag = 'Y'
GROUP BY
  drug_type
ORDER BY
  total_cost DESC;

-- a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

SELECT
  COUNT(DISTINCT cbsa) AS tn_cbsa
FROM
  cbsa
WHERE
  cbsaname ILIKE '%TN%';

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT
  cbsa.cbsaname,
  SUM(p.population) AS population
FROM
  population AS p
  INNER JOIN cbsa USING (fipscounty)
GROUP BY
  cbsa.cbsaname
ORDER BY
  population DESC
LIMIT
  1;

SELECT
  cbsa.cbsaname,
  SUM(p.population) AS population
FROM
  population AS p
  INNER JOIN cbsa USING (fipscounty)
GROUP BY
  cbsa.cbsaname
ORDER BY
  population
LIMIT
  1;

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT
  fc.county,
  p.population
FROM
  population AS p
  INNER JOIN fips_county AS fc USING (fipscounty)
WHERE
  p.fipscounty NOT IN (
    SELECT
      fipscounty
    FROM
      cbsa
  )
ORDER BY
  p.population DESC
LIMIT
  1;


-- a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT
  rx.drug_name,
  rx.total_claim_count
FROM
  prescription AS rx
GROUP BY
  rx.drug_name,
  rx.total_claim_count
HAVING
  rx.total_claim_count >= 3000;
	
-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT
  rx.drug_name,
  d.opioid_drug_flag,
  rx.total_claim_count
FROM
  prescription AS rx
  INNER JOIN drug AS d USING (drug_name)
GROUP BY
  rx.drug_name,
  d.opioid_drug_flag,
  rx.total_claim_count
HAVING
  rx.total_claim_count >= 3000;

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT
  p.nppes_provider_first_name,
  p.nppes_provider_last_org_name,
  rx.drug_name,
  d.opioid_drug_flag,
  rx.total_claim_count
FROM
  prescription AS rx
  INNER JOIN drug AS d USING (drug_name)
  INNER JOIN prescriber AS p USING (npi)
GROUP BY
  p.nppes_provider_first_name,
  p.nppes_provider_last_org_name,
  rx.drug_name,
  d.opioid_drug_flag,
  rx.total_claim_count
HAVING
  rx.total_claim_count >= 3000;

-- The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.
-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opioid_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT
  p.npi,
  d.drug_name
FROM
  prescriber AS p
  CROSS JOIN drug AS d
WHERE
  p.specialty_description = 'Pain Management'
  AND p.nppes_provider_city ILIKE '%Nashville%'
  AND d.opioid_drug_flag = 'Y';

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT
  p.npi,
  d.drug_name,
  rx.total_claim_count
FROM
  prescriber AS p
  CROSS JOIN drug AS d
  LEFT JOIN prescription AS rx USING (npi)
WHERE
  p.specialty_description = 'Pain Management'
  AND p.nppes_provider_city ILIKE '%Nashville%'
  AND d.opioid_drug_flag = 'Y'
GROUP BY
  p.npi,
  d.drug_name,
  rx.total_claim_count;


-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT
  p.npi,
  d.drug_name,
  COALESCE(rx.total_claim_count, 0) AS total_claims
FROM
  prescriber AS p
  CROSS JOIN drug AS d
  LEFT JOIN prescription AS rx USING (npi)
WHERE
  p.specialty_description = 'Pain Management'
  AND p.nppes_provider_city ILIKE '%Nashville%'
  AND d.opioid_drug_flag = 'Y'
GROUP BY
  p.npi,
  d.drug_name,
  rx.total_claim_count
ORDER BY
  total_claims DESC;
