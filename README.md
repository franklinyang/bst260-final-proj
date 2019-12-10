# Quality vs Quantity: A Medicare Story
## Rachel Ketchum, Genevieve Lyons, Franklin Yang


### Background

As the US is making greater strides towards a value based care system, it will become critical to understand the relationship between better outcomes and cost efficiency. When compared to other similar countries, the [US currently spends far more and has worse health outcomes](http://www.oecd.org/els/health-systems/Health-at-a-Glance-2013.pdf).

![Health Outcomes](/images/OECD US Health Outcomes.png)

The current US healthcare system operates under a fee-for-service payment scheme, which encourages a "quantity over quality" approach to healthcare. When a hospital's payment depends on how *many* services they can provide and not the *value* of those services, the focus of care shifts from a patient-centric experience to a payment-centric experience. 

Using Medicare as a paradigm, we have examined the relationship between spending, outcomes, and other extrinsic driving factors of quality within states and hospitals. Furthermore, we have attempted to investigate the relationship between a state's healthcare policymaking behavior and their Medicare outcomes.

### File Structure and Results

* The main results of our analysis, including the screencast, is available in our [website](https://franklinyang.github.io/bst260-final-proj/).
* The `data` folder contains all raw data, which has been aggregated and analyzed from [CMS Hospital Compare Datasets](https://data.medicare.gov/data/hospital-compare) and the [US Census Bureau](https://www.census.gov/data.html).
* The `database` folder contains the SQLite database used to manage, aggregate, and analyze the data.
* The `images` folder contains images used in the website.
* The `code` folder contains all code used to load, wrangle, and analyze the data. These files must be run sequentially:
1) `01_loader.Rmd` creates the SQLite database and loads the data in our relational file structure.
2) `02_Regression_Master_Table_Build.R` combines and wrangles the data into a usable format for analysis.
3) `03_Analysis_and_Interpretation.Rmd` and `03_Analysis_and_Interpretation.html` contain the results and main takeaways of our analyses.
4) `app.R` contains an interactive tool to compare state-level quality and spending metrics. 