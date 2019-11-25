rm(list=ls())
library(DBI)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(ggthemes)


#setwd("/Users/genevievelyons/Intro to DS/bst260-final-proj/code")
con <- dbConnect(RSQLite::SQLite(), "../database/db.sqlite")

master <- dbFetch(dbSendQuery(con,"select * FROM master_hospital_table"))
View(master)
names(master)


master %>% ggplot()+
  geom_point(aes(total_spend,as.numeric(hospital_level_complications_score), color = as.factor(hc_policy_focused_state)))+
  geom_smooth(aes(total_spend,as.numeric(hospital_level_complications_score)))+
  facet_wrap(.~hospital_ownership)



master$income_cat <- rep(NA, nrow(master))
for(i in 1:nrow(master)){
  if(master$median_household_income[i] <= 46180.25){
    master$income_cat[i] <- 1
  } else if(master$median_household_income[i] <= 53626){
    master$income_cat[i] <- 2
  } else if (master$median_household_income[i] <= 56569.82){
    master$income_cat[i] <- 3
  } else {
    master$income_cat[i] <- 3
  }
}

master$income_cat[master$median_household_income <= 46180.25] <- 1
master$income_cat[master$median_household_income > 46180.25 & master$median_household_income <= 53626] <- 2
master$income_cat[master$median_household_income > 53626 & master$median_household_income <= 62532] <- 3
master$income_cat[master$median_household_income > 62532] <- 4

mod_hospital_complications <- lm(as.numeric(hospital_level_complications_score) ~ 
                                   ip_spend + 
                                   I(ip_spend^2) + 
                                   hospital_ownership + 
                                   ip_spend*hospital_ownership + 
                                   hc_policy_focused_state+
                                   hospital_density_per_100k_capita+
                                   emergency_services+
                                   as.factor(income_cat)+
                                   perc_pop_below_poverty+
                                   pop_census_2017+
                                   I(pop_no_healthinsurance/pop_denominator_healthinsurance),
                                 data = master)
summary(mod_hospital_complications)

plot(as.factor(master$income_cat))

master %>% ggplot(aes(median_household_income))+
  geom_histogram(color="black")+
  scale_x_continuous(trans="log10")

summary(master$median_household_income)[2]



master %>% ggplot()+
  geom_point(aes(total_spend,hospital_level_complications_score))+
  geom_line(aes(total_spend,fitted(mod_hospital_complications)))
  

mod_spending <- lm(total_spend ~ as.factor(hc_policy_focused_state), data = master)
summary(mod_spending)

#mod_spendlog <- lm(hospital_level_complications_score ~ total_spend + 
#                     log(total_spend)+
#                     hospital_ownership + 
#                     total_spend*hospital_ownership + 
#                     hc_policy_focused_state, data=master)
#summary(mod_spendlog)

plot(mod_spendlog)
plot(mod_hospital_complications)

plot(as.factor(master$hc_policy_focused_state), master$ip_spend) 
plot(as.factor(master$hc_policy_focused_state), master$total_performance_score_patient_experience)
plot(as.factor(master$hc_policy_focused_state), as.numeric(master$hospital_overall_rating))

master %>% ggplot()+
  geom_point(aes(perc_pop_below_poverty, hospital_density_per_100k_capita, color = hospital_ownership))+
  geom_smooth(aes(perc_pop_below_poverty, hospital_density_per_100k_capita))+
  facet_wrap(.~region)

mod_spendbylocation <- 

dbDisconnect(con)
