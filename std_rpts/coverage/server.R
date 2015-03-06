library(shiny)
library(plyr)
library(ggplot2)

district <- read.csv('data/district.csv')
country <- read.csv('data/country.csv')

shinyServer(function(input, output) {
  
  ## Build Input Panels #########################################################################
  
  output$selectReport <- renderUI({
    if(input$type == "prg"){
      selectInput("report", "Select a Report:", 
                  c("Program Coverage - 1" = "prg_1", 
                    "Program Coverage - 4" = "prg_4"))
    } else if(input$type == "epi"){ 
      selectInput("report", "Select a Report:", 
                  c("Epi Coverage - 1" = "epi_1"))
    } else { return(NULL) }
  })
  
  output$selectDisease <- renderUI({
    if(!is.null(input$report) & !input$report %in% c("prg_1", "epi_1"))
    selectInput("disease", "Select a Disease", 
                c("LF" = "lf", "Oncho" = "oncho", "Schisto" = "schisto", 
                  "STH" = "sth", "Trachoma" = "trachoma"))
  })
  
  output$selectLevel <- renderUI({
    if(!is.null(input$report) & input$report %in% c("prg_4", "epi_4")){
    selectInput("level", "Select Report Level", 
                c("USAID portfolio", "Project", "Country", "Region", "District"))}
  })
  
  output$selectProject <- renderUI({
    if(!is.null(input$level) & input$level == "Project"){
      checkboxGroupInput("project", "Choose Project(s):", 
                         choices = unique(as.character(country$project)), 
                         selected = "ENVISION")
    }
  })
  
  output$selectCountry <- renderUI({
    if(!is.null(input$level) & input$level %in% c("Country", "Region", "District")){
      checkboxGroupInput("country", "Choose Country(ies):", 
                         choices = unique(as.character(country$country)), 
                         selected = "Benin")
    }
  })
  
  output$selectRegion <- renderUI({
    if((!is.null(input$level) & input$level %in% c("Region", "District")) & !is.null(input$country)){
      regionList <- unique(as.character(district[district$country %in% input$country, "region"]))
      checkboxGroupInput("region", "Choose Region(s):", 
                         choices = regionList)
    }
  })
  
  output$selectDistrict <- renderUI ({
    if(input$level == "District" & !is.null(input$country) & !is.null(input$region)){
      districtList <- unique(as.character(district[district$region %in% input$region & 
                                                     district$country %in% input$country, "district"]))
      checkboxGroupInput("district", "Choose District(s):", 
                         choices = districtList)
    } else { return(NULL) }  
  })
  
  ## Build Main Panel ##############################################################################
  
  output$main <- renderUI({
    if(!is.null(input$report) & input$report %in% c("prg_1", "epi_1")){
      mainPanel(
        downloadButton("exportData", "Download Data"), 
        tableOutput('table')
        )
    } else if(!is.null(input$report) & input$report %in% c("prg_4", "epi_4")){
      mainPanel(
        plotOutput('plot'), 
        tableOutput('test')
        )
    }
  })
  
  ## Build Main Panel Objects ################################################################################
  output$test <- renderTable({
    setData()
  })
  
  output$table <- renderTable({
    if(!is.null(input$report) & input$report %in% c("prg_1", "epi_1")){
      pivotCountry()
    }
  }, include.rownames=FALSE)
  
  output$plot <- renderPlot({
    if(!is.null(input$report) & input$report %in% c("prg_4", "epi_4")){
      cvgPlot()
    }
  })
  
  cvgPlot <- reactive({
    plotData <- setData()
    max_cvg <- max(plotData[,"prg_cvg"], na.rm=TRUE)
    
    ggplot(plotData, aes(x=workbook_year, y=prg_cvg)) + 
      geom_line() + 
      scale_x_continuous(breaks = seq(min(plotData$workbook_year, na.rm=TRUE), 
                                      max(plotData$workbook_year, na.rm=TRUE))) + 
      scale_y_continuous(breaks = round(seq(0, max_cvg, by=0.1), 1)) +
      geom_hline(aes(yintercept=0.8), colour="#990000", linetype="dashed")
      
  })
  
  ## Dataset Functions ################################################################################
  
  setData <- reactive({
    prg_1 <- c("country", "disease", "workbook_year", "districts_treated", "districts_bad_prg_cvg")
    epi_1 <- c("country", "disease", "workbook_year", "districts_treated", "districts_bad_epi_cvg")
    
    if(input$report == "prg_1"){
      data <- country[, prg_1]
      data <- data[with(data, order(disease, workbook_year)), ]
    } else if(input$report == "epi_1"){
      data <- country[, epi_1]
      data <- data[with(data, order(disease, workbook_year)), ]
    } else if(input$report == "prg_4"){
      data <- setLevel()
      data[data$disease == input$disease, ]
    }
    return(data)
  })
  
  setLevel <- reactive({
    if(!is.null(input$level) & input$level == "USAID portfolio"){
      data <- ddply(country, c('disease', 'workbook_year'), summarize, 
                    persons_treated = sum(persons_treated), 
                    persons_targeted = sum(persons_targeted),
                    prg_cvg = (sum(persons_treated) / sum(persons_targeted)))
      data <- data[data$disease %in% input$disease, ]
    } else if(!is.null(input$level) & input$level == "Project"){
      data <- country[(country$disease %in% input$disease & country$project %in% input$project), ]
      data <- ddply(data, c('project', 'disease', 'workbook_year'), summarize, 
                    persons_treated = sum(persons_treated), 
                    persons_targeted = sum(persons_targeted), 
                    prg_cvg = (sum(persons_treated) / sum(persons_targeted)))
    } else if(!is.null(input$level) & input$level == "Country"){
      data <- country[(country$disease %in% input$disease & country$country %in% input$country), ]
      data <- ddply(data, c('country', 'disease', 'workbook_year'), summarize, 
                    persons_treated = sum(persons_treated), 
                    persons_targeted = sum(persons_targeted), 
                    prg_cvg = (sum(persons_treated) / sum(persons_targeted)))
    } else if(!is.null(input$level) & input$level == "Region"){
      data <- district[(district$disease %in% input$disease & 
                          district$country %in% input$country & 
                          district$region %in% input$region), ]
      data <- ddply(data, c('country', 'region', 'disease', 'workbook_year'), summarize, 
                    persons_treated = sum(persons_treated_usaid), 
                    persons_targeted = sum(persons_targeted_usaid), 
                    prg_cvg = (sum(persons_treated_usaid) / sum(persons_targeted_usaid)))
    } else if(!is.null(input$level) & input$level == "District"){
      data <- district[(district$disease %in% input$disease & 
                          district$country %in% input$country & 
                          district$region %in% input$region & 
                          district$district %in% input$district), ]
      data <- ddply(data, c('country', 'region', 'district', 'disease', 'workbook_year'), summarize, 
                    persons_treated = sum(persons_treated_usaid), 
                    persons_targeted = sum(persons_targeted_usaid), 
                    prg_cvg = (sum(persons_treated_usaid) / sum(persons_targeted_usaid)))
    }
    return(data)
  })
  
  pivotCountry <- reactive({
    table <- setData()
    table <- reshape(table, 
                     timevar = "workbook_year", 
                     idvar = c("country", "disease"), 
                     direction = "wide")
    table <- table[with(table, order(country, disease)), ]
    return(table)
  })
  
  
  ## Download Handlers #########################################################################################
  
#   output$exportData <- downloadHandler(
#     filename = function(){
#       paste(input$level, " - ", input$report, '.csv', sep='')
#     }, 
#     content = function(file){
#       write.csv(setReport(), file)
#     }
#   )
  
})
