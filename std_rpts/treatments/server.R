library(shiny)

data <- read.csv('data/data.csv')

# sets country access permissions
countries <- c("Benin", "Cameroon", "Democratic Republic of Congo", "Ethiopia", "Guinea", "Haiti", "Indonesia", 
               "Mali", "Mozambique", "Nepal", "Nigeria", "Senegal", "Sierra Leone", "Tanzania", "Uganda")

# restrict countries in "data" object to only ones with access permissions
data <- data[data$country %in% countries, ]




# create lf_col, oncho_col, etc...



shinyServer(function(input, output) {
  
  setFunding <- reactive({ 
    # define columns for each funding support option
    usaid_cols <- c("country", "disease", "workbook_year", "persons_targeted_usaid", "sac_targeted_usaid", 
                    "persons_targeted_usaid_r1", "persons_targeted_usaid_r2", "sac_targeted_usaid_r1", "sac_targeted_usaid_r2",   
                    "persons_treated_usaid", "sac_treated_usaid", "persons_treated_usaid_r1", "persons_treated_usaid_r2", 
                    "sac_treated_usaid_r1", "sac_treated_usaid_r2", "persons_at_risk", "sac_at_risk") 
    usaid_names <- c("country", "disease", "workbook_year", "targeted", "sac_targeted", "targeted_r1", "targeted_r2", 
                     "sac_targeted_r1", "sac_targeted_r2", "treated", "sac_treated", "treated_r1", "treated_r2", 
                     "sac_treated_r1", "sac_treated_r2", "at_risk", "sac_at_risk")
    
    all_cols <- c("country", "disease", "workbook_year", "persons_targeted_all", "persons_targeted_all_r1", 
                  "persons_targeted_all_r2", "persons_treated_all", "sac_treated_all", "persons_treated_all_r1", 
                  "sac_treated_all_r1", "sac_treated_all_r2", "persons_at_risk", "sac_at_risk", "persons_treated_all_r2")
    all_names <- c("country", "disease", "workbook_year", "targeted", "targeted_r1", "targeted_r2", "treated", "sac_treated", 
                   "treated_r1", "sac_treated_r1", "sac_treated_r2", "at_risk", "sac_at_risk", "treated_r2")

    if(!is.null(input$funding) && input$funding == "all"){
      data <- data[, all_cols]
    } else {
      data <- data[, usaid_cols]
      for(i in 1:length(usaid_cols)){colnames(data)[i] <- usaid_names[i]} # set column names
    }
    return(data)
  })
  
  setReport <- reactive({
    # define columns for each funding support option
    lf_cols <- c("country", "workbook_year", "at_risk", "targeted", "treated")
    oncho_cols <- c("country", "workbook_year", "at_risk", "targeted_r1", "treated_r1", "targeted_r2", "treated_r2", "treated")
    sch_cols <- c("country", "workbook_year", "at_risk", "targeted", "treated", "sac_at_risk", "sac_targeted", "sac_treated")
    sth_total_cols <- c("country", "workbook_year", "at_risk", "targeted_r1", "treated_r1", "targeted_r2", "treated_r2", "treated")
    sth_sac_cols <- c("sac_at_risk", "sac_targeted_r1", "sac_treated_r1", "sac_targeted_r2", "sac_treated_r2", "sac_treated")
    tra_cols <- c("country", "workbook_year", "at_risk", "targeted", "treated")
    
    # generate data
    report <- switch(input$report, 
                     "LF treatments" = setFunding()[setFunding()[, "disease"] == "lf", lf_cols], 
                     "Oncho treatments" = setFunding()[setFunding()[, "disease"] == "oncho", oncho_cols], 
                     "Schisto treatments" = setFunding()[setFunding()[, "disease"] == "schisto", sch_cols],
                     "STH treatments - total" = setFunding()[setFunding()[, "disease"] == "sth", sth_total_cols], 
                     "STH treatments - SAC" = setFunding()[setFunding()[, "disease"] == "sth", sth_sac_cols], 
                     "Trachoma treatments" = setFunding()[setFunding()[, "disease"] == "trachoma", tra_cols])
    report <- report[with(report, order(workbook_year)), ]
    report <- reshape(report, 
                      timevar = "workbook_year", 
                      idvar = "country", 
                      direction = "wide")
    return(report)
  })
  
  output$table <- renderTable({setReport()}, include.rownames=FALSE)
  
  output$downloadData <- downloadHandler(
      filename = function(){
        paste(input$report, ".csv", sep="")
      }, 
      content = function(file){
        write.csv(setReport(), file)
      }
    )

})
