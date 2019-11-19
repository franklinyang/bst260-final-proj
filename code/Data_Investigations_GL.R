####################
#Some Data Investigations
####################


rm(list=ls())
library(DBI)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(ggthemes)

#setwd("/Users/genevievelyons/Intro to DS/bst260-final-proj/code")
con <- dbConnect(RSQLite::SQLite(), "../database/db.sqlite")

####################
#Pull Data from DB
####################

dbListTables(con)
dbListFields(con, "outcomes_hac_reductions")
dbListFields(con, "hospital_info")
dbReadTable(con, "hospital_info")
dbReadTable(con, "spending_by_claim")

# View(dbFetch(dbSendQuery(con, "select * from outcomes_hac_reductions")))
# View(dbFetch(dbSendQuery(con, "select * from hospital_info")))
# View(dbFetch(dbSendQuery(con, "select * from spending_by_claim where Facility_ID = '450148' and claim_type = 'inpatient'")))

####################
####################
#Hospital Info, Complications and Deaths, and Spending by Claim
####################
####################

####################
#Pull Spending Data
####################

#Pull Hospital Info and Spending from DB
hospital_info <- dbFetch(dbSendQuery(con, 
                          "SELECT A.*, 
                                B.Claim_Type,
                                B.Period,
                                B.Avg_Spending_Per_Episode_Hospital 
                          FROM hospital_info a 
                          left join spending_by_claim b 
                                on a.facility_id = b.facility_id
                                and b.Claim_Type in('Total','Outpatient','Inpatient')"))

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

  #Example
  hospital_info %>% filter(Facility_ID =="100183") %>% View()
  
  #QC check
  hospital_info %>% select(Facility_ID) %>% distinct() %>% dim() #5344
  dbFetch(dbSendQuery(con, "select count(*) from hospital_info")) #5344

  
  
####################
#Some Summary Stats
####################
  
  #Hospital type
  hospital_info %>% group_by(Hospital_Type) %>% 
    summarize(count = length(Facility_ID), 
              ip_spend = mean(na.omit(ip_spend)),
              op_spend = mean(na.omit(op_spend)),
              total_spend = mean(na.omit(total_spend)))
  #The only hospital types with meaningful data here is Acute Care. There are 3,306 of them.
  #Missing data most notably for CAH's
  
  #Hospital ownership
  hospital_info %>% filter(Hospital_Type == "Acute Care Hospitals") %>%
    group_by(Hospital_Ownership) %>% 
    summarize(count = length(Facility_ID), 
              ip_spend = mean(na.omit(ip_spend)),
              op_spend = mean(na.omit(op_spend)),
              total_spend = mean(na.omit(total_spend)))
  
  #Hospital overall rating
  hospital_info %>% filter(Hospital_Type == "Acute Care Hospitals") %>%
    group_by(Hospital_overall_rating) %>% 
    summarize(count = length(Facility_ID), 
              ip_spend = mean(na.omit(ip_spend)),
              op_spend = mean(na.omit(op_spend)),
              total_spend = mean(na.omit(total_spend)))
  
  #Hospital patient experience rating
  hospital_info %>% filter(Hospital_Type == "Acute Care Hospitals") %>%
    group_by(Patient_experience_national_comparison) %>% 
    summarize(count = length(Facility_ID), 
              ip_spend = mean(na.omit(ip_spend)),
              op_spend = mean(na.omit(op_spend)),
              total_spend = mean(na.omit(total_spend))) #%>% View()
  
  #Hospital readmissions rating
  hospital_info %>% filter(Hospital_Type == "Acute Care Hospitals") %>%
    group_by(Readmission_national_comparison) %>% 
    summarize(count = length(Facility_ID), 
              ip_spend = mean(na.omit(ip_spend)),
              op_spend = mean(na.omit(op_spend)),
              total_spend = mean(na.omit(total_spend))) #%>% View()
  
####################
#Deaths/Complications, HACs
####################
  
#Pull patient experience and performance metric
patient_experience_performance <- 
dbFetch(dbSendQuery(con, "select a.Facility_ID, b.responsiveness_of_hospital_Staff_performance_rate, c.total_performance_score
                    from (select distinct Facility_ID from hospital_info) a
                    left join outcomes_pt_experience_scores b
                        on a.Facility_ID = b.Facility_ID
                    left join outcomes_performance_scores c
                        on a.Facility_ID = c.Facility_ID"))

hospital_info <- left_join(hospital_info, patient_experience_performance, by = "Facility_ID")
hospital_info$Total_Performance_Score <- as.numeric(hospital_info$Total_Performance_Score)
hospital_info$Responsiveness_of_Hospital_Staff_Performance_Rate <- as.numeric(hospital_info$Responsiveness_of_Hospital_Staff_Performance_Rate)


#Pull deaths and HACs
deaths <- dbFetch(dbSendQuery(con, "select * from outcomes_complications_and_deaths"))
deaths <- deaths %>% 
  group_by(Facility_ID) %>% 
  mutate(complications_score = sum(na.omit(as.numeric(Score) * as.numeric(Denominator)))/sum(na.omit(as.numeric(Denominator)))) %>%
  select(Facility_ID, complications_score) %>%
  distinct()

  #deaths %>% filter(Facility_ID == "330279") %>% View()

hospital_info <- left_join(hospital_info, deaths, by = "Facility_ID") 


hac <- dbFetch(dbSendQuery(con, "select * from outcomes_hac_reductions"))

### Graphs ###

#Look at performance score by spending
hospital_info %>% 
  filter(Hospital_Type == "Acute Care Hospitals") %>% 
  #filter(State == "MA") %>% 
  ggplot() + 
  #geom_point(aes(x = total_spend, y = Total_Performance_Score, color = Hospital_Ownership)) + 
  geom_point(aes(x = total_spend, y = Total_Performance_Score, color = Hospital_overall_rating)) + 
  theme(legend.position = "bottom") 
  #Generally negatively correlated

hospital_info %>% 
  filter(Hospital_Type == "Acute Care Hospitals") %>% 
  ggplot() + 
  geom_point(aes(x = total_spend, y = Total_Performance_Score, color = Hospital_Ownership), alpha = 0.5) +
  facet_wrap(. ~ Hospital_overall_rating) + 
  theme(legend.position = "bottom") 

#Look at deaths by spending
hospital_info %>% 
  filter(Hospital_Type == "Acute Care Hospitals") %>% 
  filter(State == "MA") %>% 
  ggplot() + 
  geom_point(aes(x = total_spend, y = complications_score, color = Hospital_Ownership), alpha = 0.5) + 
  #geom_point(aes(x = total_spend, y = complications_score, color = Hospital_overall_rating), alpha = 0.5) + 
  scale_y_continuous(limits = c(0,5)) +
  theme(legend.position = "bottom") 
  #higher score associated with total spend
  #VERY clear correlation when looking just in Mass.

hospital_info %>% 
  filter(Hospital_Type == "Acute Care Hospitals") %>% 
  ggplot() + 
  geom_point(aes(x = total_spend, y = complications_score, color = Hospital_Ownership), alpha = 0.5) +
  facet_wrap(. ~ Hospital_overall_rating) + 
  scale_y_continuous(limits = c(0,5)) +
  theme(legend.position = "bottom") 



####################
#Other looks at the data 
####################
  
#Join
data <- dbFetch(dbSendQuery(con, 
                           "SELECT a.*, 
                                b.Avg_Spending_Per_Episode_Hospital 
                          FROM hospital_info a 
                          left join spending_by_claim b 
                                on a.facility_id = b.facility_id
                                and b.claim_type = 'Total'"))

View(data)

spending <- dbFetch(dbSendQuery(con, "SELECT * from spending_by_claim "))
spending %>% filter(Facility_ID == "100183") %>% View()

#Hospital_overall_rating
#Mortality_national_comparison
#b.Avg_Spending_Per_Episode_Hospital

data %>% ggplot() + 
  geom_boxplot(aes(Hospital_overall_rating, Avg_Spending_Per_Episode_Hospital))

data %>% ggplot() + 
  geom_boxplot(aes(Mortality_national_comparison, Avg_Spending_Per_Episode_Hospital))

#All measures
dbFetch(dbSendQuery(con, "select *from outcomes_complications_and_deaths"))  %>% select(Measure_Name) %>% distinct()
dbFetch(dbSendQuery(con, "select *from outcomes_complications_and_deaths"))  %>% filter(Facility.ID == "330024") %>% View()


deaths <- 
  dbFetch(dbSendQuery(con, "select *from outcomes_complications_and_deaths")) %>% 
  filter(Measure_Name == "Death rate for stroke patients") %>%
  mutate(Facility_ID = Facility_ID)

View(deaths)

data <- left_join(data, deaths, by = "Facility_ID")
View(data)


data %>% ggplot() + 
  geom_point(aes(Avg_Spending_Per_Episode_Hospital, as.numeric(Score)))
                                
#################
#HAC vs Spending, etc.
#################


#Join
hac <- dbFetch(dbSendQuery(con, 
                            "SELECT a.*, 
                                b.Avg_Spending_Per_Episode_Hospital, 
                                c.Avg_Spending_Per_Episode_Hospital as OP_Avg_Spend
                          FROM outcomes_hac_reductions a 
                          left join spending_by_claim b 
                                on a.facility_id = b.facility_id
                                and b.claim_type = 'Total'
                           left join spending_by_claim c
                                on a.facility_id = c.facility_id
                                and c.claim_type = 'Outpatient'
                                and c.Period = '1 through 30 days After Discharge from Index Hospital Admission'"))

#3281

View(hac)



hac %>% ggplot() + 
  geom_point(aes(Avg_Spending_Per_Episode_Hospital, as.numeric(TOTAL_HAC_SCORE), color = PAYMENT_REDUCTION))

hac %>% ggplot() + 
  geom_point(aes(OP_Avg_Spend, as.numeric(TOTAL_HAC_SCORE), color = PAYMENT_REDUCTION))


hac %>% ggplot() + 
  geom_point(aes(Avg_Spending_Per_Episode_Hospital, log(as.numeric(TOTAL_HAC_SCORE))))

dbFetch(dbSendQuery(con, "select * from spending_by_claim")) %>% filter(Claim_Type == "Outpatient") %>% View() 
dbFetch(dbSendQuery(con, "select * from spending_by_claim")) %>% filter(Claim_Type == "Outpatient") %>% select(Period) %>% distinct()
dbFetch(dbSendQuery(con, "select * from spending_by_claim")) %>% filter(Claim_Type == "Outpatient" & Period == "During Index Hospital Admission") %>% head()

dbDisconnect(con)

