library(shiny)
library(reshape2)
library(ggplot2)
library(scales)

portfolio <- read.csv('data/portfolio.csv')
project <- read.csv('data/project.csv')
country <- read.csv('data/country.csv')
region <- read.csv('data/region.csv')
district <- read.csv('data/district.csv')

shinyServer(function(input, output) {
  
## Build Input Panels #########################################################################

output$selectProject <- renderUI({
  if(input$level == "Project"){
    checkboxGroupInput("project", "Choose Project(s):", 
                       choices = unique(as.character(project$project)))
  } else { return(NULL) }
})

output$selectCountry <- renderUI({
  if(input$level %in% c("Country", "Region", "District")){
    checkboxGroupInput("country", "Choose Country(ies):", 
                       choices = unique(as.character(country$country)))
  } else { return(NULL) }
})

output$selectRegion <- renderUI({
  if(input$level %in% c("Region", "District") & !is.null(input$country)){
    regionList <- unique(as.character(region[region$country %in% input$country, "region"]))
    checkboxGroupInput("region", "Choose Region(s):", 
                       choices = regionList)
  } else { return(NULL) }
})

output$selectDistrict <- renderUI ({
  if(input$level == "District" & !is.null(input$country) & !is.null(input$region)){
    districtList <- unique(as.character(district[district$region %in% input$region & 
                                                   district$country %in% input$country, "district"]))
    checkboxGroupInput("district", "Choose District(s):", 
                       choices = districtList)
  } else { return(NULL) }  
})
  
## Build Plot Panels ################################################################################
  
stackedBar <- reactive({
  data <- plotData()
  ggplot(data, aes(x = workbook_year, y = value, fill = variable)) + 
    geom_bar(stat="identity") + 
    scale_y_continuous(labels = comma) +
    scale_x_continuous(breaks = seq(min(data$workbook_year, na.rm=TRUE), 
                                    max(data$workbook_year, na.rm=TRUE))) 
})

output$plot <- renderPlot({
  stackedBar()
})

output$table <- renderTable({setReport()}, include.rownames=FALSE)

## Dataset Functions ################################################################################

  setReport <- reactive({
    
    persons_col <- c("persons_treated_usaid", "pop_stop_mda")
    
    dist_col <- c("districts_treated_usaid", "districts_stop_mda")
    
    if(input$level == "USAID portfolio") {
      data <- portfolio
      if(input$report == "persons"){data <- data[, c("disease", "workbook_year", persons_col)]}
      if(input$report == "districts"){data <- data[, c("disease", "workbook_year", dist_col)]}
      data <- data[(data$disease %in% input$disease), ]
    }
    if(input$level == "Project"){
      data <- project
      if(input$report == "persons"){data <- data[, c("project", "disease", "workbook_year", persons_col)]}
      if(input$report == "districts"){data <- data[, c("project", "disease", "workbook_year", dist_col)]}
      data <- data[(data$disease %in% input$disease & data$project %in% input$project), ]
    }
    if(input$level == "Country"){
      data <- country
      if(input$report == "persons"){data <- data[, c("country", "disease", "workbook_year", persons_col)]}
      if(input$report == "districts"){data <- data[, c("country", "disease", "workbook_year", dist_col)]}
      data <- data[(data$disease %in% input$disease & data$country %in% input$country), ]
    }
    if(input$level == "Region"){
      data <- region
      if(input$report == "persons"){data <- data[, c("country", "region", "disease", "workbook_year", persons_col)]}
      if(input$report == "districts"){data <- data[, c("country", "region", "disease", "workbook_year", dist_col)]}
      data <- data[(data$disease %in% input$disease & 
                      data$country %in% input$country &
                      data$region %in% input$region), ]
      
    }
    if(input$level == "District"){
      data <- district
      if(input$report == "persons"){data <- data[, c("country", "region", "district", 
                                                     "disease", "workbook_year", persons_col)]}
      if(input$report == "districts"){data <- data[, c("country", "region", "district", 
                                                       "disease", "workbook_year", dist_col)]}
      data <- data[(data$disease %in% input$disease & 
                      data$country %in% input$country &
                      data$region %in% input$region & 
                      data$district %in% input$district), ]
      
    }
    
    return(data)
  })

 setID <- reactive({
   if(input$level == "USAID portfolio") {
     return(c("disease", "workbook_year"))
   }
   if(input$level == "Project") {
     return(c("project", "disease", "workbook_year"))
   }
   if(input$level == "Country") {
     return(c("country", "disease", "workbook_year"))
   }
   if(input$level == "Region") {
     return(c("country", "region", "disease", "workbook_year"))
   }
   if(input$level == "District") {
     return(c("country", "region", "district", "disease", "workbook_year"))
   }
 })

 plotData <- reactive({
    data <- setReport()
    id_var <- ifelse(input$level == "USAID portfolio", c("disease", "workbook_year"), 
                     ifelse(input$level == "Project", c("project", "disease", "workbook_year"), 
                     ifelse(input$level == "Country", c("country", "disease", "workbook_year"), "poop")))
    return(melt(data, id.vars = setID()))
  })

})
