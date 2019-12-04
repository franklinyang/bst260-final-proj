library(shiny)
library(DBI)
library(tidyverse)
library(forcats)
require(maps)
require(viridis)
require(openintro)

# Begin connection
con <- dbConnect(RSQLite::SQLite(), "database/db.sqlite")

measure_options = c("Readmissions" = "excess_readmissions",
                    "Post-operative complications" = "hospital_level_complications_score",
                    "Responsiveness of hospital staff" = "responsiveness_of_hospital_staff_performance_rate",
                    "In-patient spend" = "ip_spend",
                    "Total spend" = "total_spend",
                    "Policy-focused state" = "hc_policy_focused_state",
                    "Hospital density" = "hospital_density_per_100k_capita",
                    "Median household income" = "median_household_income")
states_outcomes_data <- dbFetch(
  dbSendQuery(
    con,
    "
        SELECT
          state,
          AVG(excess_readmissions) AS excess_readmissions,
          AVG(hospital_level_complications_score) AS hospital_level_complications_score,
          AVG(responsiveness_of_hospital_staff_performance_rate) AS responsiveness_of_hospital_staff_performance_rate,
          AVG(ip_spend) AS ip_spend,
          AVG(total_spend) AS total_spend,
          AVG(hc_policy_focused_state) AS hc_policy_focused_state,
          AVG(hospital_density_per_100k_capita) AS hospital_density_per_100k_capita,
          AVG(median_household_income) AS median_household_income
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
          excess_readmissions,

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
      "Other visualizations"
    ),
    tabPanel(
      "Performance, Complication, Overall Scores by state",
      sidebarLayout(
        sidebarPanel(
          radioButtons("measure", "Select outcome measure:", measure_options)
        ),
        mainPanel(
          plotOutput(outputId = "state_performance_map")
        )
      )
    ),
    tabPanel(
      "Performance and Complications against spending",
      selectInput(
        'pop_measure',
        'Measure',
        c('excess_readmissions', 'hospital_level_complications_score'),
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
      ggtitle(names(which(measure_options == input$measure))) +
      geom_polygon(aes(fill = !!as.symbol(input$measure)), color = "white") +
      theme(
        panel.background = element_blank(),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        legend.position="top",
        legend.direction="horizontal",
        legend.title=element_blank(),
        plot.title = element_text(size=18, hjust = 0.5),
        legend.key.width = unit(3, "cm")
      ) + scale_color_gradient(low = "#132B43",
                               high = "#56B1F7")
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