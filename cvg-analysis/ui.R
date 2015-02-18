library(shiny)

shinyUI(navbarPage("Coverage Analysis Tool", 
                   
                   tabPanel("Country Snapshot", 
                            uiOutput("uiMainTab"), 
                            
                            tags$style(type="text/css",
                                       ".shiny-output-error { visibility: hidden; }",
                                       ".shiny-output-error:before { visibility: hidden; }"
                            ),
                            
                            mainPanel(
                              fluidRow(
                                h3("Coverage Trends"), 
                                plotOutput("plotHistory")
                              ),
                              
                              br(), 
                              br(),
                              
                              fluidRow(
                                h3("Country Summary Table"),
                                tableOutput("tableHistory")
                              ),  
                              
                              br(), 
                              br(),
                              
                              fluidRow(
                                h3("Program Coverage Distribution by Disease"),
                                plotOutput("histograms")
                              ), 
                              
                              br(), 
                              br(),
                              
                              fluidRow(
                                h3("Region-Level Program Coverage"),
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
                                h3(textOutput("districtHeader"))
                                ),
                              
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
                            ), 
                   tabPanel("District-Trends", 
                            
                            tags$style(type="text/css",
                                       ".shiny-output-error { visibility: hidden; }",
                                       ".shiny-output-error:before { visibility: hidden; }"
                            ),
                            
                            titlePanel(
                              textOutput("districtTitle")
                              ), 
                            
                            sidebarPanel(
                              
                              tags$form(
                                uiOutput("uiRegion"), 
                                
                                uiOutput("uiDistrict"),
                                
                                actionButton("districtButton", "Submit")
                                ) 
                              ),

                            mainPanel(
                              uiOutput("districtTabIntro"),
                              
                              conditionalPanel("input.district != null", 
                                               plotOutput("districtLinegraph")),
                              
                              conditionalPanel("input.district != null", 
                                               tableOutput("districtHistoryTable"))
                              )
                            )
))