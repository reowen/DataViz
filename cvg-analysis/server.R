library(shiny)
library(ggplot2)
library(gridExtra)

country <- read.csv("data/country.csv")
region <- read.csv("data/region.csv")
district <- read.csv("data/district.csv")
source("helpers.R")

shinyServer(function(input, output) {
  
  countryData <- reactive({
    return(country[(country$country_name %in% input$country & 
                      country$disease %in% input$disease & 
                      country$fiscal_year == input$year), ])
  })
  
  regionData <- reactive({
    return(region[(region$country_name %in% input$country & 
                     region$disease %in% input$disease & 
                     region$fiscal_year == input$year), ])
  })
  
  districtData <- reactive({
    return(district[(district$country_name %in% input$country & 
                       district$disease %in% input$disease & 
                       district$fiscal_year == input$year), ])
  })
  
  underSixtyData <- reactive({
    cols <- c('country_name', 'region_name', 'district_name', 'prg_cvg', 'times_treated', 
              'avg_hist_cvg', 'min_prg_cvg', 'max_prg_cvg')
    data <- districtData()[(districtData()[, 'prg_cvg'] < 0.6), cols]
    data <- data[!is.na(data$country_name), ]
    return(data[with(data, order(country_name, region_name, prg_cvg)), ])
  })
  
  
  output$ui <- renderUI({
    sidebarPanel(
      
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
  
  output$plotHistory <- renderPlot({
    ggplot(country[(country$country_name %in% input$country & country$disease %in% input$disease), ], 
           aes(x=fiscal_year, y=median_cvg, group=disease, color=disease, shape=disease)) + 
      geom_line() + 
      geom_point() + 
      scale_x_continuous(breaks = seq(min(country$fiscal_year, na.rm=TRUE), 
                                        max(country$fiscal_year, na.rm=TRUE))) + 
      labs(title = paste('Median Program Coverage Over Time:', input$country),
           x = 'Fiscal Year', 
           y = 'Median Program Coverage')
  })
  
  output$tableHistory <- renderTable(countryData()[, 2:length(countryData())], include.rownames=FALSE)

  output$histograms <- renderPlot({
    ggplot(districtData(), aes(x=prg_cvg)) + 
      geom_histogram(binwidth=.1, colour="black", fill="white") +
      scale_x_continuous(breaks = round(seq(0, (max(districtData()[,'prg_cvg'], na.rm=TRUE) + 0.1), by=0.1), 1)) + 
      labs(title = paste('Program Coverage Distribution:', input$disease, input$year),
           x = 'Program Coverage', 
           y = '# districts') + 
      facet_wrap( ~ disease, ncol=1)
  })

  output$stackedBars <- renderPlot({      
    g <- gridExtra::borderGrob(type=9)
    
    ggplot(districtData()[!is.na(districtData()[,'cvg_category']), ], aes(region_name, fill=cvg_category)) + 
      geom_bar() + 
      coord_flip() + 
      labs(title = paste('Region-Level Coverage Breakdowns:', input$disease, input$year),
           x = 'Region Name', 
           y = 'Number of treated districts') + 
      scale_fill_discrete(name="Coverage\nCategory") +
      facet_wrap( ~ disease, ncol=1) + 
      annotation_custom(g)
  })

  output$districtUnder60 <- renderTable(underSixtyData(), include.rownames=FALSE)

  
})




