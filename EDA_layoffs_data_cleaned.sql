-- Exploratory Data Analysis With Newly Cleaned World Layoff Data
-- world layoffs of various companies from 03/2020- 03/2023

SELECT * 
FROM layoffs_staging3;

-- most likely focusing around the total and (maybe) the percentage laid off columns

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging3;

-- inspecting companies that completely went under 
SELECT * 
FROM layoffs_staging3
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- insepcting companies by how many people they laid off in aggregate
-- by looking at the top of this list we can see some BIG NAME companies 
-- laid off the most people in the timeframe of this data

SELECT company, SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY company
ORDER BY 2 DESC;

-- checking date range of our data table
-- NOTE: data starts RIGHT at the beginning of the COVID19 pandemic! 
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging3;

-- inspecting the industries that laid off the most people 
-- within the timeframe of our data

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY industry
ORDER BY 2 DESC;

-- same thing across countries, USA by FAR had the most layoffs across our timeframe. 

SELECT country, SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY country
ORDER BY 2 DESC;

-- Now seeing the year that resulted in the most people being laid off in aggregate across our time frame

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- same query but for which stage classification of companies laid off the most in aggregate
-- the POST IPO stage makes sense to have the most layoffs as these are often the HUGE corporations like Amazon, Google, Meta, etc
SELECT stage , SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY stage
ORDER BY 2 DESC;

-- now we want to inspect how layoffs progressed across other columns eg. the 'rolling sum' 
-- specifically want to see progression over time, using the month from the date column 
-- to see the rolling total of layoffs over our time frame 


-- first getting the layoffs in each month throughout or table
SELECT SUBSTRING(`date`, 1,7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging3
WHERE SUBSTRING(`date`, 1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- now defining cte to select the totals in each month and add to the previous month as a rolling sum
-- NOTE: don't need a group by in the final statements because we define it in the cte
-- the 'rolling' sum is achieved with the SUM() OVER() with an ORDER BY inside to add to the following month 

WITH Rolling_layoffs_sum AS 
( 
SELECT SUBSTRING(`date`, 1,7) AS `MONTH`, SUM(total_laid_off) AS sum_total
FROM layoffs_staging3
WHERE SUBSTRING(`date`, 1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, sum_total, SUM(sum_total) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_layoffs_sum;

-- now we want to do something similar, inspecting the total layoffs per company, PER year. 

SELECT company, SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY company
ORDER BY 2 DESC;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY company, YEAR(`date`)
ORDER BY 3 desc;

-- want to rank which companies laid off the most people by year, with 1 being the company that laid off the most in that year, 
-- we use the above query to create a CTE to get the required data, then performa the ranking with the dense_rank() function over 
-- the partitioned year data as a separate CTE, and also ordering by the number of people laid off by that company to define the 
-- rank order. The second CTE queries the first to get the layoffs each company made PER YEAR, then performs the partitioning and 
-- ranking. Finally we make a selection of only the top 5 rankings of each year from our second CTE. 

-- NOTE: could redo this for any column you wanted to see rankings for. 


-- with this we can see which companies were laying off the most people in each year of our data table

WITH company_year (company, years, total_laid_off_sum) AS 
( 
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY company, YEAR(`date`)
), company_year_rank AS (
SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off_sum DESC) AS ranking
FROM company_year
WHERE years IS NOT NULL)
SELECT * 
FROM company_year_rank
WHERE ranking <= 5;  













