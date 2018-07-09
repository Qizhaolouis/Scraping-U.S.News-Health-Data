library(shiny)
library(shinydashboard)
library(tidyverse)
library(rbokeh)
library(maps)
data(world.cities)
data = read_csv('best_hospital.csv')
unique(data$specialty)
ui <- dashboardPage(
  dashboardHeader(title = "Best Hospitals by U.S.News", titleWidth = 500),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Data Table", tabName = "widgets", icon = icon("th"))
    )
  ),
  ## Body content
  dashboardBody(
    tabItems(
      # First tab content
      tabItem(tabName = "dashboard",
              h1("Hospital Map"),
              fluidRow(  
              box(background = "light-blue", solidHeader = TRUE,
                selectInput('select1', 'specialty', unique(data$specialty)))
              ),
              rbokehOutput("plot1")
      ),
      
      # Second tab content
      tabItem(tabName = "widgets",
              h1("Top 20 Hospitals of Different Specialty"),
              fluidRow(              
                box(dataTableOutput("table1"),pageLength = 5),
                                      
                box(title = "Specialty", background = "aqua", solidHeader = TRUE,
                    selectInput('select', 'specialty', unique(data$specialty))))
      )
      
      )
    )
  )


server <- function(input, output) {
  output$table1 <- renderDataTable(
    data %>%filter(specialty == input$select) %>% .[c('name','score','city','state')],
    options = list(pageLength = 5))
  output$plot1 <- renderRbokeh({
    caps <- subset(world.cities, capital == 1)
    caps$population <- prettyNum(caps$pop, big.mark = ",")
    figure(width = 1400, height = 800, padding_factor = 0) %>%
      ly_map("world", col = "coral") %>%
      ly_points(as.numeric(long), as.numeric(lat), data = data[data$specialty==input$select1,], size = 3,
                color = score,
                hover = c(name, city, state, score))
  })
}
shinyApp(ui, server)


