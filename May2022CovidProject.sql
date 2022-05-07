select *
from [COVID-DATA]..CovidDeaths
where continent is not null
-- from exploring the data we can see there were issues with continent as a location, so we change our query to filter out continents and other groupings
order by 3, 4


--Let's select some data to work with
select location, date, total_cases, new_cases,total_deaths, population
from [COVID-DATA]..CovidDeaths
where continent is not null
order by 1, 2


-- Let's look at possbility of dying from covid in Canada if one gets the virus
-- We'll do this using total deaths vs total cases in Canada

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as percent_death
from [COVID-DATA]..CovidDeaths
where location like '%canada%' and continent is not null
order by 1, 2


-- Let's look at the percentage of population who have contracted the virus
-- We'll do this using total cases per population

select location, date, total_cases, population, (total_cases/population)*100 as percent_infected
from [COVID-DATA]..CovidDeaths
where location like '%canada%' and continent is not null
order by 1, 2

-- Let's look at countries which have the highest infection rates
-- We'll do this also using total cases per population


select location, population, max(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as PercentOfPopulationInfected
from [COVID-DATA]..CovidDeaths
where continent is not null
group by location, population
order by 4 desc

-- Let's look at the countries with the highest number of deaths per population
-- We'll do this using total deaths per population

select location, population, max(cast(total_deaths as int)) as TotalDeathCount
--running it the first time, there was an issue with data type so we had to cast the total_death column to an integer to get tge right results
from [COVID-DATA]..CovidDeaths
where continent is not null
group by location, population
order by 3 desc

-- Let's look at the deaths per population by continents this time

select location, population, max(cast(total_deaths as int)) as TotalDeathCount
from [COVID-DATA]..CovidDeaths
where continent is null
group by location, population
order by 2 desc

-- Looking at the results from the previous query, we'll have to filter out other groupings that are not continents 

select location, population, max(cast(total_deaths as int)) as TotalDeathCount
from [COVID-DATA]..CovidDeaths
where continent is null and (location not like '%world%' and location not like '%income%' and location not like '%union%' and location not like '%international%')
group by location, population
order by 3 desc

-- Showing all the numbers from the world on a daily bases

select date, sum(new_cases) as TotalCasesDaily, sum(cast(new_deaths as int)) as TotalDeathsDaily, (sum(cast(new_deaths as int))/sum(new_cases)) * 100 as DailyDeathPercentage
--cast new deaths as int because it is in the float type originally
from [COVID-DATA]..CovidDeaths
where continent is not null
group by date
order by 1, 2

-- showing overall global numbers
select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, (sum(cast(new_deaths as int))/sum(new_cases)) * 100 as DeathPercentage
from [COVID-DATA]..CovidDeaths
where continent is not null
order by 1, 2


-- Let's now work with the vaccination table too

-- Let's show the population that have been vaccinated on a daily basis
 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from [COVID-DATA]..CovidVaccinations vac
join [COVID-DATA]..CovidDeaths dea
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- Let's do the daily vaccinations on a rolling count basis ie the sum changes when a new location is reached

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) over(partition by dea.location order by dea.location,
	dea.date) as ConsecutivePopulationVaccinated
-- convert is used here instead of cast (both same) and big int is used because int could not accommodate the values
--(ConsecutivePopulationVaccinated/population)*100
from [COVID-DATA]..CovidVaccinations vac
join [COVID-DATA]..CovidDeaths dea
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- use CTE(Common table expression - creating temporary tables)

with PopulationVaccinated (continent, location, date, population, new_vaccinations, ConsecutivePopulationVaccinated)

as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) over(partition by dea.location order by dea.location,
	dea.date) as ConsecutivePopulationVaccinated
-- convert is used here instead of cast (both same) and big int is used because int could not accommodate the values
--(ConsecutivePopulationVaccinated/population)*100
from [COVID-DATA]..CovidVaccinations vac
join [COVID-DATA]..CovidDeaths dea
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)

select *, (ConsecutivePopulationVaccinated/population)*100 as PercentagePopulationVaccinated
from PopulationVaccinated

-- To get a better view, let's look at only the maximum percentage

with PopulationVaccinated (continent, location, population, new_vaccinations, ConsecutivePopulationVaccinated)

as
(
Select dea.continent, dea.location, dea.population, vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) over(partition by dea.location order by dea.location) as ConsecutivePopulationVaccinated
-- convert is used here instead of cast (both same) and big int is used because int could not accommodate the values
--(ConsecutivePopulationVaccinated/population)*100
from [COVID-DATA]..CovidVaccinations vac
join [COVID-DATA]..CovidDeaths dea
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)

select *, ((max(ConsecutivePopulationVaccinated))/population)*100 as PercentagePopulationVaccinated
from PopulationVaccinated
group by continent, location, population, new_vaccinations


--Alternative we can use Temporary Tables

Drop table if exists #PopulationVaccinated
Create table #PopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
ConsecutivePopulationVaccinated numeric
)

insert into #PopulationVaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) over(partition by dea.location order by dea.location,
	dea.date) as ConsecutivePopulationVaccinated
-- convert is used here instead of cast (both same) and big int is used because int could not accommodate the values
--(ConsecutivePopulationVaccinated/population)*100
from [COVID-DATA]..CovidVaccinations vac
join [COVID-DATA]..CovidDeaths dea
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3

select *, (ConsecutivePopulationVaccinated/Population)*100 as PercentagePopulationVaccinated
from #PopulationVaccinated


-- Creating view to store data for later visualizations

Create View PercentagePopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) over(partition by dea.location order by dea.location,
	dea.date) as ConsecutivePopulationVaccinated
-- convert is used here instead of cast (both same) and big int is used because int could not accommodate the values
--(ConsecutivePopulationVaccinated/population)*100
from [COVID-DATA]..CovidVaccinations vac
join [COVID-DATA]..CovidDeaths dea
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3

--confirm our view is working
select *
from PercentagePopulationVaccinated


create view ContinentalNumbers as
select location, population, max(cast(total_deaths as int)) as TotalDeathCount
from [COVID-DATA]..CovidDeaths
where continent is null and (location not like '%world%' and location not like '%income%' and location not like '%union%' and location not like '%international%')
group by location, population
--order by 3 desc


--confirm our view works
select *
from ContinentalNumbers
