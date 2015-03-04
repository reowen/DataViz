library(shiny)

shinyUI(fluidPage(
  #   tags$style(type="text/css",
  #              ".shiny-output-error { visibility: hidden; }",
  #              ".shiny-output-error:before { visibility: hidden; }"
  #   ),
  
  titlePanel('Disease Reports'),
  
  fluidRow(
    column(3, radioButtons("funding", 
                           label = "Funding", 
                           choices = c("USAID support" = "usaid"), 
                           selected = "usaid", 
                           inline = TRUE),
           selectInput("report", "Choose a Report:", 
                       c("Disease persons" = "persons", 
                         "Disease districts" = "districts")),
           radioButtons("disease", label = "Select a Disease", 
                        c("LF" = "lf", "Oncho" = "oncho", "Schisto" = "schisto", 
                          "STH" = "sth", "Trachoma" = "trachoma")),
           radioButtons("level", 
                        label = "Select Report Level", 
                        choices = c("USAID portfolio", "Project", "Country", "Region", "District"))), 
    
    column(3, uiOutput("selectProject"), 
           uiOutput("selectCountry")), 
    
    column(3, uiOutput("selectRegion")), 
    
    column(3, uiOutput("selectDistrict"))
  ),
  
  br(), hr(),
  fluidRow(
    plotOutput('plot'),
    tableOutput('table')
    )
  )
)