####################
#Some Data Investigations
####################


rm(list=ls())
library(DBI)
library(dplyr)
library(ggplot2)
library(ggthemes)


con <- dbConnect(RSQLite::SQLite(), "../database/db.sqlite")

#Pull Data from DB
dbListTables(con)
dbListFields(con, "hospital_info")
dbReadTable(con, "hospital_info")
dbReadTable(con, "spending_by_claim")
res <- dbSendQuery(con, "SELECT * FROM hospital_info WHERE Facility_ID = '400120'")
dbFetch(res)

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
dbFetch(dbSendQuery(con, "select *from outcomes_complications_and_deaths"))  %>% select(Measure.Name) %>% distinct()
dbFetch(dbSendQuery(con, "select *from outcomes_complications_and_deaths"))  %>% filter(Facility.ID == "330024") %>% View()


deaths <- 
  dbFetch(dbSendQuery(con, "select *from outcomes_complications_and_deaths")) %>% 
  filter(Measure.Name == "Death rate for stroke patients") %>%
  mutate(Facility_ID = Facility.ID)

data <- left_join(data, deaths, by = "Facility_ID")
View(data)


data %>% ggplot() + 
  geom_point(aes(Avg_Spending_Per_Episode_Hospital, as.numeric(Score)))
                                







dbDisconnect(con)

