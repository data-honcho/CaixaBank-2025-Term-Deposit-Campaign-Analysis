-- CaixaBank Telemarketing Campaign Analysis Project Summary

--Q1 What is the total number of customers contacted?
SELECT DISTINCT(COUNT(campaign)) AS total_customers
FROM fact_marketing_campaign;

--Q2 What is the total number of calls made?
SELECT SUM(campaign) AS total_contacts
FROM fact_marketing_campaign;


-- Q3 How many contacted customers subscribed vs non-subscribers to CaixaBank term deposit?
SELECT CAST(COUNT(CASE WHEN deposit = 'yes' THEN 1 END) AS DECIMAL(10,0)) AS total_subscribers,
CAST(COUNT(CASE WHEN deposit = 'no' THEN 1 END) AS DECIMAL(10,0)) AS total_non_subscribers,
-- subscriber vs non-subscriber by percent
CAST(CAST(ROUND(100.0 * SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) / COUNT(*),2 ) AS DECIMAL(10,2)) AS VARCHAR(10)) + '%' AS subscription_rate,  
CAST(CAST(ROUND(100.0 * SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(10,2)) AS VARCHAR(10)) + '%' AS bounce_rate
FROM fact_marketing_campaign;


--Q4 What is the average annual balance in customers account during the campaign?
SELECT
CAST(AVG(1.0 * balance) AS DECIMAL(10,2)) AS avg_balance	,
CAST(AVG(CASE WHEN deposit = 'yes' THEN balance END) AS DECIMAL(10,2)) AS avg_bal_subscribers,
CAST(AVG(CASE WHEN deposit = 'no' THEN balance END) AS DECIMAL(10,2)) AS avg_bal_non_subscribers
FROM fact_marketing_campaign;


--CONVERSION RATE
--Q5 What is the overall percentage of conversion vs bounce rate for the period?
SELECT
    -- Corrected: Cast to decimal first, then cast to varchar, then append '%'
    CAST(CAST(ROUND(100.0 * SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(10,2)) AS VARCHAR(10)) + '%' AS subscription_rate,  
    CAST(CAST(ROUND(100.0 * SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(10,2)) AS VARCHAR(10)) + '%' AS bounce_rate
FROM fact_marketing_campaign;

--Q5 Analyzing Conversion vs. Bounce Trend for the period
WITH total AS (
SELECT
month_number,
COUNT(contact) AS total_customers,
SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS total_conversion,
SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) AS total_bounce
FROM fact_marketing_campaign
 GROUP BY month_number
)
SELECT 
COUNT(month_number) AS months_count,
SUM(total_customers) AS overall_total_customers,
SUM(total_conversion) AS overall_total_conversions, 
SUM(total_bounce) AS overall_total_bounces,
CAST(100.0 * SUM(total_conversion) / SUM(total_customers) AS DECIMAL(10,2)) AS grand_subscription_rate,
CAST(100.0 * SUM(total_bounce) / SUM(total_customers) AS DECIMAL(10,2)) AS grand_bounce_rate
FROM total;

--Q6 What is the Conversion rate vs. Bounce rate monthly trend?
SELECT
    month_number,
    COUNT(*) AS total_contacts,
    SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS conversions_rate,
    SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) AS bounces_rate,
	CAST(ROUND(100.0 * SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY month_number
ORDER BY month_number;


--Q7 Which job category performed best overall for the period?
WITH conversion_by_job_ranking AS (
    SELECT 
        month_number,
        job,
        COUNT(*) AS total_contacts,
        SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS total_conversions,
        SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) AS total_bounces,
        CAST(ROUND(100.0 * SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
        CAST(ROUND(100.0 * SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate
    FROM fact_marketing_campaign
    GROUP BY month_number, job
),
ranked_data AS (
SELECT 
    month_number,
    job,
    total_contacts,
    total_conversions,
    subscription_rate,
    -- This partitions the data by month and ranks conversion rates from highest to lowest
    ROW_NUMBER() OVER (
        PARTITION BY month_number 
        ORDER BY subscription_rate DESC
    ) AS conversion_rank
FROM conversion_by_job_ranking
)
SELECT 
    month_number,
    job,
    total_contacts,
    total_conversions,
    subscription_rate,
    conversion_rank
FROM ranked_data
WHERE conversion_rank <= 3
ORDER BY month_number, conversion_rank;


--Q8 How does job type influence conversion rate, which category should be prioritize for term deposit subscription?
SELECT job AS Job_Profile, SUM(campaign) AS Total_Calls, COUNT(campaign) AS Contacts,
CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*),2)AS DECIMAL(10,2)) AS Subscription_Rate,
CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*),2) AS DECIMAL (10,2)) AS Bounce_Rate
FROM fact_marketing_campaign
GROUP BY job
ORDER BY subscription_rate DESC;

-- 8B Cross Analysis Call Time by Job Type
SELECT 
    job AS job_type, 
    COUNT(campaign) AS total_customer,
	SUM(campaign) AS total_call_volume,
    -- Fixed: Rounded the final divided result to 2 decimal places
    ROUND(SUM(duration_min) / 60.0, 2) AS total_call_time_hrs,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*),2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*),2) AS DECIMAL (10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY job
ORDER BY subscription_rate DESC;


--Q8 How does job type influence conversion rate, which category should be prioritize for term deposit subscription?
SELECT 
	job AS job_type,
    COUNT(campaign) AS contacts,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*),2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*),2) AS DECIMAL(10,2)) AS bounce_rate,
    -- Strategic priority alignment based on volume and efficiency balance
    CASE 
        WHEN job IN ('student', 'retired') THEN 'Tier 1: High Efficiency (Immediate Target)'
        WHEN job IN ('management', 'admin.') THEN 'Tier 2: High Volume (Core Revenue)'
        WHEN job IN ('unemployed', 'self-employed', 'unknown', 'technician') THEN 'Tier 3: Moderate Potential'
        ELSE 'Tier 4: Deprioritize / Restructure Strategy'
    END AS strategic_priority
FROM fact_marketing_campaign
GROUP BY job
ORDER BY strategic_priority ASC, subscription_rate DESC;



--Q9 WHat is the average conversion rate vs bounce rate performance per month? 
WITH monthly_performace AS (
    SELECT
        month_number,
        COUNT(*) AS total_contacts,
        SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS monthly_conversions,
        SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) AS monthly_bounces
    FROM fact_marketing_campaign
    GROUP BY month_number
)
SELECT 
    -- 1. Grand average volumes per month
    CAST(AVG(1.0 * total_contacts) AS DECIMAL(10,2)) AS avg_monthly_contacts,
    CAST(AVG(1.0 * monthly_conversions) AS DECIMAL(10,2)) AS avg_monthly_conversions, 
    CAST(AVG(1.0 * monthly_bounces) AS DECIMAL(10,2)) AS avg_monthly_bounces,
    -- 3. Average monthly percentages 
    CAST(AVG(100.0 * monthly_conversions / NULLIF(total_contacts,0)) AS DECIMAL(10,2)) AS monthly_subscription_rate,
    CAST(AVG(100.0 * monthly_bounces / NULLIF(total_contacts,0)) AS DECIMAL(10,2)) AS monthly_bounce_rate
FROM monthly_performace;


--Q10 How doess customer balances influence conversion rate, which category should be prority for term deposit subscription?
SELECT
    CASE
        WHEN balance < 0 THEN 'Negative'
        WHEN balance > 0 AND balance < 1804 THEN 'Low'
        WHEN balance > 1804 AND balance < 5000 THEN 'Medium'
        ELSE 'High'
    END AS balance_group,

COUNT(*) AS customers,
CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/ COUNT(*),2) AS DECIMAL(10,2)) AS subscription_Rate,
CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/ COUNT(*),2) AS DECIMAL(10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY
    CASE
        WHEN balance < 0 THEN 'Negative'
        WHEN balance > 0 AND balance < 1804 THEN 'Low'
        WHEN balance > 1804 AND balance < 5000 THEN 'Medium'
        ELSE 'High'
    END
ORDER BY subscription_rate DESC;


--Q11 How does education level influence conversion rate, which category should be prioritize for term deposit subscription?
SELECT education AS level_of_education, 
CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*),2)AS DECIMAL(10,2)) AS subscription_rate,
CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*),2) AS DECIMAL (10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY education
ORDER BY subscription_rate DESC;


--Q12 How does marital status influence conversion rate, which category should be prioritized for term deposit subscription? 
SELECT marital AS marital_status, 
CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*),2)AS DECIMAL(10,2)) AS subscription_rate,
CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*),2) AS DECIMAL (10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY marital
ORDER BY subscription_rate DESC;


--Q13 What is conversion rate based on previous default history?
SELECT 
    [default] AS default_status,
    COUNT(*) AS total_customers,
	SUM(balance) AS balance,
	 -- Your original conversion & bounce percentages
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*),2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*),2) AS DECIMAL(10,2)) AS bounce_rate,
	  -- Average minutes for successful conversions ('yes')
    CAST(AVG(CASE WHEN deposit = 'yes' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_converted,
    -- Average minutes for rejections ('no')
    CAST(AVG(CASE WHEN deposit = 'no' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_bounced
FROM fact_marketing_campaign
GROUP BY [default]
ORDER BY subscription_rate DESC;


--Q14 How is personal loan influencing subscription to term deposit/conversion rate?
SELECT 
    loan AS personal_loan_status,
    COUNT(*) AS total_customers,
	SUM(balance) AS balance,
    -- Average call length in minutes for successes vs rejections
    CAST(AVG(CASE WHEN deposit = 'yes' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_converted,
    CAST(AVG(CASE WHEN deposit = 'no' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_bounced,
    -- Outcome percentages
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY loan
ORDER BY subscription_rate DESC;

--Q15 How is housing loan influencing subscription to term deposit/conversion rate?
SELECT 
    housing AS housing_loan_status,
    COUNT(*) AS total_customers,
	SUM(balance) AS balance,
    -- Average call length in minutes for successes vs rejections
    CAST(AVG(CASE WHEN deposit = 'yes' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_converted,
    CAST(AVG(CASE WHEN deposit = 'no' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_bounced,
    -- Outcome percentages
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY housing
ORDER BY subscription_rate DESC;


--Q16 How is customer contact channel/type influencing subscription to term deposit/conversion rate?
SELECT 
    contact AS contact_channel,
    COUNT(*) AS total_customers,
	SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS customers_converted,
	SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) AS customer_bounced,
    -- Average call length in minutes for successes vs rejections
    CAST(AVG(CASE WHEN deposit = 'yes' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_converted,
    CAST(AVG(CASE WHEN deposit = 'no' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_bounced,
    -- Outcome percentages
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY contact
ORDER BY subscription_rate DESC;


--Q17 How is previous contact pattern likely to effect on current campaign?
SELECT 
    CASE 
        WHEN pdays = -1 THEN 'Never Contacted Before'
        WHEN pdays <= 30 THEN 'Contacted Within Last 30 Days'
        ELSE 'Contacted Over 30 Days Ago'
    END AS historical_call_analysis,
    COUNT(*) AS total_customers,
    -- Average call length in minutes for successes vs rejections
    CAST(AVG(CASE WHEN deposit = 'yes' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_converted,
    CAST(AVG(CASE WHEN deposit = 'no' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_bounced,
    -- Outcome percentages
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY 
    CASE 
        WHEN pdays = -1 THEN 'Never Contacted Before'
        WHEN pdays <= 30 THEN 'Contacted Within Last 30 Days'
        ELSE 'Contacted Over 30 Days Ago'
    END
ORDER BY subscription_rate DESC;

--Q18 Analysing previous contact pattern for new leads vs existing customers and its effect on current campaign?
SELECT 
    CASE 
        WHEN previous = 0 THEN 'Brand New Lead (0 Past Contacts)'
        ELSE 'Historical Lead (1+ Past Contacts)'
    END AS customer_history,
    COUNT(*) AS total_customers,
    -- Average call length in minutes for successes vs rejections
    CAST(AVG(CASE WHEN deposit = 'yes' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_converted,
    CAST(AVG(CASE WHEN deposit = 'no' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_bounced,
    -- Outcome percentages
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY 
    CASE 
        WHEN previous = 0 THEN 'Brand New Lead (0 Past Contacts)'
        ELSE 'Historical Lead (1+ Past Contacts)'
    END
ORDER BY subscription_rate DESC;


--Q19 Analysing patterns in poutcome column and its outlook on current campaign?
SELECT 
    poutcome AS previous_outcome,
	CAST(ROUND(COUNT(CASE WHEN deposit = 'yes' THEN 1 END),2)  AS DECIMAL(10,0)) AS  total_yes,
	CAST(ROUND(COUNT(CASE WHEN deposit = 'no' THEN 1 END),2)  AS DECIMAL(10,0)) AS total_no,
    COUNT(*) AS total_customers,
    -- Average call length in minutes for successes vs rejections
    CAST(AVG(CASE WHEN deposit = 'yes' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_converted,
    CAST(AVG(CASE WHEN deposit = 'no' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_bounced,
    -- Outcome percentages
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY poutcome
ORDER BY subscription_rate DESC;


--Q20 Which age group should the marketing campaingn team focus on for term deposits?
SELECT 
    age_group,
    COUNT(*) AS total_customers,
    CAST(AVG(CASE WHEN deposit = 'yes' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_converted,
    CAST(AVG(CASE WHEN deposit = 'no' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_bounced,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY age_group
ORDER BY subscription_rate DESC;


--20_ Total Campaign Hours Spent by Age Group
SELECT 
    age_group,
    COUNT(*) AS total_customers,

    -- Conversion rate for baseline context
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
	    -- Bounce rate for baseline context
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate,

	    -- Total Hours Spent across all calls (Converted vs Bounced combined)
    CAST(SUM(duration_min) / 60.0 AS DECIMAL(10,1)) AS total_call_hours_spent,

	 -- Percentage of total campaign labor time consumed
    CAST(ROUND(100.0 * SUM(duration_min) / SUM(SUM(duration_min)) OVER(), 2) AS DECIMAL(10,2)) AS pct_of_talk_time,
    
    -- Breakdowns of hours spent on successes vs rejections
    CAST(SUM(CASE WHEN deposit = 'yes' THEN duration_min ELSE 0 END) / 60.0 AS DECIMAL(10,1)) AS hours_spent_converted,
    CAST(SUM(CASE WHEN deposit = 'no' THEN duration_min ELSE 0 END) / 60.0 AS DECIMAL(10,1)) AS hours_spent_bounced

FROM fact_marketing_campaign
GROUP BY age_group
ORDER BY subscription_rate DESC;


--Q21 Contact frequency analysis (campaign).
SELECT 
    CASE 
        WHEN campaign = 1 THEN '1 Contact'
        WHEN campaign = 2 THEN '2 Contacts'
        WHEN campaign = 3 THEN '3 Contacts'
        WHEN campaign <= 5 THEN '4-5 Contacts'
        ELSE '6+ Contacts (Diminishing Returns)'
    END AS contact_frequency_bucket,
    COUNT(*) AS total_customers,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate    
FROM fact_marketing_campaign
GROUP BY 
    CASE 
        WHEN campaign = 1 THEN '1 Contact'
        WHEN campaign = 2 THEN '2 Contacts'
        WHEN campaign = 3 THEN '3 Contacts'
        WHEN campaign <= 5 THEN '4-5 Contacts'
        ELSE '6+ Contacts (Diminishing Returns)'
    END
ORDER BY MIN(campaign);

--Q22 What months performed better with conversion/customer subscription to term deposit
SELECT 
    month_number,
    COUNT(*) AS total_customers,
    -- Average call length in minutes for successes vs rejections
    CAST(AVG(CASE WHEN deposit = 'yes' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_converted,
    CAST(AVG(CASE WHEN deposit = 'no' THEN duration_min END) AS DECIMAL(10,2)) AS avg_min_bounced,
    -- Outcome percentages
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
    CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate
FROM fact_marketing_campaign
GROUP BY month_number
ORDER BY month_number ASC;


	--___________________________________________
	-- Debt Trap Cross-Analysis (Housing Loan vs. Personal Loan)
	--Q23 How is debth profile affecting conversion rate and subscription to term deposit?
	SELECT 
		CASE 
			WHEN housing = 'yes' AND loan = 'yes' THEN 'Double Debt (Housing + Personal)'
			WHEN housing = 'yes' AND loan = 'no' THEN 'Housing Mortgage Only'
			WHEN housing = 'no' AND loan = 'yes' THEN 'Personal Loan Only'
			ELSE 'Debt-Free Customer'
		END AS debt_profile,
		COUNT(*) AS total_customers,
		CAST(AVG(duration_min) AS DECIMAL(10,2)) AS avg_call_duration_min,
		CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate,
		CAST(ROUND(100.0 * SUM(CASE WHEN deposit='no' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS bounce_rate
	FROM fact_marketing_campaign
	GROUP BY 
		CASE 
			WHEN housing = 'yes' AND loan = 'yes' THEN 'Double Debt (Housing + Personal)'
			WHEN housing = 'yes' AND loan = 'no' THEN 'Housing Mortgage Only'
			WHEN housing = 'no' AND loan = 'yes' THEN 'Personal Loan Only'
			ELSE 'Debt-Free Customer'
		END
	ORDER BY subscription_rate DESC;

--______________________________________
-- Analyzing "Call" Threshold (Contact Channel vs. Campaign Frequency)
--Q24 Which contact channel and call threshold performed better
	SELECT 
		contact AS contact_channel,
		CASE 
			WHEN campaign = 1 THEN '1 Call'
			WHEN campaign <= 3 THEN '2-3 Calls'
			ELSE '4+ Calls (High Fatigue)'
		END AS call_frequency,
		COUNT(*) AS total_customers,
		CAST(ROUND(100.0 * SUM(CASE WHEN deposit='yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS DECIMAL(10,2)) AS subscription_rate
	FROM fact_marketing_campaign
	GROUP BY 
		contact,
		CASE 
			WHEN campaign = 1 THEN '1 Call'
			WHEN campaign <= 3 THEN '2-3 Calls'
			ELSE '4+ Calls (High Fatigue)'
		END
	ORDER BY contact_channel, MIN(campaign);


-- 25 Investigating unknown data points
SELECT 
    COUNT(CASE WHEN education = 'unknown' THEN 1 END) AS unknown_edu,
	COUNT(CASE WHEN education = 'unknown' AND deposit = 'yes' THEN 1 END) AS unknown_edu_subscribers,
    COUNT(CASE WHEN job = 'unknown' THEN 1 END) AS unknown_job,
	COUNT(CASE WHEN job = 'unknown' AND deposit = 'yes' THEN 1 END) AS unknown_job_subscribers,
    COUNT(CASE WHEN contact = 'unknown' THEN 1 END) AS unknown_contact,
	  COUNT(CASE WHEN contact = 'unknown' AND deposit = 'yes' THEN 1 END) AS unknown_contact_subscribers,
    COUNT(CASE WHEN poutcome = 'unknown' THEN 1 END) AS poutcome,
	COUNT(CASE WHEN poutcome = 'unknown' AND deposit = 'yes' THEN 1 END) AS poutcome_subscribers
FROM fact_marketing_campaign;
