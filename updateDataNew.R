library(RMySQL)
library(plyr)

script.dir <- dirname(sys.frame(1)$ofile)
setwd(script.dir)
rm(script.dir)

con <- dbConnect(MySQL(), 
                 user="envision", password="envisionRead!C4eMfw", 
                 dbname="ntd", host="productionread.c6u52zchwjde.us-east-1.rds.amazonaws.com")

rs <- dbSendQuery(con, 
                  "SELECT country_desc, region_desc, district_desc, disease, workbook_year, indicator, value_num 
                  FROM reporting_values 
                  WHERE most_recent_submission_f = 1 
                  AND indicator IN ('program_coverage_all', 'program_coverage_usaid', 'ci_diseasedist_dist_endmc_above_treat_thrshd', 'population_at_risk') 
                  AND reporting_period <> 'work_planning'")

data <- dbFetch(rs, n = -1)
check <- dbHasCompleted(rs)

dbClearResult(rs)
dbDisconnect(con)
rm(con, check, rs)

data[data$value_num == 0, "value_num"] <- NA
data <- data[data$disease != "at_least_one_ntd", ]
district <- reshape(data, 
                    timevar = 'indicator', 
                    idvar = c('country_desc', 'region_desc', 'district_desc', 'disease', 'workbook_year'), 
                    direction = 'wide')
rm(data)

# update diseases to match old names from cube (specific to this one app)

district[district$disease == 'lf', 'disease'] <- "LF"
district[district$disease == 'oncho', 'disease'] <- "Oncho"
district[district$disease == 'schisto', 'disease'] <- "Schisto"
district[district$disease == 'sth', 'disease'] <- "STH"
district[district$disease == 'trachoma', 'disease'] <- "Trachoma"

# update column names to match those in app

cols <- c('country_name', 'region_name', 'district_name', 'disease', 'fiscal_year', 
          'endemic', 'pop_at_risk', 'prg_cvg_all', 'prg_cvg')
for(i in 1:length(cols)){colnames(district)[i] <- cols[i]}
rm(i, cols)

# deal with quirk in NTDCP data entries

cvg <- c("prg_cvg", "prg_cvg_all")
district[district$fiscal_year < 2012, 'prg_cvg'] <- apply(district[district$fiscal_year < 2012, cvg], 1, 
                                                          function(x) max(x, na.rm=TRUE))

district[district$fiscal_year < 2012, 'prg_cvg_all'] <- apply(district[district$fiscal_year < 2012, cvg], 1, 
                                                              function(x) max(x, na.rm=TRUE))

for(c in cvg){
  district[(is.nan(district[, c]) | is.infinite(district[,c])), c] <- NA
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

write.csv(country, 'cvg-analysis\\data\\country.csv')

# code the district dataset

# district2 <- district

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


write.csv(district, 'cvg-analysis\\data\\district.csv')

rm(country, district)
