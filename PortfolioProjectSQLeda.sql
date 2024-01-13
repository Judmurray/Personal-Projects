
--  Data is the COVID19 Death and Vaccination Data for Jan, 2020 - April, 2021
-- Taken from  ourworldindata.org/covid-deaths


Select * 
From Portfolio_project..CovidDeaths
Where continent is not null
order by 3,4


--Select * 
--From Portfolio_project..CovidVaccinations
--order by 3,4

-- Select Specific data that we want 

Select Location, date, total_cases, new_cases, total_deaths, population 
From Portfolio_project..CovidDeaths
Where continent is not null
order by 1,2


-- Examining Total Cases vs Total Deaths 
-- Death% is essentially likelihood of death if you caught Covid at that time, in that country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Portfolio_project..CovidDeaths
Where location like '%states%'and continent is not null
order by 1,2


-- Looking at the Total Cases vs The Population 
-- Shows what % of the population contracted COVID during this time

Select Location, date, total_cases, population, (total_cases/population)*100 as CatchRate
From Portfolio_project..CovidDeaths
-- Where location like '%states%'
Where continent is not null
order by 1,2



-- Looking at Countries with the highest CatchRates relative to population

Select Location, population, MAX(total_cases) as HighestCatchCount, MAX((total_cases/population))*100 as CatchRate
From Portfolio_project..CovidDeaths
-- Where location like '%states%'
Where continent is not null
Group by Location, population
order by CatchRate desc


-- Now examining countries with the highest death count relative to population
-- NOTE: runs into issue with data type of total deaths, check the data type in the table
-- column and make sure it works, need to cast as numeric if not 

-- also NOTE: some of the data for location is NOT a country, but a continent
-- and we should fix this 


Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From Portfolio_project..CovidDeaths
-- Where location like '%states%'
Where continent is not null
Group by Location
order by TotalDeathCount desc


-- NOW WANT TO BREAK DOWN THE DATA BY CONTINENT
-- can do this for any other query to see the continental 
-- data, just add 'continent' to the list of covariates included
-- Showing the continents with the highest death counts 
-- NOTE: need continent == null for the correct counts to be shown

/*

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From Portfolio_project..CovidDeaths
-- Where location like '%states%'
Where continent is null
Group by Location
order by TotalDeathCount desc

*/


-- SAME thing but we want to examine it this way so 
-- visualizations planned later will not be disrupted. 

-- NOTE: with this option, some of the counts seem to be 
-- messed up potentially, eg. the North America count only 
-- seems to contain the USA 

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From Portfolio_project..CovidDeaths
-- Where location like '%states%'
Where continent is not null
Group by continent
order by TotalDeathCount desc


-- Global Numbers - Death Percentage across the world on a given
-- day within this time frame 
-- comment out the group by line to see the death % accross 
-- the world in total 

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From Portfolio_project..CovidDeaths
--Where location like '%states%'and
Where continent is not null
Group by date
order by 1,2


-- Now examining Total population vs Vaccinations

-- need to partition on location, ordered by 
-- LOCATION AND DATE so that the aggregate 
-- function runs the correct amount of times 
--  and keeps a running count of vacciations 
-- for each location



Select dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RunningVaxCount 

From Portfolio_project..CovidDeaths dea
join Portfolio_project..CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 2,3



-- USING CTE , eg filter original table to obtain required subset
-- make sure you include same number of columns in cte as the query 
-- you're including within the cte expression 
-- NOTE: can't include order by clause in cte 


With PopVsVac (continent, location, date, population, New_Vaccinations, RunningVaxCount)
as (
Select dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RunningVaxCount 
From Portfolio_project..CovidDeaths dea
join Portfolio_project..CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
-- order by 2,3 
)
Select * , (RunningVaxCount/population)*100
From PopVsVac


-- Temp Table using cte 

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric, 
New_vaccinations numeric , 
RunningVaxCount numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RunningVaxCount 
From Portfolio_project..CovidDeaths dea
join Portfolio_project..CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
-- order by 2,3 

Select * , (RunningVaxCount/population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for visualizations 

Create View PercentPopulationVaccinatedView as  
Select dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as RunningVaxCount 
From Portfolio_project..CovidDeaths dea
join Portfolio_project..CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by 2,3 

Select * 
From PercentPopulationVaccinatedView