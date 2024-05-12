-- Data Cleaning Project: this small project will be for 
-- cleaning a dataset consisting of job layoff data from 
-- all over the world, so that we can use it for exploratory data analysis. 

SELECT * 
FROM layoffs;

-- STEPS: 
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Inspect Null/NA/Missing Values 
-- 4. Remove Irrelevant Columns or Rows (be careful removing from the RAW dataset, create a 
-- new table to do this) 

-- creating new table to inspect duplicates with row number to index by for removal
CREATE TABLE layoffs_staging
LIKE layoffs; 

SELECT * 
FROM layoffs_staging;

INSERT layoffs_staging
SELECT * 
FROM layoffs; 

SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date` ) as row_num
FROM layoffs_staging;

WITH duplicate_cte AS 
( 
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry,  total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging
) 
SELECT * 
FROM duplicate_cte
WHERE row_num > 1; 

SELECT * 
FROM layoffs_staging
WHERE company = 'Casper';

-- Now creating ANOTHER new table to remove the duplicates from WITHOUT changing the 
-- initial raw data. NOTE: now have 3 tables total

CREATE TABLE `layoffs_staging3` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL, 
  `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging3; 

-- remaking our 2nd table with the row num and inspecting
INSERT INTO layoffs_staging3
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry,  total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging3
WHERE row_num > 1; 

-- finally removing duplicate values - SAFE UPDATES NEED TO BE OFF
DELETE
FROM layoffs_staging3
WHERE row_num > 1; 

SELECT *
FROM layoffs_staging3
WHERE row_num > 1;

-- inspecting table now that duplicates have been removed
SELECT *
FROM layoffs_staging3
WHERE company = 'Airbnb'; 

-- Standardizing our data (fixing appearance and scale of the data) 

-- first removing white space from company column
SELECT company, TRIM(company)
FROM layoffs_staging3; 

UPDATE layoffs_staging3
SET company = TRIM(company);

-- Now fixing industry column, some repeated industries with slightly different names, etc. 

SELECT *
FROM layoffs_staging3
WHERE industry LIKE 'Crypto%'; 

UPDATE layoffs_staging3
SET industry = 'Crypto' 
WHERE industry LIKE 'Crypto%'; 

SELECT DISTINCT(industry) 
FROM layoffs_staging3; 

-- now inspecting issues with country column
-- use TRAILING-FROM to remove things from the end of string
-- used here to update duplicate 'United States.' column with period to remove the trailing period. 

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging3
ORDER BY 1; 

UPDATE layoffs_staging3
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'; 

-- now updating date column format so we can use it for time series analysis if we want
-- currently in 'text' format, need datetime
-- to format the datetime, need to use the '%m/%d/%Y' format specifically after passing in the date column 

SELECT `date`, 
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging3; 

UPDATE layoffs_staging3
SET `date` = str_to_date(`date`, '%m/%d/%Y'); 

SELECT `date`
FROM layoffs_staging3; 

-- now date is in the right format, but still a 'text' type
-- NEED to alter table, NEVER do in raw table, just in staging table for edits
-- done below 

ALTER TABLE layoffs_staging3
MODIFY COLUMN `date` DATE; 

-- Now addressing the 'null' or blank values in our table
-- use IS NULL to inspect null values
-- TAKE NOTE of observations with nulls in multiple columns

-- inspecting nulls in some of our columns

-- nulls in total and percentage laid off

SELECT *
FROM layoffs_staging3
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 

-- nulls and blanks in industry column

UPDATE layoffs_staging3
SET industry = NULL 
WHERE industry = ''; 

SELECT * 
FROM layoffs_staging3
WHERE industry IS NULL 
OR industry = '';

SELECT * 
FROM layoffs_staging3
WHERE company LIKE 'Bally%';

SELECT t1.industry, t2.industry
FROM layoffs_staging3 t1
JOIN layoffs_staging3 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL; 

UPDATE layoffs_staging3 t1
JOIN layoffs_staging3 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL; 

-- now inspecting remaining data 

SELECT * 
FROM layoffs_staging3; 

-- still have some missing/null values, but with the remaining data, it would be hard to populate those 
-- observations since we do not have enough context to infer what they should be replaced with. 

-- now removing any irrelevant columns or rows

-- since our data is about layoffs, and the following observations have no total or percentage laid off 
-- it is hard to tell if these are important to our analysis of layoffs, or if these observations' companies 
-- even laid anyone off at all, cannot trust this for analysis so we are deleting these observations 

SELECT *
FROM layoffs_staging3
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 

DELETE 
FROM layoffs_staging3
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 

-- now dealing with row_num that we added earlier, this time dropping a column 

ALTER TABLE layoffs_staging3
DROP COLUMN row_num; 

-- inspecting to make sure it worked 

SELECT *
FROM layoffs_staging3;

DROP TABLE layoffs_staging2;
DROP TABLE temp_table;

-- NOW the data is (more or less) CLEAN for our purposes (can now move to eda)





 







