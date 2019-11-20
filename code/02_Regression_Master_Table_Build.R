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

#setwd("/Users/genevievelyons/Intro to DS/bst260-final-proj/code")
con <- dbConnect(RSQLite::SQLite(), "../database/db.sqlite")


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
                          WHERE Hospital_Type = 'Acute Care Hospitals'"))
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

#Fix the NaN's
hospital_info$any_complications_score[is.nan(hospital_info$any_complications_score) == T] <- NA_character_
hospital_info$hospital_level_complications_score[is.nan(hospital_info$hospital_level_complications_score) == T] <- NA_character_
hospital_info$patient_level_complications_score[is.nan(hospital_info$patient_level_complications_score) == T] <- NA_character_


####################
#Healthcare Policy Focus (IV: Medicaid Expansion)
####################



####################
#Census Data: median income, mean income, estimated income with social security, with retirement income, mean retirement income, per capita income, health insurance coverage, % below poverty line 
####################



####################
#Hospital density in the county (# hospitals in county; # hospitals per capita in the county)
####################


####################
#Region (northeast, northwest, south, etc.)
####################




# Make all columns lowercase


###########
#Disconnect from DB
###########

dbDisconnect(con)
