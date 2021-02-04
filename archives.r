library("rvest")

# Base version of archived data web scraper, modified for each year (shown: 2012)

alpha = LETTERS
URLS = paste0("https://archive.fortune.com/magazines/fortune/most-admired/2012/top358/",alpha,".html")
URLS[1] = "https://archive.fortune.com/magazines/fortune/most-admired/2012/top358/"

# Take each URL and fetch html table (second one in source code)

df <- lapply(URLS,
                    function(url){
                      url %>% read_html() %>% 
                        html_nodes("table") %>% 
                        .[[2]] %>%
                        html_table()
                    })
                    
# Collapse nested list 

YearData <- plyr::rbind.fill(df)
