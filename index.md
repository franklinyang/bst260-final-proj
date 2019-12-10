# Quality vs Quantity: A Medicare Story
### Rachel Ketchum, Genevieve Lyons, Franklin Yang

## Background 

As the US is making greater strides towards a value based care system, it will become critical to understand the relationship between better outcomes and cost efficiency. When compared to other similar countries, the [US currently spends far more and has worse health outcomes](http://www.oecd.org/els/health-systems/Health-at-a-Glance-2013.pdf).

![Health Outcomes](/images/OECD US Health Outcomes.png)

The current US healthcare system operates under a fee-for-service payment scheme, which encourages a "quantity over quality" approach to healthcare. When a hospital's payment depends on how *many* services they can provide and not the *value* of those services, the focus of care shifts from a patient-centric experience to a payment-centric experience. 

Using Medicare as a paradigm, we have examined the relationship between spending, outcomes, and other extrinsic driving factors of quality within states and hospitals. Furthermore, we have attempted to investigate the relationship between a state's healthcare policymaking behavior and their Medicare outcomes.

## Purpose

The purpose of this project is to understand:
1. General trends in Medicare spending and outcomes by state
2. The association between costs and outcomes across individual hospitals.
3. The relationship between healthcare policy focused states and outcomes.

## Data Collection and Cleaning Process

### Key Data Sources: 

The Center for Medicare and Medicaid Services (CMS) publishes costs and outcomes datasets related to Medicare claims at acute care hospitals each year in the [CMS Hospital Compare Datasets](https://data.medicare.gov/data/hospital-compare). These datasets are structured as CSV files.

The [US Census Bureau](https://www.census.gov/data.html) publishes data related to socio-economic factors by county. 

Medicaid Expansion has been used as in Instrumental Variable to model states that prioritize healthcare in their policymaking. 

All data was ingested into a SQLite relational database and then combined. All analyses conducted were done using a denormalized analysis table that was created. 

### Key Data Elements and Data Documentation

Data Elements Collected at the Hospital Level:

* [Postoperative Complications Score](https://data.medicare.gov/Hospital-Compare/Complications-and-Deaths-Hospital/ynj2-r877) - Complications and deaths scores for Medicare hospital claims, including only complications and deaths that occurred postoperatively.
* [Patient Experience Measure: Responsiveness of Hospital Staff](https://data.medicare.gov/Hospital-Compare/Hospital-Value-Based-Purchasing-HVBP-Patient-Exper/avtz-f2ge) - Patient Experience of Care Domain Scores for Responsiveness of Hospital Staff (Hospital Value-Based Purchasing Program)
* [Inpatient and Total Spend per Claim](https://data.medicare.gov/Hospital-Compare/Medicare-Hospital-Spending-by-Claim/nrth-mfg3) - average spending levels during hospitals’ Medicare Spending per Beneficiary (MSPB) episodes for inpatient and all claims (respectively). These represent price-standardized, non-risk-adjusted values. An MSPB episode includes all Medicare Part A and Part B claims paid during the period from 3 days prior to an inpatient hospital admission through 30 days after discharge. 
* [Hospital Ownership](https://data.medicare.gov/Hospital-Compare/Hospital-General-Information/xubh-q36u) - Hospital ownership, such as Proprietary, Voluntary Non-Profit - Private, Government - Local, etc.
* Hospital Density per 100,000 Residents - Calculated as the number of hospitals in the county per 100,000 residents in that county.
* [Emergency Services](https://data.medicare.gov/Hospital-Compare/Hospital-General-Information/xubh-q36u) - Indicates presence of emergency services at a hospital.
* [Meets Criteria for Meaningful Use of EHRs](https://data.medicare.gov/Hospital-Compare/Hospital-General-Information/xubh-q36u) - Indicates if is using certified EHR technology in a [meaningful manner to improve care](https://www.cdc.gov/ehrmeaningfuluse/introduction.html).

Data Elements Collected at the County Level:

* Income Category - Median household income in the county. Defined as < \$46,000, \$46,000 - \$53,000, \$53,000 - \$62,500, and > \$62,500
* Population - Population of the county.
* Region - Northeast, North Central, South, and West
* Percent Uninsured - Calculated as the population without health insurance in the county divided by the population in the county.

Data Elements Collected at the State Level:

* Healthcare policy focused state - Medicaid Expansion has been used as in Instrumental Variable to model states that prioritize healthcare in their policymaking.


![Data Map](/images/Data_Map.jpeg)

## Data Analysis Methodologies

Using this tool, it is easy to dig into the relationship between  outcome measures and costs:

<iframe id="shiny-app" src="https://franklinyang.shinyapps.io/code/" style="border: none; width: 100%; height: 850px" frameborder="0"></iframe>

The analyses to follow dig into the relationship between two outcome measures (Postoperative Complications and Responsiveness of Hospital Staff) and Costs. For each outcome measure, we do regressions, confidence interval estimates, segment by covariates, and visualize.

## Takeaways

### Postoperative Complications vs. Total Spending

We analyzed the relationship between hospitals' postoperative complications in the inpatient setting, such as "Blood stream infection after surgery" and inpatient spending per claim. We used a linear least squares regression with a quadratic transformation on inpatient spending per claim to model this relationship. We adjusted for other significant factors, including hospital ownership (e.g., "Government - Federal" and "Government - Local"), whether the hospital offers emergency services, whether the hospital meets the criteria for for meaningful use of EHRs, the number of hospitals per capita in the surrounding county, socioeconomic factors of the surrounding county including median income, population, and the percentage of residents without health insurance, region, and whether the state is a "healthcare policy focused state" (i.e., Medicaid Expansion Instrumental Variable).

The regression results are:
![Postoperative Regression Results](/images/regression_results_postoperative complications.png)

![Nationwide Complications](/images/complications.png) ![MA Complications](/images/complications_ma.png)



### Hospital Staff Responsiveness vs. Total Spending
![Responsiveness by Emergency Y/N](/images/responsiveness_emergency.png) ![Responsiveness by Density](/images/responsiveness_density.png) ![MA Responsiveness](/images/responsiveness_ma.png)

* All else being equal, a hospital with an average total spend per claim of $11,500 has a Responsiveness of Hospital Staff score 15.1% lower than a hospital that spends $2k per claim less.
* On average, a hospital in a county with a given hospital density per capita (100,000 residents) had a responsiveness score that was 0.93 points higher than a hospital in a county with one less hospital per capita (100,000 residents). This makes intuitive sense, because the more hospitals serving a population, the faster the service.
* On average, a hospital with emergency services had a responsiveness score that was 1.97 points lower than a hospital without emergency services. This is likely because of the long lines that result from emergency care. There are two contributing factors: 1) patients who seek non-emergency care may be deprioritized compared to emergency cases, and 2) patients who need emergency care are likely to be more disgruntled about any delay and may tend to score a hospital’s responsiveness lower.
