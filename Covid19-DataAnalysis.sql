----- 1. import the data and view the first 10 records in both tables

SELECT TOP 10 * FROM CovidDeaths;
SELECT TOP 10 * FROM CovidVaccination;


----- 2. CHECKING FOR NULL VALUES
SELECT COUNT(*) AS NullDeaths FROM CovidDeaths WHERE Total_Deaths IS NULL; --0 null deaths
SELECT COUNT(*) AS NullVaccinations FROM CovidVaccination WHERE Total_Vaccinations IS NULL;--14595 null vacinnations


----- 3. CHECKING TOTAL DEATHS PER COUNTRY
SELECT location,
SUM(Total_Deaths) AS TotalDeaths,
SUM(Total_cases) AS TotalCases,
ROUND((SUM(Total_Deaths) /SUM(Total_cases))*100,2) AS DeathPercentage
FROM CovidDeaths
WHERE location NOT IN ('Asia', 'Europe', 'Africa', 'North America', 'South America', 'Australia', 'Oceania','Aruba')
AND location is not null
GROUP BY location
ORDER BY 3 DESC;

---- 4. Checking total deaths per continent

SELECT continent,
SUM(Total_Deaths) AS TotalDeaths,
SUM(Total_cases) AS TotalCases,
ROUND((SUM(Total_Deaths) /SUM(Total_cases))*100,2) AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY 3 DESC;


----- 5. CHECKING TOTAL VACCINATIONS PER COUNTRY
SELECT location, 
SUM(Total_Vaccinations) AS TotalVaccinations,

FROM CovidVaccination
WHERE location NOT IN ('Asia', 'Europe', 'Africa', 'North America', 'South America', 'Australia', 'Oceania','Aruba')
AND location is not null
GROUP BY location
ORDER BY TotalVaccinations DESC;

---- 6. Countries with highest infection rate

SELECT 
location,
population,
MAX(total_cases) AS HighestInfectionCount ,
ROUND((MAX(Total_cases)/Population)*100,2) AS PopulationInfectedPercentage
FROM CovidDeaths
WHERE location NOT IN ('Asia', 'Europe', 'Africa', 'North America', 'South America', 'Australia', 'Oceania','Aruba')
AND location is not null
GROUP BY location,population
ORDER BY PopulationInfectedPercentage DESC


----- 7. Daily new deaths over time

SELECT Date, SUM(New_Deaths) AS TotalNewDeaths
FROM CovidDeaths
GROUP BY Date
ORDER BY Date;

----- 8. Daily vaccinations over time

SELECT Date, SUM(Total_Vaccinations) AS TotalVaccinations
FROM CovidVaccination
GROUP BY Date
ORDER BY Date


----- 9. Countries with the highest death-to-vaccination ratio

SELECT cd.location,
       SUM(cd.Total_Deaths) AS TotalDeaths,
       SUM(cv.Total_Vaccinations) AS TotalVaccinations,
       ROUND(SUM(cd.Total_Deaths)/ SUM(cv.Total_Vaccinations),2) AS DeathToVaccinationRatio
FROM CovidDeaths cd
JOIN CovidVaccination cv ON cd.location = cv.location
WHERE cd.location NOT IN ('Asia', 'Europe', 'Africa', 'North America', 'South America', 'Australia', 'Oceania','Aruba')
AND cd.location is not null
GROUP BY cd.location
ORDER BY DeathToVaccinationRatio DESC;

---- 10. Continents with highest death-to-vaccination ratio

SELECT cd.continent,
       SUM(cd.Total_Deaths) AS TotalDeaths,
       SUM(cv.Total_Vaccinations) AS TotalVaccinations,
       ROUND(SUM(cd.Total_Deaths)/ SUM(cv.Total_Vaccinations),2) AS DeathToVaccinationRatio
FROM CovidDeaths cd
JOIN CovidVaccination cv ON cd.location = cv.location
WHERE cd.continent is not null
GROUP BY cd.continent
ORDER BY DeathToVaccinationRatio DESC;


----- 11. The peak dates for deaths and vaccinations

SELECT TOP 1 Date, SUM(New_Deaths) AS PeakDeaths
FROM CovidDeaths
GROUP BY Date
ORDER BY PeakDeaths DESC;

SELECT TOP 1 Date, SUM(Total_Vaccinations) AS PeakVaccination
FROM CovidVaccination
GROUP BY Date
ORDER BY PeakVaccination DESC;


---- 12. Percantage of population covered 
SELECT 
continent,
location,
date,
total_cases,
population,
ROUND((total_cases/population)*100,2) AS PopulationCoveredPercentage
FROM CovidDeaths
ORDER BY PopulationCoveredPercentage DESC


---- 13. using CTE to get people Vaccinated Percentage

WITH PopulationVSVaccinations
AS(
SELECT 
D.continent,
D.date,
D.location,
D.population,
SUM(C.new_vaccinations) OVER (PARTITION BY D.location ORDER BY D.location,D.date) AS PeopleVaccinated
FROM CovidDeaths D
JOIN CovidVaccination C ON(D.location=C.location AND D.date=C.date)
WHERE D.continent IS NOT NULL 
)
SELECT 
*,
ROUND((PeopleVaccinated/population)*100,2) AS PeopleVaccinatedPercentage
FROM PopulationVSVaccinations
ORDER BY PeopleVaccinatedPercentage DESC


---- 14. using TEMP table for the above solution

CREATE TABLE #populationVSvaccination
(continent NVARCHAR(255),date DATETIME,location NVARCHAR(255),population INT,PeopleVaccinated INT)

INSERT INTO #populationVSvaccination (continent, date, location, population, PeopleVaccinated)

SELECT 
D.continent,
D.date,
D.location,
D.population,
SUM(C.new_vaccinations) OVER (PARTITION BY D.location ORDER BY D.location,D.date) AS PeopleVaccinated
FROM CovidDeaths D
JOIN CovidVaccination C ON(D.location=C.location AND D.date=C.date)
WHERE D.continent IS NOT NULL

SELECT 
*,
ROUND((PeopleVaccinated/population)*100,2) AS PeopleVaccinatedPercentage
FROM #populationVSvaccination
ORDER BY PeopleVaccinatedPercentage DESC


----- 15. Correlation between population size and total deaths by country
SELECT 
location, 
Population, 
SUM(Total_Deaths) AS TotalDeaths,
ROUND(SUM(Total_Deaths) / Population * 100,2) AS MortalityRate
FROM CovidDeaths
WHERE location NOT IN ('Asia', 'Europe', 'Africa', 'North America', 'South America', 'Australia', 'Oceania','Aruba')
AND location is not null
GROUP BY location, Population
ORDER BY MortalityRate DESC


----- 16. Average daily vaccinations per continent
SELECT 
Continent, 
ROUND(AVG(Total_Vaccinations),2) AS AvgDailyVaccinations
FROM CovidVaccination
WHERE continent is not null
GROUP BY Continent
ORDER BY AvgDailyVaccinations DESC


----- 17. Rolling 7-day average of new deaths for a given location

SELECT Date, 
location, 
ROUND(AVG(New_Deaths) OVER (PARTITION BY location ORDER BY Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS SevenDayAvgDeaths
FROM CovidDeaths
WHERE location = 'Africa'
ORDER BY SevenDayAvgDeaths DESC


----- 18. Identify dates with sudden vaccination spikes (Anomalies)
WITH Anomalies AS(
SELECT 
Location, 
Date, 
total_vaccinations, 
LAG(total_vaccinations) OVER (PARTITION BY location ORDER BY Date) AS PreviousVaccinations,
total_vaccinations - LAG(total_vaccinations) OVER (PARTITION BY location ORDER BY Date) AS VaccinationIncrease
FROM CovidVaccination
WHERE continent is not null

)
SELECT * FROM Anomalies
WHERE VaccinationIncrease > 50000
ORDER BY VaccinationIncrease DESC

----- 19. Deaths and vaccination status on the same day for all countries

SELECT 
cd.Date, 
cd.location,
cd.New_Deaths, 
cv.Total_Vaccinations
FROM CovidDeaths cd
LEFT JOIN CovidVaccination cv ON (cd.location = cv.location AND cd.Date = cv.Date)
WHERE cd.New_Deaths IS NOT NULL
AND cd.location NOT IN ('Asia', 'Europe', 'Africa', 'North America', 'South America', 'Australia', 'Oceania','Aruba')
AND cd.location is not null
ORDER BY cd.Date, cd.location;


----- 20. Countries with the highest number of new deaths per 100K

SELECT TOP 10 location, 
Date, 
New_Deaths, 
ROUND((New_Deaths / Population) * 100000,2) AS DeathsPer100k
FROM CovidDeaths

ORDER BY DeathsPer100k DESC;