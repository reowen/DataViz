library(shiny)
library(ggplot2)
library(grid)
library(gridExtra)

country <- read.csv("data/country.csv")
# region <- read.csv("data/region.csv")
district <- read.csv("data/district.csv")

country_all_cols <- c("country_name", "disease", "fiscal_year", "min_cvg_all", "max_cvg_all", "median_cvg_all", 
                      "mean_cvg_all", "total_treated_all", "total_endemic")

country_usaid_cols <- c("country_name", "disease", "fiscal_year", "min_cvg", "max_cvg", "median_cvg", 
                        "mean_cvg", "total_treated", "total_endemic")

district_all_cols <- c("country_name", "region_name", "district_name", "disease", "fiscal_year", 
                       "times_treated_all", "min_prg_cvg_all", "max_prg_cvg_all", 
                       "prg_cvg_all", "avg_hist_cvg_all", "cvg_category_all")

district_usaid_cols <- c("country_name", "region_name", "district_name", "disease", "fiscal_year", 
                         "times_treated", "min_prg_cvg", "max_prg_cvg", 
                         "prg_cvg", "avg_hist_cvg", "cvg_category")

shinyServer(function(input, output) {
  
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
    data <- country[(country$country_name %in% input$country & 
                       country$disease %in% input$disease & 
                       country$fiscal_year %in% input$year), ]
    if(!is.null(input$funding) && input$funding == "all"){
      data <- data[, country_all_cols]
      for(i in 1:length(country_all_cols)){colnames(data)[i] <- country_usaid_cols[i]}
    } else {
      data <- data[, country_usaid_cols]
    }
    return(data)
  })
  
#   regionData <- reactive({
#     return(region[(region$country_name %in% input$country & 
#                      region$disease %in% input$disease & 
#                      region$fiscal_year == input$year), ])
#   })
  
  districtData <- reactive({
    data <- district[(district$country_name %in% input$country & 
                        district$disease %in% input$disease & 
                        district$fiscal_year %in% input$year), ]
    if(!is.null(input$funding) && input$funding == "all"){
      data <- data[, district_all_cols]
      for(i in 1:length(district_all_cols)){colnames(data)[i] <- district_usaid_cols[i]}
    } else {
      data <- data[, district_usaid_cols]
    }
    return(data)
  })
  
  underSixtyData <- reactive({
    cols <- c('country_name', 'region_name', 'district_name', 'prg_cvg', 'times_treated', 
              'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')
    data <- districtData()[(districtData()[, 'prg_cvg'] < 0.6), cols]
    data <- data[!is.na(data$country_name), ]
    return(data[with(data, order(country_name, region_name, prg_cvg)), ])
  })
  
  sixtyEightyData <- reactive({
    cols <- c('country_name', 'region_name', 'district_name', 'prg_cvg', 'times_treated', 
              'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')
    data <- districtData()[(districtData()[, 'prg_cvg'] >= 0.6 & districtData()[, 'prg_cvg'] < 0.8), cols]
    data <- data[!is.na(data$country_name), ]
    return(data[with(data, order(country_name, region_name, prg_cvg)), ])
  })
  
  eighty100Data <- reactive({
    cols <- c('country_name', 'region_name', 'district_name', 'prg_cvg', 'times_treated', 
              'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')
    data <- districtData()[(districtData()[, 'prg_cvg'] >= 0.8 & districtData()[, 'prg_cvg'] <= 1), cols]
    data <- data[!is.na(data$country_name), ]
    return(data[with(data, order(country_name, region_name, prg_cvg)), ])
  })
  
  hundredPlusData <- reactive({
    cols <- c('country_name', 'region_name', 'district_name', 'prg_cvg', 'times_treated', 
              'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')
    data <- districtData()[(districtData()[, 'prg_cvg'] > 1), cols]
    data <- data[!is.na(data$country_name), ]
    return(data[with(data, order(country_name, region_name, prg_cvg)), ])
  })
  
  output$ui <- renderUI({
    sidebarPanel(
      radioButtons("funding", 
                   label = "Select a funding option", 
                   choices = c("USAID support" = "usaid", 
                               "All support" = "all"), 
                   selected = "usaid", 
                   inline = TRUE),
      
      radioButtons("country", 
                   label = "Choose a country",
                   choices = levels(country$country_name),
                   selected = "Benin"),
      
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

  output$ui2 <- renderUI({
    sidebarPanel(
      checkboxGroupInput("region", "Select Regions", 
                         c("Region1", "Region2", "Region3"), 
                         selected = "Region1"), 
      checkboxGroupInput("district", "Select Districts", 
                         c("District1", "District2", "District3"), 
                         selected = "District1"), 
      submitButton("Submit")
        )
  })
 
  
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

  
  output$districtUnder60 <- renderTable(underSixtyData(), 
                                        include.rownames = FALSE)

  output$district60to80 <- renderTable(sixtyEightyData(), 
                                       include.rownames=FALSE)
  
  output$district80to100 <- renderTable(eighty100Data(),
                                        include.rownames=FALSE)
  
  output$district100plus <- renderTable(hundredPlusData(),
                                        include.rownames=FALSE)
})

