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

##
## Set up Categorical Median Household Income by Quartile
master$income_cat[master$median_household_income <= 46180.25] <- 1
master$income_cat[master$median_household_income > 46180.25 & master$median_household_income <= 53626] <- 2
master$income_cat[master$median_household_income > 53626 & master$median_household_income <= 62532] <- 3
master$income_cat[master$median_household_income > 62532] <- 4




##########################################
# Main Regression - Hospital Complications
##########################################
mod_hospital_complications <- lm(as.numeric(hospital_level_complications_score) ~ 
                                   ip_spend + 
                                   I(ip_spend^2) + 
                                   hc_policy_focused_state+
                                   hospital_ownership + 
                                   #ip_spend * hospital_ownership + 
                                   #ip_spend * region+
                                   ip_spend * hc_policy_focused_state + 
                                   hospital_density_per_100k_capita+
                                   emergency_services+
                                   as.factor(income_cat)+
                                   #perc_pop_below_poverty+
                                   pop_census_2017+
                                   region+
                                   as.factor(meets_criteria_for_meaningful_use_of_ehrs)+
                                   I(pop_no_healthinsurance/pop_denominator_healthinsurance),
                                 data = master)
summary(mod_hospital_complications)

master %>% ggplot() + geom_boxplot(aes(hc_policy_focused_state, perc_pop_below_poverty))


# Interesting find, log10 of median household income is ~normal
master %>% ggplot(aes(median_household_income))+
  geom_histogram(color="black")+
  scale_x_continuous(trans="log10")

# Quartile Summary statistics for Median Household Income
summary(master$median_household_income)




lim <- master %>%
  mutate(perc_no_healthinsurance = pop_no_healthinsurance/pop_denominator_healthinsurance) %>%
  select (hospital_level_complications_score, ip_spend, excess_readmissions,
          hospital_ownership ,
          hc_policy_focused_state,
          hospital_density_per_100k_capita,
          emergency_services,
          income_cat,
          perc_pop_below_poverty,
          pop_census_2017,
          region,
          perc_no_healthinsurance) 

lim <- lim %>% filter(complete.cases(lim) == T)


##Visualize the model against the data points
lim %>% ggplot()+
  geom_point(aes(ip_spend,hospital_level_complications_score, color = hospital_ownership, size = income_cat), alpha = 0.6)+
  geom_line(aes(ip_spend,fitted(mod_hospital_complications)), color = "blue") + 
  facet_wrap(. ~ region)

lim %>% ggplot()+
  geom_point(aes(ip_spend,hospital_level_complications_score, color = as.factor(income_cat)), alpha = 0.6)+
  geom_line(aes(ip_spend,fitted(mod_hospital_complications)), color = "blue") + 
  facet_wrap(. ~ region + hc_policy_focused_state)

lim %>% ggplot()+
  geom_point(aes(ip_spend,hospital_level_complications_score, color = region), alpha = 0.6)+
  geom_line(aes(ip_spend,fitted(mod_hospital_complications)), color = "blue") + 
  facet_wrap(. ~ income_cat + hc_policy_focused_state)

#################################
# Excess Readmissions Regression
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


##Visualize on the State Level
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
            income_cat = mean(na.omit(income_cat))
  )


View(state)

#State Level Viz
state %>% ggplot() + 
  geom_point(aes(ip_spend, hospital_level_complications_score, color = region, size = income_cat))


state %>% ggplot() + 
  geom_point(aes(ip_spend, excess_readmissions, color = region, size = income_cat))

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
                                      as.factor(income_cat)+
                                      perc_pop_below_poverty+
                                      pop_census_2017+
                                      meets_criteria_for_meaningful_use_of_ehrs+
                                      I(pop_no_healthinsurance/pop_denominator_healthinsurance),
                                    data = massachusetts)
summary(mod_hospital_complications_MA)

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

########################################
# New York State Regression
########################################

newyork <- master %>% filter(state == 'NY')

# Hospital COmplications
mod_hospital_complications_NY <- lm(as.numeric(hospital_level_complications_score) ~ 
                                      ip_spend + 
                                      I(ip_spend^2) + 
                                      hospital_ownership + 
                                      hospital_density_per_100k_capita+
                                      emergency_services+
                                      as.factor(income_cat)+
                                      perc_pop_below_poverty+
                                      pop_census_2017+
                                      meets_criteria_for_meaningful_use_of_ehrs+
                                      I(pop_no_healthinsurance/pop_denominator_healthinsurance),
                                    data = newyork)
summary(mod_hospital_complications_NY)

newyork %>% filter(hospital_ownership == "Voluntary non-profit - Private") %>% ggplot()+
  geom_point(aes(total_spend,as.numeric(hospital_level_complications_score)))+
  geom_smooth(aes(total_spend,as.numeric(hospital_level_complications_score)))

# Excess Readmissions
mod_excess_readmit_NY <- lm(excess_readmissions ~
                              total_spend+
                              pop_with_healthinsurance+
                              as.factor(income_cat)+
                              perc_pop_below_poverty+
                              hospital_ownership+
                              hospital_density_per_100k_capita, data = newyork)
summary(mod_excess_readmit_NY)


#############################################
# Alabama Regression (Non-Medicaid Expansion)
#############################################
alabama <- master %>% filter(state == 'AL')
View(alabama)
# Hospital COmplications
mod_hospital_complications_AL <- lm(as.numeric(hospital_level_complications_score) ~ 
                                      ip_spend + 
                                      I(ip_spend^2) + 
                                      hospital_ownership + 
                                      hospital_density_per_100k_capita+
                                      as.factor(income_cat)+
                                      perc_pop_below_poverty+
                                      pop_census_2017+
                                      meets_criteria_for_meaningful_use_of_ehrs+
                                      I(pop_no_healthinsurance/pop_denominator_healthinsurance),
                                    data = alabama)
summary(mod_hospital_complications_AL)

alabama %>% ggplot()+
  geom_point(aes(total_spend,as.numeric(hospital_level_complications_score)))+
  geom_smooth(aes(total_spend,as.numeric(hospital_level_complications_score)))

# Excess Readmissions
mod_excess_readmit_AL <- lm(excess_readmissions ~
                              total_spend+
                              pop_with_healthinsurance+
                              as.factor(income_cat)+
                              perc_pop_below_poverty+
                              hospital_ownership+
                              hospital_density_per_100k_capita, data = alabama)
summary(mod_excess_readmit_AL)


dbDisconnect(con)
