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

#Scatterplot of Total Spending by Hospital Level Complications Score, separated by hospital ownership type
master %>% ggplot()+
  geom_point(aes(total_spend,as.numeric(hospital_level_complications_score), color = as.factor(hc_policy_focused_state)))+
  geom_smooth(aes(total_spend,as.numeric(hospital_level_complications_score)))+
  facet_wrap(.~hospital_ownership)


## Set up Categorical Median Household Income by Quartile
master$income_cat[master$median_household_income <= 46180.25] <- 1
master$income_cat[master$median_household_income > 46180.25 & master$median_household_income <= 53626] <- 2
master$income_cat[master$median_household_income > 53626 & master$median_household_income <= 62532] <- 3
master$income_cat[master$median_household_income > 62532] <- 4




######################
# Main Regression
######################
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


# Interesting find, log10 of median household income is ~normal
master %>% ggplot(aes(median_household_income))+
  geom_histogram(color="black")+
  scale_x_continuous(trans="log10")

# Quartile Summary statistics for Median Household Income
summary(master$median_household_income)


## Still need to fix this graph (why are lengths different?) - trying to visualize the model against the data points
master %>% ggplot()+
  geom_point(aes(total_spend,hospital_level_complications_score))+
  geom_line(aes(total_spend,fitted(mod_hospital_complications)))
  

# Is "Policy Focused State Significant?" - Answer, not really?
mod_spending <- lm(total_spend ~ as.factor(hc_policy_focused_state), data = master)
summary(mod_spending)

#mod_spendlog <- lm(hospital_level_complications_score ~ total_spend + 
#                     log(total_spend)+
#                     hospital_ownership + 
#                     total_spend*hospital_ownership + 
#                     hc_policy_focused_state, data=master)
#summary(mod_spendlog)



# Residuals for main regression - not completely random
plot(mod_hospital_complications)



#Boxplots of Various data
plot(as.factor(master$hc_policy_focused_state), master$ip_spend) 
plot(as.factor(master$hc_policy_focused_state), master$total_performance_score_patient_experience)
plot(as.factor(master$hc_policy_focused_state), as.numeric(master$hospital_overall_rating))


## Graphs of hospital density and poverty by region
master %>% ggplot()+
  geom_point(aes(perc_pop_below_poverty, hospital_density_per_100k_capita, color = hospital_ownership))+
  geom_smooth(aes(perc_pop_below_poverty, hospital_density_per_100k_capita))+
  facet_wrap(.~region)



dbDisconnect(con)
