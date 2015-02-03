library(shiny)

shinyUI(fluidPage(
  titlePanel("Coverage Analysis Tool"),
  
  uiOutput("ui"),
  
  mainPanel(
    fluidRow(
       plotOutput("plotHistory")
      ),
    
    br(), 
    br(),
    
    fluidRow(
      tableOutput("tableHistory")
      ),  
    
    br(), 
    br(),
    
    fluidRow(
      plotOutput("histograms")
      ), 
    
    br(), 
    br(),
    
    fluidRow(
      plotOutput("stackedBars")
      ), 
    
    br(), 
    br(),
    
    fluidRow(
      tableOutput("districtUnder60")
      ), 
    
    br(), 
    br(),
    
    fluidRow(
      tableOutput("district60to80")
    ),    
    
    br(), 
    br(),
    
    fluidRow(
      tableOutput("district80to100")
    ),    
    
    br(), 
    br(),
    
    fluidRow(
      tableOutput("district100plus")
    )  
  )
))