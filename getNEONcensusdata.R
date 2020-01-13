#loding libraries - not sure I need all of these yet
library(tidycensus)
library(tidyverse)
library(dplyr)
library(tidyr)
library(foreign)
library(sf)

#######################################################
# Retrive fips codes 
#######################################################
data_dir <- "/nfs/public-data/NEON_workshop_data/NEON"
NEONgeoids <-  readr::read_csv(file.path(data_dir, "NEON-AOP-CensusGEOIDs.csv"), col_types = "cccccccc")
state.use = unique(NEONgeoids$STATEFP)

#######################################################
# Retrive ACS dataset names and codes
#######################################################
ACScodes <-  readr::read_csv(file.path(data_dir, "NEON-AOP-ACSdatasets.csv"), col_types = "cc")

########### Downloading Census Data ######################
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

##############################################################################################
#Function to query the ACS API for all states containing a NEON site. The tract level data is
#then joined to the list of tracts overlaping the sites provided by Kelly.
##############################################################################################
GetOneDataset = function(temp, state.use, NEONgeoids){
  ACSdataset = paste0(substr(temp,1,6),"_",substr(temp,7,9))
  df <- get_acs(geography = "tract", 
                        variables = ACSdataset,
                        state = state.use,
                        geometry = FALSE, survey = "acs5")
  
  NEON.ACS.one = dplyr::left_join(NEONgeoids,df[,c(1,4)])
  names(NEON.ACS.one)[which(names(NEON.ACS.one) == "estimate")] = ACSdataset

  return(NEON.ACS.one[,which(names(NEON.ACS.one) == ACSdataset)])
}

##############################################################################################
#Loop through all the ACS variables selected earlier and provided in the data.frame: ACScodes
#After each call to GetOneDataset, bind the new data to the NEON.ACS data.frame
##############################################################################################
NEON.ACS = NEONgeoids
for(temp in ACScodes$dataset){
  NEON.ACS.one = GetOneDataset(temp, state.use, NEONgeoids)
  NEON.ACS = cbind(NEON.ACS,NEON.ACS.one)
}

#Write the new data.frame to disk. 
#write.csv(NEON.ACS,file.path(data_dir, "NEON-AOP-ACS.csv")) #why can't I write here?
write.csv(NEON.ACS,"/research-home/aelmore/NEON/NEON-AOP-ACS.csv")
