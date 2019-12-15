library(tigris)
library(sf)
library(dplyr)
library(ggplot2)

data_dir <- "/nfs/public-data/NEON_workshop_data/NEON"

aop <- sf::st_read(file.path(data_dir, "NEON-AOP-FlightBoxes"))
head(aop)
plot(aop$geometry)

us_states <- states(class = "sf")

plot(us_states$geometry)
head(us_states)


aop_join_states <- aop %>% 
  dplyr::select(-Name) %>%
  st_transform(crs = st_crs(us_states)) %>%
  st_join(us_states) %>% 
  dplyr::select(Site, STUSPS, geometry)

aop_statesFP <- aop_join_states %>% 
  pull(STUSPS) %>% 
  unique()

aop_statesFP[2] %>% 
  tigris::tracts(class = "sf", refresh = TRUE) %>%
  st_join(aop_join_states, left = FALSE)

aop_join_states %>% st_join(nh_tracts)
