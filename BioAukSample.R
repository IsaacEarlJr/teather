# Script:   [Auk_Pipeline3.0]
# Purpose:  [Three-step auk pipeline for hourly/daily ER]
# Author:   [Isaac E. Coleman]
# Date:     [NOV 2025]
# R: 4.3.2   |   eBird Taxonomy: v2025

# Note: This is a trimmed down pipeline. It is still effective stand 
# Requirements: AWK install for windows



# ___________________________________________________________________________
# (zero) Pre-Load
# -------------+--------------------------------------------------------------

# station | year | date
station <- "KBRO"
year    <- 2020
date_min <- sprintf("%d-04-23", year)
date_max <- sprintf("%d-05-11", year)

# packages
library(auk)
library(readr)
library(dplyr)
library(lubridate)
library(hms)

# input paths
ebd_path  <- "/home/EBDdata/ebd_relJul-2025.txt"        # EBD file
samp_path <- "/home/ebd_sampling_relJul-2025.txt"  # sampling event file

# output paths
out_dir  <- file.path("/home/auk_out/filtered", station, year)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_ebd  <- file.path(out_dir, sprintf("ebd_filtered_%s_%s.txt", station, year))
out_samp <- file.path(out_dir, sprintf("ebd_sampling_filtered_%s_%s.txt", station, year))

# spatial and temporal pre-filters 
time_min <- "04:00"; time_max <- "13:00"
bbox     <- c(-98.7714, 24.69937, -96.06676, 27.13181)  # (W.S.E.N.)

# load tax for Passeriformes filter
tax_path <- "/home/EBDdata/ebird_taxonomy_v2025.csv"




# __________________________________________________________________________
# (one) FILTER - time + footprint + completeness + effort caps + taxonomic order
# --------------------------------------------------------------------------

# Build auk filter  [@key1;@key2] + species
f <- auk_ebd(ebd_path, file_sampling = samp_path, sep = "\t") %>%
  auk_bbox(bbox) %>%
  auk_date(c(date_min, date_max)) %>%
  auk_time(c(time_min, time_max)) %>%
  auk_complete() %>%
  auk_protocol(c("Stationary", "Traveling")) %>%
  auk_duration(c(0, 300)) %>% # min
  auk_distance(c(0, 5)) # km

# clear directory for new sample run 
unlink(out_ebd,  force = TRUE)
unlink(out_samp, force = TRUE)

# Run auk filter
auk_filter(f, file = out_ebd, file_sampling = out_samp, overwrite = TRUE)

# Read filtered results
ebd_raw <- read_ebd(out_ebd,  unique = TRUE)
samp    <- read_sampling(out_samp)

# ---------------------------------
# filter by order

# Read taxonomy table + Select Columns
tax_path <- "/home/EBDdata/ebird_taxonomy_v2025.csv"
tax <- readr::read_csv(tax_path, show_col_types = FALSE) %>%
  select(SCI_NAME, CATEGORY, ORDER)

# Join taxonomy to ebd_raw to get ORDER and CATEGORY fields
ebd <- ebd_raw %>%
  left_join(tax, by = c("scientific_name" = "SCI_NAME")) %>%
  filter(CATEGORY == "species", ORDER == "Passeriformes")


# ___________________________________________________________________
# Step (two) - Join taxonomy to ZF data and filter  @key1
# -------------------------------------------------------------------

# Step 1: Zero-fill to generate detection/non-detection data 

#...... uploading...





# [1]eBird Basic Dataset. Version: ebd_relFeb-2018. Cornell Lab of Ornithology, Ithaca, New York. May 2013.
#     Guillera-Arroita, G., Lahoz-Monfort, J. J., Elith, J., Gordon, A., Kujala, H., Lentini, P. E., McCarthy, M. A., Tingley, R., & Wintle, B. A. (2015). Is my species distribution model fit for purpose? Matching data and models to applications. *Global Ecology and Biogeography, 24*, 276–292.

# [2] Strimas-Mackey, M., Johnston, A., Hochachka, W. M., Ruiz-Gutierrez, V., Robinson, O. J., Miller, E. T., Auer, T., Kelling, S., & Fink, D. (2019, November 16). *eBird Best Practices Workshop*.
