library(shiny)

shinyUI(
  fluidPage(
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
           
           selectInput("disease", "Select a Disease", 
                        c("LF" = "lf", "Oncho" = "oncho", "Schisto" = "schisto", 
                          "STH" = "sth", "Trachoma" = "trachoma")),
           
           selectInput("level", "Select Report Level", 
                       c("USAID portfolio", "Project", "Country", "Region", "District")),
           
           uiOutput("selectProject"), 
           uiOutput("selectCountry"),
           uiOutput("selectRegion"), 
           uiOutput("selectDistrict")
           ),
    column(9, 
           plotOutput('plot'),
           fluidRow(
             downloadButton("exportData", "Download Data"),
             br(), br(),
             tableOutput('table')
             )
           )
  )
  )
)