install.packages('tidyverse')
install.packages('skimr')
install.packages('janitor')
install.packages('here')

library('ggplot2') # for data visualization.
library('tidyr') #  to tidy data.
library('dplyr') # for data manipulation.
library('skimr') # for summarizing data. 
library('janitor') # for cleaning data.
library('here') # to manage file paths.
library(lubridate) # for working with dates and times.

# Loading the data from different files
c202307 <- read.csv('202307.csv')
c202308 <- read.csv('202308.csv')
c202309 <- read.csv('202309.csv')
c202310 <- read.csv('202310.csv')
c202311 <- read.csv('202311.csv')
c202312 <- read.csv('202312.csv')
c202401 <- read.csv('202401.csv')
c202402 <- read.csv('202402.csv')
c202403 <- read.csv('202403.csv')
c202404 <- read.csv('202404.csv')
c202405 <- read.csv('202405.csv')
c202406 <- read.csv('202406.csv')

# Merging data in one frame
cyclistic_bike_share <- bind_rows(c202307, c202308, c202309, c202310, c202311,
                                  c202312, c202401, c202402, c202403, c202404,
                                  c202405, c202406)

#==============================================================================

#CLEANING DATA
#------------------------------------------------------------------------------

## fist we need to confirm the structure of the data.

head(cyclistic_bike_share)
skim_without_charts(cyclistic_bike_share)
View(cyclistic_bike_share)
summary(cyclistic_bike_share)

------------------------------------------------------------------------------
  
  # After confirming the structure of the data, some problems were detected.
  #
  # 1- the dates and hours are in character format and need to be changed for
  # later calculations.
  # 2 - The started_at and ended_at column names are not clear enough, so they
  # need to be changed
  # 3 - It is not easy to determine how long each trip lasted, so we will define 
  # a new column with this information, dropping negative values.
  # 4 - Define the days of the week and months
  # 5 - Stations names and ID are missing. If the information of name or ID of a 
  # station is present, it's possible to track it's ID or name respectively. But if
  # there is no information, the data is useless because de coordinates doesn't
  # match with the station in several cases, so de data have to be filtered.
  # 6 - Where the data is incomplete it will be dropped to avoid mistakes.
  # 7 - And we want no duplicates, so if there is any duplicate we will drop it with distinct()
  #
  # To make sure that the column names are unique and consistent we will use the
  # clean_names() function from the janitor package
  #
  # So a new frame is defined as bike_share filtering and dropping data, changing
  # the names and type of the columns mentioned before and adding a new column with
  # the trip time in minutes.
  
  all_trips <- cyclistic_bike_share %>%
  
  # Convert date-time columns to POSIXct
  mutate(
    started_at = ymd_hms(started_at),
    ended_at = ymd_hms(ended_at)
  ) %>%
  
  # Rename columns
  rename(                         
    initial_time = started_at,
    final_time = ended_at,
    client = member_casual
  ) %>%
  
  #determine the date of the week
  mutate(
    date1 = as.Date(initial_time),
    day_of_week = weekdays(date1, abbreviate = FALSE),
    # Convert day_of_week to a factor with natural order
    day_of_week = factor(day_of_week, levels = c("Monday", "Tuesday", "Wednesday",
                                                 "Thursday", "Friday", "Saturday",
                                                 "Sunday"))
  ) %>% 
  
  #determine the month
  mutate(
    date2 = as.Date(initial_time),
    month = format(date2, "%B"),
    # Convert month to a factor with natural order
    month = factor(month, levels = c("January", "February", "March", "April", "May", "June",
                                     "July", "August", "September",
                                     "October", "November", "December"))
  ) %>% 
  
  # Calculate trip time in minutes
  mutate(
    trip_time_minutes = as.numeric(difftime(final_time,
                                            initial_time,
                                            units = 'mins'))
  ) %>%
  
  # Filter out negative trip times
  filter(trip_time_minutes >= 0) %>%
  
  
  # Filter rows with blank fields for station's names or id
  filter(
    (start_station_name != "" |   # filter the data to keep rows where at least 
       start_station_id != "") &   # the start station name or id exists and where
      (end_station_name != "" |   # the end station name or id exists.
         end_station_id != "")
  ) %>% 
  
  # Drop rows with NA values
  drop_na() %>%
  
  # Drop duplicates
  distinct() %>% 
  
  # Select all columns except hours, minutes, seconds and trip_time_seconds
  select(-date1, -date2) %>% 
  
  # Clean column names
  clean_names()
#------------------------------------------------------------------------------

#Now that we have our data set cleaned we need to check if everything is ok.

# Check the updated data set
skim_without_charts(all_trips)
View(all_trips)
summary(all_trips)
#------------------------------------------------------------------------------

#==========================================================================================
# CONDUCT DESCRIPTIVE ANALYSIS
#------------------------------------------------------------------------------------------
# Descriptive analysis on trip_time_minutes (all data in minutes)
summary(all_trips$trip_time_minute)

# Compare members and casual users
aggregate(all_trips$trip_time_minutes ~ all_trips$client, FUN = mean)
aggregate(all_trips$trip_time_minutes ~ all_trips$client, FUN = median)
aggregate(all_trips$trip_time_minutes ~ all_trips$client, FUN = max)
aggregate(all_trips$trip_time_minutes ~ all_trips$client, FUN = min)

# See the average ride time by each day for members vs casual users
aggregate(all_trips$trip_time_minutes ~ all_trips$client +
            all_trips$day_of_week, FUN = mean)



# analyze ridership data by type and weekday
all_trips %>% 
  group_by(client, day_of_week) %>%  #groups by usertype and weekday
  summarise(number_of_rides = n()							#calculates the number of rides and average duration 
            ,average_duration = mean(trip_time_minutes)) %>% 		# calculates the average duration
  arrange(client, day_of_week)								# sorts

# Let's visualize the number of rides by rider type
all_trips %>% 
  group_by(client, day_of_week) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(trip_time_minutes)) %>% 
  arrange(client, day_of_week)  %>% 
  ggplot(aes(x = day_of_week, y = number_of_rides, fill = client)) +
  geom_col(position = "dodge")+ 
  theme_minimal() +
  labs(title = "Ride Number Representation of Client Types by day of the week")

# Let's create a visualization for average duration
all_trips %>% 
  group_by(client, day_of_week) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(trip_time_minutes)) %>% 
  arrange(client, day_of_week)  %>% 
  ggplot(aes(x = day_of_week, y = average_duration, fill = client)) +
  geom_col(position = "dodge") +
  theme_minimal() +
  labs(title = "Trip Duration Representation of Client Types by day of the week")

#Now by month
# Let's visualize the number of rides by rider type
all_trips %>% 
  group_by(client, month) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(trip_time_minutes)) %>% 
  arrange(client, month)  %>% 
  ggplot(aes(x = month, y = number_of_rides, fill = client)) +
  geom_col(position = "dodge") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  labs(title = "Ride Number Representation of Client Types by Month")

# Let's create a visualization for average duration
all_trips %>% 
  group_by(client, month) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(trip_time_minutes)) %>% 
  arrange(client, month)  %>% 
  ggplot(aes(x = month, y = average_duration, fill = client)) +
  geom_col(position = "dodge") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  labs(title = "Trip Duration Representation of Client Types by Month")

#now a weekly one
all_trips %>% 
  group_by(client, day_of_week) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(trip_time_minutes)) %>% 
  arrange(client, day_of_week)  %>% 
  ggplot(aes(x = day_of_week, y = average_duration, fill = client)) +
  geom_col(position = "dodge") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  labs(title = "Trip Duration Representation of Client Types by day of the week")

#-------------------------------------------------------------------------------



# Process the data
week_summary <- all_trips %>%
  # Convert initial_time to Date type
  mutate(date1 = as.Date(initial_time),
         day_of_week = weekdays(date1, abbreviate = FALSE),
         # Convert day_of_week to a factor with natural order
         day_of_week = factor(day_of_week, levels = c("Monday", "Tuesday", "Wednesday",
                                                      "Thursday", "Friday", "Saturday",
                                                      "Sunday"))
  ) %>%
  # Group by day_of_week and client_type
  group_by(day_of_week, client) %>%
  summarise(total_cases = n(), .groups = 'drop') %>%
  # Group by month and year to get total cases per month
  group_by(day_of_week) %>%
  mutate(total_cases_day = sum(total_cases)) %>%
  # Calculate percentage for each client type
  mutate(percentage = (total_cases / total_cases_day) * 100) %>%
  ungroup()



# Process the data
monthly_summary <- all_trips %>%
  # Convert initial_time to Date type
  mutate(date2 = as.Date(initial_time),
         month2 = format(date2, "%B"),
         year2 = year(date2),
         # Convert month2 to a factor with natural order
         month2 = factor(month2, levels = c("January", "February", "March", "April", "May", "June",
                                            "July", "August", "September",
                                            "October", "November", "December"))
  ) %>%
  # Group by month, year, and client_type
  group_by(year2, month2, client) %>%
  summarise(total_cases = n(), .groups = 'drop') %>%
  # Group by month and year to get total cases per month
  group_by(year2, month2) %>%
  mutate(total_cases_month = sum(total_cases)) %>%
  # Calculate percentage for each client type
  mutate(percentage = (total_cases / total_cases_month) * 100) %>%
  ungroup()

# week and monthly summary to export and make a dashboard
monthly_week_summary <- all_trips %>%
  # Convert initial_time to Date type
  mutate(date2 = as.Date(initial_time, format = "%Y-%m-%d"),
         day_of_week = weekdays(date2, abbreviate = FALSE),
         # Convert day_of_week to a factor with natural order
         day_of_week = factor(day_of_week, levels = c("Monday", "Tuesday", "Wednesday",
                                                      "Thursday", "Friday", "Saturday",
                                                      "Sunday")),
         month2 = format(date2, "%B"),
         year2 = year(date2),
         # Convert month2 to a factor with natural order
         month2 = factor(month2, levels = c("January", "February", "March", "April", "May", "June",
                                            "July", "August", "September", "October", "November", "December"))
  ) %>%
  # Group by year, month, client, and day_of_week
  group_by(year2, month2, client, day_of_week) %>%
  summarise(total_cases = n(), .groups = 'drop') %>%
  # Group by year and month to get total cases per month
  group_by(year2, month2) %>%
  mutate(total_cases_month = sum(total_cases)) %>%
  # Calculate percentage for each client type
  mutate(percentage = (total_cases / total_cases_month) * 100) %>%
  ungroup()





# View the summary
View(monthly_summary)
aggregate(monthly_summary$percentage ~ monthly_summary$client +
            monthly_summary$month2, FUN = mean)


#plot
ggplot(data = monthly_summary, mapping =aes(x = month2, y = percentage, fill = client)) +
  geom_bar(stat = "identity", position = "fill") +
  labs(title = "Percentage Representation of Client Types by Month",
       x = "Month",
       y = "Percentage",
       fill = "Client") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

#=================================================
# EXPORT SUMMARY FILE FOR FURTHER ANALYSIS
#=================================================
# Create a csv file that we will visualize in Excel, Tableau, or my presentation software
weeklycounts <- aggregate(all_trips$trip_time_minutes ~ all_trips$client + all_trips$day_of_week, FUN = mean)
monthlycounts <- aggregate(all_trips$trip_time_minutes ~ all_trips$client + all_trips$month, FUN = mean)
monthly_week_counts <- aggregate(all_trips$trip_time_minutes ~ all_trips$client + all_trips$month + all_trips$day_of_week, FUN = mean)


# Define the file paths

#file_path <- "C:/Users/week_ride_length.csv" #complete and remove the "#"

#file_path2 <- "C:/Users/...cases_ride_month.csv" #complete and remove the "#"

#file_path3 <- "C:/Users/...cases_ride_week.csv" #complete and remove the "#"

#file_path4 <- "C:/...month_ride_length.csv" #complete and remove the "#"

#file_path5 <- "C:/Users/...month__week_cases.csv" #complete and remove the "#"

#file_path6 <- "C:/Users/...month_week_rlength.csv" #complete and remove the "#"



# Write the data frame to a CSV files

#write.csv(weeklycounts, file = file_path, row.names = FALSE) # remove the "#"

#write.csv(monthly_summary, file = file_path2, row.names = FALSE) # remove the "#"

#write.csv(week_summary, file = file_path3, row.names = FALSE) # remove the "#"

#write.csv(monthlycounts, file = file_path4, row.names = FALSE) # remove the "#"

#write.csv(monthly_week_summary, file = file_path5, row.names = FALSE) # remove the "#"

#write.csv(monthly_week_counts, file = file_path6, row.names = FALSE) # remove the "#"

