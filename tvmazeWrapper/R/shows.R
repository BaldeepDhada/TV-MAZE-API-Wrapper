library(httr)
library(jsonlite)
library(glue)
library(roxygen2)
library(ggplot2)
library(dbplyr)

BASE_URL = "https://api.tvmaze.com/"
#httr_mock(on = FALSE)
#' get_shows
#'
#' @param query
#'
#' @return a dataframe containing all information on a given television show
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples get_shows("Hello Kitty")
get_shows <- function(query){
  query = paste0(BASE_URL, "search/shows?q=", URLencode(query))
  response = httr::GET(query)
  json_content = httr::content(response, "text", encoding = "UTF-8")
  parse_json = jsonlite::fromJSON(json_content)$show
  ifelse(length(parse_json) == 0, return (NULL), return (parse_json))
}

#' format_show_name
#'
#' @param show
#'
#' @return a dataframe of the shows returned in the get_shows() function, along
#' with premier date, end date, and the genres
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples format_show_name(get_shows("Hello Kitty"))
format_show_name <- function(show){

  genres = character()
  for (i in 1: length(show$genres)){
    genres[i] = paste(unlist(show$genres[i]), collapse = ", ")
  }

  df_shows <- data.frame(
    "name" = show$name,
    "premiered" = show$premiered,
    "ended" = show$ended,
    "genres" = genres
  )


  df_shows <- data.frame(apply(df_shows, c(1, 2),
                               function(x) ifelse(is.na(x) | x == " ", "?", x)))
  df_shows[] <- apply(df_shows, 2, function(x) ifelse(trimws(as.character(x)) == "", "?", x))

  df_shows$premiered = gsub("-.*", "", df_shows$premiered)
  df_shows$ended = gsub("-.*", "", df_shows$ended)

  return (df_shows)
}


#' get_seasons
#'
#' @param show_id
#'
#' @return parsed json file containing information about the seasons
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples get_seasons(1505)
get_seasons <- function(show_id){

  link <- paste0(BASE_URL, "shows/", as.character(show_id), "/seasons")
  response <- httr::GET(link)
  json_content <- httr::content(response, "text", encoding = "UTF-8")
  parsed_json <- jsonlite::fromJSON(json_content)
  parsed_json <- data.frame(apply(parsed_json, c(1, 2), function(x) ifelse(is.na(x) | x == " ", "?", x)))
  return(parsed_json)

}

#' format_season_name
#'
#' @param season
#'
#' @return a data frame that has been cleaned of NA values
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples format_season_name(season)
format_season_name <- function(season){

  # making the data frame
  formatted_seasons <- data.frame(Season = glue::glue("Season {season$number}"), Name = season$name, Premier = glue::glue("{substr(season$premiereDate, 1, 4)}"),
                                  End = glue::glue("{substr(season$endDate, 1, 4)}"), Episodes = season$episodeOrder)

  # replacing NA values with ? to account for missing information in the API
  formatted_seasons[is.na(formatted_seasons) | formatted_seasons == ""] <- "?"
  return(formatted_seasons)
}

#' get_episodes_of_season
#'
#' @param season_id
#'
#' @return a data frame of the parsed json
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples get_episodes_of_season(season_id)
get_episodes_of_season <- function(season_id) {
  link <- paste0(BASE_URL, "seasons/", as.character(season_id), "/episodes")
  response <- httr::GET(link)
  json_content <- httr::content(response, "text", encoding = "UTF-8")

  if (json_content == "[]") {
    return("There is no information for this season")
  } else {
    parsed_json <- jsonlite::fromJSON(json_content)
    return(parsed_json)
  }
}

#' format_episode_name
#'
#' @param episode
#'
#' @return a data frame that has been cleaned of NA values
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples
format_episode_name <- function(episode) {
  number <- lapply(episode$number, replace_na)
  rating <- lapply(episode$rating, replace_na)
  name <- lapply(episode$name, replace_na)

  ep_number <- paste0("S", episode$season, "E", number)
  df <- data.frame('Episode' = ep_number, 'Name' = episode$name, 'Rating' = rating)
  new_col_names <- c("Episode", "Name", "Rating")

  colnames(df) <- new_col_names
  return(df)
}

#' replace_na
#'
#' @param x
#'
#' @return ? if x was NA
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples replace_na(x)
replace_na <- function(x) {
  x[is.na(x)] <- "?"
  return(x)
}

#' get_all_episodes
#'
#' @param show_id
#'
#' @return a data frame of the parsed json of the get response
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples get_all_episodes(show_id)
get_all_episodes <- function(show_id) {
  link <- paste0(BASE_URL, "shows/", as.character(show_id), "/episodes")
  response <- httr::GET(link)
  json_content <- httr::content(response, "text", encoding = "UTF-8")
  parsed_json <- jsonlite::fromJSON(json_content)
  return(parsed_json)
}

#' format_all_episodes
#'
#' @param all_episodes
#'
#' @return a data frame that has been cleaned cleaned and filtered of missing values
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples format_all_episodes(all_episodes)
format_all_episodes <- function(all_episodes) {
  number <- lapply(all_episodes$number, replace_na)
  rating <- lapply(all_episodes$rating, replace_na)
  name <- lapply(all_episodes$name, replace_na)

  ep_number <- paste0("S", all_episodes$season, "E", number)
  df <- data.frame('Episode' = ep_number, 'Name' = all_episodes$name, 'Rating' = rating)
  new_col_names <- c("Episode", "Name", "Rating")

  colnames(df) <- new_col_names
  return(df)
}

#' generate_ratings_plot
#'
#' @param all_episodes_df
#'
#' @return a line plot representing the average rating across the seasons of the show
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples generate_ratings_plot(all_episodes_df)
generate_ratings_plot <- function(all_episodes_df) {
  all_episodes_df <- subset(all_episodes_df, !grepl("\\?", Rating))
  all_episodes_df$Rating <- as.numeric(all_episodes_df$Rating)
  all_episodes_df$Season <- as.numeric(gsub("^S(\\d+)E.*", "\\1", all_episodes_df$Episode))

  # if ratings is all "?" then you return "There are no ratings for this show"
  # if atleast one rating then make the plot
  all_episodes_df <- all_episodes_df[all_episodes_df$Rating != "?",]
  if (nrow(all_episodes_df) == 0) {
    return("There are no ratings for this show")
  }
  season_avg <- aggregate(all_episodes_df$Rating, by = list(all_episodes_df$Season), FUN = mean)
  colnames(season_avg) <- c("Season", "Mean_Rating")
  base <- ggplot2::ggplot(season_avg, ggplot2::aes(x = Season, y = Mean_Rating))
  plot <- base + ggplot2::geom_point() + ggplot2::geom_line(color = 'blue') + ggplot2::labs(x = "Season", y = "Mean Rating") + ggplot2::ggtitle("Mean Ratings of Each Season") +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, size = 20),
          axis.title.x = ggplot2::element_text(size = 14),
          axis.title.y = ggplot2::element_text(size = 14))

  return(plot)
}

#' generate_season_ratings_plot
#'
#' @param season_df
#'
#' @return a plot of the rating for each episode in a given season
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples generate_season_ratings_plot(season_df)
generate_season_ratings_plot <- function(season_df) {
  season_df$Episode <- as.numeric(gsub(".*E", "", season_df$Episode))
  season_df$Rating <- as.numeric(season_df$Rating)
  season_df <- season_df[complete.cases(season_df$Rating),]
  if (nrow(season_df) == 0) {
    return("There are no ratings for this show")
  }
  season_plot <- ggplot2::ggplot(season_df, ggplot2::aes(x = Episode, y = Rating)) +
    ggplot2::geom_line(color = 'orange') +
    ggplot2::geom_point() +
    ggplot2::labs(title = "Ratings of Each Episode",
         x = "Season Episodes",
         y = "Ratings") + ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, size = 20),
                                axis.title.x = ggplot2::element_text(size = 14),
                                axis.title.y = ggplot2::element_text(size = 14))

  return(season_plot)

}

#' main
#'
#'
#' @import httr
#' @import jsonlite
#' @import glue
#' @import roxygen2
#' @import ggplot2
#' @import dbplyr
#' @export
#'
#' @examples main()
main <- function(){
  exit <- FALSE
  while (exit == FALSE) {
    query <- readline("Enter a Show (or 0 to exit): ")
    if (query == "0") {
      break
    }
    results <- get_shows(query)

    if(is.null(results)) { # if there are no results for the keywords inputted by the user
      cat("No results found")
    } else {
      # all the results related to the keywords inputted
      cat("Here are the results:\n")
      details <- format_show_name(results)
      print(details)

      # ask the user to select a specific show they want to view the seasons for
      is_valid_input <- FALSE
      seasons_input <- NULL
      while (!is_valid_input) {
        seasons_input <- readline("Select a Show Number (or 0 to exit): ")
        if (grepl("^\\d+$", seasons_input) & as.numeric(seasons_input) >= 0 & as.numeric(seasons_input) <= nrow(details)) {
          is_valid_input <- TRUE
          break
        } else {
          cat("Please enter a valid input.\n")
        }
      }
      if(seasons_input == "0") {
        break
      }
      index_seasons <- as.numeric(seasons_input)
      seasons_id <- results$id[index_seasons]
      seasons_id <- trimws(seasons_id) # to account for white space in the ID

      seasons <- get_seasons(seasons_id)
      season_names <- format_season_name(seasons)
      print(season_names)

      # ask the user to select a specific season from the show and print all of the episodes in the season
      is_valid_input <- FALSE
      while (!is_valid_input) {
        season_number_input <- as.numeric(readline("Select a Season Number (or 0 to exit): "))
        if (grepl("^\\d+$", season_number_input) & as.numeric(season_number_input) >= 0 & as.numeric(season_number_input) <= nrow(season_names)) {
          is_valid_input <- TRUE
          break
        } else {
          cat("Please enter a valid input.\n")
        }
      }
      if (season_number_input == "0") {
        break
      }

      season_id <- trimws(seasons$id[season_number_input])
      episodes <- get_episodes_of_season(season_id)

      if (is.character(episodes)) { # if there is no information about the season
        cat(episodes, "\n")
      } else { # if a data frame is returned from the get_episodes_of_season function
        episode_details <- format_episode_name(episodes)
        print(episode_details)
      }

      # generating plots
      cat("\n1. Plot of average rating per season for all the seasons in a show \n2. Plot of ratings for each episodes in a season")
      is_valid_input <- FALSE
      while (!is_valid_input) {
        average_seasons_ratings <- readline("Do you want to see any of the 2 visualizations? (or 0 to exit): ")
        if (grepl("^\\d+$", average_seasons_ratings) & as.numeric(average_seasons_ratings) >= 0 & as.numeric(average_seasons_ratings) <= 2) {
          is_valid_input <- TRUE
          break
        } else {
          cat("Please enter a valid input.\n")
        }
      }
      if (average_seasons_ratings == "0") {
        break

        # graph for the average rating across the seasons
      } else if (average_seasons_ratings == "1") {
        all_episodes <- get_all_episodes(seasons_id)
        all_episodes_df <- format_all_episodes(all_episodes)
        plot <- generate_ratings_plot(all_episodes_df)
        print(plot)

        # graph for the rating for each individual episode in a season
      } else if (average_seasons_ratings == "2") {
        is_valid_input <- FALSE
        while (!is_valid_input) {
          season_rating_input <- as.numeric(readline("Which season do you want to visualize? "))
          if (grepl("^\\d+$", season_rating_input) & as.numeric(season_rating_input) > 0 & as.numeric(season_rating_input) <= nrow(season_names)) {
            is_valid_input <- TRUE
            break
          } else {
            cat("Please enter a valid input.\n")
          }
        }
        season_rating_id <- trimws(seasons$id[season_rating_input])
        episodes_rating <- get_episodes_of_season(season_rating_id)
        if (is.character(episodes_rating)) {
          cat(episodes_rating)
        } else {
          episode_details <- format_episode_name(episodes_rating)
          season_plot <- generate_season_ratings_plot(episode_details)
          print(season_plot)
        }
      }
    }
  }
}
