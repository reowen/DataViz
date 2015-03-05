library(shiny)

shinyUI(
  fluidPage(
    #   tags$style(type="text/css",
    #              ".shiny-output-error { visibility: hidden; }",
    #              ".shiny-output-error:before { visibility: hidden; }"
    #   ),
    
    titlePanel('Coverage Reports'),
    
    fluidRow(
      column(3, radioButtons("funding", 
                             label = "Funding", 
                             choices = c("USAID support" = "usaid"), 
                             selected = "usaid", 
                             inline = TRUE),           
             
             selectInput("type", "Coverage Type:", 
                         c("Program Coverage" = "prg", 
                           "Epi Coverage" = "epi")),
             
             uiOutput("selectReport"), 
             uiOutput("selectLevel"), 
             uiOutput("selectProject"), 
             uiOutput("selectDisease"),
             uiOutput("selectCountry"),
             uiOutput("selectRegion"), 
             uiOutput("selectDistrict")
      ),
      column(9, uiOutput('main'))
    )
  )
)