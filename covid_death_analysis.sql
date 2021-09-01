select cd."location", cd.date, cd.total_cases, cd.new_cases, cd.total_deaths, cd.population 
from covid_deaths cd
order by cd."location", cd.date


-- The total number of deaths vs total cases(daily trend)
select cd."location", cd.date, cd.total_cases, cd.total_deaths, 
round((cd.total_deaths/cd.total_cases)*100,3)||'%' as total_deaths_percentage
from covid_deaths cd
where cd.continent is not null
order by cd."location", cd.date
 

-- new deaths vs new cases(daily trend)
select cd."location",cd.date,cd.new_cases,cd.new_deaths, 
case cd.new_cases
	when 0 then '0'
	else round((cd.new_deaths/cd.new_cases)*100,5)||'%'
end as new_deaths_percentage
from covid_deaths cd
where cd.continent is not null
order by cd."location", cd.date
 

-- Daily trend of total cases vs  population and total_deaths vs population
select cd."location",cd.date,
round((cd.total_cases/cd.population)*100,5)||'%' infected_population,
round((cd.total_deaths/cd.population)*100,5)||'%' death_percent
from covid_deaths cd
where cd.continent is not null
order by cd.location, cd.date


/* I want to look a the total number of deaths per each country(hence continent is not null condition)
as it stands. On analysis what I found is that the sum of new deaths need not be equal to the total number of deaths in the total_deaths column. This is because for some countries the new_deaths column was not updated properly but at the same time tota_deaths column has the correct data. So, I am going with the total_deaths column to get the correct data. We can take the max(total_deaths) to get the total death count, but what if the total death was corrected later on? So, I am going with the data from the latest row. This should ideally be the last row of each country, but what if the total_deaths was not recorded on the last day? So we remove all the rows where total_deaths is NULL and then find out the latest row using rank(). 
The below query shows us cases where the sum of new deaths != total deaths from total_deaths column. 
*/
with temp as
(select cd.location,
	cd.date, 
	rank() over(partition by cd.location order by cd.date desc),
	cd.total_deaths TotalDeaths,
	cd.new_deaths,
	sum(cd.new_deaths) over(partition by cd.location) SumOfNewdeaths
from covid_deaths cd
where cd.continent is not null
	and cd.total_deaths is not null
order by location, date desc)
select location,date,TotalDeaths,SumOfNewdeaths from temp
where rank = 1
and TotalDeaths != SumOfNewdeaths
order by location;


/* the below query gives the total deaths in each country */
with temp as
(select cd.location,
	rank() over(partition by cd.location order by cd.date desc),
	cd.total_deaths TotalDeaths
from covid_deaths cd
where cd.continent is not null
	and cd.total_deaths is not null
order by location, date desc)
select location,TotalDeaths from temp
where rank = 1
order by location


-- Countries where the covid infection rate is the highest
with temp as
(select cd.location,
	rank() over(partition by cd.location order by cd.date desc) pos,
	cd.total_cases TotalCases,
    cd.population
from covid_deaths cd
where cd.continent is not null
	and cd.total_cases is not null
order by location, date desc)
select location,TotalCases,population, round((TotalCases/population)*100,3) InfectionPercent 
from temp
where pos = 1
order by InfectedPopulationPercent desc


-- Countries where the death toll is the highest
with temp as
(select cd.location,
	rank() over(partition by cd.location order by cd.date desc),
	cd.total_deaths TotalDeaths,
    cd.population
from covid_deaths cd
where cd.continent is not null
	and cd.total_deaths is not null
order by location, date desc)
select location,TotalDeaths,population,round((TotalDeaths/population)*100,3) DeathPercent 
from temp
where rank = 1
order by DeathPercent desc


/* now let's break down by continents 
  when continet is not null, then location represents data for a country
  when continent is null, then location represents data for a continent
*/

-- total cases in each continent
with temp as
(select cd.location,
	rank() over(partition by cd.location order by cd.date desc),
	cd.total_deaths TotalDeaths
from covid_deaths cd
where cd.continent is null
	and cd.total_deaths is not null
order by location, date desc)
select location,TotalDeaths 
from temp
where rank = 1
order by location


-- total death in each continent
with temp as
(select cd.location,
	rank() over(partition by cd.location order by cd.date desc),
	cd.total_deaths TotalDeaths
from covid_deaths cd
where cd.continent is null
	and cd.total_deaths is not null
order by location, date desc)
select location,TotalDeaths 
from temp
where rank = 1
order by location


--  deaths as a percentage of continent's population
with temp as
(select cd.location,
	rank() over(partition by cd.location order by cd.date desc),
	cd.total_deaths TotalDeaths,
    cd.population
from covid_deaths cd
where cd.continent is null
    and cd.location not in ('World','International')
	and cd.total_deaths is not null
order by location, date desc)
select location,TotalDeaths,population,round((TotalDeaths/population)*100,3) DeathPercent 
from temp
where rank = 1
order by DeathPercent desc


-- deaths as a percentage of total number of cases in the continent
-- we consider only those rows where both the death data and cases data are available
select inr.location, (inr.total_deaths/inr.total_cases) death_ratio
from
(select cd.location, cd.date,cd.population, cd.total_deaths,cd.total_cases,
rank() over(partition by cd.location order by cd.date desc) pos
from covid_deaths cd
where cd.continent is null
and cd.location not in ('World','International')
and cd.total_deaths is not NULL
and cd.total_cases is not NULL
) inr
where inr.pos = 1
order by death_ratio desc nulls last

