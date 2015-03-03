
# check if required packages installed, if not, install them
required_packages <- c("shiny", "ggplot2", "gridExtra", "plyr", "RMySQL")
for(p in required_packages){
  if(p %in% rownames(installed.packages()) == FALSE){
    install.packages(p)
  }
}
rm(required_packages, p)

# set working directory to the directory where this script is saved
script.dir <- dirname(sys.frame(1)$ofile)
setwd(script.dir)
rm(script.dir)

library(RMySQL)
library(plyr)

con <- dbConnect(MySQL(), 
                 user="envision", password="envisionRead!C4eMfw", 
                 dbname="ntd", host="productionread.c6u52zchwjde.us-east-1.rds.amazonaws.com")

query <- 
"SELECT country_name, region_name, district_name, disease, fiscal_year, 
MAX(prg_cvg) AS 'prg_cvg', MAX(prg_cvg_all) AS 'prg_cvg_all', 
MAX(endemic) AS 'endemic', MAX(pop_at_risk) AS 'pop_at_risk'
FROM
(SELECT 
 country_desc AS 'country_name', 
 region_desc AS 'region_name', 
 district_desc AS 'district_name', 
 disease, 
 workbook_year AS 'fiscal_year', 
 CASE WHEN indicator = 'program_coverage_usaid' then value_num END AS prg_cvg, 
 CASE WHEN indicator = 'program_coverage_all' then value_num END AS prg_cvg_all,
 CASE WHEN indicator = 'ci_diseasedist_dist_endmc_above_treat_thrshd' then value_num END AS endemic,
 CASE WHEN indicator = 'population_at_risk' then value_num END AS pop_at_risk
 
 FROM reporting_values
 WHERE most_recent_submission_f = 1 
 AND indicator IN ('program_coverage_all', 'program_coverage_usaid', 'ci_diseasedist_dist_endmc_above_treat_thrshd', 'population_at_risk') 
 AND reporting_period <> 'work_planning' AND disease <> 'at_least_one_ntd')x
GROUP BY country_name, region_name, district_name, disease, fiscal_year;"

rs <- dbSendQuery(con, query)
rm(query)

data <- dbFetch(rs, n = -1)
check <- dbHasCompleted(rs)

dbClearResult(rs)
dbDisconnect(con)
rm(con, check, rs)

# update diseases to match old names from cube (specific to this one app)
district <- data
rm(data)

district[district$disease == 'lf', 'disease'] <- "LF"
district[district$disease == 'oncho', 'disease'] <- "Oncho"
district[district$disease == 'schisto', 'disease'] <- "Schisto"
district[district$disease == 'sth', 'disease'] <- "STH"
district[district$disease == 'trachoma', 'disease'] <- "Trachoma"

# deal with quirk in NTDCP data entries

cvg <- c("prg_cvg", "prg_cvg_all")
district[district$fiscal_year < 2012, 'prg_cvg'] <- apply(district[district$fiscal_year < 2012, cvg], 1, 
                                                          function(x) max(x, na.rm=TRUE))

district[district$fiscal_year < 2012, 'prg_cvg_all'] <- apply(district[district$fiscal_year < 2012, cvg], 1, 
                                                              function(x) max(x, na.rm=TRUE))

for(c in cvg){
  district[(is.nan(district[, c]) | is.infinite(district[,c]) | district[,c] == 0), c] <- NA
}

rm(cvg, c)

# create country csv file

district['endemic_flag'] <- ifelse((district$fiscal_year > 2011 & district$endemic == 1), 1, 
                                   ifelse((district$fiscal_year < 2012 & district$pop_at_risk > 0), 1, 0))

country <- ddply(district, c('country_name', 'disease', 'fiscal_year'), summarize, 
                 min_cvg = min(prg_cvg, na.rm=TRUE), 
                 max_cvg = max(prg_cvg, na.rm=TRUE), 
                 median_cvg = median(prg_cvg, na.rm=TRUE), 
                 mean_cvg = mean(prg_cvg, na.rm=TRUE), 
                 std_dev = sd(prg_cvg, na.rm=TRUE),
                 total_treated = sum(prg_cvg > 0, na.rm=TRUE), 
                 min_cvg_all = min(prg_cvg_all, na.rm=TRUE), 
                 max_cvg_all = max(prg_cvg_all, na.rm=TRUE), 
                 median_cvg_all = median(prg_cvg_all, na.rm=TRUE), 
                 mean_cvg_all = mean(prg_cvg_all, na.rm=TRUE), 
                 std_dev_all = sd(prg_cvg_all, na.rm=TRUE),
                 total_treated_all = sum(prg_cvg_all > 0, na.rm=TRUE),
                 total_endemic = sum(endemic_flag, na.rm=TRUE))

vars = c('min_cvg', 'max_cvg', 'median_cvg', 'mean_cvg', 'total_treated', 'total_endemic', 
         'min_cvg_all', 'max_cvg_all', 'median_cvg_all', 'mean_cvg_all', 'total_treated_all')
for(i in 1:length(vars)){
  country[(is.nan(country[, vars[i]]) | is.infinite(country[, vars[i]])), vars[i]] <- NA
}
rm(vars, i)

# code the district dataset

keepcols <- c('country_name', 'region_name', 'district_name', 'disease', 'fiscal_year', 
              'prg_cvg_all', 'prg_cvg')
district <- district[,keepcols]
rm(keepcols)

unique = paste(district$country_name, district$region_name, district$district_name, district$disease)

district['times_treated'] = ave(district[,'prg_cvg'], 
                                unique, 
                                FUN = function(x) sum(x > 0, na.rm=TRUE))

district['times_treated_all'] = ave(district[,'prg_cvg_all'], 
                                    unique, 
                                    FUN = function(x) sum(x > 0, na.rm=TRUE))

district['min_prg_cvg'] = ave(district[,'prg_cvg'], 
                              unique,
                              FUN = function(x) min(x, na.rm=TRUE))

district['min_prg_cvg_all'] = ave(district[,'prg_cvg_all'], 
                                  unique,
                                  FUN = function(x) min(x, na.rm=TRUE))

district['max_prg_cvg'] = ave(district[,'prg_cvg'], 
                              unique,
                              FUN = function(x) max(x, na.rm=TRUE))

district['max_prg_cvg_all'] = ave(district[,'prg_cvg_all'], 
                                  unique,
                                  FUN = function(x) max(x, na.rm=TRUE))


vars = c('min_prg_cvg', 'max_prg_cvg', 'times_treated', 
         'min_prg_cvg_all', 'max_prg_cvg_all', 'times_treated_all')
for(v in vars){
  district[(is.nan(district[, v]) | is.infinite(district[, v])), v] <- NA
}
rm(vars, v)

unique = paste(district$country_name, district$region_name, district$district_name, district$disease)

district['avg_hist_cvg'] <- ave(district[,'prg_cvg'], 
                                unique, 
                                FUN = function(x) mean(x, na.rm=TRUE))

district['avg_hist_cvg_all'] <- ave(district[,'prg_cvg_all'], 
                                    unique, 
                                    FUN = function(x) mean(x, na.rm=TRUE))
rm(unique)

district['cvg_category'] <- with(district, ifelse((prg_cvg > 0 & prg_cvg < 0.6), "(1) Under 60 percent", 
                                                  ifelse((prg_cvg >= 0.6 & prg_cvg < 0.8), "(2) 60 to 80 percent", 
                                                         ifelse((prg_cvg >= 0.8 & prg_cvg <= 1), "(3) 80 to 100 percent", 
                                                                "(4) Over 100 percent"))))

district['cvg_category_all'] <- with(district, ifelse((prg_cvg_all > 0 & prg_cvg_all < 0.6), "(1) Under 60 percent", 
                                                      ifelse((prg_cvg_all >= 0.6 & prg_cvg_all < 0.8), "(2) 60 to 80 percent", 
                                                             ifelse((prg_cvg_all >= 0.8 & prg_cvg_all <= 1), "(3) 80 to 100 percent", 
                                                                    "(4) Over 100 percent"))))

district["region_district"] <- paste(as.character(district$region_name), "-", as.character(district$district_name))

# restrict to ENVISION only
ENVISION = c("Benin", "Cameroon", "Democratic Republic of Congo", "Ethiopia", "Guinea", "Haiti", "Indonesia", 
             "Mali", "Mozambique", "Nepal", "Nigeria", "Senegal", "Sierra Leone", "Tanzania", "Uganda")

country <- country[country$country_name %in% ENVISION, ]
district <- district[district$country_name %in% ENVISION, ]

# write to csv
write.csv(country, 'cvg-analysis\\data\\country.csv')
write.csv(district, 'cvg-analysis\\data\\district.csv')

rm(country, district, ENVISION)
