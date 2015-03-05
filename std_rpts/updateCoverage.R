library(RMySQL)

# set working directory to the directory where this script is saved
script.dir <- dirname(sys.frame(1)$ofile)
setwd(script.dir)
rm(script.dir)

con <- dbConnect(MySQL(), 
                 user="envision", password="envisionRead!C4eMfw", 
                 dbname="ntd", host="productionread.c6u52zchwjde.us-east-1.rds.amazonaws.com")

query <- 
  "SELECT country, region, district, project, disease, workbook_year, 
MAX(persons_treated_usaid) AS persons_treated_usaid, 
MAX(persons_treated_usaid_r1) AS persons_treated_usaid_r1, 
MAX(persons_treated_usaid_r2) AS persons_treated_usaid_r2, 
MAX(prg_cvg) AS prg_cvg, 
MAX(prg_cvg_r1) AS prg_cvg_r1, 
MAX(prg_cvg_r2) AS prg_cvg_r2

FROM
(SELECT country_desc AS 'country', region_desc AS 'region', district_desc AS 'district', 
project, disease, workbook_year, 
CASE WHEN indicator = 'ppl_treated_usaid_num' THEN value_num END AS persons_treated_usaid, 
CASE WHEN indicator = 'r1_ppl_treated_usaid_num' THEN value_num END AS persons_treated_usaid_r1, 
CASE WHEN indicator = 'r2_ppl_treated_usaid_num' THEN value_num END AS persons_treated_usaid_r2, 
CASE WHEN indicator = 'program_coverage_usaid' THEN value_num END AS prg_cvg, 
CASE WHEN indicator = 'r1_program_coverage_usaid' THEN value_num END AS prg_cvg_r1,
CASE WHEN indicator = 'r2_program_coverage_usaid' THEN value_num END AS prg_cvg_r2

FROM reporting_values
WHERE most_recent_submission_f = 1 
AND indicator IN ('ppl_treated_usaid_num', 'r1_ppl_treated_usaid_num', 'r2_ppl_treated_usaid_num',
'program_coverage_usaid', 'r1_program_coverage_usaid', 'r2_program_coverage_usaid')
AND reporting_period <> 'work_planning' AND disease <> 'at_least_one_ntd')x
GROUP BY country, region, district, disease, workbook_year;"

rs <- dbSendQuery(con, query)
rm(query)

data <- dbFetch(rs, n = -1)
check <- dbHasCompleted(rs)

dbClearResult(rs)
dbDisconnect(con)
rm(con, check, rs)

# create flag for coverage, oncho/sth
cstag <- data
cstag['cvg_f'] <- 0
cstag[cstag$disease %in% c('sth', 'oncho') & (cstag$prg_cvg_r1 >= 0.8 | cstag$prg_cvg_r2 >= 0.8), 'cvg_f'] <- 1
cstag[!(cstag$disease %in% c('sth', 'oncho')) & cstag$prg_cvg >= 0.8, 'cvg_f'] <- 1

country <- ddply(cstag, c('country', 'disease', 'workbook_year'), summarize, 
                   districts_treated = sum(persons_treated_usaid > 0, na.rm=TRUE), 
                   districts_cvg_over80 = sum(cvg_f == 1))
rm(cstag)


write.csv(data, 'coverage\\data\\district.csv')
write.csv(country, 'coverage\\data\\country.csv')
rm(data, country)