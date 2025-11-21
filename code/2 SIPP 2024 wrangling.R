# DESCRIPTION:
# this file reads in the SIPP subset (variables selected in SIPP subset.do), and exports the SIPP 2024 file for analysis

# load SIPP data and compile statistics for retirement demographics.
rm(list = ls())

###########################
###   Load Packages     ###
###########################
library(haven)
library(dplyr)
library(tidyr)
library(openxlsx)
library(ggplot2)

#################
### Set paths ###
#################

# Define user-specific project directories
project_directories <- list(
  "sarah" = "",
  "your path" = "ENTER-USER-PATH-HERE"
)

# Setting project path based on current user
current_user <- Sys.info()[["user"]]
if (!current_user %in% names(project_directories)) {
  stop("Root folder for current user is not defined.")
}

path_project <- project_directories[[current_user]]
path_data = file.path(path_project, "Data")
path_output = file.path(path_project, "Output")

# Set working directory for SIPP data
setwd(path_data)

#####################
# IDENTIFIERS
# SHHADID - Household address ID. Used to differentiate households spawned from an original sample household.
# SPANEL - Panel year
# SSUID - Sample unit identifier. This identifier is created by scrambling together PSU, Sequence #1, Sequence #2, and the Frame Indicator for a case. It may be used in matching sample units from different waves.
# SWAVE - Wave number of interview
# PNUM - Person number
# MONTHCODE - Value of reference month
# WPFINWGT - Final person weight
# DEMOGRAPHICS -
# TAGE - Age as of last birthday
# EEDUC - What is the highest level of school ... completed or the highest degree received by December of (reference year)?
# ESEX - Sex of this person
# ERACE - What race(s) does ... consider herself/himself to be?
# TMETRO_INTV - metropolitian status for interview address
# LABORFORCE
# EJB1_JBORSE - This variable describes the type of work arrangement, whether work for an employer, self employed or other.Respondents who held a job during the reference month
# EJB1_CLWRK - Class of worker
# INCOME
# TFTOTINC - Sum of monthly earnings and income received by family members age 15 and older, as well as SSI payments received by children under age 15
# TRANSFERS
# for access - 
# EMJOB_401
# EMJOB_IRA
# EMJOB_PEN
# EOWN_THR401
# EOWN_IRAKEO
# EOWN_PENSION
# participation -
# ESCNTYN_401
# matching - 
# EECNTYN_401
####################
#### load data #####
####################

sipp_2024 = read.csv("pu2024.csv") # 2023 simplified dataset from stata export. see "1 SIPP subset.do"

sipp_2024 = sipp_2024 %>%
  filter(MONTHCODE == 12) %>% # Retirement data is collected in December, so we can drop all other months here
  mutate(
    EDUCATION = case_when(
      EEDUC >=31 & EEDUC <= 39 ~ "High School or less",
      EEDUC >= 40 & EEDUC <=42 ~ "Some college",
      EEDUC >= 43 & EEDUC <= 46 ~ "Bachelor's degree or higher",
      TRUE ~ "Missing"
    ),
    SEX = case_when(
      ESEX == 1 ~ "Male",
      ESEX == 2 ~ "Female",
      TRUE ~ "Missing"
    ),
    RACE = case_when(
      ERACE == 1 & EORIGIN ==2 ~ "Non-Hispanic White",
      ERACE == 2 & EORIGIN ==2 ~ "Non-Hispanic Black",
      ERACE == 3 & EORIGIN ==2 ~ "Asian",
      EORIGIN == 1 ~ "Hispanic",
      ERACE == 4 & EORIGIN == 2 ~ "Mixed/Other",
      TRUE ~ "Missing"
    ),
    EMPLOYMENT_TYPE = case_when(
      EJB1_JBORSE == 1 ~ "Employer",
      EJB1_JBORSE == 2 ~ "Self-employed (owns a business)",
      EJB1_JBORSE == 3 ~ "Other work arrangement",
      TRUE ~ "Missing"
    ),
    CLASS_OF_WORKER = case_when(
      EJB1_CLWRK == 1 ~ "Federal government employee",
      EJB1_CLWRK == 2 ~ "Active duty military",
      EJB1_CLWRK == 3 ~ "State government employee",
      EJB1_CLWRK == 4 ~ "Local government employee",
      EJB1_CLWRK == 5 ~ "Employee of a private, for-profit company",
      EJB1_CLWRK == 6 ~ "Employee of a private, not-for-profit company",
      EJB1_CLWRK == 7 ~ "Self-employed in own incorporated business",
      EJB1_CLWRK == 8 ~ "Self-employed in own not incorporated business",
      TRUE ~ "Missing"
    ),
    TOTYEARINC = TPTOTINC*12,
    ANY_RETIREMENT_ACCESS = case_when(
      EMJOB_401 == 1 ~ "Yes", # Any 401k, 403b, 503b, or Thrift Savings Plan account(s) provided through main employer or business during the reference period.
      EMJOB_IRA == 1 ~ "Yes", # Any IRA or Keogh account(s) provided through main employer or business during the reference period.
      EMJOB_PEN == 1 ~ "Yes", # Any defined-benefit or cash balance plan(s) provided through main employer or business during the reference period.
      EMJOB_401 == 2 ~ "No",
      EMJOB_IRA == 2 ~ "No",
      EMJOB_PEN == 2 ~ "No",
      EOWN_THR401  == 2 ~ "No",
      EOWN_IRAKEO  == 2 ~ "No",
      EOWN_PENSION == 2 ~ "No",
      TRUE ~ "Missing"
    ),
    PARTICIPATING = case_when(
      ESCNTYN_401 == 1 ~ "Yes", # During the reference period, respondent contributed to the 401k, 403b, 503b, or Thrift Savings Plan account(s) provided through their main employer or business.
      EECNTYN_401 == 1 ~ "Yes", # if they report having employer matching then we term them as participating 
      ESCNTYN_PEN == 1 ~ "Yes", # During the reference period, respondent contributed to the defined-benefit or cash balance plan(s) provided through their main employer or business.
      ESCNTYN_IRA == 1 ~ "Yes", # During the reference period, respondent contributed to the IRA or Keogh account(s) provided through their main employer or business.
      ESCNTYN_401 == 2 ~ "No",
      ESCNTYN_PEN == 2 ~ "No",
      ESCNTYN_IRA == 2 ~ "No",
      EOWN_THR401  == 2 ~ "No",
      EOWN_IRAKEO  == 2 ~ "No",
      EOWN_PENSION == 2 ~ "No",
      TRUE ~ "Missing"
    ),
    MATCHING = case_when(
      EECNTYN_401 == 1 ~ "Yes", # Main employer or business contributed to respondent's 401k, 403b, 503b, or Thrift Savings Plan account(s) during the reference period.
      EECNTYN_IRA == 1  ~ "Yes", # Main employer or business contributed to respondent's IRA or Keogh account(s) during the reference period.
      EECNTYN_401 == 2 ~ "No",
      EECNTYN_IRA == 2 ~ "No",
      EOWN_THR401  == 2 ~ "No",
      EOWN_IRAKEO  == 2 ~ "No",
      EOWN_PENSION == 2 ~ "No",
      # is.na(EECNTYN_401) ~ "No",
      TRUE ~ "Missing"
    ),
    METRO_STATUS = case_when(
      TMETRO_INTV == 1 ~ "Metropolitan area",
      TMETRO_INTV == 2 ~ "Nonmetropolitan area",
      TMETRO_INTV == 3 ~ "Not identified",
      TRUE ~ NA
    ),
    FULL_PART_TIME = case_when( # Define full time workers as those working at least 35 hours
      TJB1_JOBHRS1 >=35 ~ "full time",
      TJB1_JOBHRS1 >0 & TJB1_JOBHRS1< 35 ~ "part time",
      TRUE ~ NA
    ),
    in_age_range = case_when(
      TAGE >= 18 & TAGE <= 65 ~ "yes",
      TAGE >= 0 & TAGE <= 17 ~ "no",
      TAGE >= 66 & TAGE <= 100 ~ "no",
      TRUE ~ NA 
    ) # 18-65 ages
  )


################################
# filtering
# 18-65 years old (note: keeping in those outside of age group for all worker analysis for RSAA universe)
# Private employees
# Full and part-time workers with non-zero hours worked per week
# Non-zero income
################################

errors = sipp_2024 %>%
  filter(PARTICIPATING == "Missing")

table(sipp_2024$PARTICIPATING)
table(sipp_2024$ANY_RETIREMENT_ACCESS)
table(sipp_2024$MATCHING)

sipp_2024 = sipp_2024 %>%
  filter(EMPLOYMENT_TYPE == "Employer") %>%
  filter(CLASS_OF_WORKER ==  "Employee of a private, for-profit company" | 
           CLASS_OF_WORKER == "Employee of a private, not-for-profit company") %>%
  filter(!is.na(FULL_PART_TIME))  %>%
  filter(TPTOTINC >0)  # earning an income 


# save subset for export
sipp_2024 = sipp_2024 %>%
  select("SHHADID", "SPANEL", "SSUID", "SWAVE", "PNUM", "MONTHCODE", "WPFINWGT",
         "TAGE", "EDUCATION", "SEX", "RACE", "METRO_STATUS",
         "EMPLOYMENT_TYPE", "CLASS_OF_WORKER",
         "TPTOTINC",
         "ANY_RETIREMENT_ACCESS",
         "PARTICIPATING",
         "MATCHING", "MONTHCODE", "TJB1_JOBHRS1", "TOTYEARINC",
         "in_age_range","FULL_PART_TIME", "TVAL_RET")

setwd(path_output)

write.csv(sipp_2024, "sipp_2024_wrangled.csv")
