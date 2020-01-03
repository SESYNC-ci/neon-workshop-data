# NLCD data for NEON AOP footprints
# devtools::install_github("ropensci/FedData")

library(sf)
library(FedData)
library(dplyr)
library(tidyr)
# library(ggplot2)
# library(data.table)
library(glue)
library(fs)

data_dir <- "/nfs/public-data/NEON_workshop_data/NEON"

# read in AOP flight boxes shapefile
aop <- sf::st_read(file.path(data_dir, "NEON-AOP-FlightBoxes")) %>% 
  dplyr::select(-Name) %>% 
  group_by(Site) %>% 
  summarise_all(first) %>%
  st_cast("MULTIPOLYGON")

aop_sites <- unique(aop$Site) %>% as.character()

aop_site <- aop_sites[55]
nlcd_codes <- readr::read_csv("nlcd_legend_2011.csv")
# https://www.mrlc.gov/data/legends/national-land-cover-database-2016-nlcd2016-legend

download.file("https://www.neonscience.org/science-design/field-sites/export", 
              destfile = "neon-field-sites.csv")

neon_site_data <- readr::read_csv("neon-field-sites.csv") %>% 
  dplyr::select(`Domain Number`, `Site ID`, State) %>%
  mutate(Site = glue::glue("{`Domain Number`}_{`Site ID`}")) %>%
  mutate(landmass = dplyr::case_when(State == "PR" ~ "PR",
                                     State == "AK" ~ "AK",
                                     State == "HI" ~ "HI",
                                     !State %in% c("PR", "AK", "HI") ~ "L48")) %>%
  mutate(nlcd_year = dplyr::case_when(State == "PR" ~ 2001,
                                     State == "AK" ~ 2011,
                                     State == "HI" ~ 2001,
                                     !State %in% c("PR", "AK", "HI") ~ 2016)) %>%
  dplyr::select(Site, landmass, nlcd_year) %>% 
  mutate(Site = as.character(Site)) %>%
  add_row(Site = "D05_CHEQ", landmass = "L48", nlcd_year = 2016) %>%
  add_row(Site = "D18_BARO", landmass = "AK", nlcd_year = 2011)

aop_x_sitedata <- aop %>% left_join(neon_site_data)
  
# for one site
get_nlcd_percents <- function(aop_site){
  
  aop_site_sf <- aop_x_sitedata %>% dplyr::filter(Site == aop_site)
  site_landmass <- aop_site_sf %>% pull(landmass)
  nlcd_year <- aop_site_sf %>% pull(nlcd_year)
    
  nlcd_site <- FedData::get_nlcd(aop_site_sf,
                      label = aop_site,
                      dataset = "Land_Cover", 
                      landmass = site_landmass,
                      year = nlcd_year,
                      force.redo = TRUE)
  
  aop_site_sf_prj <- aop_site_sf %>% st_transform(proj4string(nlcd_site))
  nlcd_site_mask <- raster::mask(nlcd_site, as(aop_site_sf_prj, "Spatial"))
  
  filename <- glue::glue("plots/nlcd/landcover-{aop_site}-{nlcd_year}.png")
  png(filename)
  # nlcd_agg <- raster::disaggregate(nlcd_site, fact = 3)
  plot(nlcd_site, maxpixels=1e8, mar = c(1,1,1,1), mfrow = c(1,1))
  plot(st_geometry(aop_site_sf_prj), add = TRUE, col = NA, border = "red")
  dev.off()
  
  
  # tabulate number of cells in each type and 
  # Merge with legend to see land cover types
  cover <- raster::freq(nlcd_site_mask) %>%
    as.data.frame() %>%
    dplyr::filter(!is.na(value)) %>%
    dplyr::left_join(nlcd_codes, by = c("value" = "Class")) %>%
    dplyr::mutate(percent_cover = count/sum(count)) %>%
    dplyr::select(class_name, percent_cover) %>%
    mutate(Site = aop_site)
  
  cover %>% readr::write_csv(glue::glue("data/nlcd/landcover-{aop_site}-{nlcd_year}.csv"))
}


# get_nlcd_percents(aop_sites[55])

purrr::walk(aop_sites, ~get_nlcd_percents(.x))


# combine data into one table and save as csv

all_aop_landcover <- fs::dir_ls("data/nlcd") %>%
  purrr::map_df(~readr::read_csv(.x)) %>%
  mutate(percent_cover = percent_cover*100) %>%
  tidyr::spread(key = class_name, value = percent_cover, fill = 0) %>%
  mutate(all_developed = `Developed High Intensity` + `Developed, Low Intensity` +
           `Developed, Medium Intensity` + `Developed, Open Space`) %>%
  arrange(-all_developed)

all_aop_landcover %>% readr::write_csv(file.path(data_dir, "NEON-AOP-LandCover.csv"))
