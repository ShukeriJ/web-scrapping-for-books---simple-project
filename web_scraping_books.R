# =========================================================
# TASK 2: WEB SCRAPING
# Website: Books to Scrape
# Groups: Fiction vs Sequential Art
# Scrape: First 3 pages for each group
# =========================================================

# Install packages only once
install.packages("rvest")
install.packages("dplyr")
install.packages("ggplot2")
install.packages("stringr")
install.packages("readr")

# Load packages
library(rvest)
library(dplyr)
library(ggplot2)
library(stringr)
library(readr)

# =========================================================
# FUNCTION: Convert rating words to numbers
# =========================================================

rating_to_number <- function(rating) {
  case_when(
    rating == "One" ~ 1,
    rating == "Two" ~ 2,
    rating == "Three" ~ 3,
    rating == "Four" ~ 4,
    rating == "Five" ~ 5,
    TRUE ~ NA_real_
  )
}

# =========================================================
# FUNCTION: Scrape books
# =========================================================

scrape_books <- function(category_name, base_url, total_pages = 3) {
  
  all_books <- data.frame()
  
  for (page in 1:total_pages) {
    
    if (page == 1) {
      url <- paste0(base_url, "index.html")
    } else {
      url <- paste0(base_url, "page-", page, ".html")
    }
    
    webpage <- read_html(url)
    
    titles <- webpage %>%
      html_elements("article.product_pod h3 a") %>%
      html_attr("title")
    
    prices <- webpage %>%
      html_elements("p.price_color") %>%
      html_text() %>%
      str_remove("£") %>%
      as.numeric()
    
    availability <- webpage %>%
      html_elements("p.instock.availability") %>%
      html_text() %>%
      str_squish()
    
    ratings <- webpage %>%
      html_elements("p.star-rating") %>%
      html_attr("class") %>%
      str_remove("star-rating ")
    
    rating_number <- rating_to_number(ratings)
    
    page_data <- data.frame(
      category = category_name,
      title = titles,
      price = prices,
      availability = availability,
      rating_text = ratings,
      rating_number = rating_number,
      page = page,
      stringsAsFactors = FALSE
    )
    
    all_books <- bind_rows(all_books, page_data)
  }
  
  return(all_books)
}

# =========================================================
# SCRAPE FIRST 3 PAGES
# These categories have at least 3 pages
# =========================================================

fiction_url <- "https://books.toscrape.com/catalogue/category/books/fiction_10/"
sequential_art_url <- "https://books.toscrape.com/catalogue/category/books/sequential-art_5/"

fiction_books <- scrape_books("Fiction", fiction_url, 3)
sequential_art_books <- scrape_books("Sequential Art", sequential_art_url, 3)

# Combine data
books_data <- bind_rows(fiction_books, sequential_art_books)

# View dataset
View(books_data)
head(books_data)

# Save dataset
write_csv(books_data, "books_scraping_dataset.csv")

# =========================================================
# SIMPLE ANALYSIS
# =========================================================

summary_table <- books_data %>%
  group_by(category) %>%
  summarise(
    total_books = n(),
    average_price = round(mean(price), 2),
    minimum_price = min(price),
    maximum_price = max(price),
    average_rating = round(mean(rating_number), 2)
  )

print(summary_table)

rating_table <- books_data %>%
  group_by(category, rating_number) %>%
  summarise(total = n(), .groups = "drop")

print(rating_table)

# =========================================================
# VISUALISATION 1: Average Price
# =========================================================

ggplot(summary_table, aes(x = category, y = average_price, fill = category)) +
  geom_col(width = 0.6) +
  labs(
    title = "Average Price: Fiction vs Sequential Art",
    x = "Book Category",
    y = "Average Price (£)"
  ) +
  theme_minimal()

# =========================================================
# VISUALISATION 2: Price Distribution
# =========================================================

ggplot(books_data, aes(x = category, y = price, fill = category)) +
  geom_boxplot() +
  labs(
    title = "Price Distribution: Fiction vs Sequential Art",
    x = "Book Category",
    y = "Price (£)"
  ) +
  theme_minimal()

# =========================================================
# VISUALISATION 3: Rating Distribution
# =========================================================

ggplot(books_data, aes(x = factor(rating_number), fill = category)) +
  geom_bar(position = "dodge") +
  labs(
    title = "Rating Distribution: Fiction vs Sequential Art",
    x = "Rating",
    y = "Number of Books",
    fill = "Category"
  ) +
  theme_minimal()

