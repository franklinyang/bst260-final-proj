#####################
#Example Code to pull from SQLite DB
#####################


rm(list=ls())
library(DBI)
library(dplyr)
library(ggplot2)
library(ggthemes)

#Establish connection - need to run this so R knows where to pull the data from
con <- dbConnect(RSQLite::SQLite(), "../database/db.sqlite")

#List Tables in the DB
dbListTables(con)

#List fields in a table in the DB
dbListFields(con, "outcomes_hac_reductions")

#Import data to R dataframe -- replace the table name "outcomes_hac_reductions" in the query to pull data from a different table
hac_reductions <- dbFetch(dbSendQuery(con, "select * from outcomes_hac_reductions"))

#Import data to R and combine the hospital_info table with the spending_by_claim table
#This code pulls ONLY data for Claim_Type "Total" -- would need to change this to Outpatient or Inpatient to pull those records
hosp_info_spending <- dbFetch(dbSendQuery(con, 
                            "SELECT a.*, 
                                b.Claim_Type, b.Period,
                                b.Avg_Spending_Per_Episode_Hospital 
                          FROM hospital_info a 
                          left join spending_by_claim b 
                                on a.facility_id = b.facility_id
                                and b.claim_type = 'Total'"))   #Can Delete this line to pull all claim types or change this from "Total to "Outpatient" or "Inpatient" to pull those records




#Disconnect
dbDisconnect(con)
