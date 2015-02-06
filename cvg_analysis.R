
#master_file is a .csv version of the mda_demography_decreased-ntd-burden.tab offline file
master_file = read.csv("C:\\Users\\reowen\\Documents\\Offline Files\\master_file.csv")

#columns used in the script
colnames = c("country_name", "region_name", "district_name", "fiscal_year", "reporting_period", 
             "disease", "persons_at_risk", "persons_targeted_usaid_funding", "persons_targeted_usaid_funding_r1", 
             "persons_targeted_usaid_funding_r2", "persons_treated_usaid_funding", "persons_treated_usaid_funding_r1", 
             "persons_treated_usaid_funding_r2", "sac_at_risk", "sac_targeted_with_usaid_support", 
             "sac_targeted_with_usaid_support_r1", "sac_targeted_with_usaid_support_r2", "sac_treated_usaid_funding", 
             "sac_treated_usaid_funding_r1", "sac_treated_usaid_funding_r2", 
             "persons_targeted_all_funding", "persons_targeted_all_funding_r1", "persons_targeted_all_funding_r2", 
             "persons_treated_all_funding", "persons_treated_all_funding_r1", "persons_treated_all_funding_r2")



raw = master_file[, colnames]
#free up some memory (this takes 45 mb)
rm(master_file)

for(i in 7:length(colnames)){
  raw[, colnames[i]] = as.numeric(as.character(raw[, colnames[i]]))
}

for(i in 7:length(colnames)){
  raw[is.na(raw[,colnames[i]]) == TRUE, colnames[i]] = 0
}
rm(colnames, i)


#create number targeted and treated (usaid support)

usaid_targeted = c("persons_targeted_usaid_funding", "persons_targeted_usaid_funding_r1", "persons_targeted_usaid_funding_r2")
usaid_treated = c("persons_treated_usaid_funding", "persons_treated_usaid_funding_r1","persons_treated_usaid_funding_r2")

raw['usaid_targeted'] = apply(raw[, usaid_targeted], 1, max)
raw['usaid_treated'] = apply(raw[, usaid_treated], 1, max)
rm(usaid_targeted, usaid_treated)

# create number targeted and treated (all support)
all_targeted = c("persons_targeted_all_funding", "persons_targeted_all_funding_r1", "persons_targeted_all_funding_r2", 
                 "persons_targeted_usaid_funding", "persons_targeted_usaid_funding_r1", "persons_targeted_usaid_funding_r2")
all_treated = c("persons_treated_all_funding", "persons_treated_all_funding_r1", "persons_treated_all_funding_r2", 
                "persons_treated_usaid_funding", "persons_treated_usaid_funding_r1", "persons_treated_usaid_funding_r2")

#note these are the max values across persons targeted, persons targeted r1 and r2
raw['all_targeted'] = apply(raw[, all_targeted], 1, max)
raw['all_treated'] = apply(raw[, all_treated], 1, max)
rm(all_targeted, all_treated)

# #create SAC treated variable
# 
# sac_targeted = c("sac_targeted_with_usaid_support", "sac_targeted_with_usaid_support_r1", 
#                  "sac_targeted_with_usaid_support_r2")
# 
# sac_treated = c("sac_treated_usaid_funding", "sac_treated_usaid_funding_r1", "sac_treated_usaid_funding_r2")
# 
# raw['sac_targeted'] = apply(raw[, sac_targeted], 1, max)
# raw['sac_treated'] = apply(raw[, sac_treated], 1, max)
# rm(sac_targeted, sac_treated)

#######################################################
###### Code program and epidemiological coverage ######
#######################################################

keep_cols = c("country_name", "region_name", "district_name", "fiscal_year", "disease", 
              'usaid_targeted', 'usaid_treated', 'all_targeted', 'all_treated', "persons_at_risk")

raw_cvg = raw[raw$reporting_period == '2nd SAR (October-September)', keep_cols]
rm(raw, keep_cols)

# Program coverage variables

raw_cvg['prg_cvg'] <- with(raw_cvg, usaid_treated / usaid_targeted)
raw_cvg[(raw_cvg$prg_cvg == 0 | is.nan(raw_cvg$prg_cvg) | is.infinite(raw_cvg$prg_cvg)), 'prg_cvg'] <- NA

raw_cvg['prg_cvg_all'] <- with(raw_cvg, all_treated / all_targeted)
raw_cvg[(raw_cvg$prg_cvg_all == 0 | is.nan(raw_cvg$prg_cvg_all) | is.infinite(raw_cvg$prg_cvg_all)), 'prg_cvg_all'] <- NA


# #Code program coverage variable, using SAC coverage for STH and Schisto
# sac = c('STH', "Schisto")
# 
# raw_cvg['prg_cvg'] = with(raw_cvg, ifelse((disease %in% sac), 
#                                           (sac_treated / sac_targeted), 
#                                           (usaid_treated / usaid_targeted)))
# raw_cvg[(raw_cvg$prg_cvg == 0 | is.nan(raw_cvg$prg_cvg) | is.infinite(raw_cvg$prg_cvg)), 'prg_cvg'] <- NA
# 
# raw_cvg['epi_cvg'] = with(raw_cvg, ifelse((disease %in% sac), 
#                                           (sac_treated / sac_at_risk), 
#                                           (usaid_treated / persons_at_risk)))
# raw_cvg[(raw_cvg$epi_cvg == 0 | is.nan(raw_cvg$epi_cvg) | is.infinite(raw_cvg$epi_cvg)), 'epi_cvg'] <- NA
# rm(sac)

################################################
######## code the country-level dataset ########
################################################

library(plyr)
country <- ddply(raw_cvg, c('country_name', 'disease', 'fiscal_year'), summarize, 
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
                 total_endemic = sum(persons_at_risk > 0, na.rm=TRUE))

vars = c('min_cvg', 'max_cvg', 'median_cvg', 'mean_cvg', 'total_treated', 'total_endemic', 
         'min_cvg_all', 'max_cvg_all', 'median_cvg_all', 'mean_cvg_all', 'total_treated_all')
for(i in 1:length(vars)){
  country[(is.nan(country[, vars[i]]) | is.infinite(country[, vars[i]])), vars[i]] <- NA
}
rm(vars, i)

# write.csv(country, 'Datasets\\cvg_analysis\\country.csv')

################################################
######## code the district-level dataset #######
################################################

unique = paste(raw_cvg$country_name, raw_cvg$region_name, raw_cvg$district_name, raw_cvg$disease)

raw_cvg['times_treated'] = ave(raw_cvg[,'usaid_treated'], 
                               unique, 
                               FUN = function(x) sum(x > 0))

raw_cvg['times_treated_all'] = ave(raw_cvg[,'all_treated'], 
                                   unique, 
                                   FUN = function(x) sum(x > 0))

raw_cvg['min_prg_cvg'] = ave(raw_cvg[,'prg_cvg'], 
                             unique,
                             FUN = function(x) min(x, na.rm=TRUE))

raw_cvg['min_prg_cvg_all'] = ave(raw_cvg[,'prg_cvg_all'], 
                                 unique,
                                 FUN = function(x) min(x, na.rm=TRUE))

raw_cvg['max_prg_cvg'] = ave(raw_cvg[,'prg_cvg'], 
                             unique,
                             FUN = function(x) max(x, na.rm=TRUE))

raw_cvg['max_prg_cvg_all'] = ave(raw_cvg[,'prg_cvg_all'], 
                                 unique,
                                 FUN = function(x) max(x, na.rm=TRUE))

# raw_cvg['count_below_epi_threshold'] = ave(raw_cvg[,'epi_cvg'], 
#                                            unique, 
#                                            FUN = function(x) sum(x < 0.65, na.rm=TRUE))
# 
# raw_cvg['count_above_epi_threshold'] = ave(raw_cvg[,'epi_cvg'], 
#                                            unique, 
#                                            FUN = function(x) sum(x >= 0.65, na.rm=TRUE))
# 
# unique = paste(raw_cvg$country_name, raw_cvg$region_name, raw_cvg$district_name, raw_cvg$fiscal_year)
# raw_cvg['average_cvg'] = ave(raw_cvg[,'prg_cvg'], 
#                              unique,
#                              FUN = function(x) mean(x, na.rm=TRUE))
rm(unique)

vars = c('min_prg_cvg', 'max_prg_cvg', 'times_treated', 
         'min_prg_cvg_all', 'max_prg_cvg_all', 'times_treated_all')
for(i in 1:length(vars)){
  raw_cvg[(is.nan(raw_cvg[, vars[i]]) | is.infinite(raw_cvg[, vars[i]])), vars[i]] <- NA
}
rm(vars, i)


#####################################
### create district-level dataset ###
#####################################

cols = c("country_name", "region_name", "district_name", "disease", "fiscal_year", "times_treated", 
         "min_prg_cvg", "max_prg_cvg", "prg_cvg", "times_treated_all", "min_prg_cvg_all", 
         "max_prg_cvg_all", "prg_cvg_all")

district = raw_cvg[, cols]
rm(cols)

district = district[with(district, order(fiscal_year)), ]
rm(raw_cvg)

# library(reshape)
# district2 = melt(district, id=c("country_name", "region_name", "district_name", "disease", "fiscal_year", "times_treated", 
#                                 "min_prg_cvg", "max_prg_cvg", "count_below_epi_threshold", "count_above_epi_threshold"))
# 
# district2 = cast(district2, ... ~ variable + fiscal_year)

# write.csv(district, 'Datasets\\cvg_analysis\\district.csv')


# #######################################
# ### save excel workbook, multi-tabs ###
# #######################################
# 
# lf_district <- district2[district2$disease == 'LF', ]
# oncho_district <- district2[district2$disease == 'Oncho', ]
# sch_district <- district2[district2$disease == 'Schisto', ]
# sth_district <- district2[district2$disease == 'STH', ]
# tra_district <- district2[district2$disease == 'Trachoma', ]
# 
# 
# library(xlsx)
# cvg_analysis = createWorkbook()
# 
# country_tab = createSheet(wb=cvg_analysis, sheetName="Country")
# # district_tab = createSheet(wb=cvg_analysis, sheetName="District")
# lf = createSheet(wb=cvg_analysis, sheetName="lf")
# oncho = createSheet(wb=cvg_analysis, sheetName="oncho")
# sch = createSheet(wb=cvg_analysis, sheetName="sch")
# sth = createSheet(wb=cvg_analysis, sheetName="sth")
# trachoma = createSheet(wb=cvg_analysis, sheetName="trachoma")
# 
# addDataFrame(x=country, sheet=country_tab)
# # addDataFrame(x=district2, sheet=district_tab)
# addDataFrame(x=lf_district, sheet=lf)
# addDataFrame(x=oncho_district, sheet=oncho)
# addDataFrame(x=sch_district, sheet=sch)
# addDataFrame(x=sth_district, sheet=sth)
# addDataFrame(x=tra_district, sheet=trachoma)
# 
# 
# saveWorkbook(cvg_analysis, "Datasets\\cvg_analysis\\cvg_analysis.xlsx")
# rm(country_tab, cvg_analysis, district_tab, lf_district, oncho_district, sch_district, sth_district, tra_district, 
#    lf, oncho, sch, sth, trachoma)
