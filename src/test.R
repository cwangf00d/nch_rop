# install packages
options(repos = c(CRAN = "https://cloud.r-project.org"))
install.packages("Rcpp")
install.packages("stringfish")
install.packages("qs")
install.packages("data.table")
install.packages("lubridate")
# loading in
suppressPackageStartupMessages(library(qs))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(lubridate))

# setup
setwd("/n/data2/hms/dbmi/beamlab/nch_rop")
von_note <- read.csv("ROP_Data_Batch1b/VON_Stage_Note_Level_20230406.csv")  # has all the specific notes + times
print(head(von_note))
print("hi")