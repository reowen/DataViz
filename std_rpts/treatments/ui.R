library(shiny)

shinyUI(fluidPage(
#   tags$style(type="text/css",
#              ".shiny-output-error { visibility: hidden; }",
#              ".shiny-output-error:before { visibility: hidden; }"
#   ),
  
  titlePanel('Treatments - Standard Reports'),
  
  sidebarLayout(
    sidebarPanel(
      radioButtons("funding", 
                   label = "Funding", 
                   choices = c("USAID support" = "usaid"), 
                   selected = "usaid", 
                   inline = TRUE),
      selectInput("report", "Choose a Report:", 
                  choices = c("LF treatments", "Oncho treatments", "Schisto treatments", 
                              "STH treatments - total", "STH treatments - SAC", "Trachoma treatments")),
      downloadButton('downloadData', 'Download')
    ),
    mainPanel(
      tableOutput('table')
    )
  )
))
