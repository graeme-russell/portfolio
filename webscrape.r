library("readxl")
library("rvest")

# Read list of scaped or copied URLs and Company Names

YearData <- read.csv("YearData.csv", as.is = TRUE)

# Check for correct selector

# read_html(YearData$URL[1]) %>% 
#   html_nodes(".dataTable__value--3n5tL") %>% 
#   html_text()

# For each URL fetch the html text (or table) of the requried data

df <- lapply(YearData$URL,
                    function(url){
                      url %>% read_html() %>% 
                        html_nodes(".dataTable__value--3n5tL") %>% 
                        html_text()
                    })

df <- data.frame(matrix(unlist(df), nrow=length(df), byrow=T))

# Name and Clean the data as appropriate

names(df) = c("Industry", "Location", "Industry Ranking", "Previous Industry Ranking", "Previous Top 50 Ranking", "Website","Overall Score", "Innovation", "People Management", "Use of corporate assets", "Social responsibility", "Quality Management", "Financial Soundess", "Long-term investment value", "Quality of products/services", "Global competitiveness")

# Bind to original data

YearData <- cbind(YearData, df)
