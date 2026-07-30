create database zomato_project;
use zomato_project;

DROP TABLE IF EXISTS zomato;

CREATE TABLE zomato (
    RestaurantID BIGINT PRIMARY KEY,
    RestaurantName VARCHAR(255),
    CountryCode INT,
    CountryName VARCHAR(100),
    City VARCHAR(120),
    Address TEXT,
    Locality VARCHAR(255),
    Longitude DECIMAL(12,6),
    Latitude DECIMAL(12,6),
    Cuisines VARCHAR(500),
    Currency VARCHAR(100),
    Has_Table_booking VARCHAR(10),
    Has_Online_delivery VARCHAR(10),
    Is_delivering_now VARCHAR(10),
    Price_range INT,
    PriceLabel VARCHAR(50),
    Votes INT,
    Average_Cost_for_two INT,
    Rating DECIMAL(3,1),
    RatingCategory VARCHAR(50),
    Datekey_Opening VARCHAR(20),
    Opening_Date_Fixed DATE,
    `Year` INT,
    `Month` INT,
    MonthName VARCHAR(20),
    MonthFull VARCHAR(20),
    `Quarter` VARCHAR(5),
    YearMonth VARCHAR(20),
    WeekdayNo INT,
    WeekdayName VARCHAR(20),
    FinMonth VARCHAR(5),
    FinQuarter VARCHAR(5)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Zomato_Final.csv'
INTO TABLE zomato
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Zomato_Final.csv'
INTO TABLE zomato
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
RestaurantID, RestaurantName, CountryCode, CountryName, City, Address, Locality,
Longitude, Latitude, Cuisines, Currency, Has_Table_booking, Has_Online_delivery,
Is_delivering_now, Price_range, PriceLabel, Votes, Average_Cost_for_two,
Rating, RatingCategory, Datekey_Opening, @Opening_Date_Fixed,
`Year`, `Month`, MonthName, MonthFull, `Quarter`, YearMonth,
WeekdayNo, WeekdayName, FinMonth, FinQuarter
)
SET Opening_Date_Fixed = STR_TO_DATE(@Opening_Date_Fixed, '%d-%m-%Y');


SELECT COUNT(*) AS total_rows FROM zomato;

-- Q1. Country Map Table
CREATE OR REPLACE VIEW country_map AS
SELECT
    CountryCode,
    CountryName,
    COUNT(*) AS No_of_Restaurants,
    ROUND(AVG(Rating),2) AS Avg_Rating,
    ROUND(AVG(Average_Cost_for_two),0) AS Avg_Cost_for_Two,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zomato),2) AS Percent_of_Total
FROM zomato
GROUP BY CountryCode, CountryName
ORDER BY No_of_Restaurants DESC;

SELECT * FROM country_map;


-- Q2. Calendar Table using Opening_Date_Fixed / Datekey
CREATE TABLE calendar_table AS
SELECT DISTINCT
    Opening_Date_Fixed AS Datekey,
    YEAR(Opening_Date_Fixed) AS `Year`,
    MONTH(Opening_Date_Fixed) AS MonthNo,
    MONTHNAME(Opening_Date_Fixed) AS MonthFullName,
    CONCAT('Q', QUARTER(Opening_Date_Fixed)) AS `Quarter`,
    DATE_FORMAT(Opening_Date_Fixed, '%Y-%b') AS YearMonth,
    DAYOFWEEK(Opening_Date_Fixed) AS WeekdayNo,
    DAYNAME(Opening_Date_Fixed) AS WeekdayName,
    CONCAT('FM',
        CASE
            WHEN MONTH(Opening_Date_Fixed) >= 4
            THEN MONTH(Opening_Date_Fixed) - 3
            ELSE MONTH(Opening_Date_Fixed) + 9
        END
    ) AS FinancialMonth,
    CONCAT('FQ',
        CEIL(
            (
                CASE
                    WHEN MONTH(Opening_Date_Fixed) >= 4
                    THEN MONTH(Opening_Date_Fixed) - 3
                    ELSE MONTH(Opening_Date_Fixed) + 9
                END
            ) / 3
        )
    ) AS FinancialQuarter
FROM zomato
WHERE Opening_Date_Fixed IS NOT NULL
ORDER BY Datekey;

SELECT * FROM calendar_table LIMIT 20;

-- Q3. Number of Restaurants based on City and Country
SELECT CountryName, City, COUNT(*) AS No_of_Restaurants
FROM zomato
GROUP BY CountryName, City
ORDER BY No_of_Restaurants DESC;

-- Q4A. Restaurants opening based on Year
SELECT `Year`, COUNT(*) AS No_of_Restaurants
FROM zomato
GROUP BY `Year`
ORDER BY `Year`;

-- Q4B. Restaurants opening based on Year and Quarter
SELECT `Year`, `Quarter`, COUNT(*) AS No_of_Restaurants
FROM zomato
GROUP BY `Year`, `Quarter`
ORDER BY `Year`, `Quarter`;

-- Q4C. Restaurants opening based on Year and Month
SELECT `Year`, `Month`, MonthFull, COUNT(*) AS No_of_Restaurants
FROM zomato
GROUP BY `Year`, `Month`, MonthFull
ORDER BY `Year`, `Month`;

-- Q5. Count of Restaurants based on Average Ratings
SELECT
    CASE
        WHEN Rating BETWEEN 0 AND 1 THEN '0-1 Very Poor'
        WHEN Rating > 1 AND Rating <= 2 THEN '1-2 Poor'
        WHEN Rating > 2 AND Rating <= 3 THEN '2-3 Average'
        WHEN Rating > 3 AND Rating <= 4 THEN '3-4 Good'
        WHEN Rating > 4 AND Rating <= 5 THEN '4-5 Excellent'
        ELSE 'No Rating'
    END AS Rating_Bucket,
    COUNT(*) AS No_of_Restaurants
FROM zomato
GROUP BY Rating_Bucket
ORDER BY Rating_Bucket;

-- Alternate: using existing RatingCategory
SELECT RatingCategory, COUNT(*) AS No_of_Restaurants
FROM zomato
GROUP BY RatingCategory
ORDER BY RatingCategory;

-- Q6. Average Price buckets and restaurant count
SELECT
    CASE
        WHEN Average_Cost_for_two BETWEEN 0 AND 250 THEN '0-250'
        WHEN Average_Cost_for_two BETWEEN 251 AND 500 THEN '251-500'
        WHEN Average_Cost_for_two BETWEEN 501 AND 1000 THEN '501-1000'
        WHEN Average_Cost_for_two BETWEEN 1001 AND 2000 THEN '1001-2000'
        WHEN Average_Cost_for_two BETWEEN 2001 AND 5000 THEN '2001-5000'
        ELSE '5000+'
    END AS Avg_Price_Bucket,
    COUNT(*) AS No_of_Restaurants,
    ROUND(AVG(Rating),2) AS Avg_Rating
FROM zomato
GROUP BY Avg_Price_Bucket
ORDER BY MIN(Average_Cost_for_two);

-- Q7. Percentage of Restaurants based on Has_Table_booking
SELECT
    Has_Table_booking,
    COUNT(*) AS No_of_Restaurants,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zomato),2) AS Percentage
FROM zomato
GROUP BY Has_Table_booking;

-- Q8. Percentage of Restaurants based on Has_Online_delivery
SELECT
    Has_Online_delivery,
    COUNT(*) AS No_of_Restaurants,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zomato),2) AS Percentage
FROM zomato
GROUP BY Has_Online_delivery;


-- Q9A. Chart Data: Top cuisines by restaurant count
SELECT Cuisines, COUNT(*) AS No_of_Restaurants, ROUND(AVG(Rating),2) AS Avg_Rating
FROM zomato
WHERE Cuisines IS NOT NULL AND Cuisines <> ''
GROUP BY Cuisines
ORDER BY No_of_Restaurants DESC
LIMIT 15;

-- Q9B. Chart Data: Top cities by restaurant count
SELECT City, CountryName, COUNT(*) AS No_of_Restaurants, ROUND(AVG(Rating),2) AS Avg_Rating
FROM zomato
GROUP BY City, CountryName
ORDER BY No_of_Restaurants DESC
LIMIT 15;

-- Q9C. Chart Data: Rating category count
SELECT RatingCategory, COUNT(*) AS No_of_Restaurants
FROM zomato
GROUP BY RatingCategory
ORDER BY RatingCategory;

-- EXTRA KPI 1: Total Restaurants, Countries, Cities, Avg Rating, Total Votes
SELECT
    COUNT(*) AS Total_Restaurants,
    COUNT(DISTINCT CountryName) AS Total_Countries,
    COUNT(DISTINCT City) AS Total_Cities,
    ROUND(AVG(Rating),2) AS Average_Rating,
    SUM(Votes) AS Total_Votes,
    ROUND(AVG(Average_Cost_for_two),0) AS Avg_Cost_for_Two
FROM zomato;

-- EXTRA KPI 2: Top 10 restaurants by votes
SELECT RestaurantName, City, CountryName, Rating, Votes
FROM zomato
ORDER BY Votes DESC
LIMIT 10;

-- EXTRA KPI 3: Top 10 cities by average rating, minimum 20 restaurants
SELECT City, CountryName, COUNT(*) AS No_of_Restaurants, ROUND(AVG(Rating),2) AS Avg_Rating
FROM zomato
GROUP BY City, CountryName
HAVING COUNT(*) >= 20
ORDER BY Avg_Rating DESC
LIMIT 10;

-- EXTRA KPI 4: Online delivery + table booking combination
SELECT Has_Online_delivery, Has_Table_booking, COUNT(*) AS No_of_Restaurants,
       ROUND(AVG(Rating),2) AS Avg_Rating
FROM zomato
GROUP BY Has_Online_delivery, Has_Table_booking
ORDER BY No_of_Restaurants DESC;

-- EXTRA KPI 5: Price label performance
SELECT PriceLabel, COUNT(*) AS No_of_Restaurants,
       ROUND(AVG(Rating),2) AS Avg_Rating,
       ROUND(AVG(Average_Cost_for_two),0) AS Avg_Cost_for_Two
FROM zomato
GROUP BY PriceLabel
ORDER BY No_of_Restaurants DESC;














