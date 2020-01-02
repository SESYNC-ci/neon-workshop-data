library(tigris)
library(sf)
library(dplyr)
library(ggplot2)
library(data.table)
library(glue)
library(fs)

data_dir <- "/nfs/public-data/NEON_workshop_data/NEON"

# read in AOP flight boxes shapefile
aop <- sf::st_read(file.path(data_dir, "NEON-AOP-FlightBoxes"))

# download shapefiles for all states 
# use cb = TRUE for less detailed version
us_states <- tigris::states(class = "sf")

# spatial join of aop and states data
# in states projection (NAD83)
aop_join_states <- aop %>% 
  dplyr::select(-Name) %>%
  st_transform(crs = st_crs(us_states)) %>%
  st_join(us_states) %>% 
  dplyr::select(Site, STUSPS, geometry)

aop_sites <- aop$Site %>% unique() %>% as.character()


##################################
## function based on one aop site
# uses objects: aop_join_states, state_codes
##################################

save_tracts_for_aop_site <- function(aop_site){
  # combined geometry of all flight boxes for site
  aop_site_sf <- dplyr::filter(aop_join_states, Site == aop_site) %>%
    st_union(by_feature = FALSE) %>% st_as_sf()
  
  # get all states that site includes
  aop_site_states <- dplyr::filter(aop_join_states, Site == aop_site) %>%
    dplyr::pull(STUSPS) %>% unique()
  
  # get all tracts for those states 
  aop_site_statetracts_list <- tryCatch({
    purrr::map(aop_site_states, ~tigris::tracts(state = .x, 
                                                class = "sf", 
                                                year = 2017,
                                                refresh = TRUE))
  }, error = function(e){
    purrr::map(aop_site_states, ~tigris::tracts(state = .x, 
                                                class = "sf", 
                                                year = 2018, # problem with NC 2017 (default year)
                                                refresh = TRUE))
  })
  # combine list of all tracts into one sf
  aop_site_statetracts_sf <- aop_site_statetracts_list %>% 
    purrr::map(~st_cast(.x, to = "MULTIPOLYGON")) %>%
    data.table::rbindlist() %>% st_as_sf()
  
  # identify tracts that overlap aop site
  mat <- aop_site_statetracts_sf %>% 
    sf::st_intersects(aop_site_sf, sparse = FALSE)
  tracts_in_aop <- which(apply(mat, 1, any))
  tracts_subset <- aop_site_statetracts_sf[tracts_in_aop,]
  
  tracts_subset <- tracts_subset %>% left_join(state_codes)
  
  tracts_data <- tracts_subset %>% 
    st_drop_geometry() %>%
    dplyr::select(STUSPS, STATEFP, COUNTYFP, TRACTCE, GEOID, NAME, NAMELSAD) %>%
    mutate(Site = aop_site)
  
  tracts_data %>% readr::write_csv(path = glue::glue("data/tracts-data-{aop_site}.csv"))
  
  g1 <- ggplot(tracts_subset) +
    geom_sf(aes(fill = STUSPS)) +
    geom_sf(data = aop_site_sf, col = "black", lwd = 1, fill = NA) +
    geom_sf_label(data = aop_site_sf, label = aop_site) +
    xlab(element_blank()) + ylab(element_blank()) +
    theme_bw()
  
  filename <- glue::glue("plots/tracts-map-{aop_site}.pdf")
  pdf(filename)
  print(g1)
  dev.off()
  
}

# try one
# save_tracts_for_aop_site(aop_site = aop_sites[1])
# run function over all sites
purrr::walk(aop_sites, ~save_tracts_for_aop_site(.x))

# combine data into one table and save as csv

fs::dir_ls("data") %>%
  purrr::map_df(~readr::read_csv(.x, col_types = "cccccccc")) %>%
  readr::write_csv(file.path(data_dir, "NEON-AOP-CensusGEOIDs.csv"))
