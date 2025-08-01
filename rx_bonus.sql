-- How many npi numbers appear in the prescriber table but not in the prescription table?

(SELECT 
	COUNT(npi)
FROM 
	prescriber)
EXCEPT
(SELECT 
	npi 
FROM
 	prescription);


-- a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT 
	d.generic_name, SUM(total_claim_count) AS prescription_count
FROM 
	prescriber AS p
INNER JOIN 
	prescription AS rx USING (npi)
INNER JOIN 
	drug AS d USING (drug_name)
WHERE 
	p.specialty_description = 'Family Practice'
GROUP BY 
	d.generic_name
ORDER BY 
	prescription_count DESC
LIMIT 5;

-- b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT 
	d.generic_name, SUM(total_claim_count) AS prescription_count
FROM 
	prescriber AS p
INNER JOIN 
	prescription AS rx USING (npi)
INNER JOIN 
	drug AS d USING (drug_name)
WHERE 
	p.specialty_description = 'Cardiology'
GROUP BY 
	d.generic_name
ORDER BY 
	prescription_count DESC 
LIMIT 5;


-- c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT 
	d.generic_name, SUM(total_claim_count) AS prescription_count
FROM 
	prescriber AS p
INNER JOIN 
	prescription AS rx USING (npi)
INNER JOIN 
	drug AS d USING (drug_name)
WHERE 
	p.specialty_description IN ('Cardiology', 'Family Practice')
GROUP BY 
	d.generic_name
ORDER BY 
	prescription_count DESC
LIMIT 5;

-- Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee. a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT 
	p.npi, p.nppes_provider_city, SUM(rx.total_claim_count) AS total_claims
FROM 
	prescriber AS p
INNER JOIN 
	prescription AS rx
USING
	(npi)
WHERE 
	p.nppes_provider_city ILIKE '%Nashville%'
GROUP BY 
	p.npi, p.nppes_provider_city
ORDER BY
	total_claims DESC
LIMIT 5;

-- b. Now, report the same for Memphis.

SELECT 
	p.npi, p.nppes_provider_city, SUM(rx.total_claim_count) AS total_claims
FROM 
	prescriber AS p
INNER JOIN 
	prescription AS rx
USING
	(npi)
WHERE 
	p.nppes_provider_city ILIKE '%Memphis%'
GROUP BY 
	p.npi, p.nppes_provider_city
ORDER BY
	total_claims DESC
LIMIT 5;


-- c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

SELECT 
	p.npi, p.nppes_provider_city, SUM(rx.total_claim_count) AS total_claims
FROM 
	prescriber AS p
INNER JOIN 
	prescription AS rx
USING
	(npi)
WHERE 
	p.nppes_provider_city ILIKE '%Memphis%'
	OR p.nppes_provider_city ILIKE '%Nashville%'
	OR p.nppes_provider_city ILIKE 'Knoxville%'
	OR p.nppes_provider_city ILIKE '%Chattanooga%'
GROUP BY 
	p.npi, p.nppes_provider_city
ORDER BY
	total_claims DESC;

-- Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

WITH overdose_deaths AS (
	SELECT f.county, SUM(o.overdose_deaths) AS total_deaths
	FROM overdose_deaths AS o
	INNER JOIN fips_county AS f
	ON CAST(o.fipscounty AS TEXT)=f.fipscounty
	GROUP BY f.county
),
avg_deaths AS (
	SELECT AVG(total_deaths) AS avg_deaths
	FROM overdose_deaths
)
SELECT 
	county, total_deaths
FROM 
	overdose_deaths, avg_deaths
WHERE 
	total_deaths > avg_deaths.avg_deaths
ORDER BY 
	county;

-- a. Write a query that finds the total population of Tennessee.

SELECT 
	SUM(population) AS tn_population
FROM 
	population;

-- b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT 
	f.county, p.population, ROUND((p.population * 100) / tn_total.tn_population, 2) AS percent_of_state
FROM
	fips_county AS f
INNER JOIN
	population AS p
USING
	(fipscounty)
CROSS JOIN(
	SELECT SUM(population) AS tn_population
	FROM population
) AS tn_total
ORDER BY
	f.county;