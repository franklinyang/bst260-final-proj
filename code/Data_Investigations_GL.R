####################
#Some Data Investigations
####################


rm(list=ls())
library(DBI)
library(dplyr)
library(ggplot2)
library(ggthemes)

#setwd("/Users/genevievelyons/Intro to DS/bst260-final-proj/code")
con <- dbConnect(RSQLite::SQLite(), "../database/db.sqlite")


#Pull Data from DB
dbListTables(con)
dbListFields(con, "outcomes_hac_reductions")
dbListFields(con, "hospital_info")
dbReadTable(con, "hospital_info")
dbReadTable(con, "spending_by_claim")
res <- dbSendQuery(con, "SELECT * FROM hospital_info WHERE Facility_ID = '400120'")
dbFetch(res)

View(dbFetch(dbSendQuery(con, "select * from outcomes_hac_reductions")))
View(dbFetch(dbSendQuery(con, "select * from hospital_info")))
View(dbFetch(dbSendQuery(con, "select * from spending_by_claim where Facility_ID = '450148' and claim_type = 'inpatient'")))

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

