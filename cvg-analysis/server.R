library(shiny)
library(ggplot2)
library(grid)
library(gridExtra)

ENVISION = c("Benin", "Cameroon", "Democratic Republic of Congo", "Ethiopia", "Guinea", "Haiti", "Indonesia", 
             "Mali", "Mozambique", "Nepal", "Nigeria", "Senegal", "Sierra Leone", "Tanzania", "Uganda")

country <- read.csv("data/country.csv")
country <- country[country$country_name %in% ENVISION, ]
# region <- read.csv("data/region.csv")
district <- read.csv("data/district.csv")

country_all_cols <- c("country_name", "disease", "fiscal_year", "min_cvg_all", "max_cvg_all", "median_cvg_all", 
                      "mean_cvg_all", "std_dev_all", "total_treated_all", "total_endemic")

country_usaid_cols <- c("country_name", "disease", "fiscal_year", "min_cvg", "max_cvg", "median_cvg", 
                        "mean_cvg", "std_dev", "total_treated", "total_endemic")

district_all_cols <- c("country_name", "region_name", "district_name", "disease", "fiscal_year", 
                       "times_treated_all", "min_prg_cvg_all", "max_prg_cvg_all", 
                       "prg_cvg_all", "avg_hist_cvg_all", "cvg_category_all", "region_district")

district_usaid_cols <- c("country_name", "region_name", "district_name", "disease", "fiscal_year", 
                         "times_treated", "min_prg_cvg", "max_prg_cvg", 
                         "prg_cvg", "avg_hist_cvg", "cvg_category", "region_district")

shinyServer(function(input, output) {
 
## Data-generating functions ######################################################################################
  
  countryHistoryData <- reactive({
    data <- country[(country$country_name %in% input$country & country$disease %in% input$disease), ]
    if(!is.null(input$funding) && input$funding == "all"){
      data <- data[, country_all_cols]
      for(i in 1:length(country_all_cols)){colnames(data)[i] <- country_usaid_cols[i]}
    } else {
      data <- data[, country_usaid_cols]
    }
    return(data)
  })
  
  countryTableData <- reactive({
    data <- countryHistoryData()
    data <- data[with(data, order(country_name, disease, fiscal_year)), ]
    
    colnames(data) <- c("", "Disease", "Fiscal year", "Lowest coverage", "Highest coverage", 
                        "Median coverage", "Average coverage", "Std Deviation", "# Districts Treated", 
                        "# Endemic districts")
    
    return(data)
  })
  
  #   regionData <- reactive({
  #     return(region[(region$country_name %in% input$country & 
  #                      region$disease %in% input$disease & 
  #                      region$fiscal_year == input$year), ])
  #   })
  
  districtSetFunding <- reactive({
    if(!is.null(input$funding) && input$funding == "all"){
      data <- district[, district_all_cols]
      for(i in 1:length(district_all_cols)){colnames(data)[i] <- district_usaid_cols[i]}
    } else {
      data <- district[, district_usaid_cols]
    }
    return(data)
  })

  districtData <- reactive({
    data <- districtSetFunding()
    data <- data[(data$country_name %in% input$country & 
                    data$disease %in% input$disease & 
                    data$fiscal_year %in% input$year), ]
    return(data)
  })

  districtHistoryData <- reactive({
    input$districtButton
    data <- districtSetFunding()
    data <- data[(data$region_district %in% isolate(input$district) & 
                        data$disease %in% input$disease), ]
    return(data)
  })

  districtHistoryTableData <- reactive({
    input$districtButton
    data <- districtSetFunding()
    data <- data[(data$region_district %in% isolate(input$district) & 
                    data$disease %in% input$disease & !is.na(data$prg_cvg)), 
                 c("region_name", "district_name", "disease", "fiscal_year", "prg_cvg")]
    
    colnames(data) <- c("Region", "District", "Disease", "fiscal_year", "Program coverage")
    
    data <- reshape(data, 
                    timevar = "fiscal_year", 
                    idvar = c('Region', 'District', 'Disease'), 
                    direction = 'wide')
    
    if(nrow(data) > 0){
      return(data)
    } else {
      return(NULL)
    }
    
  })
  
  setDistrictColnames <- function(data){
    data <- data[with(data, order(disease, region_name, prg_cvg)), ]
    colnames(data) <- c("Disease", "Region", "District", "Program coverage", "Times treated", "Average program coverage", 
                        "Lowest historical program coverage", "Highest historical program coverage")
    return(data)
  }

  underSixtyData <- reactive({
    cols <- c('disease', 'region_name', 'district_name', 'prg_cvg', 'times_treated', 
              'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')
    data <- districtData()[(districtData()[, 'prg_cvg'] < 0.6), cols]
    data <- data[!is.na(data$region_name), ]
    
    if(nrow(data) > 0){
      data <- setDistrictColnames(data)
      return(data)
    } else {
      return(NULL)
    }
    
  })
  
  sixtyEightyData <- reactive({
    cols <- c('disease', 'region_name', 'district_name', 'prg_cvg', 'times_treated', 
              'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')
    data <- districtData()[(districtData()[, 'prg_cvg'] >= 0.6 & districtData()[, 'prg_cvg'] < 0.8), cols]
    data <- data[!is.na(data$region_name), ]
    
    if(nrow(data) > 0){
      data <- setDistrictColnames(data)
      return(data)
    } else {
      return(NULL)
    }
    
  })
  
  eighty100Data <- reactive({
    cols <- c('disease', 'region_name', 'district_name', 'prg_cvg', 'times_treated', 
              'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')
    data <- districtData()[(districtData()[, 'prg_cvg'] >= 0.8 & districtData()[, 'prg_cvg'] <= 1), cols]
    data <- data[!is.na(data$region_name), ]
    
    if(nrow(data) > 0){
      data <- setDistrictColnames(data)
      return(data)
    } else {
      return(NULL)
    }

  })
  
  hundredPlusData <- reactive({
    cols <- c('disease', 'region_name', 'district_name', 'prg_cvg', 'times_treated', 
              'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')
    data <- districtData()[(districtData()[, 'prg_cvg'] > 1), cols]
    data <- data[!is.na(data$region_name), ]
    
    if(nrow(data) > 0){
      data <- setDistrictColnames(data)
      return(data)
    } else {
      return(NULL)
    }

  })
  
## Sidebar, main tab ######################################################################################
  
  output$uiMainTab <- renderUI({
    sidebarPanel(
      radioButtons("funding", 
                   label = "Select a funding option", 
                   choices = c("USAID support" = "usaid", 
                               "All support" = "all"), 
                   selected = "usaid", 
                   inline = TRUE),
  
      radioButtons("country", 
                   label = "Choose a country",
                   choices = unique(as.character(country$country_name))),
      
      checkboxGroupInput("disease", "Choose applicable diseases:", 
                         c("LF" = "LF", 
                           "Oncho" = "Oncho", 
                           "Schisto" = "Schisto", 
                           "STH" = "STH", 
                           "Trachoma" = "Trachoma"), 
                         selected = "LF"),
      
      radioButtons("year", "Choose a fiscal year", 
                   c("FY07" = 2007, 
                     "FY08" = 2008, 
                     "FY09" = 2009, 
                     "FY10" = 2010, 
                     "FY11" = 2011,
                     "FY12" = 2012, 
                     "FY13" = 2013,
                     "FY14" = 2014), 
                   selected = 2014)
    )
  })
  
## Main panel, main tab ####################################################################
  
  output$plotHistory <- renderPlot({
    data <- countryHistoryData()
    max_cvg <- max(data[,"median_cvg"], na.rm=TRUE)
      
    ggplot(data, aes(x=fiscal_year, y=median_cvg, group=disease, color=disease, shape=disease)) + 
      geom_line() + 
      geom_point() + 
      scale_x_continuous(breaks = seq(min(country$fiscal_year, na.rm=TRUE), 
                                      max(country$fiscal_year, na.rm=TRUE))) + 
      scale_y_continuous(breaks = round(seq(0, max_cvg, by=0.1), 1)) +
      expand_limits(y=0) + 
      labs(title = paste('Median Program Coverage Over Time:', input$country),
           x = 'Fiscal Year', 
           y = 'Median Program Coverage')
  })
  
  output$tableHistory <- renderTable(countryTableData()[, 2:length(countryTableData())], include.rownames=FALSE)

  output$histograms <- renderPlot({
    data <- districtData()
    pList <- list()
    for(d in input$disease){
      if(nrow(data[data$disease == d & !is.na(data$prg_cvg),]) > 0){
        pList[[(length(pList) + 1)]] <- ggplot(data[data$disease == d,], aes(x=prg_cvg)) + 
          geom_histogram(binwidth=.1, colour="black", fill="white") +
          scale_x_continuous(breaks = round(seq(0, (max(data[,'prg_cvg'], na.rm=TRUE) + 0.1), by=0.1), 1)) + 
          labs(title = paste(d, input$year),
               x = 'Program Coverage', 
               y = '# districts')
      }
    }
    if(length(pList) > 0){do.call("grid.arrange", c(pList, ncol=2))}
  })

  output$stackedBars <- renderPlot({      
    data <- districtData()[!is.na(districtData()[,'cvg_category']), ]
    pList <- list()
    for(d in input$disease){
      if(nrow(data[data$disease == d & !is.na(data$prg_cvg),]) > 0){
        pList[[(length(pList) + 1)]] <- ggplot(data[data$disease == d,], aes(region_name, fill=cvg_category)) + 
          geom_bar() + 
          coord_flip() + 
          labs(title = paste(d, input$year),
               x = 'Region Name', 
               y = 'Number of treated districts') + 
          scale_fill_discrete(name="Coverage\nCategory")
      }
    }
    if(length(pList) > 0){do.call("grid.arrange", c(pList, ncol=1))}
  })

  output$districtHeader <- renderText({
    paste("District-level Program Coverage: FY", input$year, sep="")
  })  

  output$districtUnder60 <- renderTable(underSixtyData(), 
                                        caption = "Districts with Program Coverage under 60%", 
                                        caption.placement = "top",
                                        include.rownames = FALSE)

  output$district60to80 <- renderTable(sixtyEightyData(), 
                                       caption = "Districts with Program Coverage 60% - 80%", 
                                       caption.placement = "top",
                                       include.rownames=FALSE)
  
  output$district80to100 <- renderTable(eighty100Data(),
                                        caption = "Districts with Program Coverage 80% - 100%", 
                                        caption.placement = "top",
                                        include.rownames=FALSE)
  
  output$district100plus <- renderTable(hundredPlusData(),
                                        caption = "Districts with Program Coverage Over 100%", 
                                        caption.placement = "top",
                                        include.rownames=FALSE)


# Side panel, District Trends Tab ##########################################################################

output$uiRegion <- renderUI({
  if(is.null(input$country)){
    return(NULL)
  }
  regions <- unique(as.character(district[district$country_name == input$country, "region_name"]))
#   regions <- order(regions)
  checkboxGroupInput("region", "Select Regions", 
                     regions)
})

output$uiDistrict <- renderUI({
  if(is.null(input$region)){
    return(NULL)
  }
  districts <- unique(as.character(district[district$country_name == input$country & 
                                              district$region_name %in% input$region, "region_district"]))
#   districts <- order(districts)
  checkboxGroupInput("district", "Select Districts", 
                     districts)
})

## Main panel, District Trends tab ##################################################################

output$districtTitle <- renderText({
  input$country
})

output$districtTabIntro <- renderUI({
  input$districtButton
  if(is.null(isolate(input$district))){
    h4("Select regions, then districts, and click submit to view a graph.")
  } else {
    return(NULL)
  }
})

output$districtLinegraph <- renderPlot({
  data <- districtHistoryData()
  data$region_district <- as.factor(data$region_district)
  max_cvg <- max(data[,"prg_cvg"], na.rm=TRUE)
  
  ggplot(data, aes(x=fiscal_year, y=prg_cvg, group=interaction(disease, region_district), 
                   color=interaction(disease, region_district))) + 
    geom_line() + 
    geom_point() + 
    scale_x_continuous(breaks = seq(min(data$fiscal_year, na.rm=TRUE), 
                                    max(data$fiscal_year, na.rm=TRUE))) + 
    scale_y_continuous(breaks = round(seq(0, max_cvg, by=0.1), 1)) +
    expand_limits(y=0) + 
    labs(title = 'Program Coverage Trends',
         x = 'Fiscal Year', 
         y = 'Program Coverage')
})

output$districtHistoryTable <- renderTable(districtHistoryTableData(), 
                                           include.rownames = FALSE)

})

