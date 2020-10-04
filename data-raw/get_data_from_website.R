# Scrap metadata of Denis de Rougemont Books
library(tidyverse)
library(rvest)

base_url <- "https://www.unige.ch/rougemont/livres"

meta <- base_url %>%
  read_html() %>%
  html_node(".covers") %>%
  rvest::html_nodes("a")

url_book <- meta %>%
  rvest::html_attr("href") %>%
  paste0("https://www.unige.ch/rougemont/", .)

title_book <- meta %>%
  rvest::html_attr("title")

url_img <- meta %>%
  html_nodes(".cover") %>%
  rvest::html_attr("src")

publisher <- meta %>%
  html_nodes(".publisher") %>%
  html_text()

date <- meta %>%
  html_nodes(".date") %>%
  html_text()

metadata <- tibble(
  url_book = url_book,
  title_book = title_book,
  url_img = url_img,
  publisher = publisher,
  date = date
)

# Scrap chapter links for each book
get_rougemont_chapters <- function(url) {

  summary <- url %>%
    read_html() %>%
    html_nodes(".toclocal")
  
  url_chapter <- summary %>%
    html_nodes(".chapter") %>%
    html_nodes("a") %>%
    rvest::html_attr("href") %>%
    paste0("https://www.unige.ch/rougemont/livres/", .)
    
  title_chapter <- summary %>%
    html_nodes(".chapter") %>%
    html_text() %>%
    stringr::str_split("\n") %>%
    unlist() %>%
    stringr::str_trim() %>%
    purrr::discard(!str_detect(., "")) %>%
    # remove if starts with "–  " because error in some subchapters
    purrr::discard(str_detect(., "^–  "))
  
  df <- tibble(
    url_chapter = url_chapter,
    title_chapter = title_chapter
  )
  
  return(df)
}

# Loop on all chapter urls to get their urls and titles
df_empty <- tibble(
  url_chapter = character(0),
  title_chapter = character(0)
)

getAllData <- function(url_path) {
  cat(url_path, " ")
  df <- get_rougemont_chapters(url_path) %>%
    mutate(url_book = url_path)
  df <- full_join(df_empty, df)
}

df_metadata <- map_dfr(metadata$url_book, getAllData)

# join two dataframes together
rougemont_metadata <- df_metadata %>%
  full_join(metadata, by = "url_book")

usethis::use_data(rougemont_metadata, overwrite = TRUE)

# Download all texts ------------------------------------------------------

rougemont_meta <- rougemont_metadata %>%
  mutate(url_chapter = str_remove(url_chapter, "#.*")) %>%
  select(-title_chapter, -url_img) %>%
  distinct()

get_rougemont_texts <- function(url_chapter){
  
  text_by_paragraph <- url_chapter %>%
    read_html() %>%
    html_node("article") %>%
    html_text() %>%
    stringr::str_trim() %>%
    str_split("\n") %>%
    unlist() %>%
    str_trim() %>%
    purrr::discard(!str_detect(., ""))
  
  df_text <- tibble(
    url_chapter = url_chapter,
    text = text_by_paragraph
  )
  
  return(df_text)
}

df_text_empty <- tibble(
  url_chapter = character(0),
  text = character(0)
)

getAllTexts <- function(url_path) {
  Sys.sleep(1)
  cat(url_path, " ")
  df <- get_rougemont_texts(url_path)
  df <- full_join(df_text_empty, df)
  df
}

rougemont <- map_df(rougemont_meta$url_chapter, getAllTexts)

rougemont <- rougemont %>%
  full_join(rougemont_meta) %>%
  select(title_book, date, publisher, url_book, url_chapter, text)

usethis::use_data(rougemont, overwrite = TRUE)
