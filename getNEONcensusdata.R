#loding libraries - not sure I need all of these yet
library(tidycensus)
library(tidyverse)
library(plyr)
library(dplyr)
library(tidyr)
library(foreign)
library(sf)

########### Downloading County Data ######################
# must set up .Renviron file with an API key requested from here:
# https://api.census.gov/data/key_signup.html
# once they send you a key, put it in the .Renviron file using function
# census_api_key('YOUR KEY', install = TRUE)

# codes for ACS variables found here
# https://www.socialexplorer.com/data/ACS2017_5yr/metadata/?ds=ACS17_5yr
# and by adding _001, _002, etc to each of the codes 
# survey = "acs5" is default argument for this dataset, gives 5 year estimate
# to clear environment: remove(list=ls())

#A Personal census API key is required (see above). 
#Save it in a file called "PersonalCensusAPIkey.txt"
apikey = readLines("PersonalCensusAPIkey.txt")
census_api_key(apikey, install = TRUE, overwrite=TRUE)
readRenviron("~/.Renviron")
Sys.getenv("CENSUS_API_KEY")

#This example gets population data for state 4, count 1, which is Apache County, Arizona
#I think the plan will be to read in a list of states and counties overlaping the AOP footprints 
population <- get_acs(geography = "tract", 
                              variables = "B01003_001",
                              state = 4, county = 1,
                              geometry = FALSE, survey = "acs5")


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

allpovertydata <- get_acs(geography = "tract", 
                      variables = "B17001_001",
                      state = 4, county = 1,
                      geometry = FALSE, survey = "acs5")

belowpoverty <- get_acs(geography = "tract", 
                      variables = "B17001_002",
                      state = 4, county = 1,
                      geometry = FALSE, survey = "acs5")

abovepoverty <- get_acs(geography = "tract", 
                   variables = "B17001_031",
                   state = 4, county = 1,
                   geometry = FALSE, survey = "acs5")

#Transportation related variables
# 
#B08101001 Total: (workers 16 years and over)
#B08101009 Car, Truck, or Van - Drove Alone:
#B08101017 Car, Truck, or Van - Carpooled:
#B08101025 Public Transportation (Excluding Taxicab):
#B08101033 Walked:
#B08101041 Taxicab, Motorcycle, Bicycle, or Other Means:
#B08101049 Worked At Home:

