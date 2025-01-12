library(data.table)
library(dplyr)
library(stringr)
library(readxl)
library(shiny)
library(sf)
library(rsconnect)
library(leaflet)
library(ggplot2)
library(lubridate)
library(leaflet)
library(leaflet.extras)



data1 <- fread("data/2018_S1_NB_FER.txt", header = TRUE, sep = "\t")  
data2 <- fread("data/2018_S2_NB_FER.txt", header = TRUE, sep = "\t")  
data3 <- fread("data/2019_S1_NB_FER.txt", header = TRUE, sep = "\t")
data4 <- fread("data/2019_S2_NB_FER.txt", header = TRUE, sep = "\t")
data5 <- fread("data/2020_S1_NB_FER.txt", header = TRUE, sep = "\t")
data6 <- fread("data/2020_S2_NB_FER.txt", header = TRUE, sep = "\t")
data7 <- fread("data/2021_S1_NB_FER.txt", header = TRUE, sep = "\t")
data8 <- fread("data/2021_S2_NB_FER.txt", header = TRUE, sep = "\t")
data9 <- fread("data/2022_S1_NB_FER.txt", header = TRUE, sep = "\t")
data10 <- fread("data/2022_S2_NB_FER.txt", header = TRUE, sep = ";")



data11<- fread("data/data-rf-2023-s1.csv", header = TRUE, sep = ";")




#combine the whole data
data_list <- list(data1, data2, data3, data4, data5, data6, data7, data8, data9, data10)

#print the column names and types
invisible(lapply(seq_along(data_list), function(i) {
  cat("\n--- Structure of dataset", i, "---\n")
  str(data_list[[i]])
}))
combined_dataI <- rbindlist(data_list)


data11[[1]] <- as.Date(data11[[1]])  # Convert IDate to Date


# Convert 'JOUR' column to Date format
combined_dataI$JOUR <- as.Date(combined_dataI$JOUR, format = "%d/%m/%Y")


# Append data11 to the combined dataset
combined_data <- rbindlist(list(combined_dataI, data11))



# Convert CODE_STIF_RES and CODE_STIF_ARRET to integer in place
combined_data[, CODE_STIF_RES := as.integer(CODE_STIF_RES)]
combined_data[, CODE_STIF_ARRET := as.integer(CODE_STIF_ARRET)]



########Treating Missing Values ##############

# Identify numeric columns
numeric_cols <- names(combined_data)[sapply(combined_data, is.numeric)]

# Check for missing values in numeric columns
missing_summary <- sapply(numeric_cols, function(col) sum(is.na(combined_data[[col]])))

# Print the summary
print("Missing values in numeric columns:")
print(missing_summary)

#missing values percentage 
missing_rate_res <- sum(is.na(combined_data$CODE_STIF_RES)) / nrow(combined_data)
missing_rate_arret <- sum(is.na(combined_data$CODE_STIF_ARRET)) / nrow(combined_data)

print(paste("Missing rate for CODE_STIF_RES:", missing_rate_res))
print(paste("Missing rate for CODE_STIF_ARRET:", missing_rate_arret))


# Remove rows with any NA values
dt<- na.omit(combined_data)

# Verify the number of rows before and after removal
nrow(combined_data)  # Original number of rows
nrow(dt)  # Number of rows after removal



# Convert the empty values to NA
dt[dt == ""] <- NA

# Replace "?" with NA in the column ID_REFA_LDA
dt<- dt %>%
  mutate(ID_REFA_LDA = ifelse(ID_REFA_LDA == "?", NA, ID_REFA_LDA))
# Replace "?" with NA in the column CATEGORIE_TITRE
dt <- dt %>%
  mutate(CATEGORIE_TITRE = ifelse(CATEGORIE_TITRE == "?", NA, CATEGORIE_TITRE))

# Count the number of missing values for each column
missing_values <- colSums(is.na(dt))



# Delete missing values
dt <- na.omit(dt)

# Count the number of missing values in every column
missing_values <- colSums(is.na(dt))


#########deleting any redundancy####

dt <-dt[!duplicated(dt), ]
nrow(dt)


###########Checking outliers

# Extract the NB_VALD column
nb <- dt$NB_VALD

# Calculate Q1 (25th percentile) and Q3 (75th percentile)
Q1 <- quantile(nb, 0.25, na.rm = TRUE)
Q3 <- quantile(nb, 0.75, na.rm = TRUE)

# Calculate IQR
IQR <- Q3 - Q1

# Define lower and upper bounds for outliers
lower_bound <- Q1 - 1.5 * IQR
upper_bound <- Q3 + 1.5 * IQR

# Identify and print outliers
outliers <- nb[nb < lower_bound | nb > upper_bound]
cat("Outliers:\n")
print(outliers)



########### Load the new dataset
# Read the CSV file with a header
GeoData <- read.csv("data/zones-d-arrets.csv", header = TRUE, sep = ";")



# Columns to check
columns_to_check <- c("ZdAYEpsg2154", "ZdAXEpsg2154", "ZdCId")

# Check for NA values in these columns
na_counts <- sapply(GeoData[columns_to_check], function(col) sum(is.na(col)))

# Print the count of NA values for each column
print(na_counts)


GeoData <-GeoData[!duplicated(GeoData), ]



# Check if any column in GeoData matches ID_REFA_LDA
table(GeoData$ZdCId %in% unique(dt$ID_REFA_LDA))



# Check duplicates in GeoData
GeoData_duplicates <- GeoData[duplicated(GeoData$ZdCId), ]

# Check duplicates in merged_data
merged_data_duplicates <- dt[duplicated(dt$ID_REFA_LDA), ]



# Select only the required columns
cols <- c("ZdAYEpsg2154", "ZdAXEpsg2154", "ZdCId")

GeoData <- GeoData[, cols, drop = FALSE]
head(GeoData)
# Select only duplicates in GeoData
GeoData_duplicates <- GeoData[duplicated(GeoData$ZdCId) | duplicated(GeoData$ZdCId, fromLast = TRUE), ]



# Ensure ZdCId is unique in GeoData
GeoData_unique <- GeoData %>%
  distinct(ZdCId, .keep_all = TRUE) # Keep only the first occurrence of each ZdCId

# Perform the join with dt, keeping only matching rows
final_data <- dt %>%
  group_by(ID_REFA_LDA, JOUR, LIBELLE_ARRET) %>%
  summarize(Sum_NB_VALD = sum(as.numeric(NB_VALD), na.rm = TRUE), .groups = 'drop') %>%
  inner_join(GeoData_unique, by = c("ID_REFA_LDA" = "ZdCId")) # Use inner join to keep only common values


