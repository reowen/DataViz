library(shiny)

shinyUI(navbarPage("Coverage Analysis Tool", 
                   tabPanel("Country Snapshot", 
                            uiOutput("uiMainTab"), 
                            
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
                                h4("Districts with Program Coverage Under 60%"),
                                tableOutput("districtUnder60")
                              ), 
                              
                              br(), 
                              br(),
                              
                              fluidRow(
                                h4("Districts with Program Coverage 60% - 80%"),
                                tableOutput("district60to80")
                              ),    
                              
                              br(), 
                              br(),
                              
                              fluidRow(
                                h4("Districts with Program Coverage 80% - 100%"),
                                tableOutput("district80to100")
                              ),    
                              
                              br(), 
                              br(),
                              
                              fluidRow(
                                h4("Districts with Program Coverage Over 100%"),
                                tableOutput("district100plus")
                              )  
                            )
                            ), 
                   tabPanel("District-Trends", 
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
                              
                              plotOutput("districtLinegraph"), 
                              textOutput("testText2")
                              )
                            )
))