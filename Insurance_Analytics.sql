SELECT * FROM insurance_analytics.customers;
use insurance_analytics;
select * 
from customers;

-- KPI Question 1 to 5

-- KPI Q.1 Total number of customers available in the policy database
select count(*) as Total_Customers
from customers;

-- KPI Q.2 Total number of policies issued?
select count(*) as Total_Policy
from policy;

-- KPI Q.3 What is the total claim amount generated from all policies?
Select concat(round(sum(`Claim Amount`) / 1000000,2),' M')  as Total_claim
from Claims;

-- KPI Q.4 Average coverage amount per policy?
Select concat(round(avg(`Coverage Amount`) / 1000,2), ' K') as Avg_Coverage_amt
from policy;

-- KPI Q.5 Average premium amount collected per policy?
Select concat(round(avg(`Premium Amount`) / 1000,2), ' K') as Avg_Premium_amt
from policy;

-- KPI Q.6 Percentage of policies are currently active?
Select concat(round(Count(*)/5000 * 100,2), '%') as Active_Policy_Percentage
from policy
where status="active";

-- KPI Q.6 Percentage of policies are currently Inactive?
Select concat(round(Count(*)/5000 * 100,2), '%') as Inactive_Policy_Percentage
from policy
where status!="active";

-- KPI Q.7 Policies are in active, lapsed, and terminated status?
Select status, count(*) as policy_count
from policy
group by status;

-- KPI Q.8  Which policy status has the highest number of policies?
Select max(policy_count) as max_policy_count
from (
Select status, count(*) as policy_count
from policy
group by status) as Policy_summary;

Select status, count(*) as policy_count
from policy
group by status
order by policy_count Desc
Limit 1;

-- KPI Q.9  Ratio between active policies and inactive policies?
Select
round(sum(Case when Status = 'Active'
Then 1 else 0 End) / sum(Case when Status != 'Active'
                          Then 1 else 0 End),2) as Active_inactive_ratio
From policy;

-- KPI Q.10  Which age group has the highest number of policies?
Select c.`Age Group`,count(distinct p.`Policy ID`) as Age_policy_count
from customers c JOIN Policy p 
on c.`Customer ID` = p.`Customer ID`
group by c.`Age Group`
order by Age_policy_count desc
limit 1;

-- KPI Q.11  Top three age groups by policy count ?
Select c.`Age Group`,count(distinct p.`Policy ID`) as Age_policy_count
from customers c JOIN Policy p 
on c.`Customer ID` = p.`Customer ID`
group by c.`Age Group`
order by Age_policy_count desc
limit 3;

-- KPI Q.12 Which gender type has the highest number of policies?
Select c.Gender,count(distinct p.`Policy ID`) as Gender_policy_count
from customers c join policy p
on c.`Customer ID` =p.`Customer ID`
group by gender
order by Gender_policy_count desc
limit 1;

-- KPI Q.13 Difference between male and female policy counts ?
Select
ABS(
sum(case when c.Gender="Male"
then 1 else 0 End) - Sum(case when c.Gender="Female"
                               then 1 else 0 End)) as Male_Female_Difference
from customers c join policy p
on c.`Customer ID`=p.`Customer ID`;

-- KPI Q.14 Which policy type has the maximum number of policies
Select `Policy Type`,count(distinct `Policy ID`) as policy_count
from policy
Group by `Policy Type`
order by policy_count desc
limit 1;

-- KPI Q.16 Compare Auto and Health policy counts 
Select
(
sum(case when `Policy Type`="Auto"
then 1 else 0 end)/sum(case when `Policy Type`="Health"
					  then 1 else 0 end)) as AutoVSHealth
from policy;

-- alternate way

Select `Policy Type`,count(distinct `Policy ID`) as Policy_count
from policy
where `Policy Type` in ("Auto","Health")
Group by `Policy Type`;

-- KPI Q.17 Total number of policies across all policy types 
Select count(distinct`Policy ID`) as Policy_Count
from policy;

-- KPI Q.18 Average premium growth rate over all years  
With 
YearlyPremium as ( Select `Policy Start Date (Year)`,sum(`Premium Amount`) as TotalPremium
from policy
Group by `Policy Start Date (Year)`),
GrowthRate as ( select `Policy Start Date (Year)`, TotalPremium,
              lag(TotalPremium) over (order by `Policy Start Date (Year)`) as PreviousPremium
			  From YearlyPremium)
Select `Policy Start Date (Year)`,Round(( TotalPremium - PreviousPremium ) * 100.0 / nullif(PreviousPremium,0),2) as YOY_GrowthRate
from GrowthRate
where PreviousPremium is not null
Order by `Policy Start Date (Year)`;

-- KPI Q.18 Is the premium growth trend increasing or decreasing ? 
With 
YearlyPremium as ( Select `Policy Start Date (Year)`,sum(`Premium Amount`) as TotalPremium
from policy
Group by `Policy Start Date (Year)`),
GrowthRate as ( select `Policy Start Date (Year)`, TotalPremium,
              lag(TotalPremium) over (order by `Policy Start Date (Year)`) as PreviousPremium
			  From YearlyPremium),
YOY_GrowthRate as (Select `Policy Start Date (Year)`,Round(( TotalPremium - PreviousPremium ) * 100.0 / nullif(PreviousPremium,0),2) as Current_growth_rate
from GrowthRate),
Trend as (
         Select `Policy Start Date (Year)`,Current_growth_rate,lag(Current_growth_rate) over(order by `Policy Start Date (Year)`) as previous_growth_rate
         from YOY_GrowthRate
         )
Select `Policy Start Date (Year)`,Current_growth_rate,previous_growth_rate,
Case
    when Current_growth_rate > previous_growth_rate then 'Increasing'
    when Current_growth_rate < previous_growth_rate then 'Decreasing'
    when Current_growth_rate = previous_growth_rate then 'Stable'
    Else 'Insufficient Data'
    End as premium_growth_trend
from Trend
Order by `Policy Start Date (Year)`;

-- 20 Difference between the highest and lowest premium growth rates --

WIth YearlyPremium as 
(select `Policy Start Date (Year)` as PolicyYear,
sum(`Premium Amount`) as  totalpremium
from policy
group by PolicyYear
),
GrowthRate as 
(select PolicyYear, totalpremium,
lag(totalpremium) over (order by PolicyYear) as Previouspremium
from YearlyPremium
),
YOY_Growthrate as
(select PolicyYear,
round((totalpremium - Previouspremium)*100.0 / nullif(Previouspremium,0),2) as YOYGrowth
from GrowthRate
),
Max_YOYGrowthRate as
(select max(YOYGrowth) as MAX_YOY
from YOY_Growthrate
where YOYGrowth < (select max(YOYGrowth)
                  from YOY_Growthrate)
)
Select round(
             (Select MAX_YOY from Max_YOYGrowthRate) - min(YOYGrowth),2) as 'max-min difference'
From YOY_Growthrate;

-- 21 What is the yearly trend of policies ending from 2016 to 2034 ----

SELECT `Policy End Date(Year)` AS ending_year,
COUNT(DISTINCT `Policy ID`) AS policies_ending
FROM policy
WHERE `Policy End Date(Year)` BETWEEN 2016 AND 2034
GROUP BY `Policy End Date(Year)`
ORDER BY `Policy End Date(Year)`;