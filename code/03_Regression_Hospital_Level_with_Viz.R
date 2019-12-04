
##########################################
#Load Libraries
##########################################

rm(list=ls())
library(DBI)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(ggthemes)


##########################################
#Establish Connection and pull data
#See prior scripts for loading and master table build
##########################################

#setwd("/Users/genevievelyons/Intro to DS/bst260-final-proj/code")
con <- dbConnect(RSQLite::SQLite(), "../database/db.sqlite")

master <- dbFetch(dbSendQuery(con,"select * FROM master_hospital_table"))
#View(master)
#names(master)


## Set up Categorical Median Household Income by Quartile
master$income_cat[master$median_household_income <= 46180.25] <- 1
master$income_cat[master$median_household_income > 46180.25 & master$median_household_income <= 53626] <- 2
master$income_cat[master$median_household_income > 53626 & master$median_household_income <= 62532] <- 3
master$income_cat[master$median_household_income > 62532] <- 4
master$income_cat <- as.factor(master$income_cat)

#Convert meaningful use into factor
master$meets_criteria_for_meaningful_use_of_ehrs <- as.factor(master$meets_criteria_for_meaningful_use_of_ehrs)

##########################################
##########################################
# Regression #1 - Hospital Complications
##########################################
##########################################

##########################################
# Regression
##########################################

mod_hospital_complications <- lm(hospital_level_complications_score ~ 
                                   ip_spend + 
                                   I(ip_spend^2) + 
                                   hc_policy_focused_state+
                                   ip_spend * hc_policy_focused_state + 
                                   hospital_ownership + 
                                   hospital_density_per_100k_capita+
                                   emergency_services+
                                   income_cat+
                                   pop_census_2017+
                                   region+
                                   meets_criteria_for_meaningful_use_of_ehrs+
                                   I(pop_no_healthinsurance/pop_denominator_healthinsurance),
                                 data = master)
summary(mod_hospital_complications) 
confint(mod_hospital_complications)

summary(master$ip_spend); sd(na.omit(master$ip_spend)) #Median 11,482; sd 2,651.519
hist(master$ip_spend)
hist(log10(master$ip_spend))
summary(master$hospital_level_complications_score); sd(na.omit(master$hospital_level_complications_score))

#Interpretation
4.036e-04*11500-8.999e-09*11500^2+1.536e-05*11500 - (4.036e-04*9500-8.999e-09*9500^2+1.536e-05*9500) #0.459962 - HC focused
(4.036e-04*11500-8.999e-09*11500^2+1.536e-05*11500 - (4.036e-04*9500-8.999e-09*9500^2+1.536e-05*9500))/(4.036e-04*9500-8.999e-09*9500^2+1.536e-05*9500) #14.5% - HC focused
4.036e-04*11500-8.999e-09*11500^2 - (4.036e-04*9500-8.999e-09*9500^2) #0.429242 - not HC focused
(4.036e-04*11500-8.999e-09*11500^2 - (4.036e-04*9500-8.999e-09*9500^2))/(4.036e-04*9500-8.999e-09*9500^2) #14.2% - not HC focused
# All else being equal, a hospital in a state with a healthcare policy focus with an average IP spend per claim of $11,500 has a postoverative complications score 14.5% higher than a hospital that spends $2k per claim less (14.2% in non-healthcare policy focused states).


##########################################
# Visualizations
##########################################

#Limit the data so we can graph the model
lim_complications <- master %>%
  mutate(perc_no_healthinsurance = pop_no_healthinsurance/pop_denominator_healthinsurance) %>%
  select (hospital_level_complications_score,
            ip_spend,
            hc_policy_focused_state,
            hospital_ownership,
            hospital_density_per_100k_capita,
            emergency_services,
            income_cat,
            pop_census_2017,
            region,
            meets_criteria_for_meaningful_use_of_ehrs,
            perc_no_healthinsurance,
            state) 

lim_complications <- lim_complications %>% filter(complete.cases(lim_complications) == T)

## The fitted model - National - Hospital Type
lim_complications %>% 
  ggplot()+
  geom_point(aes(ip_spend,hospital_level_complications_score, color = hospital_ownership), alpha = 0.7)+
  geom_line(aes(ip_spend,fitted(mod_hospital_complications)), color = "blue") + 
  facet_wrap(. ~ region + hc_policy_focused_state)

#Smoothed Model - National - Hospital Type
lim_complications %>% 
  ggplot()+
  geom_point(aes(ip_spend,hospital_level_complications_score, color = hospital_ownership), alpha = 0.7)+
  geom_smooth(aes(ip_spend,fitted(mod_hospital_complications))) + 
  facet_wrap(. ~ region + hc_policy_focused_state)


## The fitted model - National - Income cat
lim_complications %>% 
  ggplot()+
  geom_point(aes(ip_spend,hospital_level_complications_score, color = income_cat), alpha = 0.7)+
  geom_line(aes(ip_spend,fitted(mod_hospital_complications)), color = "blue") + 
  facet_wrap(. ~ region + hc_policy_focused_state)

#Smoothed Model - National - Income cat
lim_complications %>% 
  ggplot()+
  geom_point(aes(ip_spend,hospital_level_complications_score, color = income_cat), alpha = 0.7)+
  geom_smooth(aes(ip_spend,fitted(mod_hospital_complications))) + 
  facet_wrap(. ~ region + hc_policy_focused_state)



#################################
# Regression #2 - Excess Readmissions Regression
#################################

mod_excess_readmit <- lm(excess_readmissions ~
                           total_spend+
                           pop_with_healthinsurance+
                           as.factor(income_cat)+
                           perc_pop_below_poverty+
                           region+
                           hospital_ownership+
                           hc_policy_focused_state+
                           hospital_density_per_100k_capita, data = master)
summary(mod_excess_readmit)
plot(mod_excess_readmit)

confint(mod_excess_readmit)

##Excess Readmissions
lim %>% ggplot()+
  geom_point(aes(ip_spend,excess_readmissions, color = hospital_ownership, size = income_cat), alpha = 0.6)+
  facet_wrap(. ~ region)

lim %>% ggplot()+
  geom_point(aes(ip_spend,excess_readmissions, color = hospital_ownership, size = income_cat), alpha = 0.6)+
  facet_wrap(. ~ region + hc_policy_focused_state)

master %>% ggplot()+
  geom_point(aes(median_household_income,excess_readmissions, color = ip_spend), alpha = 0.6)+
  facet_wrap(. ~ region + hc_policy_focused_state)




mod_hac <- lm(responsiveness_of_hospital_staff_performance_rate ~
                           total_spend+
                           I(total_spend^2)+
                           pop_with_healthinsurance+
                           as.factor(income_cat)+
                           perc_pop_below_poverty+
                           region+
                           hospital_ownership+
                           hc_policy_focused_state+
                           hospital_density_per_100k_capita, data = master)
summary(mod_hac)
plot(mod_hac)

master %>% ggplot()+geom_point(aes(ip_spend,total_hac_score, color = hospital_ownership), alpha = 0.6) +
  geom_smooth(aes(ip_spend,total_hac_score))



master %>% ggplot()+geom_point(aes(total_spend,total_hac_score, color = hospital_ownership), alpha = 0.6) +
  geom_smooth(aes(total_spend,total_hac_score))

master %>% ggplot()+geom_point(aes(total_spend,excess_readmissions, color = hospital_ownership), alpha = 0.6) +
  geom_smooth(aes(total_spend,excess_readmissions))

master %>% ggplot()+geom_point(aes(total_spend,responsiveness_of_hospital_staff_performance_rate, color = hospital_ownership), alpha = 0.6) +
  geom_smooth(aes(total_spend,responsiveness_of_hospital_staff_performance_rate))


master %>% ggplot()+geom_point(aes(median_household_income,total_hac_score, color = hospital_ownership), alpha = 0.6) +
  geom_smooth(aes(median_household_income,total_hac_score))

master %>% ggplot()+geom_point(aes(median_household_income,excess_readmissions, color = hospital_ownership), alpha = 0.6) +
  geom_smooth(aes(median_household_income,excess_readmissions))


master %>% ggplot()+geom_point(aes(perc_pop_below_poverty,total_hac_score, color = hospital_ownership), alpha = 0.6) +
  geom_smooth(aes(perc_pop_below_poverty,total_hac_score))

master %>% ggplot()+geom_point(aes(perc_pop_below_poverty,excess_readmissions, color = hospital_ownership), alpha = 0.6) +
  geom_smooth(aes(perc_pop_below_poverty,excess_readmissions))



##########################################
##########################################
##Visualize on the State Level
##########################################
##########################################

state <- master %>%
  group_by(state) %>%
  summarize(region = max(na.omit(region)),
            hc_policy_focused_state = max(na.omit(hc_policy_focused_state)),
            ip_spend = mean(na.omit(ip_spend)),
            op_spend = mean(na.omit(op_spend)),
            total_spend = mean(na.omit(total_spend)),
            hospital_level_complications_score = mean(na.omit(hospital_level_complications_score)),
            excess_readmissions = mean(na.omit(excess_readmissions)),
            hospital_density_per_100k_capita = mean(na.omit(hospital_density_per_100k_capita)),
            income_cat = mean(na.omit(as.numeric(income_cat))),
            responsiveness_of_hospital_staff_performance_rate = mean(na.omit(responsiveness_of_hospital_staff_performance_rate)) 
  )


View(state)

#State Level Viz
state %>% ggplot() + 
  geom_point(aes(ip_spend, hospital_level_complications_score, color = region, size = income_cat), alpha = 0.7) +
  geom_smooth(aes(ip_spend, hospital_level_complications_score))


state %>% ggplot() + 
  geom_point(aes(total_spend, excess_readmissions, color = region, size = income_cat)) + 
  geom_smooth(aes(total_spend, excess_readmissions))


state %>% ggplot() + 
  geom_point(aes(total_spend, responsiveness_of_hospital_staff_performance_rate, color = region, size = income_cat)) + 
  geom_smooth(aes(total_spend, responsiveness_of_hospital_staff_performance_rate))

state %>% ggplot() + 
  geom_point(aes(log(total_spend), excess_readmissions, color = region, size = income_cat)) + 
  geom_smooth(aes(log(total_spend), excess_readmissions)) 

state %>% ggplot() + 
  geom_point(aes(total_spend, log(excess_readmissions), color = region, size = income_cat)) + 
  geom_smooth(aes(total_spend, log(excess_readmissions)))



plot(mod_hospital_complications)

#point 2157 is very high leverage, consider excluding.


mod_bystate <- lm(hospital_level_complications_score ~ 
                    ip_spend + 
                    I(ip_spend^2) + 
                    hc_policy_focused_state+
                    ip_spend * hc_policy_focused_state + 
                    hospital_density_per_100k_capita+
                    income_cat+
                    region,
                  data = state)
summary(mod_bystate)


# Is "Policy Focused State Significant?" - Answer, not really?
mod_spending <- lm(total_spend ~ as.factor(hc_policy_focused_state), data = master)
summary(mod_spending)



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


#######################################################################################################################################################################################################################################
#Delete all this?
#######################################################################################################################################################################################################################################


#################################
# Massachusetts State Regression
#################################

massachusetts <- master %>% filter(state == 'MA')
view(massachusetts)

#Hospital Complications
mod_hospital_complications_MA <- lm(as.numeric(hospital_level_complications_score) ~ 
                                      ip_spend + 
                                      I(ip_spend^2) + 
                                      hospital_density_per_100k_capita+
                                      emergency_services+
                                      hospital_ownership+
                                      as.factor(income_cat)+
                                      perc_pop_below_poverty+
                                      pop_census_2017+
                                      meets_criteria_for_meaningful_use_of_ehrs+
                                      I(pop_no_healthinsurance/pop_denominator_healthinsurance),
                                    data = massachusetts)
summary(mod_hospital_complications_MA)

confint(mod_hospital_complications_MA)

massachusetts %>% filter(hospital_ownership == "Voluntary non-profit - Private") %>% ggplot()+
  geom_point(aes(total_spend,as.numeric(hospital_level_complications_score)))+
  geom_smooth(aes(total_spend,as.numeric(hospital_level_complications_score)))

# Excess Readmissions
mod_excess_readmit_MA <- lm(excess_readmissions ~
                           total_spend+
                           pop_with_healthinsurance+
                           as.factor(income_cat)+
                           perc_pop_below_poverty+
                           hospital_ownership+
                           hospital_density_per_100k_capita, data = massachusetts)
summary(mod_excess_readmit_MA)

confint(mod_excess_readmit_MA)



#############################################
# Texas Regression (non-Medicaid Expansion)
#############################################
texas <- master %>% filter(state == 'TX')

# Hospital COmplications
mod_hospital_complications_TX <- lm(as.numeric(hospital_level_complications_score) ~ 
                                      ip_spend + 
                                      I(ip_spend^2) + 
                                      hospital_ownership + 
                                      hospital_density_per_100k_capita+
                                      as.factor(income_cat)+
                                      perc_pop_below_poverty+
                                      pop_census_2017+
                                      emergency_services+
                                      meets_criteria_for_meaningful_use_of_ehrs+
                                      I(pop_no_healthinsurance/pop_denominator_healthinsurance),
                                    data = texas)
summary(mod_hospital_complications_TX)

confint(mod_hospital_complications_TX)

texas %>% ggplot()+
  geom_point(aes(total_spend,as.numeric(hospital_level_complications_score)))+
  geom_smooth(aes(total_spend,as.numeric(hospital_level_complications_score)))

# Excess Readmissions
mod_excess_readmit_TX <- lm(excess_readmissions ~
                              total_spend+
                              pop_with_healthinsurance+
                              as.factor(income_cat)+
                              perc_pop_below_poverty+
                              hospital_ownership+
                              hospital_density_per_100k_capita, data = texas)
summary(mod_excess_readmit_TX)

confint(mod_excess_readmit_TX)

dbDisconnect(con)
