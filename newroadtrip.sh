#!/bin/bash

# Function to prompt for and validate the number of people
get_number_of_people() {
    while true; do
        echo "How many people are traveling with you for the road trip? (Maximum 5)"
        read number_of_people
        if [[ $number_of_people =~ ^[0-9]+$ ]] && [ "$number_of_people" -le 5 ] && [ "$number_of_people" -gt 0 ]; then
            echo "Number of people: $number_of_people"
            break
        else
            echo "Invalid input. Please enter a number between 1 and 5."
        fi
    done
}

# Function to prompt for and validate the number of travel days
get_travel_days() {
    while true; do
        echo "How many days are you looking to travel during this road trip?"
        read travel_days
        if [[ $travel_days =~ ^[0-9]+$ ]] && [ "$travel_days" -gt 0 ]; then
            echo "Number of travel days: $travel_days"
            break
        else
            echo "Invalid input. Please enter a positive number."
        fi
    done
}

# Function to prompt for and validate the travel date
get_travel_date() {
    while true; do
        echo "Which month and day are you looking to travel? (e.g., June 17)"
        read travel_date
        month=$(echo $travel_date | awk '{print $1}')
        day=$(echo $travel_date | awk '{print $2}')
        if [[ $day =~ ^[0-9]+$ ]] && [ "$day" -gt 0 ] && [ "$day" -le 31 ]; then
            month=$(echo "$month" | tr '[:upper:]' '[:lower:]')
            case $month in
                january|february|march|april|may|june|july|august|september|october|november|december)
                    echo "Month: $month, Day: $day"
                    break
                    ;;
                *)
                    echo "Invalid month. Please try again."
                    ;;
            esac
        else
            echo "Invalid day. Please enter a valid day."
        fi
    done
}

# Function to prompt for and validate the MPG
get_mpg() {
    while true; do
        echo "What is the average MPG (Miles Per Gallon) of your car?"
        read mpg
        if [[ $mpg =~ ^[0-9]+$ ]] && [ "$mpg" -gt 0 ]; then
            echo "MPG: $mpg"
            break
        else
            echo "Invalid input. Please enter a positive number."
        fi
    done
}

# Function to determine maximum round-trip distance based on travel days
get_max_distance() {
    case $travel_days in
        1) max_distance=500 ;;
        2) max_distance=1000 ;;
        *) max_distance=$((travel_days * 500)) ;;  # Default to days * 500 miles for more than 2 days
    esac
}

# Call the functions to get inputs
get_number_of_people
get_travel_days
get_travel_date
get_mpg
get_max_distance

# Convert month name to number
case $month in
    january) month_num=01 ;;
    february) month_num=02 ;;
    march) month_num=03 ;;
    april) month_num=04 ;;
    may) month_num=05 ;;
    june) month_num=06 ;;
    july) month_num=07 ;;
    august) month_num=08 ;;
    september) month_num=09 ;;
    october) month_num=10 ;;
    november) month_num=11 ;;
    december) month_num=12 ;;
    *) echo "Invalid month"; exit 1 ;;
esac
echo "Month number: $month_num"

# Load gas price for the month from a CSV file
gas_price=$(awk -F, -v month="$month" 'tolower($1) == tolower(month) {print $2}' Gas_Prices_Month.csv)
if [ -z "$gas_price" ]; then
    echo "Gas price not found for month: $month"
    exit 1
fi
echo "Gas price: $gas_price"

# Read parks data from a CSV file and calculate cost
#printf "--------------------------------------------------------------------------------------------------------------------------\n"
printf "| %-35s | %-15s | %-13s | %-17s | %-21s | %-14s |\n" "Park" "High Temp (°F)" "Low Temp (°F)" "Distance (miles)" "Cost Per Person ($)" "Total Cost ($)"
#printf "--------------------------------------------------------------------------------------------------------------------------\n"
total_trip_cost=0
while IFS=, read -r park distance round_trip
do
    if [ -z "$park" ] || [ -z "$distance" ] || [ -z "$round_trip" ]; then
        continue
    fi

    total_distance=$round_trip
    # Check if park distance is within max distance limit
    if [ "$total_distance" -le "$max_distance" ]; then
        # Calculate gallons required
        gallons_required=$(echo "scale=2; $total_distance / $mpg" | bc)
        # Calculate total cost and cost per person
        total_cost=$(echo "scale=2; $gallons_required * $gas_price" | bc)
        cost_per_person=$(echo "scale=2; $total_cost / $number_of_people" | bc)
        total_trip_cost=$(echo "scale=2; $total_trip_cost + $total_cost" | bc)

        # Get historical weather data for the park on the specified travel date from CSV files
        high_temp=$(awk -F, -v date="2023-$month_num-$day" -v park="$park" '
        BEGIN { park_idx = -1 }
        NR==1 {
            for (i=2; i<=NF; i++) {
                if ($i == park) {
                    park_idx = i
                    break
                }
            }
        }
        $1 ~ date {
            if (park_idx != -1) {
                print $(park_idx)
            }
        }' Daily_High_Temp.csv)

        low_temp=$(awk -F, -v date="2023-$month_num-$day" -v park="$park" '
        BEGIN { park_idx = -1 }
        NR==1 {
            for (i=2; i<=NF; i++) {
                if ($i == park) {
                    park_idx = i
                    break
                }
            }
        }
        $1 ~ date {
            if (park_idx != -1) {
                print $(park_idx)
            }
        }' Daily_Low_Temp.csv)

        # Output result in table format
        printf "| %-35s | %-15s | %-13s | %-17s | %-21s | %-14s |\n" "$park" "${high_temp:-N/A}" "${low_temp:-N/A}" "$total_distance" "$cost_per_person" "$total_cost"
    fi
done < Distances.csv
#printf "--------------------------------------------------------------------------------------------------------------------------\n"

