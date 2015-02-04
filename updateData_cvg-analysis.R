
library(ggplot2)
library(plyr)

source('C:\\Users\\reowen\\Documents\\Coding\\R_Scripts\\coverage_analysis\\cvg_analysis.R')

unique = paste(district$country_name, district$region_name, district$district_name, district$disease)
district['avg_hist_cvg'] <- ave(district[,'prg_cvg'], 
                                      unique, 
                                      FUN = function(x) mean(x, na.rm=TRUE))
rm(unique)

district['cvg_category'] <- with(district, ifelse((prg_cvg > 0 & prg_cvg < 0.6), "(1) Under 60 percent", 
                                                  ifelse((prg_cvg >= 0.6 & prg_cvg < 0.8), "(2) 60 to 80 percent", 
                                                         ifelse((prg_cvg >= 0.8 & prg_cvg <= 1), "(3) 80 to 100 percent", 
                                                                "(4) Over 100 percent"))))

region <- ddply(district, c('country_name', 'region_name', 'disease', 'fiscal_year'), summarize, 
                total_treated = sum(prg_cvg > 0, na.rm=TRUE),
                under_60 = sum((prg_cvg < 0.6 & prg_cvg > 0), na.rm=TRUE), 
                sixty_80 = sum((prg_cvg >= 0.6 & prg_cvg < 0.8), na.rm=TRUE), 
                eighty_100 = sum((prg_cvg >= 0.8 & prg_cvg <= 1), na.rm=TRUE), 
                hundred_plus = sum(prg_cvg > 1, na.rm=TRUE))

vars = c('total_treated', 'under_60', 'sixty_80', 'eighty_100', 'hundred_plus')
for(i in 1:length(vars)){
  region[(is.nan(region[, vars[i]]) | is.infinite(region[, vars[i]])), vars[i]] <- NA
}
rm(vars, i)

write.csv(country, 'C:\\Users\\reowen\\Documents\\Coding\\DataViz\\cvg-analysis\\data\\country.csv')
write.csv(region, 'C:\\Users\\reowen\\Documents\\Coding\\DataViz\\cvg-analysis\\data\\region.csv')
write.csv(district, 'C:\\Users\\reowen\\Documents\\Coding\\DataViz\\cvg-analysis\\data\\district.csv')



# # Make dataset, histogram showing distribution
# 
# cdata <- district[(district$country_name == COUNTRY & district$fiscal_year == FY & district$disease == DISEASE), ]
# 
# cvg_hist <-  ggplot(cdata, aes(x=prg_cvg)) + 
#   geom_histogram(binwidth=.1, colour="black", fill="white") +
#   geom_vline(aes(xintercept=median(prg_cvg, na.rm=T)), color="red", linetype="dashed", size=1) +
#   scale_x_continuous(breaks = round(seq(0, (max(cdata$prg_cvg, na.rm=TRUE) + 0.1), by=0.1), 1)) + 
#   labs(title = paste(DISEASE, 'Program Coverage:', COUNTRY, 'FY', FY),
#        x = 'Program Coverage', 
#        y = '# districts')
# 
# ggsave('cvg_hist.pdf', cvg_hist)
# 
# # Categorize districts
# 
# under_60 <- cdata[cdata$prg_cvg < 0.6, ]
# under_60 <- under_60[!(is.na(under_60$country_name)), 
#                      c('region_name', 'district_name', 'prg_cvg', 'times_treated', 
#                        'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')]
# under_60 <- under_60[with(under_60, order(prg_cvg)), ]
# 
# 
# sixty_to_eighty <- cdata[cdata$prg_cvg >= 0.6 & cdata$prg_cvg < 0.8, ]
# sixty_to_eighty <- sixty_to_eighty[!(is.na(sixty_to_eighty$country_name)), 
#                                    c('region_name', 'district_name', 'prg_cvg', 'times_treated', 
#                                      'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')]
# sixty_to_eighty <- sixty_to_eighty[with(sixty_to_eighty, order(prg_cvg)), ]
# 
# eighty_to_100 <- cdata[cdata$prg_cvg >= 0.8 & cdata$prg_cvg <= 1, ]
# eighty_to_100 <- eighty_to_100[!(is.na(eighty_to_100$country_name)), 
#                                c('region_name', 'district_name', 'prg_cvg', 'times_treated', 
#                                  'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')]
# eighty_to_100 <- eighty_to_100[with(eighty_to_100, order(prg_cvg)), ]
# 
# 
# hundred_plus <- cdata[cdata$prg_cvg > 1, ]
# hundred_plus <- hundred_plus[!(is.na(hundred_plus$country_name)), c('region_name', 'district_name', 'prg_cvg', 
#                                                                     'times_treated', 'avg_hist_cvg', 'min_prg_cvg', 
#                                                                     'max_prg_cvg')] 
# hundred_plus <- hundred_plus[with(hundred_plus, order(prg_cvg)), ]
# 
# 
# ### country-level snapshot table
# # the t() transposes the dataset to flip columns and rows
# c_snap <- t(country[(country$country_name == COUNTRY & country$fiscal_year == FY & country$disease == DISEASE), ])

