

# appendix table

rm(list = ls())

###########################
###   Load Packages     ###
###########################

library(dplyr)
library(tidyr)
library(openxlsx)
library(haven)

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



################################
# national compensation survey #
################################

ncs = read_excel(file.path(path_data, "employee-benefits-in-the-united-states-march-2024", "march-2024-all-data.xlsx"),
                 sheet = "All data") %>%
filter(
  `Characteristic category` == "All workers",
  `Occupation` == "All occupations",
  `Estimate category` == "Retirement benefits",
  `Industry` == "All industries",
  `Ownership` == "Private industry workers",
  `Datatype` %in% c("Access rate", "Participation rate"),
  `Provision` %in% c("Participation rate for all retirement benefits", "Access to all retirement benefits")
  ) %>%
  select(Datatype, Estimate) %>%
  mutate(IDCol = ifelse(Datatype == "Access rate", "Retirement Plan Access", "Retirement Plan Participation"),
         `National Compensation Survey` = paste0(Estimate, ".0%")) %>%
  select(IDCol, `National Compensation Survey`)

ncs = bind_rows(
    data_frame(
      `IDCol` = c("Survey Type", "Survey Scope", "Survey Frequency"),
      `National Compensation Survey` = c("Establishment Survey", "1989-2025", "Annual")
    ), 
    ncs
  )


#############################
# Current Population Survey #
#############################

cps = read_dta(file.path(path_data, "cps_00066.dta")) %>%
filter(age >=18 & age<=65) %>%
  filter(classwkr <24 & classwkr >=20) %>%
  filter(inctot > 0) %>%
  filter(uhrswork1 >=35 & uhrswork1 <999) %>%
  mutate(has_access = ifelse(pension ==2 | pension ==3, 1,0),
         is_participating = ifelse(pension == 3, 1, 0)
         ) %>%
  ungroup() %>% summarise(`Retirement Plan Access` = paste0(round(100*weighted.mean(has_access, w = asecwt),1),"%"),
                          `Retirement Plan Participation` = paste0(round(100*weighted.mean(is_participating, w = asecwt, na.rm = TRUE),1), "%")) %>%
  pivot_longer(cols = c(`Retirement Plan Access`, `Retirement Plan Participation`),
                        names_to = "IDCol", values_to = "Current Population Survey: Annual Social and Economic Suplement")
  
  
cps = bind_rows(
  data_frame(
    `IDCol` = c("Survey Type", "Survey Scope", "Survey Frequency"),
    `Current Population Survey: Annual Social and Economic Suplement` = c("Household Survey", "1969-2024", "Annual")
  ), 
  cps
)


###############################
# Survey of Consumer Finances #
###############################

# most recent data is from 2022.
scf = read_dta(file.path(path_data, "p22i6.dta")) %>%
  rename(age = x14, wgt = x42001) %>%
  mutate(full_time = ifelse(x4511==1, 1, 0),
         part_time = ifelse(x4511==2, 1, 0),
         non_government = ifelse(x7402 < 9370, 1, 0),
         receives_benefits = ifelse(
           x11032>0 | x11132>0 | x11332>0 | x11432>0 | x11032==-1 | x11132==-1 | 
             x11332==-1 | x11432==-1 | (x5316==1 & x6461==1) | (x5324==1 & x6466==1) | 
             (x5332==1 & x6471==1) | (x5416==1 & x6476==1),
           1, 0),
         plan_available = ifelse(receives_benefits == 1 | x4136==1, 1, 0),
         receives_contributions = ifelse(x11047==1 | x11147==1, 1, 0)) %>%
  filter(age >=18 & age <=65) %>% 
  filter(non_government == 1 & full_time == 1) %>%
  ungroup() %>%
  summarise(
    `Retirement Plan Access` = paste0(round(100*weighted.mean(plan_available, w = wgt),1), "%"),
    `Retirement Plan Participation` = paste0(round(100*weighted.mean(receives_benefits, w = wgt),1), "%"),
    `Employer Matches Contribution` = paste0(round(100*weighted.mean(receives_contributions, w = wgt),1), "%")
  )

scf = scf %>% pivot_longer(cols = names(scf), names_to = "IDCol", values_to = "Survey of Consumer Finances")

scf = bind_rows(
  data_frame(
    `IDCol` = c("Survey Type", "Survey Scope", "Survey Frequency"),
    `Survey of Consumer Finances` = c("Household Survey", "2010-2022", "Triannual")
  ), 
  scf
)

##############################################
# Survey of Income and Program Participation #
##############################################

sipp = read.csv(file.path(path_output, "sipp_2024_wrangled.csv")) %>%
  filter(ANY_RETIREMENT_ACCESS!="Missing") %>%
  filter(PARTICIPATING!="Missing") %>%
  filter(MATCHING!="Missing") %>%
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  mutate(access = ifelse(ANY_RETIREMENT_ACCESS == "Yes", 1, 0),
         participate = ifelse(PARTICIPATING == "Yes", 1, 0),
         match = ifelse(MATCHING == "Yes", 1,0)) %>%
  ungroup() %>%
  summarise(`Retirement Plan Access` = paste0(round(100*weighted.mean(access, w = WPFINWGT),1), "%"),
            `Retirement Plan Participation` = paste0(round(100*weighted.mean(participate, w = WPFINWGT),1), "%"),
            `Employer Matches Contribution`  = paste0(round(100*weighted.mean(match, w = WPFINWGT),1), "%")
            )

sipp = sipp %>%
  pivot_longer(cols = names(sipp), names_to = "IDCol", values_to = "Survey of Income and Program Participation")


sipp = bind_rows(
  data_frame(
    `IDCol` = c("Survey Type", "Survey Scope", "Survey Frequency"),
    `Survey of Income and Program Participation` = c("Household Survey", "1983-2023", "Annual")
  ), 
  sipp
)


# Combine final table
table = ncs %>% full_join(cps) %>% full_join(scf) %>% full_join(sipp)
setwd(path_output)
write.xlsx(table, "methodology_table.xlsx")
