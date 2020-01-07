# loading libraries - not sure I need all of these yet
library(tidycensus)
library(tidyverse)
library(foreign)
library(sf)

#######################################################
# Retrive fips codes 
#######################################################
data_dir <- "/nfs/public-data/NEON_workshop_data/NEON"
NEONgeoids <-  readr::read_csv(file.path(data_dir, "NEON-AOP-CensusGEOIDs.csv"), col_types = "cccccccc")
state_use <- unique(NEONgeoids$STATEFP)

#######################################################
# Retrive ACS dataset names and codes
#######################################################
# codes for ACS variables found here
# https://www.socialexplorer.com/data/ACS2017_5yr/metadata/?ds=ACS17_5yr
# and by adding _001, _002, etc to each of the codes 
# survey = "acs5" is default argument for this dataset, gives 5 year estimate
# ACScodes <- readr::read_csv(file.path(data_dir, "NEON-AOP-ACSdatasets.csv"), col_types = "cc")
ACScodes <- readr::read_csv("NEON-AOP-ACSdatasets.csv", col_types = "cc")
ACScodes <- ACScodes %>% 
            mutate(dataset_sep = paste0(substr(dataset,1,6),"_",substr(dataset,7,9)))

########### Downloading Census Data ######################
# must set up .Renviron file with an API key requested from here:
# https://api.census.gov/data/key_signup.html
# once they send you a key, put it in the .Renviron file using function
# census_api_key('YOUR KEY', install = TRUE)

readRenviron("~/.Renviron") # gets your R environment
Sys.getenv("CENSUS_API_KEY") # displays your API key

# This example gets population data for state_use, a vector of all unique states with a NEON site.
# I think the plan will be to read in a list of states (and maybe counties) overlaping the AOP footprints 

ACSdataset <- unique(ACScodes$dataset_sep)  # vector of variable IDs from ACS

Get_Dataset <- function(acs_vars, states, ...){

                 df <- get_acs(geography = "tract", variables = acs_vars,
                               state = states, geometry = FALSE, survey = "acs5")
  
                 NEON_ACS <- left_join(df, ACScodes[ ,2:3], by = c("variable" = "dataset_sep"))
                 
                 NEON_ACS_Geoid <- left_join(NEON_ACS, NEONgeoids, by = "GEOID") %>% 
                                   filter(!is.na("COUNTYFP"))
                 # names(NEON_ACS_one)[which(names(NEON_ACS_one) == "estimate")] = ACSdataset
                 # 
                 # return(NEON_ACS_one[,which(names(NEON_ACS_one) == ACSdataset)])
}

# NEON.ACS = NEONgeoids
# for(temp in ACScodes[,1]){
#   NEON.ACS.one = GetOneDataset(temp, state_use, NEONgeoids)
#   NEON.ACS = cbind(NEON.ACS,NEON.ACS.one)
# }

NEON_ACS <- Get_Dataset(ACSdataset, state_use)

write.csv(NEON_ACS, file.path(data_dir, "NEON_AOP_ACS.csv"))

########################################
# a bunch of notes on the ACS. This is all found in the NEON-AOP-ACSdatasets.csv file.
###############################################

#B01003001 Population
#Race related variables
#https://www.socialexplorer.com/data/ACS2017_5yr/metadata/?ds=ACS17_5yr&table=B02001
#B02001002 White Alone 
#B02001003 Black or African American Alone
#B02001004 American Indian and Alaska Native Alone
#B02001005 Asian Alone
#B02001006 Native Hawaiian and Other Pacific Islander Alone
#B02001007 Some Other Race Alone
#B02001008 Two or More Races:
#B02001009 Two Races Including Some Other Race
#B02001010 Two Races Excluding Some Other Race, and Three or More Races


#Age related variables
#https://www.socialexplorer.com/data/ACS2017_5yr/metadata/?ds=ACS17_5yr&table=B01002
#B01002001 Median Age -- Total:
#B01002002 Median Age -- Male
#B01002003 Median Age -- Female


#employment related variables
#https://www.socialexplorer.com/data/ACS2017_5yr/metadata/?ds=ACS17_5yr&table=B23025
#B23025001 Total population 16 Years and Over
#B23025002 In Labor Force:
#B23025003 Civilian Labor Force:
#B23025004 Employed
#B23025005 Unemployed
#B23025006 Armed Forces
#B23025007 Not in Labor Force

#economic activity related variables
#https://www.socialexplorer.com/data/ACS2017_5yr/metadata/?ds=ACS17_5yr&table=C24070
#many variables having to do with the type of work people do
#C24070001 Total:
#C24070002 Agriculture, Forestry, Fishing and Hunting, and Mining
#C24070003 Construction
#C24070004 Manufacturing
#C24070005 Wholesale Trade
#C24070006 Retail Trade
#C24070007 Transportation and Warehousing, and Utilities
#C24070008 Information
#C24070009 Finance and Insurance, and Real Estate and Rental and Leasing
#C24070010 Professional, Scientific, and Management, and Administrative and Waste Management Services
#C24070011 Educational Services, and Health Care and Social Assistance
#C24070012 Arts, Entertainment, and Recreation, and Accommodation and Food Services
#C24070013 Other Services, Except Public Administration
#C24070014 Public Administration

#poverty related variables
#https://www.socialexplorer.com/data/ACS2017_5yr/metadata/?ds=ACS17_5yr&table=B17001
#B17001001 Total:
#B17001002 Income in the Past 12 Months Below Poverty Level:
#B17001031 Income in the Past 12 Months At or Above Poverty Level:


#Transportation related variables
# 
#B08101001 Total: (workers 16 years and over)
#B08101009 Car, Truck, or Van - Drove Alone:
#B08101017 Car, Truck, or Van - Carpooled:
#B08101025 Public Transportation (Excluding Taxicab):
#B08101033 Walked:
#B08101041 Taxicab, Motorcycle, Bicycle, or Other Means:
#B08101049 Worked At Home:

