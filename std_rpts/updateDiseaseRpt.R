library(RMySQL)
library(plyr)

# set working directory to the directory where this script is saved
script.dir <- dirname(sys.frame(1)$ofile)
setwd(script.dir)
rm(script.dir)

con <- dbConnect(MySQL(), 
                 user="", password="", 
                 dbname="", host="")

# country-level query
query <- 
  "SELECT country, disease, workbook_year, project,
MAX(persons_treated_all) AS persons_treated_all,
MAX(persons_treated_usaid) AS persons_treated_usaid, 
MAX(districts_stop_mda) AS districts_stop_mda, 
MAX(districts_stop_mda_tra) AS districts_stop_mda_tra, 
MAX(pop_stop_mda_tra) AS pop_stop_mda_tra,
MAX(pop_stop_mda) AS pop_stop_mda, 
MAX(districts_treated_usaid) AS districts_treated_usaid

FROM
(SELECT
country_desc as 'country', disease, workbook_year, project,
CASE WHEN indicator = 'ppl_treated_all_num' THEN value_num END AS persons_treated_all,
CASE WHEN indicator = 'ppl_treated_usaid_num' THEN value_num END AS persons_treated_usaid,
CASE WHEN indicator = 'ci_diseasedist_dist_crit_stop_mda_achiv_num' THEN value_num END AS districts_stop_mda, 
CASE WHEN indicator = 'achieved_uig_subdist_lev_mda_pop' THEN value_num END AS districts_stop_mda_tra,
CASE WHEN indicator = 'achieved_uig_subdist_lev_mda_pop' THEN value_num END AS pop_stop_mda_tra,
CASE WHEN indicator = 'ppl_achieved_crit_stop_mda_num' THEN value_num END AS pop_stop_mda, 
CASE WHEN indicator = 'ci_districts_treated_usaid' THEN value_num END AS districts_treated_usaid

FROM reporting_values_country
WHERE most_recent_submission_f = 1 
AND indicator IN ('ppl_treated_all_num', 'ppl_treated_usaid_num', 'ci_diseasedist_dist_crit_stop_mda_achiv_num', 
'achieved_uig_subdist_lev_mda_pop', 'ppl_achieved_crit_stop_mda_num', 'ci_districts_treated_usaid') 
AND reporting_period <> 'work_planning')x
GROUP BY country, disease, workbook_year
ORDER BY country, disease, workbook_year;"

rs <- dbSendQuery(con, query)
rm(query)

data <- dbFetch(rs, n = -1)
check <- dbHasCompleted(rs)

dbClearResult(rs)

data[data$workbook_year < 2012, "project"] <- "NTD Control Program"

countries <- unique(data$country)
years <- c(2012, 2013, 2014)
for(c in countries){
  for(y in years){
    data[data$country == c & data$workbook_year == y & data$disease == "at_least_one_ntd", "project"] <- 
      unique(data[data$country == c & data$workbook_year == y & data$disease != "at_least_one_ntd", "project"])
  }
}

# update districts stop-MDA trachoma flag
data[data$districts_stop_mda_tra > 0 & !is.na(data$districts_stop_mda_tra), "districts_stop_mda_tra"] <- 1

# merge trachoma stop-MDA (districts) into same column as other diseases
data[data$disease == "trachoma", "districts_stop_mda"] <- data[data$disease == "trachoma", "districts_stop_mda_tra"]

# merge trachoma stop-MDA (pop) into same column as other diseases
data[data$disease == "trachoma", "pop_stop_mda"] <- data[data$disease == "trachoma", "pop_stop_mda_tra"]

# write country-level dataset to csv
write.csv(data, 'disease-rpt/data/country.csv')


# aggregate data by project
project <- ddply(data, c('project', 'disease', 'workbook_year'), summarize, 
                 persons_treated_all = sum(persons_treated_all), 
                 persons_treated_usaid = sum(persons_treated_usaid), 
                 districts_treated_usaid = sum(districts_treated_usaid),
                 districts_stop_mda = sum(districts_stop_mda), 
                 districts_stop_mda_tra = sum(districts_stop_mda_tra), 
                 pop_stop_mda_tra = sum(pop_stop_mda_tra), 
                 pop_stop_mda = sum(pop_stop_mda))

data <- data[data$persons_treated_usaid > 0, ]

# aggregate data by portfolio
portfolio <- ddply(data, c('disease', 'workbook_year'), summarize, 
                   persons_treated_usaid = sum(persons_treated_usaid), 
                   districts_treated_usaid = sum(districts_treated_usaid), 
                   districts_stop_mda = sum(districts_stop_mda), 
                   pop_stop_mda = sum(pop_stop_mda))

write.csv(project, 'disease-rpt/data/project.csv')  
write.csv(portfolio, 'disease-rpt/data/portfolio.csv') 
rm(data, project, portfolio)

# region-level SQL query

query <- 
  "SELECT country, region, disease, workbook_year, project,
MAX(persons_treated_all) AS persons_treated_all,
MAX(persons_treated_usaid) AS persons_treated_usaid, 
MAX(districts_stop_mda) AS districts_stop_mda, 
MAX(districts_stop_mda_tra) AS districts_stop_mda_tra, 
MAX(pop_stop_mda_tra) AS pop_stop_mda_tra,
MAX(pop_stop_mda) AS pop_stop_mda, 
MAX(districts_treated_usaid) AS districts_treated_usaid

FROM
(SELECT
country_desc as 'country', region_desc as 'region', disease, workbook_year, project,
CASE WHEN indicator = 'ppl_treated_all_num' THEN value_num END AS persons_treated_all,
CASE WHEN indicator = 'ppl_treated_usaid_num' THEN value_num END AS persons_treated_usaid,
CASE WHEN indicator = 'ci_diseasedist_dist_crit_stop_mda_achiv_num' THEN value_num END AS districts_stop_mda, 
CASE WHEN indicator = 'achieved_uig_subdist_lev_mda_pop' THEN value_num END AS districts_stop_mda_tra,
CASE WHEN indicator = 'achieved_uig_subdist_lev_mda_pop' THEN value_num END AS pop_stop_mda_tra,
CASE WHEN indicator = 'ppl_achieved_crit_stop_mda_num' THEN value_num END AS pop_stop_mda, 
CASE WHEN indicator = 'ci_districts_treated_usaid' THEN value_num END AS districts_treated_usaid

FROM reporting_values_region
WHERE most_recent_submission_f = 1 
AND indicator IN ('ppl_treated_all_num', 'ppl_treated_usaid_num', 'achieved_uig_subdist_lev_mda_pop', 
'ci_diseasedist_dist_crit_stop_mda_achiv_num', 'ppl_achieved_crit_stop_mda_num', 'ci_districts_treated_usaid') 
AND reporting_period <> 'work_planning')x
GROUP BY country, region, disease, workbook_year
ORDER BY country, region, disease, workbook_year;"

rs <- dbSendQuery(con, query)
rm(query)

data <- dbFetch(rs, n = -1)
check <- dbHasCompleted(rs)
dbClearResult(rs)

# update districts stop-MDA trachoma flag
data[data$districts_stop_mda_tra > 0 & !is.na(data$districts_stop_mda_tra), "districts_stop_mda_tra"] <- 1

# merge trachoma stop-MDA (districts) into same column as other diseases
data[data$disease == "trachoma", "districts_stop_mda"] <- data[data$disease == "trachoma", "districts_stop_mda_tra"]

# merge trachoma stop-MDA (pop) into same column as other diseases
data[data$disease == "trachoma", "pop_stop_mda"] <- data[data$disease == "trachoma", "pop_stop_mda_tra"]

# write region-level data to csv
write.csv(data, 'disease-rpt/data/region.csv')
rm(data)


# district-level SQL query

query <- 
  "SELECT country, region, district, disease, workbook_year, 
MAX(persons_treated_all) AS persons_treated_all,
MAX(persons_treated_usaid) AS persons_treated_usaid, 
MAX(districts_stop_mda) AS districts_stop_mda, 
MAX(districts_stop_mda_tra) AS districts_stop_mda_tra, 
MAX(pop_stop_mda_tra) AS pop_stop_mda_tra,
MAX(pop_stop_mda) AS pop_stop_mda, 
MAX(districts_treated_usaid) AS districts_treated_usaid

FROM
(SELECT
country_desc as 'country', region_desc as 'region', district_desc as 'district', disease, workbook_year, 
CASE WHEN indicator = 'ppl_treated_all_num' THEN value_num END AS persons_treated_all,
CASE WHEN indicator = 'ppl_treated_usaid_num' THEN value_num END AS persons_treated_usaid,
CASE WHEN indicator = 'ci_diseasedist_dist_crit_stop_mda_achiv_num' THEN value_num END AS districts_stop_mda, 
CASE WHEN indicator = 'achieved_uig_subdist_lev_mda_pop' THEN value_num END AS districts_stop_mda_tra,
CASE WHEN indicator = 'achieved_uig_subdist_lev_mda_pop' THEN value_num END AS pop_stop_mda_tra,
CASE WHEN indicator = 'ppl_achieved_crit_stop_mda_num' THEN value_num END AS pop_stop_mda, 
CASE WHEN indicator = 'ci_districts_treated_usaid' THEN value_num END AS districts_treated_usaid

FROM reporting_values
WHERE most_recent_submission_f = 1 
AND indicator IN ('ppl_treated_all_num', 'ppl_treated_usaid_num', 'achieved_uig_subdist_lev_mda_pop',  
'ci_diseasedist_dist_crit_stop_mda_achiv_num', 'ppl_achieved_crit_stop_mda_num', 'ci_districts_treated_usaid') 
AND reporting_period <> 'work_planning')x
GROUP BY country, region, district, disease, workbook_year;"

rs <- dbSendQuery(con, query)
rm(query)

data <- dbFetch(rs, n = -1)
check <- dbHasCompleted(rs)
dbClearResult(rs)

# update districts stop-MDA trachoma flag
data[data$districts_stop_mda_tra > 0 & !is.na(data$districts_stop_mda_tra), "districts_stop_mda_tra"] <- 1

# merge trachoma stop-MDA (districts) into same column as other diseases
data[data$disease == "trachoma", "districts_stop_mda"] <- data[data$disease == "trachoma", "districts_stop_mda_tra"]

# merge trachoma stop-MDA (pop) into same column as other diseases
data[data$disease == "trachoma", "pop_stop_mda"] <- data[data$disease == "trachoma", "pop_stop_mda_tra"]

# write district-level data to csv
write.csv(data, 'disease-rpt/data/district.csv')
rm(data)


dbDisconnect(con)
rm(con, check, rs, c, y, years, countries)