# SQLCustomerChurnAnalysis
- This project uses SQL to explore customer churn behaviour in a subscription-based SaaS business. It includes structured queries to uncover churn patterns, retention drivers, pricing strategy, and upselling opportunities. This helps inform product, marketing, and retention strategies.

## Dataset
- This project uses a mock Saas Telco Customer Churn dataset:
https://www.kaggle.com/datasets/blastchar/telco-customer-churn

## Objectives
- Identify churn risk by service type, contract, and customer behaviour
- Calculate retention and lifetime value (LTV) metrics
- Analyse upsell conversion potential by segment
- Evaluate ROI of potential retention campaigns

## Key Insights
- **Churn Risk** is significantly higher among month-to-month contract users and fiber optic internet subscribers.
- **Tech Support** availability reduces churn, making it a potential retention driver.
- **Lifetime Value LTV** is highest for customers on annual contracts.
- **Bundled Services** increase average revenue per user (ARPU) and could be a target for upsell opportunities.
- **Gender-based Upsell Analysis** shows variation in the adoption of security and backup services.

## Business Recommendations
- Target upsell offers to users without security or backup services.
- Promote bundled packages to drive ARPU.
- Prioritise onboarding campaigns for new users (0-6 months).

## Tools Used
- SQL: MYSQL for data extraction and analysis
- Tableau: Visualisation
- Business Concepts: LTV, ARPU, churn, retention, funnel, ROI, UCR
