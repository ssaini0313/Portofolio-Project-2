/***********Covid Data Analyst Project***********/

/*
In this project the data pertains to statistics about the Covid virsus.
The scope of the project will focus heavily on the topics of Covid vaccinations
and Covid deaths. Multiple queries will be utilized to see what conclusions can 
be drawn up from the Covid data.
*/

/*
In this query the data that is being extracted will help create a 
comparison between total cases vs total deaths. In addition, this 
comparsion will give a rough estimate of the chances of dying from
Covid after one contracts the virsus.
*/

--Calling the correct database to extract the necessary data.
USE CovidData;

--Total Cases vs Total Deaths all around the world
SELECT
	continent,
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths / total_cases) * 100 AS death_percentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, date, total_cases, total_deaths
ORDER BY location,date;

--Total Cases vs Total Deaths in the United States
SELECT
	continent,
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths / total_cases) * 100 AS death_percentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL AND location LIKE '%States%'
ORDER BY date;

/*
In this query the data that is being extracted will help create a 
comparison between total cases vs population. In addition, this 
comparison will give an insight on what percentage of the population
contracted the Covid virsus. 
*/

--Total Cases vs population all around the world
SELECT
	cd.continent,
	cd.location,
	cd.date,
	cd.total_cases,
	cv.population,
	(cd.total_cases / cv.population) * 100 AS covid_cases_percentage
FROM dbo.CovidDeaths cd
JOIN dbo.CovidVaccinations cv
	ON cv.location = cd.location AND cv.date = cd.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date;

--Total Cases vs population in the United States
SELECT
	cd.continent,
	cd.location,
	cd.date,
	cd.total_cases,
	cv.population,
	(cd.total_cases / cv.population) * 100 AS covid_cases_percentage
FROM dbo.CovidDeaths cd
JOIN dbo.CovidVaccinations cv
	ON cv.location = cd.location AND cv.date = cd.date
WHERE cd.continent IS NOT NULL AND cd.location LIKE '%States%'
ORDER BY cd.location, cd.date;

/*
In this query we are looking at the highest infection rate in comparison
to the population for each country across the whole globe.
*/

SELECT
	cd.continent,
	cd.location,
	MAX(cd.total_cases) AS highest_infection_count,
	cv.population,
	MAX((cd.total_cases / cv.population) * 100) AS highest_covid_cases_percentage
FROM dbo.CovidDeaths cd
JOIN dbo.CovidVaccinations cv
	ON cv.location = cd.location AND cv.date = cd.date
WHERE cd.continent IS NOT NULL
GROUP BY cd.location, cv.population, cd.continent
ORDER BY highest_covid_cases_percentage DESC;

/* 
This query is extracting data that portrays the highest death count per 
population for each country across the whole globe.
*/

SELECT 
	cd.continent,
	cd.location,
	MAX(CAST(cd.total_deaths AS INT)) AS highest_death_count,
	cv.population,
	MAX((cd.total_deaths / cv.population) * 100) AS highest_death_count_percentage
FROM dbo.CovidDeaths cd
JOIN dbo.CovidVaccinations cv
	ON cv.location = cd.location AND cv.date = cd.date
WHERE cd.continent IS NOT NULL --Filtering out the death counts of continents just want countries. 
GROUP BY cd.location, cv.population, cd.continent
ORDER BY highest_death_count DESC;

/* 
This query is extracting data that portrays the highest death count per 
population for each continent across the whole globe.
*/
SELECT
	cd.continent,
	cd.location,
	MAX(CAST(cd.total_deaths AS INT)) AS highest_death_count,
	cv.population,
	MAX((cd.total_deaths / cv.population) * 100) AS highest_death_count_percentage
FROM dbo.CovidDeaths cd
JOIN dbo.CovidVaccinations cv
	ON cv.location = cd.location AND cv.date = cd.date
WHERE cd.continent IS NULL --Filtering out the death counts of countries just want continents. 
GROUP BY cd.location, cv.population, cd.continent
ORDER BY highest_death_count DESC;

/*
In this query the data that is being highlighted deals with total cases vs 
total deaths across the global over time. 
*/

--Total Cases and Total Deaths over time
SELECT 
	date,
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS death_percentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;

--The sum of all the deaths and cases that have occurred so far.
SELECT 
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS death_percentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

/*
In this query the data in question deals with total number of vaccinations 
in comparsion to the total population over time. Since a column was created 
using a expression to manipulate a data, to further utilize this column for 
further data manipulation a CTE (Common Table Expression) or view has to be 
created.
*/



--Utilization of Common Table Expression
WITH PopulationVsVaccinationCTE (continent, location, date, population, new_vaccinations, people_vaccinated_counter)
AS
(
SELECT
	continent,
	location,
	date,
	population,
	new_vaccinations,
	SUM(CONVERT(INT, new_vaccinations)) OVER (PARTITION BY location ORDER BY location, date) AS people_vaccinated_counter
FROM dbo.CovidVaccinations
WHERE continent IS NOT NULL
)

--Utilization of a query to further manipulate the data in the CTE.
SELECT *, (people_vaccinated_counter / population) * 100 AS percentage_of_people_vaccinated
FROM PopulationVsVaccinationCTE
ORDER BY location, date;

--Utilization of a Temp Table

--Just in case the table needs to be dropped due to unwanted changes.
DROP TABLE IF EXISTS #PopulationVsVaccinatedTemp

--Creation of the temporary table.
CREATE TABLE #PopulationVsVaccinatedTemp (
continent NVARCHAR(55),
location NVARCHAR(55),
date DATETIME,
population numeric,
new_vaccination numeric,
people_vaccinated_counter numeric
);

--Inserting data into the temporary table.
INSERT INTO #PopulationVsVaccinatedTemp
SELECT
	continent,
	location,
	date,
	population,
	new_vaccinations,
	SUM(CONVERT(INT, new_vaccinations)) OVER (PARTITION BY location ORDER BY location, date) AS people_vaccinated_counter
FROM dbo.CovidVaccinations
WHERE continent IS NOT NULL;

--Utilization of a View to store data for later visualizations.
GO --Batch separator since the SQL statements above has the same effect as this SQL statement.

CREATE VIEW PopluationVsVaccinatedView --Creation of the view
AS
SELECT
	continent,
	location,
	date,
	population,
	new_vaccinations,
	SUM(CONVERT(INT, new_vaccinations)) OVER (PARTITION BY location ORDER BY location, date) AS people_vaccinated_counter
FROM dbo.CovidVaccinations
WHERE continent IS NOT NULL;










