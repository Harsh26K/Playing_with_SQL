
-- 1. Extract data from the table covid-deaths

SELECT * FROM [project1-sql] ..[covid-deaths]
ORDER BY 3,5

-- 2. deaths percentile
-- death percentile per country on respective date

SELECT location, date, population, total_cases, new_cases, total_deaths
FROM [project1-sql] ..[covid-deaths]
ORDER BY 1,2

SELECT location, date, total_cases, total_deaths, 
CONVERT(decimal(15,2),CONVERT(decimal(15,2),total_deaths)/CONVERT(decimal(15,2),total_cases)*100) AS DeathPercentile
FROM [project1-sql] ..[covid-deaths]
ORDER BY 1,2

--3. covid population percentile
-- COVID affected population in each country on respective date

SELECT location, date, population,total_cases,
CONVERT(decimal(15,2),CONVERT(decimal(15,2),total_cases)/CONVERT(decimal(15,2),population)*100) AS CovidPopulationPercentile
FROM [project1-sql] ..[covid-deaths]
ORDER BY 1,2

--4. highest percentile of infected population
--Highest infection percentage in each country till date 

SELECT location, population, MAX(total_cases) as HighestInfection,
CONVERT(decimal(15,2),CONVERT(decimal(15,2),MAX(total_cases))/CONVERT(decimal(15,2),population)*100) AS HighestInfectionPercentile
FROM [project1-sql] ..[covid-deaths]
GROUP BY location, population
ORDER BY HighestInfectionPercentile desc

--5. highest percentile of death
--Highest death percentage in each country till date 

SELECT location, population, MAX(total_deaths) AS HighestDeaths,
CONVERT(decimal(15,2),CONVERT(decimal(15,2),MAX(total_deaths))/CONVERT(decimal(15,2),population)*100) AS HighestDeathsPercentile
FROM [project1-sql] ..[covid-deaths]
GROUP BY location, population
ORDER BY HighestDeathsPercentile desc

--6. total death count
--Total deaths per country till date

SELECT location, MAX(cast(total_deaths as int)) AS HighestDeaths
FROM [project1-sql] ..[covid-deaths]
GROUP BY location
ORDER BY HighestDeaths desc

--7. death count per continent
--Total deaths per continent till date

SELECT continent, MAX(cast(total_deaths as int)) AS HighestDeaths
FROM [project1-sql] ..[covid-deaths]
GROUP BY continent
ORDER BY HighestDeaths desc

--8. Global Numbers
--Death statistics globally

SELECT SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_cases AS INT)) AS TotalCases
, SUM(CAST(new_deaths AS DECIMAL))/SUM(CAST(new_cases AS DECIMAL))*100 AS Percentile
FROM [project1-sql] ..[covid-deaths]
ORDER BY 1,2

--9. Extract data from the table covid-vaccinations

SELECT * FROM [project1-sql] ..[covid-vaccination]
ORDER BY 3,5

--10. total vaccination vs population
--data about the percentage of people vaccinated in each country on respective date

SELECT dea.location, CAST(dea.date as date) as date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, CAST(dea.date as date)) AS RollingPeopleVaccinated
FROM [project1-sql] ..[covid-deaths] dea
JOIN [project1-sql] ..[covid-vaccination] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE vac.continent is not null
ORDER BY 1,2

-- As we can't show the runtime created RollingPeopleVaccinated data directly, we will use CTEs and 
-- Temp Tables to achieve the goal.

--10.1 Using CTE[COMMON TABLE EXPRESSION] to perform total vaccination vs population

WITH PopVsVac(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
	SELECT dea.continent, dea.location, CAST(dea.date as date) as date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, CAST(dea.date as date)) AS RollingPeopleVaccinated
	FROM [project1-sql] ..[covid-deaths] dea
	JOIN [project1-sql] ..[covid-vaccination] vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE vac.continent is not null
	--ORDER BY 1,2
)
SELECT *, CONVERT(decimal(15,3),(CONVERT(decimal(15,3),RollingPeopleVaccinated)/CONVERT(decimal(15,3),population))*100) AS PercenageVaccination
FROM PopVsVac
ORDER BY 2,3

--10.2 Using Temp Table

DROP TABLE IF EXISTS #PercentileVaccinated
CREATE TABLE #PercentileVaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date date,
	population bigint,
	new_vacciantions bigint,
	RollingPeopleVaccinated bigint
)

INSERT INTO #PercentileVaccinated
SELECT dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM [project1-sql] ..[covid-deaths] dea
	JOIN [project1-sql] ..[covid-vaccination] vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE vac.continent is not null

SELECT *, CONVERT(decimal(15,3),(CONVERT(decimal(15,3),RollingPeopleVaccinated)/CONVERT(decimal(15,3),population))*100) AS PercenageVaccination
FROM #PercentileVaccinated
ORDER BY 2,3

--11.creating views for furthur use

--11.1 View showing total deaths per continent

CREATE VIEW DeathCount
AS
SELECT continent, MAX(CAST(total_deaths as int)) AS TotalDeaths
FROM [project1-sql] ..[covid-deaths]
GROUP BY continent

--11.2 View showing no. of people vaccinated in each country on respective date

CREATE VIEW VacVsPop
AS
SELECT dea.continent, dea.location, CAST(dea.date as date) AS date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, CAST(dea.date as date)) AS RollingPeopleVaccinated
FROM [project1-sql] ..[covid-deaths] dea
JOIN [project1-sql] ..[covid-vaccination] vac
ON 
	dea.date = vac.date AND dea.location = vac.location
WHERE dea.continent is NOT NULL


