-- Create SaaS analytics database
create database saas;
use saas;

-- Customer profile table
CREATE TABLE customers (
    customerid VARCHAR(20) PRIMARY KEY,
    gender VARCHAR(20),
    seniorcitizen VARCHAR(3),
    tenure INT,
    churn VARCHAR(3)
);

-- Billing and contract information
CREATE TABLE billing (
    customerid VARCHAR(20),
    contract VARCHAR(20),
    paperlessbilling VARCHAR(3),
    paymentmethod VARCHAR(20),
    monthlycharges DECIMAL(10 , 2 ),
    totalcharges DECIMAL(10 , 2 ),
    FOREIGN KEY (customerid)
        REFERENCES customers (customerid)
);
alter table billing
add primary key (customerid);
alter table billing
modify column paymentmethod varchar(50);

-- Subscribed service details
CREATE TABLE services (
    customerid VARCHAR(20),
    internetservice VARCHAR(20),
    onlinesecurity VARCHAR(20),
    onlinebackup VARCHAR(20),
    deviceprotection VARCHAR(20),
    techsupport VARCHAR(20),
    streamingtv VARCHAR(20),
    streamingmovies VARCHAR(20),
    phoneservice VARCHAR(3),
    multiplelines VARCHAR(20),
    FOREIGN KEY (customerid)
        REFERENCES customers (customerid)
);
alter table services
add primary key (customerid);

-- Which internet services are linked to higher churn, and what does
-- that tells us about product quality or retention risk?
-- Identify whether customers using certain internet service types are more likely to churn.
-- Insights may inform product development, pricing strategy,
-- or retention campaigns focused on high-risk segments
SELECT 
    s.internetservice, COUNT(c.churn) AS churn
FROM
    services AS s
        JOIN
    customers AS c ON s.customerid = c.customerid
WHERE
    c.churn = 'Yes'
        AND s.internetservice <> 'No'
GROUP BY s.internetservice;

-- Are flexible contract customers at higher churn risk, and should
-- We focus on converting them to longer-term plans?
-- Analyze churn behavior by contract type to support a retention strategy that
-- incentivizes customers to switch to longer-term contracts.
-- This also supports ROI evaluation of contract upgrade campaigns
SELECT 
    b.contract, COUNT(c.churn) AS churn
FROM
    customers AS c
        JOIN
    billing AS b ON b.customerid = c.customerid
WHERE
    churn = 'Yes'
GROUP BY b.contract
ORDER BY churn DESC;

-- Does offering tech support reduce churn, and should it be positioned as a retention driver?
-- Test whether customers with tech support are less likely to churn
with customercount as (
select count(customerid) as customers, techsupport
from services
group by techsupport),

churnservice as (
select s.techsupport, count(c.customerid) as churn
from customers as c
join services as s
on s.customerid = c.customerid
where churn = 'Yes'
group by s.techsupport)

select round(cast(cs.churn as float)/cc.customers, 2) as churnratio, cs.techsupport
from churnservice as cs
join customercount as cc
on cc.techsupport = cs.techsupport
order by churnratio desc;

-- retention rate = 1-churn rate
-- How does churn rate vary across customer tenure brackets?
-- Detect lifecycle churn patterns (e.g., early churn) to inform
-- onboarding, engagement, or loyalty campaigns
with churnandtenure as(
select
case when tenure <= 6 then '0-6m'
when tenure <= 12 then '6-12m'
when tenure <=24 then '12-24m'
when tenure >24 then '24+m'
end as tenurebuckets,
sum(case when churn = 'Yes' then 1
when churn = 'No' then 0 end) as churnedcustomers,
count(customerid) as totalcustomers
from customers
group by tenurebuckets)

select *, round((1-churnedcustomers/totalcustomers),2) as retentionrate
from churnandtenure
order by retentionrate desc;

-- What are the month-over-month retention trends?
-- How can we visualize churn risk over time?
-- Provide Tableau-ready data showing retention over tenure
with churntenure as (
select tenure,
sum(case when churn = 'Yes' then 1
when churn = 'No' then 0 end) as churnedcustomers,
count(customerid) as totalcustomers
from customers
group by tenure)

select *, round((1-churnedcustomers/totalcustomers),2) as retentionrate
from churntenure
order by tenure;

-- LTV = how much the customer pays before they leave
-- Do customers on fiber internet have higher LTV?
-- Identify services that lead to more profitable customer lifecycles
SELECT 
    ROUND(AVG(b.monthlycharges * c.tenure), 2) AS ltv,
    s.internetservice
FROM
    billing AS b
        JOIN
    customers AS c ON c.customerid = b.customerid
        JOIN
    services AS s ON s.customerid = b.customerid
GROUP BY s.internetservice
HAVING s.internetservice <> 'No'
ORDER BY ltv DESC;

-- Which contract types lead to the highest LTV?
-- Should marketing focus on driving customers to specific packages?
SELECT 
    ROUND(AVG(b.monthlycharges * c.tenure), 2) AS ltv,
    b.contract
FROM
    billing AS b
        JOIN
    customers AS c ON b.customerid = c.customerid
GROUP BY b.contract
ORDER BY ltv DESC;


-- Are customers paying higher monthly fees more likely to churn?
-- Should pricing tiers be adjusted to improve retention?
-- Evaluate price sensitivity: create a query calculating churn rate by price range (monthly charges)
SELECT 
    AVG(monthlycharges),
    MIN(monthlycharges),
    MAX(monthlycharges)
FROM
    billing;

SELECT 
    COUNT(*) AS churn,
    CASE
        WHEN monthlycharges <= 51 THEN '£18-£51'
        WHEN monthlycharges <= 85 THEN '£52-£85'
        ELSE '£86+'
    END AS price_range
FROM
    billing AS b
        JOIN
    customers AS c ON c.customerid = b.customerid
WHERE
    c.churn = 'Yes'
GROUP BY price_range
ORDER BY churn DESC;

-- Does bundling streaming services significantly increase Average Revenue per User (ARPU)?
-- Can we justify bundle-focused pricing strategies?
SELECT 
    ROUND(SUM(b.totalcharges) / COUNT(DISTINCT b.customerid),
            2) AS ARPU,
    CASE
        WHEN
            s.streamingmovies = 'Yes'
                AND s.streamingtv = 'Yes'
        THEN
            'bundle'
        ELSE 'not bundle'
    END AS bundletype
FROM
    billing AS b
        JOIN
    services AS s ON s.customerid = b.customerid
GROUP BY bundletype
ORDER BY ARPU DESC;


-- Which customer segments are most responsive to upsells
-- like online security and backup services?
-- Analyse a gender-based Upsell Conversion Rate (UCR) to identify upsell targeting.
with converted as(
select c.gender, count(*) as convertcust
from services as s
join customers as c
on c.customerid = s.customerid
where onlinesecurity = 'Yes'
and onlinebackup = 'Yes'
group by c.gender),

total as (
select c.gender, count(*) as totalcust
from services as s
join customers as c
on c.customerid = s.customerid
group by c.gender)

select round((c.convertcust*100/ t.totalcust), 2) as UCR, c.gender
from converted as c
join total as t
on c.gender = t.gender
group by c.gender;

-- How large is the untapped upsell market for online security and backup services?
SELECT 
    c.gender, COUNT(*) AS upsell
FROM
    services AS s
        JOIN
    customers AS c ON c.customerid = s.customerid
WHERE
    onlinesecurity = 'No'
        AND onlinebackup = 'No'
GROUP BY c.gender;


-- Is it financially beneficial to convert month-to-month customers
-- into 1-year contracts?
-- What’s the expected ROI?
-- Compare LTV uplift to cost of conversion incentive

with oneyear as(
select b.contract, round(avg(b.totalcharges),2) as avgcharge
from billing as b
join customers as c
on c.customerid = b.customerid
where b.contract = 'One year'
and c.churn = 'No'
group by b.contract
order by avgcharge desc),

monthtomonth as (
select b.contract, round(avg(b.totalcharges),2) as avgcharge
from billing as b
join customers as c
on c.customerid = b.customerid
where b.contract = 'Month-to-month'
and c.churn = 'No'
group by b.contract
order by avgcharge desc)

select oneyear.avgcharge as oneyr_avgcharge,
monthtomonth.avgcharge as mtom_avgcharge,
(oneyear.avgcharge - monthtomonth.avgcharge) as gainpercustomer,
50 as assumedconversioncost,
round(((oneyear.avgcharge - monthtomonth.avgcharge)-50)/50, 2) as roi
from oneyear, monthtomonth;


-- Where are users dropping off in their journey from basic to premium service adoption,
-- and how does this relate to churn?
-- Build a multi-step funnel to detect common churn paths
with customerservice as (
select s.customerid
from services as s
where s.phoneservice = 'Yes'
and s.internetservice <> 'No'),

secur as (
select cs.customerid
from customerservice as cs
join services as s
on cs.customerid = s.customerid
where s.techsupport = 'No'),

addon as (
select sec.customerid
from secur as sec
join services as ser
on sec.customerid = ser.customerid
where ser.streamingmovies = 'No'
and ser.streamingtv = 'No'),

churn as (
select ao.customerid
from addon as ao
join customers as c
on ao.customerid = c.customerid
where c.churn = 'Yes')

select '1: phone and internet' as step, count(*) as countcustomers from customerservice
union all
select '2: + no tech support' as step, count(*) as s from secur
union all
select '3: + no streaming' as step, count(*) as ao from addon
union all
select '4: + churned' as step, count(*) as ch from churn;
