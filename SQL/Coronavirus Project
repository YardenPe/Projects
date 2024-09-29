USE `corona virus project`;

SELECT *
FROM  CovidDeaths
ORDER BY 3,4;

SELECT *
FROM  CovidVaccinations
ORDER BY 3,4;

-- SELECT data to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2;

-- Total cases vs total deaths - likelihood of dying
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage_by_day
from CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;

-- Total_cases vs Population
SELECT location, date, population, total_cases, (total_cases/population)*100 AS covid_percentage_by_day
FROM CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;

-- Countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) as highestInfection, MAX((total_cases/population)*100) AS covid_percentage
FROM CovidDeaths
GROUP BY location, population
ORDER BY covid_percentage_by_day DESC;

-- Countries with highest death count compared to population
SELECT location, MAX(CAST(total_deaths AS INT)) AS totalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY totalDeathCount DESC;

-- Continent with highest death count
SELECT continent, MAX(CAST(total_deaths AS INT)) AS totalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY totalDeathCount DESC;

-- Continent with highest death count per population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS totalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY totalDeathCount DESC;

-- Global numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, (SUM(new_cases)/SUM(CAST(new_deaths AS INT)))*100 AS globalDeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- Total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- USE CTE
WITH popVsVac (continent, location, dt, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3
)
SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_percentage
FROM popVsVac;

-- TEMP Table - for fun another long way
DROP TABLE IF EXISTS percent_population_vaccinated

CREATE TABLE percent_population_vaccinated
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
rolling_people_vaccinated NUMERIC,
)

INSERT INTO percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_percentage
FROM percent_population_vaccinated;

-- Creating view to store data
CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *
FROM percent_population_vaccinated;




