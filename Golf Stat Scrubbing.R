# Name: Mike Kuklinski
# Date: 5/26/16
# Project: Golf Stat Scrubbing

# Description: Code file to scan PGAtour.com and extract all available statistics,
# as well as Major Championship Results from previous years. File will create individual
# csv files for every stat/year/major combination. 


# Load Packages
library(dplyr)
library(qdap)
library(stringr)
library(httr)
library(XML)
library(stringr)

# Set Working directory and create initial folders
setwd('~/R Scripts/Golf/github/')
if(!dir.exists('Data')){dir.create('Data')}
if(!dir.exists('Data/individual/')){dir.create('Data/individual/')}
if(!dir.exists('Data/individual/Majors/')){dir.create('Data/individual/Majors/')}
if(!dir.exists('Data/individual/Stat Names/')){dir.create('Data/individual/Stat Names/')}
if(!dir.exists('Data/individual/Stats/')){dir.create('Data/individual/Stats/')}


#===============================================================================

# Website urls for data

# http://www.pgatour.com/stats/stat.[TYPE].[YEAR].html
# http://espn.go.com/golf/leaderboard?tournamentId=


# Major data url lookup tournament ids
# ESPN Masters Tourney Ids (2004 - 2016)
# ids <- c(161, 210, 261, 309, 425, 537, 774, 980, 1005, 1192, 1317, 2241, 2493)

# ESPN US Open Tourney Ids (2004 - 2016)
# ids <- c(170, 219, 269, 316, 433, 545, 797, 981, 1013, 1200, 1325, 2249)

# ESPN The Open Championship Tourney Ids (2004 - 2016)
# ids <- c(174, 223, 295, 320, 411, 549, 798, 982, 1017, 1204, 1329, 2253)

# ESPN PGA Championship Tourney Ids (2004 - 2016)
# ids <- c(177, 226, 274, 322, 439, 551, 799, 983, 1018, 1206, 1330, 2255)


# ##############################################################################
#===============================================================================
# Create Stat Files
#===============================================================================
# ##############################################################################


# ==============================================================================
# Create list of Stat Names and Ids from PGAtour.com
# ==============================================================================

# Helper Function to adjust stat number to the url lookup format
num_to_url <- function(st_num){
    if(st_num < 10){st_num <- paste('00',st_num, sep = '')}
    else if(st_num < 100){st_num <- paste('0',st_num, sep = '')}
    else if(st_num >= 1000){st_num <- paste('0',st_num, sep = '')}
    as.character(st_num)
}


# Function which searches and returns list of available stats from PGAtour.com
get_stats_num_names <- function(strt_year, end_year){
    stat_names <- data.frame(stat_num = integer(), stat = character())
    for(st_num in (strt_year:end_year)){
        # Adjust stat number to the url lookup format
        st_num <- num_to_url(st_num)
        # Scrap url for stat name
        message('Check stat number ', st_num)
        url <- paste('http://www.pgatour.com/stats/stat.', st_num, '.', '2016', '.html', sep = '')
        html_text <- GET(url)
        html_text <- content(html_text, as = 'text')
        parsed_html <- htmlParse(html_text, asText = TRUE)
        stat_name <- as.character(xpathSApply(parsed_html, "//title", xmlValue))
        # Clean up name and add to list of stat names and numbers
        if(stat_name != 'Stat'){
            stat_name <- gsub('\\+', "Plus", stat_name)
            stat_name <- gsub('<', "Less", stat_name)
            stat_name <- gsub('>', "Grtr", stat_name)
            stat_name <- str_replace(stat_name, "[[:punct:]]", '')
            stat_name <- str_trim(gsub("(Stat)| ", '', stat_name))
            stat_name <- gsub("[[:punct:]]", '', stat_name)
            stat_names <- rbind(stat_names, data.frame(as.character(st_num), stat_name))
        }
    }
    names(stat_names) <- c('Stat Nmbr', 'Stat Name')
    # Save File
    write.csv(stat_names, 'Data/individual/Stat Names/stat_collection.csv', row.names = F)
}

# Run function to create collection of stats. 
get_stats_num_names(0,2700)

# Check for duplicate names
stat_collection$Dup.check <- duplicated(stat_collection$Stat.Name)
# After manual review and adjustment, the following stat names needed to be
# manually adjusted:
# (352, 361+Less125), (218+All, 458+Measured), (79+Less75yards, 330+Less125yards, 2330+Less100yards) 


# ==============================================================================
# Create a CSV file for a given stat number and year
# ==============================================================================

# Testing values
#year <- 2005
#stat_num <- 2536

# Helper Function to scrap stat data for a given year and stat type and write a csv file
get_stats <- function(year, stat_num){
    # Adjust stat number to the url lookup format
    stat_num <- num_to_url(stat_num)
    # Load stat names
    stat_collection <- read.csv('Data/individual/Stat Names/stat_collection.csv', 
                                header = T, stringsAsFactors = F, colClasses = c('character', 'character'))
    # Scrap url for stat table
    url <- paste('http://www.pgatour.com/stats/stat.', stat_num, '.', year, '.html', sep = '')
    html_text <- GET(url)
    html_text <- content(html_text, as = 'text')
    parsed_html <- htmlParse(html_text, asText = TRUE)
    # Extract table statistics
    stat_name <- stat_collection[stat_collection$Stat.Nmbr == stat_num,2]
    stat_table <- as.character(xpathSApply(parsed_html, "//td", xmlValue))
    # Get header titles
    head_start <- grep('RANK THIS WEEK', stat_table)
    head_stop <- head_start + grep('^\n( +)(T)?1', stat_table[head_start:length(stat_table)])[1] - 2
    headers <- stat_table[head_start:head_stop]
    headers <- gsub("%", "Pct", headers)
    headers <- gsub("[[:punct:]]|\n|\r| ",'', headers)
    headers <- mapply(function(x){
        x <- paste(stat_name,x, year, sep = ' ')
        x <- gsub(' ', '_', x)
        x}, headers)
    names(headers) <- NULL
    # Subset and clean up data
    stat_table <- stat_table[(head_stop+1):length(stat_table)]
    stat_table <- gsub("[$,/\\_)(&%#@!]|(\n +)", '', stat_table, perl = T)
    stat_table <- gsub("(?<=[a-z]).(?=[A-Z])", ' ', stat_table, perl = T)
    # Remove Tie (T) indicator
    stat_table <- gsub("(T(?=[0-9]))", '', stat_table, perl = T)
    # Convert Even to 0
    stat_table <- gsub("^E$", "0", stat_table)
    # Create data frame of statistics
    if(length(stat_table) %% length(headers) != 0){
        # Flag any stats which don't create a uniform data frame
        message('****** missing information found for stat: ', stat_num, ' for year: ', year, ' *******')
        missing_info <<- c(missing_info, 'stat:', stat_num, 'year:', year)
        }else{
            stat_table <- data.frame(matrix(data = stat_table, ncol = length(headers), byrow = T), stringsAsFactors = F)
            names(stat_table) <- headers
            # Clean up column classes
            num_idx <- which(grepl("PLAYERNAME", headers) !=T )
            name_idx <- which(grepl("PLAYERNAME", headers) ==T )
            for(idx in seq_along(num_idx)){
                stat_table[,headers[num_idx[idx]]] <- as.numeric(stat_table[, headers[num_idx[idx]]])
            }
            stat_table[, name_idx] <- gsub("[[:punct:]]", '', stat_table[, name_idx])
            # Save File
            file_name <- paste('Data/individual/Stats/', stat_num,'_',year, '_', stat_name, '.csv', sep = '')
            # Add columns to identify stat name and year
            stat_table$stat_name <- stat_name
            stat_table$year <- year
            # Remove Duplicate name and take the best stats
            stat_table <- stat_table[!duplicated(stat_table[,name_idx]),]
            # Save File
            write.csv(stat_table, file_name, row.names = F)
        }
}

# Test Function
#get_stats(2015, 104)

# ==============================================================================
# Create all stat csv file for a year range
# ==============================================================================

# Testing values
#strt_year <- 2005
#end_year <- 2016
#year_idx <- 2005
#stat_idx <- 467

# Reset tracking information for missing data stats
missing_info <- character()

# Function to download every listed stat for a given year range
create_indv_stat_lists <- function(strt_year, end_year){
    # Load list of stat names and lookup numbers
    stat_collection <- read.csv('Data/individual/Stat Names/stat_collection.csv', 
                                header = T, stringsAsFactors = F, colClasses = c('character', 'character'))
    # If you open the stat_collection.csv file and place a '#' next to a stat name,
    # it will be ignored in the code.
    ign_idx <- grep("^#", stat_collection$Stat.Nmbr)
    if(length(ign_idx) > 0){stat_collection <- stat_collection[-ign_idx,]}
    # For Each year, download, format, and write CSV file for stats
    for(year_idx in (strt_year:end_year)){
        for(stat_idx in seq_along(stat_collection$Stat.Nmbr)){
            stat_name <- stat_collection$Stat.Name[stat_idx]
            stat_id <- stat_collection$Stat.Nmbr[stat_idx]
            message('Reviewing stat: ', stat_id, ', for year: ', year_idx)
            file_name <- paste('Data/individual/Stats/', stat_id,'_',year_idx, '_', stat_name, '.csv', sep = '')
            # Call the get_stat function for every stat/year combination
            if(!file.exists(file_name)){
                message('File does not exist, downloading now')
                try(get_stats(year_idx, as.numeric(stat_id)), silent = T)
                }else {message("File already exists")}
        }
    }
}

# Run Function for given range
create_indv_stat_lists(2005, 2016)

# View any flagged stats
missing_info_matrix <- matrix(missing_info, ncol = 4, byrow = T)



# ##############################################################################
#===============================================================================
# Create Previous Major Finishes
#===============================================================================
# ##############################################################################

# Testing Values
#year <- 2004
#id <- 161
#major_name <- 'Masters'

# Function which takes lists of tournaments and years and create csv file of the 
# results (Player Name & Finish). If rank_cut is TRUE, then the Finish for the
# CUT players for be extrapolated from the non-CUT players 
get_major_results <- function(major_name, year_list, id_list, rank_cut = F){
    # Loop through year range and populate lists of previous performances
    for(idx in seq_along(year_list)){
        year <- year_list[idx]
        id <- id_list[idx]
        # Get html
        url <- paste('http://espn.go.com/golf/leaderboard?tournamentId=', id, sep = '')
        html_text <- GET(url)
        html_text <- content(html_text, as = 'text')
        parsed_html <- htmlParse(html_text, asText = TRUE)
        # Extract table statistics
        stat_table <- xpathSApply(parsed_html, '//*[(@id = "regular-leaderboard")]//td', xmlValue)
        # Get header titles
        headers <- c('Finish', 'skip', 'PLAYER_NAME', 'Score', 'R1', 'R2', 'R3', 'R4', 'Total', 'MONEY', 'FEDEX PTS')
        headers <- mapply(function(x){
            x <- paste(major_name,x, year, sep = ' ')
            x <- gsub(' ', '_', x)
            x}, headers)
        names(headers) <- NULL
        # Get finish results
        stat_table <- gsub("[[:punct:]]|(\n +)", '', stat_table, perl = T)
        stat_table <- gsub("(?<=[a-z]).(?=[A-Z])", ' ', stat_table, perl = T)
        stat_table <- gsub("(T(?=[0-9]))", '', stat_table, perl = T)
        stat_table <- data.frame(matrix(data = stat_table, ncol = length(headers), byrow = T), stringsAsFactors = F)
        names(stat_table) <- headers
        # Clean up column classes
        num_names <- which(grepl("PLAYER_NAME", headers) !=T )
        name_idx <- which(grepl("PLAYER_NAME", headers) ==T )
        for(idx in seq_along(num_names)){
            stat_table[,headers[num_names[idx]]] <- as.numeric(gsub(',','',stat_table[, headers[num_names[idx]]]))
        }
        stat_table[, name_idx] <- gsub("[[:punct:]]", '', stat_table[, name_idx])
        # If indicated, Estimate ranking values for CUT players
        if(rank_cut){
            max_finish <- max(stat_table[,1],na.rm = T)
            cut_ranks <- stat_table[is.na(stat_table[,1]),9]
            cut_ranks <- rank(cut_ranks, ties.method = 'min') + max_finish
            stat_table[is.na(stat_table[,1]),1] <- cut_ranks
        }
        stat_table <- stat_table[,c(3,1)]
        stat_table[is.na(stat_table[,2]),2] <- 'CUT' 
        # Save File
        file_name <- paste('Data/individual/Majors/', major_name,'_',year, '.csv', sep = '')
        stat_table$year <- year
        write.csv(stat_table, file_name, row.names = F)
    }
}

# Test
#get_major_results('Masters', 2004, 161)

# ==============================================================================
# Get Masters Finishes
# ==============================================================================

master_years <- c(2004:2016)
master_ids <- c(161, 210, 261, 309, 425, 537, 774, 980, 1005, 1192, 1317, 2241, 2493)
get_major_results('Masters', master_years, master_ids, T)

# ==============================================================================
# Get US Open Finishes
# ==============================================================================

USOpen_years <- c(2004:2015)
USOpen_ids <- c(170, 219, 269, 316, 433, 545, 797, 981, 1013, 1200, 1325, 2249)
get_major_results('USOpen', USOpen_years, USOpen_ids, T)

# ==============================================================================
# Get Open Championship Finishes
# ==============================================================================

OpenChamp_years <- c(2004:2015)
OpenChamp_ids <- c(174, 223, 295, 320, 411, 549, 798, 982, 1017, 1204, 1329, 2253)
get_major_results('OpenChamp', OpenChamp_years, OpenChamp_ids, T)


# ==============================================================================
# Get PGA Championship Finishes
# ==============================================================================

PGAChamp_years <- c(2004:2015)
PGAChamp_ids <- c(177, 226, 274, 322, 439, 551, 799, 983, 1018, 1206, 1330, 2255)
get_major_results('PGAChamp', PGAChamp_years, PGAChamp_ids, T)

