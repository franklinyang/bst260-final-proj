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

## Takeaways

### Postoperative Complications vs. Total Spending
![Nationwide Complications](/images/complications.png) ![MA Complications](/images/complications_ma.png)
* All else being equal, a hospital in a state with a healthcare policy focus with an average IP spend per claim of $11,500 has a postoperative complications score 14.5% higher than a hospital that spends $2k per claim less (14.2% in non-healthcare policy focused states).
* We noted that a states who have Medicare Expansion programs do not necessarily have better outcomes. This relationship is not causal -- because Medicare is a federally run program we can only infer that Medicare outcomes and spending are insensitive to state-level policy making differences; however, it's possible that accounting for regional socioeconomic/demographic differences may drive different insights.

### Hospital Staff Responsiveness vs. Total Spending
![Responsiveness by Emergency Y/N](/images/responsiveness_emergency.png) ![Responsiveness by Density](/images/responsiveness_density.png) ![MA Responsiveness](/images/responsiveness_ma.png)

* All else being equal, a hospital with an average total spend per claim of $11,500 has a Responsiveness of Hospital Staff score 15.1% lower than a hospital that spends $2k per claim less.
* On average, a hospital in a county with a given hospital density per capita (100,000 residents) had a responsiveness score that was 0.93 points higher than a hospital in a county with one less hospital per capita (100,000 residents). This makes intuitive sense, because the more hospitals serving a population, the faster the service.
* On average, a hospital with emergency services had a responsiveness score that was 1.97 points lower than a hospital without emergency services. This is likely because of the long lines that result from emergency care. There are two contributing factors: 1) patients who seek non-emergency care may be deprioritized compared to emergency cases, and 2) patients who need emergency care are likely to be more disgruntled about any delay and may tend to score a hospital’s responsiveness lower.

<iframe id="shiny-app" src=" https://franklinyang.shinyapps.io/bst260-final-proj/" style="border: none; width: 100%; height: 850px" frameborder="0"></iframe>
