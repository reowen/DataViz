library(shiny)

shinyUI(fluidPage(
  #   tags$style(type="text/css",
  #              ".shiny-output-error { visibility: hidden; }",
  #              ".shiny-output-error:before { visibility: hidden; }"
  #   ),
  
  titlePanel('Disease Reports'),
  
  sidebarLayout(
    sidebarPanel(
      radioButtons("funding", 
                   label = "Funding", 
                   choices = c("USAID support" = "usaid", "All support" = "all"), 
                   selected = "usaid", 
                   inline = TRUE),
      radioButtons("level", 
                   label = "Select Report Level", 
                   choices = c("District", "Region", "Country", "Project", "USAID portfolio"))
      selectInput("report", "Choose a Report:", 
                  choices = c("Disease persons", "Disease districts")),
      downloadButton('downloadData', 'Download')
    ),
    mainPanel(
      plotOutput('plot'),
      tableOutput('table')
    )
  )
))