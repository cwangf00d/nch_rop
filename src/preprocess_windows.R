# # install packages
# options(repos = c(CRAN = "https://cloud.r-project.org"))
# install.packages("qs")
# install.packages("tidyverse")
# install.packages("data.table") # Note: 'magrittr' is already included in 'tidyverse'
# install.packages("lubridate")

# loading in
suppressPackageStartupMessages(library(qs))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(lubridate))

# set the working directory and baseline date
setwd("/n/data2/hms/dbmi/beamlab/nch_rop")
baseline_date <- as.Date("2000-01-01")

# exam notes
von_note <- fread("ROP_Data_Batch1b/VON_Stage_Note_Level_20230406.csv")
comp_von <- von_note[IS_NOTE_COMPLETE == 'Y']
comp_von[, TIME := baseline_date + days(NOTE_DAY) + hms(NOTE_TIME)]

# patient ids
filenames <- list.files("export_deid_files/")
patients <- gsub("monitor_enc_([0-9]+)\\.qs", "\\1", filenames)
enc_files_path = "/n/data2/hms/dbmi/beamlab/nch_rop/export_deid_files/monitor_enc_"

# processing windows for each patient
process_patient <- function(enc_id) {
  mon_enc <- qread(paste0(enc_files_path, enc_id, ".qs"))
  setDT(mon_enc)
  mon_enc[, TIME := baseline_date + days(RECORDED_DAY) + hms(RECORDED_TIME)]

  sub_von <- comp_von[ENC_ID == enc_id]

  windows_df <- data.table()
  for (i in 1:nrow(sub_von)) {
    ub_win <- sub_von[i, TIME] + hours(12)
    lb_win <- sub_von[i, TIME] - hours(12)
    win <- mon_enc[TIME < ub_win & TIME > lb_win]
    win[, WINDOW := i]
    win[, ROP_STAGE := sub_von[i, ROP_STAGE_BY_ASSESS]]
    windows_df <- rbindlist(list(windows_df, win), use.names = TRUE)
  }
  return(windows_df)
}

# iterate through patients
result <- lapply(patients, process_patient)  # Adjust the range as needed

# combine + save
final_result <- rbindlist(result, use.names = TRUE)
fwrite(final_result, file = "/n/data2/hms/dbmi/beamlab/cindy/nch_rop/data/processed/enc_24h_windows.csv")

# # variables + dataframes
# baseline_date <- as.Date("2000-01-01")
# von_note <- read.csv("ROP_Data_Batch1b/VON_Stage_Note_Level_20230406.csv")  # has all the specific notes + times
# comp_von <- subset(von_note, IS_NOTE_COMPLETE == 'Y')
# comp_von <- comp_von %>% mutate(TIME = baseline_date + days(NOTE_DAY) + hms(NOTE_TIME))
#
# # iteration
# enc_files_path = "/Users/cindywang/PycharmProjects/nch_rop/data/export_deid_files/monitor_enc_"
# windows_df <- data.frame()
# patients = gsub("monitor_enc_([0-9]+)\\.qs", "\\1", filenames)
# for (enc_id in patients) {
#   # extracting patient file
#   mon_enc <- qread(paste(enc_files_path, enc_id, ".qs", sep=""))
#   # transform time dimension
#   mon_enc <- mon_enc %>% mutate(TIME = baseline_date + days(RECORDED_DAY) + hms(RECORDED_TIME))
#   sub_von <- filter(comp_von, ENC_ID == curr_enc)
#   num_exams <- dim(sub_von)[1]
#   for (i in 1:2) {
#     ub_win <- sub_von[i,]$TIME + hours(12)
#     lb_win <- sub_von[i,]$TIME - hours(12)
#     win <- subset(mon_enc, TIME < ub_win & TIME > lb_win)
#     win <- win %>% mutate(WINDOW = i, ROP_STAGE = sub_von[i,]$ROP_STAGE_BY_ASSESS)
#     windows_df <- rbind(windows_df, win)
#   }
# }
# write.csv(windows_df, file = "processed/enc_24h_windows.csv", row.names = FALSE)