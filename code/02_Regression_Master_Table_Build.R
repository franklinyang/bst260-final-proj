#########################
# Create Hospital Level Regression Master Table
# Created by: Genevieve Lyons
# Created date: 11/19/2019
# Goal: Create a Hospital-Level Master Table, limited to Acute Care Hospitals containing the following variables:
    #Facility ID
    #County
    #Hospital Type
    #All variables from hospital_info
    #avg spend per claim: total, ip_spend, op_spend
    #Patient experience scores: Total Patient Experience Score and Responsiveness of hospital staff
    #Deaths and Complications: Any death/complication, patient-level death/complication, post-surgical (hospital-level) death/complication
    #Healthcare Policy Focus (IV: Medicaid Expansion)
    #Census Data: median income, mean income, estimated income with social security, with retirement income, mean retirement income, per capita income, health insurance coverage, % below poverty line 
    #Hospital density in the county (# hospitals in county; # hospitals per capita in the county)
    #Region (northeast, northwest, south, etc.)
# NOTE: Exclude HAC's for now.
# NOTE: Do not have # beds per hospital at the moment, but could be informative.
#########################


###########
#Load libraries and Connect to DB
###########

rm(list=ls())
library(DBI)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(ggthemes)
library(openintro)

#setwd("/Users/genevievelyons/Intro to DS/bst260-final-proj/code")
con <- dbConnect(RSQLite::SQLite(), "../database/db.sqlite")
dbListTables(con)

####################
####################
# Hospital Level Regression Table Build
####################
####################

####################
#Pull Hospital Info & Spending Data
####################

#Pull Hospital Info and Spending from DB
#Note: limiting to Acute Care Hospitals due to data availability
hospital_info <- dbFetch(dbSendQuery(con, 
                                     "SELECT A.*, 
                                B.Claim_Type,
                                B.Period,
                                B.Avg_Spending_Per_Episode_Hospital 
                          FROM hospital_info a 
                          left join spending_by_claim b 
                                on a.facility_id = b.facility_id
                                and b.Claim_Type in('Total','Outpatient','Inpatient')
                          WHERE Hospital_Type = 'Acute Care Hospitals' and a.facility_id is not null"))
    #QC:
    #View(hospital_info)
    #hospital_info %>% filter(Facility_ID =="100183") %>% arrange(Claim_Type) %>% View()

#Calculate average outpatient, inpatient, and total spending
hospital_info <- hospital_info %>% 
  group_by(Facility_ID) %>% 
  #sum up ip/op/total spend
  mutate(ip_spend = na_if(sum(case_when(Claim_Type == "Inpatient" ~ Avg_Spending_Per_Episode_Hospital, TRUE ~ 0)),0),
         op_spend = na_if(sum(case_when(Claim_Type == "Outpatient" ~ Avg_Spending_Per_Episode_Hospital, TRUE ~ 0)),0),
         total_spend = na_if(sum(case_when(Claim_Type == "Total" ~ Avg_Spending_Per_Episode_Hospital, TRUE ~ 0)),0)) %>%
  #only pull relevant columns
  select(Facility_ID:Location, ip_spend, op_spend, total_spend) %>%
  #exclude footnote columns
  select(-ends_with("footnote")) %>% 
  distinct()

    #QC Example
    #hospital_info %>% filter(Facility_ID =="100183") %>% View()

    #QC check
    #hospital_info %>% select(Facility_ID) %>% distinct() %>% dim() #3306
    #dbFetch(dbSendQuery(con, "select count(*) from hospital_info where hospital_type = 'Acute Care Hospitals'")) #3306. Good!


####################
#Patient Experience Performance Score
####################

#Pull patient experience and performance metric
patient_experience_performance <- 
  dbFetch(dbSendQuery(con, "select a.Facility_ID, b.responsiveness_of_hospital_Staff_performance_rate, c.total_performance_score as total_performance_score_patient_experience
                    from (select distinct Facility_ID from hospital_info) a
                    left join outcomes_pt_experience_scores b
                        on a.Facility_ID = b.Facility_ID
                    left join outcomes_performance_scores c
                        on a.Facility_ID = c.Facility_ID"))

#Join to hospital info
hospital_info <- left_join(hospital_info, patient_experience_performance, by = "Facility_ID")

#Cast columns as numeric
hospital_info$total_performance_score_patient_experience <- as.numeric(hospital_info$total_performance_score_patient_experience)
hospital_info$Responsiveness_of_Hospital_Staff_Performance_Rate <- as.numeric(hospital_info$Responsiveness_of_Hospital_Staff_Performance_Rate)

####################
#Deaths and Complications
####################

#Pull deaths and complications data 
deaths <- dbFetch(dbSendQuery(con, "select * from outcomes_complications_and_deaths"))
#View(deaths)

# Categorize: Complications/Deaths are stemming from the HOSPITAL (e.g., post-surgical complication), or from PATIENTS (e.g., death from stroke)
deaths %>% select(Measure_Name) %>% distinct()

      # Classify as HOSPITAL-LEVEL complication
          # Broken hip from a fall after surgery
          # Blood stream infection after surgery
          # Serious blood clots after surgery
          # Perioperative Hemorrhage or Hematoma Rate
          # Accidental cuts and tears from medical treatment
          # Postoperative Respiratory Failure Rate
          # Serious complications
          # Rate of complications for hip/knee replacement patients
          # A wound that splits open after surgery on the abdomen or pelvis
          # Deaths among Patients with Serious Treatable Complications after Surgery
          # Postoperative Acute Kidney Injury Requiring Dialysis Rate
          # Collapsed lung due to medical treatment
          # Pressure sores
          # Death rate for CABG surgery patients

      # Classify as PATIENT-LEVEL complication
          # Death rate for stroke patients
          # Death rate for COPD patients
          # Death rate for pneumonia patients
          # Death rate for heart failure patients
          # Death rate for heart attack patients

#Create a weighted "score" - any complications
any_complications_score <- deaths %>% 
  group_by(Facility_ID) %>% 
  mutate(any_complications_score = sum(na.omit(as.numeric(Score) * as.numeric(Denominator)))/sum(na.omit(as.numeric(Denominator)))) %>%
  select(Facility_ID, any_complications_score) %>%
  distinct()

#PATIENT-level complications
patient_level_complications_score <- 
  deaths %>% 
  group_by(Facility_ID) %>% 
  filter(Measure_Name != "Death rate for CABG surgery patients" & startsWith(Measure_Name,"Death rate")) %>%
  mutate(patient_level_complications_score = sum(na.omit(as.numeric(Score) * as.numeric(Denominator)))/sum(na.omit(as.numeric(Denominator)))) %>%
  select(Facility_ID, patient_level_complications_score) %>%
  distinct()

#HOSPITAL-level complications
hospital_level_complications_score <- 
  deaths %>% 
  group_by(Facility_ID) %>% 
  filter(Measure_Name == "Death rate for CABG surgery patients" | !startsWith(Measure_Name,"Death rate")) %>%
  mutate(hospital_level_complications_score = sum(na.omit(as.numeric(Score) * as.numeric(Denominator)))/sum(na.omit(as.numeric(Denominator)))) %>%
  select(Facility_ID, hospital_level_complications_score) %>%
  distinct()

#Join them all together!
deaths_join <- left_join(left_join(any_complications_score, hospital_level_complications_score, by = "Facility_ID"),patient_level_complications_score, by = "Facility_ID")

  #QC check
  #deaths %>% select(Facility_ID) %>% distinct() %>% dim() #4929 
  #dim(deaths_join) #4929. Good!
  #deaths %>% filter(Facility_ID == "330279") %>% View()

#Link it up with hospital info
hospital_info <- left_join(hospital_info, deaths_join, by = "Facility_ID") 


####################
#Hospital Acquired Conditions
####################

#View(dbFetch(dbSendQuery(con, "select * from outcomes_hac_reductions")))
hac <- dbFetch(dbSendQuery(con, "select * from outcomes_hac_reductions"))
hac <- hac %>% select(Facility_ID, TOTAL_HAC_SCORE, PAYMENT_REDUCTION) %>% rename(payment_reduction_hac = PAYMENT_REDUCTION)

#join
hospital_info <- left_join(hospital_info, hac, by = "Facility_ID")

####################
#Readmissions
####################

readmissions <- dbFetch(dbSendQuery(con, "select * from outcomes_readmissions_reductions"))
#readmissions %>% select(Measure_Name) %>% distinct()
#View(readmissions)

#Aggregate the excess readmissons
readmissions <- readmissions %>% group_by(Facility_ID) %>% 
  mutate(excess_readmissions = sum(na.omit(as.numeric(Excess_Readmission_Ratio) * as.numeric(Number_of_Discharges)))/sum(na.omit(as.numeric(Number_of_Discharges)))) %>%
  select(Facility_ID, excess_readmissions) %>%
  distinct()

#Join 
hospital_info <- left_join(hospital_info, readmissions, by = "Facility_ID")

####################
#Healthcare Policy Focused States (IV: Medicaid Expansion)
####################

not_medicaid_expansion <- c("WY", "SD", "WI", "KS", "OK", "TX", "MO", "MS", "TN", "AL", "GA", "FL", "SC", "NC", "ID", "UT", "NE")

hospital_info <- hospital_info %>%
  mutate(hc_policy_focused_state = ifelse(State %in% not_medicaid_expansion, 0,1)) 

####################
#Census Data: median income, mean income, estimated income with social security, with retirement income, mean retirement income, per capita income, health insurance coverage, % below poverty line 
####################

#Pull census data; clean up field names
census_data <- dbFetch(dbSendQuery(con, 
                                   "select a.geography, 
                                      a.estimate_income_and_benefits_in_2017_inflation_adjusted_dollars_total_households_median_household_income_dollars as median_household_income, 
                                      a.estimate_income_and_benefits_in_2017_inflation_adjusted_dollars_with_earnings_mean_earnings_dollars as mean_household_income, 
                                      a.estimate_income_and_benefits_in_2017_inflation_adjusted_dollars_with_social_security as income_w_social_security, 
                                      a.estimate_income_and_benefits_in_2017_inflation_adjusted_dollars_with_retirement_income as income_w_retirement, 
                                      a.estimate_income_and_benefits_in_2017_inflation_adjusted_dollars_with_retirement_income_mean_retirement_income_dollars as mean_retirement_income, 
                                      a.estimate_income_and_benefits_in_2017_inflation_adjusted_dollars_per_capita_income_dollars as income_per_capita, 
                                      a.estimate_health_insurance_coverage_civilian_noninstitutionalized_population as pop_denominator_healthinsurance, 
                                      a.estimate_health_insurance_coverage_civilian_noninstitutionalized_population_with_health_insurance_coverage as pop_with_healthinsurance, 
                                      a.estimate_health_insurance_coverage_civilian_noninstitutionalized_population_no_health_insurance_coverage as pop_no_healthinsurance, 
                                      a.percent_percentage_of_families_and_people_whose_income_in_the_past_12_months_is_below_the_poverty_level_all_people as perc_pop_below_poverty, 
                                      b.census_2017 as pop_census_2017
                                   from census_data a 
                                   left join census_data_pop b 
                                      on a.geography = b.geography"))

#View(census_data)

#Clean up the County/State Name
  #Pull the county/state names
census_data$county <- unlist(str_split(census_data$geography, ', ', simplify = T))[,1]
census_data$State <- unlist(str_split(census_data$geography, ', ', simplify = T))[,2]
  #Get rid of "county", parish, etc.
census_data$county <- gsub(" County","",census_data$county)
census_data$county <- gsub(" Parish","",census_data$county)
census_data$county <- gsub(" Municipality","",census_data$county)
census_data$county <- gsub(" Borough","",census_data$county)
census_data$county <- gsub(" Census Area","",census_data$county)
census_data$county <- gsub("'","",census_data$county)
  #Abbrevate states
census_data$State <- state2abbr(census_data$State)
  #Create Uppercase version of county for joining to hospital info
census_data$County_Name <- toupper(census_data$county)
  #Fix County Names that are different in census vs hospital data 
census_data$County_Name <- ifelse(census_data$County_Name == "DEKALB", "DE KALB", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "DESOTO", "DE SOTO", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "DUPAGE", "DU PAGE", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "EAST BATON ROUGE", "E. BATON ROUGE", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "JEFFERSON DAVIS", "JEFFRSON DAVIS", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "LAPORTE", "LA PORTE", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "NORTHUMBERLAND", "NORTHUMBERLND", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "SCOTTS BLUFF", "SCOTT BLUFF", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "DISTRICT OF COLUMBIA", "THE DISTRICT", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "MCCRACKEN", "MC CRACKEN", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "MCDONOUGH", "MC DONOUGH", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "MCDOWELL", "MC DOWELL", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "MCDUFFIE", "MC DUFFIE", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "MCHENRY", "MC HENRY", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "MCKEAN", "MC KEAN", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "MCLEAN", "MC LEAN", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "MCLENNAN", "MC LENNAN", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "MCLEOD", "MC LEOD", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "MCMINN", "MC MINN", census_data$County_Name)
census_data$County_Name <- ifelse(census_data$County_Name == "DO<F1>A ANA", "DONA ANA", census_data$County_Name)

  #QC: compare counties in one vs the other
  hospital_info$County_Name[c(hospital_info$County_Name,'-', hospital_info$State) %in% c(census_data$County_Name,'-', census_data$State) == F] %>% length()
  #197 non-joins (initially)
  #many are N/A?
  sum(is.na(hospital_info$County_Name) == T) #0. OK those are fine.
  #look at them 
  hospital_info[hospital_info$State %in% census_data$State == T & c(hospital_info$County_Name,'-', hospital_info$State) %in% c(census_data$County_Name,'-', census_data$State) == F,] #%>% View()
  #All fixed. Good!
  #census_data %>% select(State) %>% distinct() %>% View()

#join to hospital_info
hospital_info <- left_join(hospital_info, census_data, by = c("County_Name","State"))


####################
#Hospital density in the county (# hospitals in county; # hospitals per capita in the county)
####################

hospital_info <- hospital_info %>% 
  group_by(County_Name, State) %>%
  mutate(hospital_density = length(Facility_ID),
         hospital_density_per_100k_capita = length(Facility_ID)*100000 / as.numeric(pop_census_2017))
  
  #hospital_info %>% filter(County_Name == "MIAMI-DADE" & State == "FL") %>% View()

####################
#Region (northeast, northwest, south, etc.)
####################

library(dslabs)
data(murders)
murders <- murders %>% select(abb,region) %>% rename(State = abb)

hospital_info <- left_join(hospital_info, murders, by = "State")


###########
#Finish fields, Write Table, Disconnect from DB
###########
  
#exclude PR, Guam, AS, and other non-states 
hospital_info %>% filter(State %in% census_data$State == F) %>% dim() #excluding 57 hospitals

hospital_info <- hospital_info %>% ungroup
hospital_info <- hospital_info %>% filter(State %in% census_data$State == T) 
#3249 records; 3306-57 = 3249. Good.

#exclude tribal hospitals - low complications because they have to move anyone with complications to a larger hospital
hospital_info %>% ungroup %>% select(Hospital_Ownership) %>% distinct()
hospital_info <- hospital_info %>% filter(Hospital_Ownership != "Tribal") #3244 hospitals

#Fix the NaN's
hospital_info$any_complications_score[is.nan(hospital_info$any_complications_score) == T] <- NA_character_
hospital_info$hospital_level_complications_score[is.nan(hospital_info$hospital_level_complications_score) == T] <- NA_character_
hospital_info$patient_level_complications_score[is.nan(hospital_info$patient_level_complications_score) == T] <- NA_character_
hospital_info$excess_readmissions[is.nan(hospital_info$excess_readmissions) == T] <- NA_character_

#fix classes of variables
class(hospital_info$ip_spend)
class(hospital_info$op_spend)
class(hospital_info$total_spend)
class(hospital_info$Responsiveness_of_Hospital_Staff_Performance_Rate)
class(hospital_info$total_performance_score_patient_experience)
class(hospital_info$any_complications_score)#chr
class(hospital_info$hospital_level_complications_score)#chr
class(hospital_info$patient_level_complications_score)#chr
class(hospital_info$TOTAL_HAC_SCORE)#chr
class(hospital_info$payment_reduction_hac)#chr
class(hospital_info$excess_readmissions)#chr
class(hospital_info$hc_policy_focused_state)#num
class(hospital_info$median_household_income)#chr
class(hospital_info$mean_household_income)#chr
class(hospital_info$income_w_social_security)#chr
class(hospital_info$income_w_retirement)#chr
class(hospital_info$mean_retirement_income)#chr
class(hospital_info$pop_denominator_healthinsurance)#chr
class(hospital_info$pop_with_healthinsurance)#chr
class(hospital_info$pop_no_healthinsurance)#chr
class(hospital_info$perc_pop_below_poverty)#chr
class(hospital_info$pop_census_2017)#chr
class(hospital_info$hospital_density)
class(hospital_info$hospital_density_per_100k_capita)


hospital_info$hc_policy_focused_state <- as.factor(hospital_info$hc_policy_focused_state)
hospital_info$any_complications_score <- as.numeric(hospital_info$any_complications_score)
hospital_info$hospital_level_complications_score <- as.numeric(hospital_info$hospital_level_complications_score)
hospital_info$patient_level_complications_score <- as.numeric(hospital_info$patient_level_complications_score)
hospital_info$TOTAL_HAC_SCORE <- as.numeric(hospital_info$TOTAL_HAC_SCORE)
hospital_info$payment_reduction_hac <- as.numeric(hospital_info$payment_reduction_hac)
hospital_info$excess_readmissions <- as.numeric(hospital_info$excess_readmissions)
hospital_info$median_household_income <- as.numeric(hospital_info$median_household_income)
hospital_info$mean_household_income <- as.numeric(hospital_info$mean_household_income)
hospital_info$income_w_social_security <- as.numeric(hospital_info$income_w_social_security)
hospital_info$income_w_retirement <- as.numeric(hospital_info$income_w_retirement)
hospital_info$mean_retirement_income <- as.numeric(hospital_info$mean_retirement_income)
hospital_info$pop_denominator_healthinsurance <- as.numeric(hospital_info$pop_denominator_healthinsurance)
hospital_info$pop_with_healthinsurance <- as.numeric(hospital_info$pop_with_healthinsurance)
hospital_info$pop_no_healthinsurance <- as.numeric(hospital_info$pop_no_healthinsurance)
hospital_info$perc_pop_below_poverty <- as.numeric(hospital_info$perc_pop_below_poverty)
hospital_info$pop_census_2017 <- as.numeric(hospital_info$pop_census_2017)
  
# Make all columns lowercase
names(hospital_info) <- tolower(names(hospital_info))
  
dbRemoveTable(con, "master_hospital_table", hospital_info)
dbWriteTable(con, "master_hospital_table", hospital_info)

#View(dbFetch(dbSendQuery(con, "select * from master_hospital_table")))

#Disconnect
dbDisconnect(con)

