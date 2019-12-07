## Background 

As the US is making greater strides towards a value based care system, it will become critical to understand the relationship between better outcomes and cost efficiency. When compared to other similar countries, the [US currently spends far more and has worse health outcomes](http://www.oecd.org/els/health-systems/Health-at-a-Glance-2013.pdf).

![Health Outcomes](/images/OECD US Health Outcomes.png)

The current US healthcare system operates under a fee-for-service payment scheme, which encourages a "quantity over quality" approach to healthcare. When a hospital's payment depends on how *many* services they can provide and not the *value* of those services, the focus of care shifts from a patient-centric experience to a payment-centric experience. 

Using Medicare as a paradigm, we have examined the relationship between spending, outcomes, and other extrinsic driving factors of quality within states and hospitals. Furthermore, we have attempted to investigate the relationship between a state's healthcare policymaking behavior and their Medicare outcomes

## Purpose

The purpose of this project is to understand:
1. General trends in Medicare spending and outcomes by state
2. The association between costs and outcomes across individual hospitals.
3. The relationship between healthcare policy focused states and outcomes.

## Data Collection and Data Analysis Methodologies

### Data Collection and Cleaning process

The Center for Medicare and Medicaid Services (CMS) publishes costs and outcomes datasets each year. These datasets are structured as CSV files. The team ingested these CSV files into a SQL database and, in the process, set appropriate column names and definitions in the database schema. All analyses conducted were done using a denormalized analysis table that was created.

![Data Map](/images/Data Map.jpeg)

### Data Analysis Methodologies

The analyses to follow dig into the relationship between two outcome measures (Postoperative Complications and Responsiveness of Hospital Staff) and Costs. Outcome measures were selected by plotting different outcome measures against cost, and attempting to dig into measures with interesting linear or non-linear relationships. For each outcome measure, we do regressions, confidence interval estimates, segment by covariates, and visualize.
