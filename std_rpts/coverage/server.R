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
                    "Program Coverage - 3" = "prg_3",
                    "Program Coverage - 4" = "prg_4", 
                    "Program Coverage - 5" = "prg_5"))
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
  
  output$selectLevel2 <- renderUI({
    if(!is.null(input$report) & input$report %in% c("prg_3", "epi_3")){
      selectInput("level", "Select Report Level", 
                  c("USAID portfolio", "Project", "Country", "Region"))}
  })
  
  output$selectProject <- renderUI({
    if(!is.null(input$level) & input$level == "Project"){
      checkboxGroupInput("project", "Choose Project(s):", 
                         choices = unique(as.character(country$project)), 
                         selected = "ENVISION")
    }
  })
  
  output$selectCountry <- renderUI({
    if((!is.null(input$level) & input$level %in% c("Country", "Region", "District"))){
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
  
  output$selectYear <- renderUI({
    if(input$report %in% c("prg_3")){
      selectInput("year", "Choose Year:", 
                  c(seq(2007, max(district$workbook_year), by=1)))
    }
  })
  
  ## Build Main Panel ##############################################################################
  
  output$main <- renderUI({
    if(!is.null(input$report) & input$report %in% c("prg_1", "epi_1")){
      mainPanel(
        downloadButton("exportData", "Download Data"), 
        tableOutput('table')
        )
    } else if(!is.null(input$report) & input$report %in% c("prg_3", "prg_4", "epi_4", "prg_5")){
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
    } else if(!is.null(input$report) & input$report %in% c("prg_5")){
      medPlot()
    } else if(!is.null(input$report) & input$report %in% c("prg_3")){
      histPlot()
    }
  })
  
  cvgPlot <- reactive({
    plotData <- setData()
    max_cvg <- max(plotData[,"prg_cvg"], na.rm=TRUE)
    
    ggplot(plotData, aes(x=workbook_year, y=prg_cvg, group=group, color=group, shape=group)) + 
      geom_line() + 
      scale_x_continuous(breaks = seq(min(plotData$workbook_year, na.rm=TRUE), 
                                      max(plotData$workbook_year, na.rm=TRUE))) + 
      scale_y_continuous(breaks = round(seq(0, max_cvg, by=0.1), 1)) + 
      expand_limits(y=0) +
      geom_hline(aes(yintercept=0.8), colour="#990000", linetype="dashed") + 
      labs(title = 'Program Coverage',
           x = 'Fiscal Year', 
           y = 'Program Coverage')  
  })
  
  medPlot <- reactive({
    lineData <- setData()
    
    ggplot(lineData, aes(x = workbook_year, y = districts_treated, color = 'Districts Treated')) + 
      geom_bar(stat="identity") + 
      geom_line(aes(x = workbook_year, y = med_prg_cvg, color = 'Median Program Coverage')) + 
      scale_x_continuous(breaks = seq(min(lineData$workbook_year, na.rm=TRUE), 
                                      max(lineData$workbook_year, na.rm=TRUE))) + 
      scale_y_continuous(breaks = round(seq(0, 100, by=20), 1)) + 
      labs(title = 'Program Coverage',
           x = 'Fiscal Year')
  })
  
  histPlot <- reactive({
    df <- setData()
    # color code variable
    df$colcode <- NA
    df[(!is.na(df$prg_cvg) & df$prg_cvg < 0.6), "colcode"] <- "red"
    df[(!is.na(df$prg_cvg) & df$prg_cvg >= 0.6 & df$prg_cvg < 0.8), "colcode"] <- "yellow"
    df[(!is.na(df$prg_cvg) & df$prg_cvg >= 0.8 & df$prg_cvg < 1), "colcode"] <- "green"
    df[(!is.na(df$prg_cvg) & df$prg_cvg >= 1), "colcode"] <- "blue"
    
    fillPalette <- c("red"="darkred", 
                     "yellow"="yellow", 
                     "green"="darkgreen", 
                     "blue"="blue")
    
    ggplot(df, aes(x=prg_cvg, fill=colcode)) + 
      geom_histogram(binwidth=0.2, color="black") + 
      labs(title = paste("Program Coverage Distribution", " - ", input$disease, ": ", input$year, sep=""),
           x = 'Program Coverage', 
           y = 'Number of Districts') + 
      theme(legend.position="none") + 
      scale_x_continuous(breaks = round(seq(0, (max(df[,'prg_cvg'], na.rm=TRUE) + 0.1), by=0.2), 1)) +
      scale_fill_manual(values=fillPalette) # manually set colors as mapped in fillPalette object
    
  })
  
  
  ## Dataset Functions ################################################################################
  
  setData <- reactive({
    prg_1 <- c("country", "disease", "workbook_year", "districts_treated", "districts_bad_prg_cvg")
    epi_1 <- c("country", "disease", "workbook_year", "districts_treated", "districts_bad_epi_cvg")
    prg_5 <- c("country", "region", "district", "disease", "workbook_year", "prg_cvg")
    
    if(input$report == "prg_1"){
      data <- country[, prg_1]
      data <- data[with(data, order(disease, workbook_year)), ]
    } else if(input$report == "epi_1"){
      data <- country[, epi_1]
      data <- data[with(data, order(disease, workbook_year)), ]
    } else if(input$report == "prg_3"){
      data <- district
      if(input$level == "USAID portfolio"){
        data <- data[(data$workbook_year %in% input$year & 
                        data$disease %in% input$disease), ]
      } else if(input$level == "Project"){
        data <- data[(data$project %in% input$project &
                        data$workbook_year %in% input$year & 
                        data$disease %in% input$disease), ] 
      } else if(input$level == "Country"){
        data <- data[(data$country %in% input$country & 
                        data$workbook_year %in% input$year & 
                        data$disease %in% input$disease), ]
      } else if(input$level == "Region"){
        data <- data[(data$country %in% input$country & 
                        data$region %in% input$region &
                        data$workbook_year %in% input$year & 
                        data$disease %in% input$disease), ]
      } 
    } else if(input$report == "prg_4"){
      data <- setLevel()
      data[data$disease == input$disease, ]
    } else if(input$report == "prg_5"){
      data <- district[(district$country %in% input$country & district$disease %in% input$disease), prg_5]
      data$prg_cvg <- (data$prg_cvg * 100)
      data <- ddply(data, c('country', 'workbook_year', 'disease'), summarize, 
                    districts_treated = sum(prg_cvg > 0, na.rm=TRUE), 
                    med_prg_cvg = median(prg_cvg, na.rm=TRUE))
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
      data['group'] <- data$disease
    } else if(!is.null(input$level) & input$level == "Project"){
      data <- country[(country$disease %in% input$disease & country$project %in% input$project), ]
      data <- ddply(data, c('project', 'disease', 'workbook_year'), summarize, 
                    persons_treated = sum(persons_treated), 
                    persons_targeted = sum(persons_targeted), 
                    prg_cvg = (sum(persons_treated) / sum(persons_targeted)))
      data['group'] <- data$project
    } else if(!is.null(input$level) & input$level == "Country"){
      data <- country[(country$disease %in% input$disease & country$country %in% input$country), ]
      data <- ddply(data, c('country', 'disease', 'workbook_year'), summarize, 
                    persons_treated = sum(persons_treated), 
                    persons_targeted = sum(persons_targeted), 
                    prg_cvg = (sum(persons_treated) / sum(persons_targeted)))
      data['group'] <- data$country
    } else if(!is.null(input$level) & input$level == "Region"){
      data <- district[(district$disease %in% input$disease & 
                          district$country %in% input$country & 
                          district$region %in% input$region), ]
      data <- ddply(data, c('country', 'region', 'disease', 'workbook_year'), summarize, 
                    persons_treated = sum(persons_treated_usaid), 
                    persons_targeted = sum(persons_targeted_usaid), 
                    prg_cvg = (sum(persons_treated_usaid) / sum(persons_targeted_usaid)))
      data['group'] <- data$region
    } else if(!is.null(input$level) & input$level == "District"){
      data <- district[(district$disease %in% input$disease & 
                          district$country %in% input$country & 
                          district$region %in% input$region & 
                          district$district %in% input$district), ]
      data <- ddply(data, c('country', 'region', 'district', 'disease', 'workbook_year'), summarize, 
                    persons_treated = sum(persons_treated_usaid), 
                    persons_targeted = sum(persons_targeted_usaid), 
                    prg_cvg = (sum(persons_treated_usaid) / sum(persons_targeted_usaid)))
      data['group'] <- data$district
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
