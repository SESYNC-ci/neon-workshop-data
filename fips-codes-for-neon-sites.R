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

# get the state
aop %>% 
  st_transform(crs = st_crs(us_states)) %>%
  st_join(us_states)

nh_tracts <- tigris::tracts(state = "NH", class = "sf")

plot(nh_tracts$geometry)

ggplot(nh_tracts) +
  geom_sf() +
  geom_sf(data = aop[1,], col = "red", fill = NA)

aop_bart <- aop %>% filter(Site == "D01_BART")

aop_bart %>% 
  st_transform(crs = st_crs(us_states)) %>%
  st_join(nh_tracts) %>% View()
