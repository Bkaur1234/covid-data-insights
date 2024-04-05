/*
Project: COVID-19 Data Analysis and Visualization
Skills Utilized: SQL, Data Analysis, Data Visualization
Data Source: Our World in Data (https://ourworldindata.org/covid-deaths)
Description: This SQL script preprocesses and analyzes COVID-19 data obtained from Our World in Data. 
             The analysis includes various metrics such as total cases, total deaths, death percentages,
             population statistics, and vaccination data. Visualizations of the insights derived from this
             analysis will be created using Tableau for further exploration and presentation.
*/

-- Query to retrieve raw COVID-19 data from the dataset
SELECT *
FROM Covid_data_insights..CovidDeaths$
ORDER BY 3, 4;

-- Additional queries for data exploration and analysis...



-- Retrieve specific columns from the CovidDeaths table and order them by location and date

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid_data_insights..CovidDeaths$
ORDER BY location, date;


-- Calculate the likelihood of dying if contracting COVID-19 in a specific country

SELECT location, date, total_cases, total_deaths, 
       (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS DeathRatePercentage
FROM Covid_data_insights..CovidDeaths$
WHERE location LIKE '%canada%'
ORDER BY location, date;


-- Calculate total cases as a percentage of the population for a specific country

SELECT location, date, population, total_cases, 
       (total_cases / population) * 100 AS CasesPopulationPercentage
FROM Covid_data_insights..CovidDeaths$
WHERE location LIKE '%canada%'
ORDER BY location, date;


-- Determine countries with the highest infection rates compared to their populations

SELECT location, population, MAX(total_cases), 
       MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM Covid_data_insights..CovidDeaths$
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;


-- Identify countries with the highest death counts per population

SELECT location, MAX(CAST(total_deaths AS INT)) AS DeathsPopulationPercentage
FROM Covid_data_insights..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathsPopulationPercentage DESC;


-- Analyze continents with the highest death counts

SELECT continent, MAX(CAST(total_deaths AS INT)) AS DeathsPopulationPercentage
FROM Covid_data_insights..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathsPopulationPercentage DESC;


-- Calculate death percentage by day

SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, 
       SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0) * 100 AS DeathPercentage
FROM Covid_data_insights..CovidDeaths$
WHERE continent IS NOT NULL
AND new_cases != 0
AND new_deaths != 0
GROUP BY date
ORDER BY date;


-- Join the CovidVaccinations and CovidDeaths tables

SELECT *
FROM Covid_data_insights..CovidVaccinations$ vac
JOIN Covid_data_insights..CovidDeaths$ dea
ON vac.location = dea.location
AND vac.date = dea.date;


-- Calculate total population vs vaccination

WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM Covid_data_insights..CovidVaccinations$ vac
    JOIN Covid_data_insights..CovidDeaths$ dea
    ON vac.location = dea.location
    AND vac.date = dea.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM PopvsVac;


-- Create a view to store data for later use

DROP VIEW IF EXISTS PercentPopulationVaccinated;
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM Covid_data_insights..CovidVaccinations$ vac
JOIN Covid_data_insights..CovidDeaths$ dea
ON vac.location = dea.location
AND vac.date = dea.date
WHERE dea.continent IS NOT NULL;



