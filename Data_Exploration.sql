/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


--CovidDeaths table
select * 
from PortfolioProject..CovidDeaths
order by 3,4;

--There is some inconsistency in the dataset. The location column has values like "World" and "Asia". It should have only countries as values.
--From data exploration it was found these inconsistence values in location are corresponded to NULL value in continent column
select * 
from PortfolioProject..CovidDeaths
where continent is not NULL
order by 1,2;

--CovidVaccinations table
--select *
--from PortfolioProject..CovidVaccinations
--order by 3,4;


--Select data we are going to be using and data exploration

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not NULL
order by  1,2;


--total_cases vs total_deaths 
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from PortfolioProject..CovidDeaths
where continent is not NULL
order by 1,2;


--death_percentage in the United States
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from PortfolioProject..CovidDeaths
where location = 'United States' and continent is not NULL
order by 1,2;


--total_cases vs population in the United States
--shows percentage of population infected by covid
select location, date, total_cases, population, (total_cases/population)*100 as percentage_population_infected 
from PortfolioProject..CovidDeaths
where location = 'United States' and continent is not NULL
order by 1,2;


--countries with the highest infection rate or percentage of population infected
select location, population, max(total_cases) as highest_infection_count, (max(total_cases)/population)*100 as percentage_population_infected
from PortfolioProject..CovidDeaths
group by location, population
where continent is not NULL
order by percentage_population_infected desc;


--countries with the highest death rate or percentage of population dead
select location, population, max(total_deaths) as highest_death_count, (max(total_deaths)/population)*100 as percentage_population_dead
from PortfolioProject..CovidDeaths
group by location, population
where continent is not NULL
order by percentage_population_died desc;


--countries with the highest death count 
--using cast function convert the total_deaths into integer (originally varchar)
select location, max(cast(total_deaths as int)) as total_death_count 
from PortfolioProject..CovidDeaths
where continent is not NULL
group by location
order by total_death_count desc;


--Exploring data with respect to continents

--continents with the highest death count 
--using cast function convert the total_deaths into integer (originally varchar)
select continent, max(cast(total_deaths as int)) as total_death_count 
from PortfolioProject..CovidDeaths
where continent is not NULL
group by continent
order by total_death_count desc;


--Global Numbers
--daily total cases, total deaths and death percentage across the world
select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
(sum(cast(new_deaths as int))/sum(new_cases))*100 as death_percentage 
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2;

--total numbers across the world upto date
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
(sum(cast(new_deaths as int))/sum(new_cases))*100 as death_percentage 
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2;


--Using table 2 - CovidVaccinations
--Joining the 2 tables

select *
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location 
and dea.date = vac.date;


--total population vs vaccinations

--select all the fields necessary by joining the two tables
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
order by 1,2,3; 


--rolling sum of vaccinations
--using partition by instead of group by to fetch all the records
--order by location and date to get the rolling sum, not just the total sum of vaccinations by location
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
order by 2,3; 


--total population vs vaccinated or rate of vaccination

--using CTE(Common Table Expression)
--not allowed to use the alias within the same select query, therefore we use cte
--(the number of fields in cte should be equal to the number in select query)
with popvsvac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as 
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
--,(rolling_people_vaccinated/population)*100 
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
--order by 2,3 - order by clause is invalid in views and inline functions
)
select *, (rolling_people_vaccinated/population)*100 as percentage_vaccinated_rolling	
from popvsvac;


--or using temp table
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)
	
insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
--,(rolling_people_vaccinated/population)*100 
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null

select *, (rolling_people_vaccinated/population)*100 as percentage_vaccinated_rolling	
from #PercentPopulationVaccinated;



--cte is a temporary result set used to store the result of a complex subquery for further use and is not stored as an object (substitute for view); limited to current query
--temp table is used to store the result of query on temporary basis in tempdb database; limited to the current session



--create view to store data for visualization
create view PercentPopulationVaccinated_ as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null

select *	
from PercentPopulationVaccinated_;
