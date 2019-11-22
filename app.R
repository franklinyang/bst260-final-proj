library(shiny)
library(DBI)
library(tidyverse)
library(forcats)
require(maps)
require(viridis)
require(openintro)

# Begin connection
con <- dbConnect(RSQLite::SQLite(), "database/db.sqlite")

# Plotting performance score / complication score against total spend and segmenting by star rating
ui <- fluidPage(
  titlePanel("BST260 Final Project Visualizations"),
  tabsetPanel(
    tabPanel(
      "Performance, Complication, Overall Scores by state",
      selectInput(
        'measure',
        'Measure',
        c('hospital_overall_rating',
          'total_performance_score_patient_experience',
          'hospital_level_complications_score')
      ),
      plotOutput(outputId = "performance_score_plot")
    )
  )
)

server <- function(input, output) {
  # also use total patient experience score and complication score
  # life_expectancy_data <- reactive(gapminder %>% filter(country == 'United States' | country == input$comp_country))
  hospital_data <- dbFetch(
    dbSendQuery(
      con,
      "
        SELECT
          state,
          AVG(hospital_overall_rating) AS hospital_overall_rating,
          AVG(total_performance_score_patient_experience) AS total_performance_score_patient_experience,
          AVG(hospital_level_complications_score) AS hospital_level_complications_score
        FROM master_hospital_table GROUP BY state
      "
    )
  )
  # map state abbrevations to full state name for the map (eg: "NY" -> "new york")
  hospital_data$region <- sapply(hospital_data$state, function(state) tolower(abbr2state(state)))
  measure <- reactive(input$measure)
  output$performance_score_plot <- renderPlot({
    states_map <- map_data("state")
    arrests_map <- left_join(states_map, hospital_data, by = "region")

    # Create the map
    ggplot(arrests_map, aes(long, lat, group = group)) +
      geom_polygon(aes(fill = hospital_overall_rating), color = "white")
      # scale_fill_viridis_c(option = "C")

  })
}

# Run the application 
shinyApp(ui = ui, server = server)