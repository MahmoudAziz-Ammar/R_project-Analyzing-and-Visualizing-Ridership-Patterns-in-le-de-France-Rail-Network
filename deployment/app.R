library(shiny)
library(leaflet)
library(dplyr)
library(ggplot2)
library(lubridate)
library(sf)

# Load the data
data <- read.csv("final_data_cleaned.csv")

# Data preprocessing
data$JOUR <- as.Date(data$JOUR)
data$Weekday <- weekdays(data$JOUR)
data$YearWeek <- format(data$JOUR, "%Y-%U")

# Filter and convert to spatial object
filtered_data <- data %>%
  filter(!is.na(ZdAXEpsg2154) & !is.na(ZdAYEpsg2154) & !is.na(Sum_NB_VALD))

filtered_data_sf <- st_as_sf(
  filtered_data,
  coords = c("ZdAXEpsg2154", "ZdAYEpsg2154"),
  crs = 2154
)
filtered_data_sf <- st_transform(filtered_data_sf, crs = 4326)

coordinates <- st_coordinates(filtered_data_sf)
filtered_data <- filtered_data %>%
  mutate(
    X = coordinates[, 1],
    Y = coordinates[, 2]
  )

# UI
iu <- fluidPage(
  titlePanel("Ridership Dashboard"),
  sidebarLayout(
    sidebarPanel(
      dateRangeInput("ref_period", "Reference Period:", start = min(data$JOUR), end = max(data$JOUR)),
      dateRangeInput("compare_period", "Comparison Period:", start = min(data$JOUR), end = max(data$JOUR)),
      selectInput("station", "Select Station:", choices = unique(data$LIBELLE_ARRET)),
      actionButton("update", "Update")
    ),
    mainPanel(
      leafletOutput("map"),
      plotOutput("trendPlot"),
      plotOutput("weekVariation"),
      verbatimTextOutput("stats")
    )
  )
)

# Server
server <- function(input, output, session) {
  filtered_data_reactive <- reactive({
    filtered_data %>%
      filter(LIBELLE_ARRET == input$station &
               JOUR >= input$ref_period[1] & JOUR <= input$ref_period[2])
  })
  
  comparison_data <- reactive({
    filtered_data %>%
      filter(LIBELLE_ARRET == input$station &
               JOUR >= input$compare_period[1] & JOUR <= input$compare_period[2])
  })
  
  output$map <- renderLeaflet({
    station_data <- filtered_data_reactive()
    leaflet(station_data) %>%
      addTiles() %>%
      setView(
        lng = mean(station_data$X, na.rm = TRUE),
        lat = mean(station_data$Y, na.rm = TRUE),
        zoom = 11
      ) %>%
      addMarkers(
        lng = ~X,
        lat = ~Y,
        popup = ~paste("Station:", LIBELLE_ARRET)
      )
  })
  
  output$trendPlot <- renderPlot({
    ggplot(filtered_data_reactive(), aes(x = JOUR, y = Sum_NB_VALD)) +
      geom_line(color = "blue") +
      ggtitle("Ridership Trend") +
      xlab("Date") +
      ylab("Number of Passengers")
  })
  
  output$weekVariation <- renderPlot({
    comp_data <- comparison_data() %>%
      group_by(Weekday) %>%
      summarise(Avg_Vald = mean(Sum_NB_VALD))
    
    ref_data <- filtered_data_reactive() %>%
      group_by(Weekday) %>%
      summarise(Avg_Vald = mean(Sum_NB_VALD))
    
    merged <- left_join(ref_data, comp_data, by = "Weekday", suffix = c("_ref", "_comp"))
    
    ggplot(merged, aes(x = Weekday)) +
      geom_col(aes(y = Avg_Vald_ref), fill = "blue", alpha = 0.6) +
      geom_col(aes(y = Avg_Vald_comp), fill = "red", alpha = 0.6) +
      ggtitle("Weekly Variation: Reference vs Comparison") +
      xlab("Day of the Week") +
      ylab("Average Passengers")
  })
  
  output$stats <- renderText({
    ref_total <- sum(filtered_data_reactive()$Sum_NB_VALD)
    comp_total <- sum(comparison_data()$Sum_NB_VALD)
    diff <- comp_total - ref_total
    paste("Reference Period Total:", ref_total,
          "\nComparison Period Total:", comp_total,
          "\nDifference:", diff)
  })
}

# Run the application
shinyApp(ui = iu, server = server)
