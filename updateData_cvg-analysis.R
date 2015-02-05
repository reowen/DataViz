
library(ggplot2)
# library(plyr)

source('C:\\Users\\reowen\\Documents\\Coding\\DataViz\\cvg_analysis.R')

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

# region <- ddply(district, c('country_name', 'region_name', 'disease', 'fiscal_year'), summarize, 
#                 total_treated = sum(prg_cvg > 0, na.rm=TRUE),
#                 under_60 = sum((prg_cvg < 0.6 & prg_cvg > 0), na.rm=TRUE), 
#                 sixty_80 = sum((prg_cvg >= 0.6 & prg_cvg < 0.8), na.rm=TRUE), 
#                 eighty_100 = sum((prg_cvg >= 0.8 & prg_cvg <= 1), na.rm=TRUE), 
#                 hundred_plus = sum(prg_cvg > 1, na.rm=TRUE))
# 
# vars = c('total_treated', 'under_60', 'sixty_80', 'eighty_100', 'hundred_plus')
# for(i in 1:length(vars)){
#   region[(is.nan(region[, vars[i]]) | is.infinite(region[, vars[i]])), vars[i]] <- NA
# }
# rm(vars, i)

write.csv(country, 'C:\\Users\\reowen\\Documents\\Coding\\DataViz\\cvg-analysis\\data\\country.csv')
# write.csv(region, 'C:\\Users\\reowen\\Documents\\Coding\\DataViz\\cvg-analysis\\data\\region.csv')
write.csv(district, 'C:\\Users\\reowen\\Documents\\Coding\\DataViz\\cvg-analysis\\data\\district.csv')
