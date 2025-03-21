create database CrowdFunding_Project;
use CrowdFunding_Project;

Select * from projects;


#Q1) -- Convert the Date fields to Natural Time--
SELECT 
    ProjectID,
    state,
    name,
    country,
    creator_id,
    location_id,
    category_id,
    FROM_UNIXTIME(created_at) AS created_at,
    FROM_UNIXTIME(deadline) AS deadline,
    FROM_UNIXTIME(updated_at) AS updated_at,
    FROM_UNIXTIME(state_changed_at) AS state_changed_at,
    FROM_UNIXTIME(successful_at) AS successful_at,
    FROM_UNIXTIME(launched_at) AS launched_at,
    goal,
    pledged,
    currency,
    currency_symbol,
    usd_pledged,
    static_usd_rate,
    backers_count,
    spotlight,
    staff_pick,
    blurb,
    currency_trailing_code,
    disable_communication
FROM projects;


#Q2) --Build a Calendar Table using the Date Column Created Date--
CREATE TABLE Calendar (
    CalendarDate DATE PRIMARY KEY,
    Year INT,
    MonthNo INT,
    MonthFullName VARCHAR(20),
    Quarter VARCHAR(2),
    YearMonth VARCHAR(10),
    WeekdayNo INT,
    WeekdayName VARCHAR(15),
    FinancialMonth VARCHAR(5),
    FinancialQuarter VARCHAR(5)
);

SELECT DISTINCT 
    FROM_UNIXTIME(created_at) AS CreatedDate,             
    YEAR(FROM_UNIXTIME(created_at)) AS Year,              
    MONTH(FROM_UNIXTIME(created_at)) AS MonthNo,          
    MONTHNAME(FROM_UNIXTIME(created_at)) AS MonthFullName, 
    CONCAT('Q', QUARTER(FROM_UNIXTIME(created_at))) AS Quarter,
    DATE_FORMAT(FROM_UNIXTIME(created_at), '%Y-%b') AS YearMonth, 
    WEEKDAY(FROM_UNIXTIME(created_at)) + 1 AS WeekdayNo,  
    DAYNAME(FROM_UNIXTIME(created_at)) AS WeekdayName,    
    CONCAT('FM', (MONTH(FROM_UNIXTIME(created_at)) - 4 + 12) % 12 + 1) AS FinancialMonth, 
    CONCAT('FQ-', ((MONTH(FROM_UNIXTIME(created_at)) - 4 + 12) % 12 DIV 3) + 1) AS FinancialQuarter 
FROM projects
ORDER BY CreatedDate;


#Q4) --Convert the Goal amount into USD using the Static USD Rate.--
SELECT 
    projectid,                     
    goal AS OriginalAmount,          
    static_usd_rate AS USD_Rate,            
    CONCAT('$', FORMAT(goal * static_usd_rate, 2)) AS GoalInUSD 
FROM projects;


#Q5)1 --Total Number of Projects based on outcome--    
SELECT 
    state AS Outcome,
    COUNT(*) AS TotalProjects
FROM 
    projects
GROUP BY 
    state;


#Q5)2 --Total Number of Projects based on Locations--
SELECT location_id, COUNT(*) as total_projects
FROM projects
GROUP BY location_id;


#Q5)3 --Total Number of Projects based on  Category--
SELECT category_id, COUNT(*) as total_projects
FROM projects
GROUP BY category_id;


#Q5)4 --Total Number of Projects created by Year , Quarter , Month--
SELECT
    YEAR(FROM_UNIXTIME(created_at)) AS year,
    QUARTER(FROM_UNIXTIME(created_at)) AS quarter,
    MONTH(FROM_UNIXTIME(created_at)) AS month,
    COUNT(*) AS total_projects
FROM
    projects
GROUP BY
    YEAR(FROM_UNIXTIME(created_at)),
    QUARTER(FROM_UNIXTIME(created_at)),
    MONTH(FROM_UNIXTIME(created_at))
ORDER BY
    YEAR(FROM_UNIXTIME(created_at)),
    QUARTER(FROM_UNIXTIME(created_at)),
    MONTH(FROM_UNIXTIME(created_at));


#Q6)1 --Successful Projects-- 
SELECT 	
	name,
    state
FROM projects
WHERE state = 'successful';


#Q6)2 --Amount Raised--
SELECT 
    state, 
    CONCAT('$', FORMAT(SUM(pledged), 2)) AS total_amount_raised
FROM 
    projects
GROUP BY 
    state
UNION ALL SELECT 'Total' AS state, CONCAT('$', FORMAT(SUM(pledged), 2)) AS total_amount_raised FROM projects;


#Q6)3 --Number of Backers--
SELECT state, SUM(backers_count) AS total_backers
FROM projects
group by state
UNION ALL SELECT 'Total' AS state, SUM(backers_count) AS total_backers FROM projects;



#Q6)4 --Avg Number of Days for successful projects--
SELECT 
    ROUND(AVG(DATEDIFF(FROM_UNIXTIME(launched_at), FROM_UNIXTIME(created_at)))) AS AvgDaysForSuccessfulProjects
FROM projects
WHERE state = 'successful';



#Q7)1 --Top 10 Successful Projects Based on Number of Backers--
SELECT 
    ProjectID,
    name,
    backers_count,
    state
FROM 
    PROJECTS
WHERE 
    state = 'successful'
ORDER BY 
    backers_count DESC
LIMIT 10;


#Q7)2 --Top 10 Successful Projects Based on Amount Raised.--
SELECT
    name, 
    pledged
FROM
    projects
WHERE
    state = 'successful'
ORDER BY
    pledged DESC
LIMIT 10;


#Q8)1 --Percentage of Successful Projects overall--
SELECT 
    CONCAT(FORMAT((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM projects)), 2), '%') AS percentage_successful
FROM 
    projects
WHERE 
    state = 'successful';
    
    
#Q8)2 --Percentage of Successful Projects  by Category--
SELECT 
    category_id,
    Concat(Round(COUNT(CASE WHEN state = 'successful' THEN 1 END) / COUNT(*) * 100, 2), '%') AS percentage_successful
FROM 
    projects
GROUP BY 
    category_id;
     
     
 
 #Q8)3 --Percentage of Successful Projects by Year , Month etc.--
SELECT 
    YEAR(FROM_UNIXTIME(created_at)) AS year, 
    MONTH(FROM_UNIXTIME(created_at)) AS month, 
    COUNT(*) AS total_projects,
    SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) AS successful_projects,
    CONCAT(FORMAT((SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2), '%') AS success_percentage
FROM 
    projects
GROUP BY 
    YEAR(FROM_UNIXTIME(created_at)), 
    MONTH(FROM_UNIXTIME(created_at))
ORDER BY 
    year, month;


#Q8)4 --Percentage of Successful projects by Goal Range--   
SELECT 
    goal_range,
    CONCAT(FORMAT((successful_projects * 100.0 / total_projects), 2), '%') AS percentage_successful
FROM 
    (
        SELECT 
            CASE 
                WHEN goal < 2500 THEN 'Less than 2,500'
                WHEN goal BETWEEN 2500 AND 5000 THEN '2,500 - 5,000'
                WHEN goal BETWEEN 5000 AND 10000 THEN '5,000 - 10,000'
                WHEN goal BETWEEN 10000 AND 20000 THEN '10,000 - 20,000'
                ELSE 'More than 20,000'
            END AS goal_range,
            COUNT(*) AS total_projects,
            COUNT(CASE WHEN state = 'successful' THEN 1 END) AS successful_projects
        FROM 
            projects
        GROUP BY 
            goal_range
    ) AS subquery;
    
    







