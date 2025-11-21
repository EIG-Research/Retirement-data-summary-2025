# DESCRIPTION:
# this file produces all of the SIPP-based statistics cited in retirement analysis piece.

# DATA SOURCE: 
# Survey of Income and Program Participation, 2024

rm(list = ls())

###########################
###   Load Packages     ###
###########################

library(haven)
library(dplyr)
library(plotly)
library(tidyr)
library(openxlsx)

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
setwd(path_output)

sipp_2024 = read.csv("sipp_2024_wrangled.csv")

# get labor force estimate
labor_force = haven::read_dta(file.path(path_data,"cps_00066.dta")) %>%
  filter(age >=18 & age<=65) %>%
  filter(classwkr <24 & classwkr >=20) %>%
  filter(inctot > 0) %>%
  mutate(full_time = 1*(uhrswork1 >=35 & uhrswork1 <999),
         part_time = 1*(uhrswork1>0 & uhrswork1<35)) %>%
  summarise(full_time = sum(asecwt*full_time),
            part_time = sum(asecwt*part_time))

full_time = labor_force$full_time[1]
part_time = labor_force$part_time[1]


# RSAA universe
rsaa_labor_force = haven::read_dta(file.path(path_data,"cps_00066.dta")) %>%
  filter(age >=15) %>%
  filter(classwkr <24 & classwkr >=20) %>%
  filter(inctot > 0 & inctot <=42200) %>%
  summarise(workers = sum(asecwt))

rsaa_labor_force = rsaa_labor_force$workers[1]
  
###################################################
## Access, Participation, and Matching - overall ##
###################################################

# to avoid difference in population totals affecting relative shares,
# filter out all of the missings prior to analysis
sipp_2024_analysis = sipp_2024 %>%
  filter(ANY_RETIREMENT_ACCESS!="Missing") %>%
  filter(PARTICIPATING!="Missing") %>%
  filter(MATCHING!="Missing")
  


# access
access_full_share = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  rename(`Has access to an Employer Retirement Plan`=ANY_RETIREMENT_ACCESS) %>%
  group_by(`Has access to an Employer Retirement Plan`) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100) %>%
  filter(`Has access to an Employer Retirement Plan`=="No") %>%
  select(Share)

access_full_share = access_full_share$Share[1]

access_part_share = sipp_2024_analysis %>% # full and part time workers
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="part time") %>%
  rename(`Has access to an Employer Retirement Plan`=ANY_RETIREMENT_ACCESS) %>%
  group_by(`Has access to an Employer Retirement Plan`) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100) %>%
  filter(`Has access to an Employer Retirement Plan`=="No") %>%
  select(Share)

access_part_share = access_part_share$Share[1]


# participation

participate_full_share = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  rename(`Participates in Employer Retirement Plan` = PARTICIPATING) %>%
  group_by(`Participates in Employer Retirement Plan`) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100) %>%
  filter(`Participates in Employer Retirement Plan` == "No") %>%
  select(Share)

participate_full_share = participate_full_share$Share[1]

participate_part_share = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="part time") %>%
  rename(`Participates in Employer Retirement Plan` = PARTICIPATING) %>%
  group_by(`Participates in Employer Retirement Plan`) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100) %>%
  filter(`Participates in Employer Retirement Plan` == "No") %>%
  select(Share)

participate_part_share = participate_part_share$Share[1]


# matching

match_full_share = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  rename(`Employer contributes to Employer Retirement Plan`=MATCHING) %>%
  group_by(`Employer contributes to Employer Retirement Plan`) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100) %>%
  filter(`Employer contributes to Employer Retirement Plan`=="No") %>%
  select(Share)

match_full_share = match_full_share$Share[1]

match_part_share = sipp_2024_analysis %>% # full and part time workers
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="part time") %>%
  rename(`Employer contributes to Employer Retirement Plan`=MATCHING) %>%
  group_by(`Employer contributes to Employer Retirement Plan`) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100) %>%
  filter(`Employer contributes to Employer Retirement Plan`=="No") %>%
  select(Share)

match_part_share = match_part_share$Share[1]


#######
# based on labor force estimates --
print("total full time workers without matching")
match_full_count = round(match_full_share/100*full_time,1)

print("total full time workers without access")
access_full_count = round(access_full_share/100*full_time,1)

print("total full time workers not participating")
participate_full_count = round(participate_full_share/100*full_time,1)

print("part-time workers without access")
access_part_count = round(access_part_share/100*part_time,1)

print("part-time workers without matching")
match_part_count = round(match_part_share/100*part_time,1)

print("part-time workers not participating")
participate_part_count = round(participate_part_share/100*part_time,1)


# combine into dataframe
table_topline <- data.frame(
  `SIPP 2024` = c("Full time workers", "Part time workers", "Full time share", "Part time share"),
  `Lacks Access` = c(access_full_count, access_part_count, access_full_share, access_part_share),
  `Lacks Matching` = c(match_full_count, match_part_count, match_full_share, match_part_share),
  `Not Participating` = c(participate_full_count, participate_part_count, participate_full_share, participate_part_share)
)

setwd(path_output)
write.csv(table_topline, "topline_table.csv")

######################################################################
## Access, Participation, Matching - by income deciles (unweighted) ##
######################################################################

ACCESS_decile = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  mutate(INCOME_DECILE = ntile(TPTOTINC, 10)) %>%
  filter(FULL_PART_TIME=="full time") %>%
  group_by(ANY_RETIREMENT_ACCESS, INCOME_DECILE) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(INCOME_DECILE) %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count)) %>%
  pivot_wider(names_from = INCOME_DECILE,
              values_from = "Share")


PARTICIPATE_decile = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  mutate(INCOME_DECILE = ntile(TPTOTINC, 10)) %>%
  group_by(PARTICIPATING, INCOME_DECILE) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(INCOME_DECILE) %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count))%>%
  pivot_wider(names_from = INCOME_DECILE,
              values_from = "Share")


MATCH_decile = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  mutate(INCOME_DECILE = ntile(TPTOTINC, 10)) %>%
  group_by(MATCHING, INCOME_DECILE) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(INCOME_DECILE) %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count))%>%
  pivot_wider(names_from = INCOME_DECILE,
              values_from = "Share")

# export for plotting
write.xlsx(ACCESS_decile, paste(path_output, "ACCESS_decile.xlsx", sep = "/"))
write.xlsx(PARTICIPATE_decile, paste(path_output, "PARTICIPATE_decile.xlsx", sep = "/"))
write.xlsx(MATCH_decile, paste(path_output, "MATCH_decile.xlsx", sep = "/"))


# display the deciles (these are monthly earnings)
earning_Deciles = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  mutate(INCOME_DECILE = ntile(TPTOTINC, 10)) %>%
  ungroup() %>%
  group_by(INCOME_DECILE) %>%
  mutate(val = max(TPTOTINC,na.rm=TRUE)) %>%
  select(val, INCOME_DECILE)

earning_Deciles = unique(earning_Deciles) %>% arrange(INCOME_DECILE) %>%
  mutate(annual = val*12)
earning_Deciles


# access -- top and bottom 50%
sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  mutate(INCOME_DECILE = ntile(TPTOTINC, 2)) %>%
  filter(FULL_PART_TIME=="full time") %>%
  group_by(ANY_RETIREMENT_ACCESS, INCOME_DECILE) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(INCOME_DECILE) %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count))  %>%
  pivot_wider(names_from = INCOME_DECILE,
              values_from = "Share")



########################################
## matching conditional on participating

# for the lowest decile.
sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  filter(PARTICIPATING =="Yes") %>%
  filter(TPTOTINC <=2199) %>%
  rename(`Employer contributes to Employer Retirement Plan`=MATCHING) %>%
  group_by(`Employer contributes to Employer Retirement Plan`) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100)


# for the highest decile.
sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  filter(PARTICIPATING =="Yes") %>%
  filter(TPTOTINC >14525) %>%
  rename(`Employer contributes to Employer Retirement Plan`=MATCHING) %>%
  group_by(`Employer contributes to Employer Retirement Plan`) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count))




###############################
## Matching - by race x edu ##
###############################

MATCH_race_edu <- sipp_2024_analysis %>% 
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  group_by(MATCHING, RACE, EDUCATION) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(RACE, EDUCATION) %>%
  mutate(Share = 100*round(count / sum(count),3)) %>%
  select(-c(count))

# education overall.
MATCH_race_edu_overall <- sipp_2024_analysis %>% 
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  group_by(MATCHING, RACE) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(RACE) %>%
  mutate(Share = 100*round(count / sum(count),3)) %>%
  select(-c(count)) %>%
  mutate(EDUCATION = "Overall")

MATCH_race_edu = rbind(MATCH_race_edu, MATCH_race_edu_overall)

MATCH_race_edu = MATCH_race_edu %>% filter(RACE!="Mixed/Other") %>%
  mutate(MATCHING = case_when(
    MATCHING =="Yes" ~ "Has Matching",
    MATCHING =="No" ~ "Lacks Matching"
  )) %>%
  mutate(label = ifelse(MATCHING == "Has Matching", Share, NA)) %>%
  mutate(order = case_when(
    EDUCATION == "Overall" ~ 1,
    EDUCATION == "High School or less" ~ 2,
    EDUCATION == "Some college" ~ 3,
    EDUCATION == "Bachelor's degree or higher" ~ 4
  )) %>%
  mutate(EDUCATION = ifelse(EDUCATION == "Bachelor's degree or higher","BA+",EDUCATION),
         EDUCATION = ifelse(EDUCATION == "High School or less" , "HS or less",EDUCATION)) %>%
  arrange(RACE, order, MATCHING)

write.xlsx(MATCH_race_edu,
           paste(path_output, "race_education_plot.xlsx",sep="/"))


# save individual plots for datawrapper. keep
unique(MATCH_race_edu$RACE)
MATCH_asian_edu =MATCH_race_edu %>% filter(RACE=="Asian") %>%
  select(EDUCATION, MATCHING, Share) %>% pivot_wider(names_from = EDUCATION, values_from = Share)
MATCH_hispan_edu =MATCH_race_edu %>% filter(RACE=="Hispanic") %>%
  select(EDUCATION, MATCHING, Share) %>% pivot_wider(names_from = EDUCATION, values_from = Share)
MATCH_black_edu =MATCH_race_edu %>% filter(RACE=="Non-Hispanic Black") %>%
  select(EDUCATION, MATCHING, Share) %>% pivot_wider(names_from = EDUCATION, values_from = Share)
MATCH_white_edu =MATCH_race_edu %>% filter(RACE=="Non-Hispanic White") %>%
  select(EDUCATION, MATCHING, Share) %>% pivot_wider(names_from = EDUCATION, values_from = Share)

write.xlsx(MATCH_asian_edu, paste(path_output, "asian_education_plot.xlsx",sep="/"))
write.xlsx(MATCH_hispan_edu, paste(path_output, "hispan_education_plot.xlsx",sep="/"))
write.xlsx(MATCH_black_edu, paste(path_output, "black_education_plot.xlsx",sep="/"))
write.xlsx(MATCH_white_edu, paste(path_output, "white_education_plot.xlsx",sep="/"))




# by edu only
sipp_2024_analysis %>% 
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  group_by(MATCHING, EDUCATION) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(EDUCATION) %>%
  mutate(hare = round(count / sum(count)*100,1)) %>%
  select(-c(count))

# by race only
sipp_2024_analysis %>% 
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  group_by(MATCHING, RACE) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(RACE) %>%
  mutate(Share = round(count / sum(count)*100,1)) %>%
  select(-c(count))


# R ggplot bar graphs for matching
MATCH_race_edu %>%
  ggplot(aes(fill=MATCHING, y=Share, x=reorder(EDUCATION,order))) + 
  geom_bar(position="stack", stat="identity") +
  facet_wrap(~RACE) +
  labs(title = "Matching by Race and Education, 2023") +
  theme_classic() +
  theme(plot.title = element_text(face = "bold", color = "#1a654d"),
        legend.position = "top",
        legend.title= element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = element_text(size = 7),
        axis.text.y = element_blank(),
        legend.text=element_text(size=7)) +
  scale_fill_manual(values = c("#e1ad28","#b3d6dd")) +
  geom_text(aes(label = scales::percent(round(label/100,3)),accuracy = 1L),vjust = 1.2,size=2.5)



###############################################
## Matching, Participation, Access - by sex ##
###############################################

sipp_2024_analysis %>% 
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  group_by(ANY_RETIREMENT_ACCESS, SEX) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(SEX) %>%
  mutate(Share = round(count / sum(count)*100,1)) %>%
  select(-c(count)) %>%
  filter(ANY_RETIREMENT_ACCESS == "No") %>%
  pivot_wider(names_from = SEX,
              values_from = Share) %>%
  mutate(`Female - Male Participating Gap` = Female - Male)


sipp_2024_analysis %>% 
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  group_by(PARTICIPATING, SEX) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(SEX) %>%
  mutate(Share = round(count / sum(count)*100,1)) %>%
  select(-c(count)) %>%
  pivot_wider(names_from = SEX,
              values_from = Share) %>%
  mutate(`Female - Male Participating Gap` = Female - Male)

sipp_2024_analysis %>% 
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  group_by(MATCHING, SEX) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(SEX) %>%
  mutate(Share = round(count / sum(count)*100,1)) %>%
  select(-c(count)) %>%
  pivot_wider(names_from = SEX,
              values_from = Share) %>%
  mutate(`Female - Male Participating Gap` = Female - Male)


#gap by low education level
sipp_2024_analysis %>% 
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  filter(EDUCATION == "High School or less") %>%
  group_by(ANY_RETIREMENT_ACCESS, SEX) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(SEX) %>%
  mutate(Share = round(count / sum(count)*100,1)) %>%
  select(-c(count)) %>%
  pivot_wider(names_from = SEX,
              values_from = Share) %>%
  mutate(`Female - Male Participating Gap` = Female - Male)


sipp_2024_analysis %>% 
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  filter(EDUCATION == "High School or less") %>%
  group_by(PARTICIPATING, SEX) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(SEX) %>%
  mutate(Share = round(count / sum(count)*100,1)) %>%
  select(-c(count)) %>%
  pivot_wider(names_from = SEX,
              values_from = Share) %>%
  mutate(`Female - Male Participating Gap` = Female - Male)

sipp_2024_analysis %>% 
  filter(in_age_range =="yes") %>%
  filter(FULL_PART_TIME=="full time") %>%
  filter(EDUCATION == "High School or less") %>%
  group_by(MATCHING, SEX) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  group_by(SEX) %>%
  mutate(Share = round(count / sum(count)*100,1)) %>%
  select(-c(count)) %>%
  pivot_wider(names_from = SEX,
              values_from = Share) %>%
  mutate(`Female - Male Participating Gap` = Female - Male)


##########
## RSAA ##
##########
# $42,200 is median income for 16+ workers, full & part time.

rsaa_labor_force
# how many earning < $42,200 have access to retirement plan?
sipp_2024_analysis %>%
  filter(TPTOTINC < 42200/12) %>%
  filter(TAGE>15) %>% # including those outside of the 18-65 age range
  group_by(ANY_RETIREMENT_ACCESS) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count))

# number:
0.794*(rsaa_labor_force)


# lack access & eligible here
sipp_2024_analysis %>%
  filter(TAGE>15) %>% 
  mutate(`eligible with no access` =
           case_when(
             TPTOTINC < 42200/12 & ANY_RETIREMENT_ACCESS == "No" ~ "eligible",
             TRUE ~ "not eligible"
           )) %>%
  group_by(`eligible with no access`) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count))

###############################
## Inclusive Wealth Building ##
###############################

# lowest 20%

ACCESS_lowest_20 = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  mutate(INCOME_DECILE = ntile(TPTOTINC, 5)) %>%
  group_by(ANY_RETIREMENT_ACCESS, INCOME_DECILE) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>% group_by(INCOME_DECILE) %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count)) %>% filter(INCOME_DECILE == 1) %>%
  filter(ANY_RETIREMENT_ACCESS=="Yes")

ACCESS_lowest_20 = ACCESS_lowest_20$Share[1]


PARTICIPATE_lowest_20 = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  mutate(INCOME_DECILE = ntile(TPTOTINC, 5)) %>%
  group_by(PARTICIPATING, INCOME_DECILE) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%  group_by(INCOME_DECILE) %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count)) %>% filter(INCOME_DECILE == 1) %>%
  filter(PARTICIPATING=="Yes")

PARTICIPATE_lowest_20 = PARTICIPATE_lowest_20$Share[1]


MATCH_lowest_20 = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  mutate(INCOME_DECILE = ntile(TPTOTINC, 5)) %>%
  group_by(MATCHING, INCOME_DECILE) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>% group_by(INCOME_DECILE) %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count)) %>%  filter(INCOME_DECILE == 1) %>%
  filter(MATCHING == "Yes")

MATCH_lowest_20 = MATCH_lowest_20$Share[1]

# total
ACCESS_overall = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  group_by(ANY_RETIREMENT_ACCESS) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>% 
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count)) %>% 
  filter(ANY_RETIREMENT_ACCESS=="Yes")
ACCESS_overall = ACCESS_overall$Share[1]

PARTICIPATE_overall = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  group_by(PARTICIPATING) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count)) %>% 
  filter(PARTICIPATING=="Yes")

PARTICIPATE_overall = PARTICIPATE_overall$Share[1]


MATCH_overall = sipp_2024_analysis %>%
  filter(in_age_range =="yes") %>%
  group_by(MATCHING) %>%
  summarise(count = sum(WPFINWGT)) %>%
  ungroup() %>%
  mutate(Share = count / sum(count)*100) %>%
  select(-c(count)) %>%
  filter(MATCHING == "Yes")

MATCH_overall = MATCH_overall$Share[1]


table = data.frame(
  income = c("Low-income","All workers"),
  Access = c(ACCESS_lowest_20,ACCESS_overall),
  Participation = c(PARTICIPATE_lowest_20,PARTICIPATE_overall),
  `Matching benefits` = c(MATCH_lowest_20,MATCH_overall)
)

setwd(path_output)
write.csv(table, "iwb_chart.csv")

