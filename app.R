library(shiny)
library(DBI)
library(tidyverse)
library(forcats)
require(maps)
require(viridis)
require(openintro)

# Begin connection
con <- dbConnect(RSQLite::SQLite(), "database/db.sqlite")
states_outcomes_data <- dbFetch(
  dbSendQuery(
    con,
    "
        SELECT
          state,
          AVG(hospital_overall_rating) AS hospital_overall_rating,
          AVG(total_performance_score_patient_experience) AS total_performance_score_patient_experience,
          AVG(hospital_level_complications_score) AS hospital_level_complications_score
        FROM master_hospital_table
        GROUP BY state
      "
  )
)
facility_outcomes_data <- dbFetch(
  dbSendQuery(
    con,
    "
        SELECT
          facility_id,
          total_performance_score_patient_experience,
          hospital_level_complications_score,

          hc_policy_focused_state,
          median_household_income,
          perc_pop_below_poverty,
          pop_with_healthinsurance,
          total_spend,
          median_household_income
        FROM master_hospital_table
      "
  )
)

# Plotting performance score / complication score against total spend and segmenting by star rating
ui <- fluidPage(
  titlePanel("BST260 Final Project Visualizations"),
  tabsetPanel(
    tabPanel(
      "Performance, Complication, Overall Scores by state",
      selectInput(
        'measure',
        'Measure',
        c('hospital_overall_rating', 'total_performance_score_patient_experience', 'hospital_level_complications_score'),
      ),
      plotOutput(outputId = "state_performance_map")
    ),
    tabPanel(
      "Performance and Complications against spending",
      selectInput(
        'pop_measure',
        'Measure',
        c('total_performance_score_patient_experience', 'hospital_level_complications_score'),
      ),
      selectInput(
        'pop_feature',
        'Population feature',
        c('median_household_income',
          'perc_pop_below_poverty',
          'pop_with_healthinsurance',
          'total_spend'
          ),
      ),
      plotOutput(outputId = "facility_performance_plot")
    )
  )
)

server <- function(input, output) {
  # map state abbrevations to full state name for the map (eg: "NY" -> "new york")
  states_outcomes_data$region <- sapply(states_outcomes_data$state, function(state) tolower(abbr2state(state)))
  output$state_performance_map <- renderPlot({
    states_map <- map_data("state")
    measures_map <- left_join(states_map, states_outcomes_data, by = "region")

    # Create the map
    ggplot(measures_map, aes(long, lat, group = group)) +
      geom_polygon(aes(fill = !!as.symbol(input$measure)), color = "white")

  })
  output$facility_performance_plot <- renderPlot({
    facility_outcomes_data %>%
        ggplot(aes(!!as.symbol(input$pop_feature),
                   !!as.symbol(input$pop_measure),
                   color=!!as.symbol(input$pop_feature))) +
        geom_point() +
        facet_grid(rows=vars(hc_policy_focused_state))
  })
}

# Run the application 
shinyApp(ui = ui, server = server)