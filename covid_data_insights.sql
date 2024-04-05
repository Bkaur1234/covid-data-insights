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



-- Query to select specific columns from the CovidDeaths table, ordered by location and date
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid_data_insights..CovidDeaths$
ORDER BY 1, 2;

-- Query to calculate the likelihood of dying if contracting COVID-19 in Canada
SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS DeathPercentage
FROM Covid_data_insights..CovidDeaths$
WHERE location LIKE '%canada%'
ORDER BY 1, 2;

-- Query to compare total cases to population in Canada
SELECT location, date, population, total_cases, (total_cases / population) * 100 AS CasesVsPopulationPercentage
FROM Covid_data_insights..CovidDeaths$
WHERE location LIKE '%canada%'
ORDER BY 1, 2;

-- Query to find countries with the highest infection rates compared to population
SELECT location, population, MAX(total_cases), MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM Covid_data_insights..CovidDeaths$
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Query to find countries with the highest death counts per population
SELECT location, MAX(CAST(total_deaths AS int)) AS PercentPopulationInfected
FROM Covid_data_insights..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY PercentPopulationInfected DESC;

-- Query to analyze death counts by continent
SELECT continent, MAX(CAST(total_deaths AS int)) AS PercentPopulationInfected
FROM Covid_data_insights..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY PercentPopulationInfected DESC;

-- Query to calculate death percentage by day
SELECT date, SUM(new_CASES), SUM(CAST(new_deaths AS INT)), SUM(CAST(new_deaths AS INT))/NULLIF(SUM(NEW_CASES)* 100,0) AS DeathPercentage
FROM Covid_data_insights..CovidDeaths$
WHERE continent IS NOT NULL
AND new_cases != 0
AND new_deaths != 0
GROUP BY date
ORDER BY 1, 2;

-- Query to join the CovidVaccinations and CovidDeaths tables
SELECT *
FROM Covid_data_insights..CovidVaccinations$ vac
JOIN Covid_data_insights..CovidDeaths$ dea
ON vac.location = dea.location
AND vac.date = dea.date;

-- Query to analyze total population vs vaccination
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated) AS (
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

-- Query to create a view for later use
DROP VIEW IF EXISTS PercentPopulationVaccinated;
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM Covid_data_insights..CovidVaccinations$ vac
JOIN Covid_data_insights..CovidDeaths$ dea
ON vac.location = dea.location
AND vac.date = dea.date
WHERE dea.continent IS NOT NULL;

