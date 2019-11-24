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


mod_hospital_complications <- lm(as.numeric(hospital_level_complications_score) ~ 
                                   total_spend + 
                                   I(total_spend^2) + 
                                   hospital_ownership + 
                                   total_spend*hospital_ownership + 
                                   as.factor(hc_policy_focused_state), data = master)
summary(mod_hospital_complications)

mod_spending <- lm(total_spend ~ as.factor(hc_policy_focused_state), data = master)
summary(mod_spending)


plot(as.factor(master$hc_policy_focused_state), master$ip_spend) 
plot(as.factor(master$hc_policy_focused_state), master$total_performance_score_patient_experience)
plot(as.factor(master$hc_policy_focused_state), as.numeric(master$hospital_overall_rating))

dbDisconnect(con)
