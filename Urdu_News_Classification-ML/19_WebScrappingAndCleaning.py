# %%
import os
import json
import time
import random
import zipfile
import requests
import pandas as pd
from bs4 import BeautifulSoup

# %% [markdown]
# # Class Explanation: `NewsScraper`
# 
# ## Overview
# The `NewsScraper` class is designed for scraping news articles from three different Urdu news websites: Geo, Jang, and Express. The class has methods that cater to each site's unique structure and requirements. Below, we will go through the class and its methods, detailing what each function does, the input it takes, and the output it returns.
# 
# ## Class Definition
# 
# ```python
# class NewsScraper:
#     def __init__(self, id_=0):
#         self.id = id_
# ```
# 
# 
# ## Method 1: `get_express_articles`
# 
# ### Description
# Scrapes news articles from the Express website across categories like saqafat (entertainment), business, sports, science-technology, and world. The method navigates through multiple pages for each category to gather a more extensive dataset.
# 
# ### Input
# - **`max_pages`**: The number of pages to scrape for each category (default is 7).
# 
# ### Process
# - Iterates over each category and page.
# - Requests each category page and finds article cards within `<ul class='tedit-shortnews listing-page'>`.
# - Extracts the article's headline, link, and content by navigating through `<div class='horiz-news3-caption'>` and `<span class='story-text'>`.
# 
# ### Output
# - **Returns**: A tuple of:
#   - A Pandas DataFrame containing columns: `id`, `title`, and `link`).
#   - A dictionary `express_contents` where the key is the article ID and the value is the article content.
# 
# ### Data Structure
# - Article cards are identified by `<li>` tags.
# - Content is structured within `<span class='story-text'>` and `<p>` tags.
# 
# 

# %% [markdown]
# ### Other websites used
# 
# Here we have used two more websites for our webscraping:
# - Geo News
# - Jang News

# %%
class NewsScraper:
    def __init__(self,id_=0):
        self.id = id_


    # write functions to scrape from other websites
    def get_geo_articles(self, max_pages=7):
        geo_df = {
            "id": [],
            "title": [],
            "link": [],
            "content": [],
            "gold_label": [],
        }
        base_url = 'https://urdu.geo.tv/category'
        categories = ['entertainment', 'business', 'sports', 'science-technology', 'world']   # saqafat is entertainment category

        # Iterating over the specified number of pages
        for category in categories:
            for page in range(1, 2):
                print(f"Scraping page {page} of category '{category}'...")
                url = f"{base_url}/{category}/archives?page={page}"
                response = requests.get(url)
                response.raise_for_status()
                soup = BeautifulSoup(response.text, "html.parser")

                # Finding article cards
                cards = soup.find_all('div', class_ = "col-xs-6 col-sm-6 col-lg-6 col-md-6 singleBlock")

                print(f"\t--> Found {len(cards)} articles on page {page} of '{category}'.")

                success_count = 0

                for card in cards:
                    try:
                        div = card.find('ul')
                        div = div.find("li")
                        
                        # Article Title
                        headline = div.find('a').get_text(strip=True).replace('\xa0', ' ')
                        
                        # Article link
                        link = div.find('a')['href']
                        
                        # Requesting the content from each article's link
                        article_response = requests.get(link)
                        article_response.raise_for_status()
                        content_soup = BeautifulSoup(article_response.text, "html.parser")

                        # Content arranged in paras inside <span> tags
                        paras = content_soup.find('div',class_='content-area').find_all('p')

                        combined_text = " ".join(
                        p.get_text(strip=True).replace('\xa0', ' ').replace('\u200b', '')
                        for p in paras if p.get_text(strip=True)
                        )

                        # Storing data
                        geo_df['id'].append(self.id)
                        geo_df['title'].append(headline)
                        geo_df['link'].append(link)
                        geo_df['gold_label'].append(category)
                        geo_df['content'].append(combined_text)

                        # Increment ID and success count
                        self.id += 1
                        success_count += 1

                        # print(f"\t--> Successfully scraped {success_count} articles from page {page} of '{category}'.")

                    except Exception as e:
                        print(f"\t--> Failed to scrape an article on page {page} of '{category}': {e}")

                print(f"\t--> Successfully scraped {success_count} articles from page {page} of '{category}'.")
        
        return pd.DataFrame(geo_df)
    
    
    
    def get_jang_articles(self):
        jang_df = {
            "id": [],
            "title": [],
            "link": [],
            "content": [],
            "gold_label": [],
        }
        base_url = 'https://jang.com.pk'
        categories = ['entertainment', 'business', 'sports', 'health-science', 'world']
        
        
        for category in categories:
            print(f"Scraping category '{category}'...")
            url = f'{base_url}/category/latest-news/{category}'
            
            response = requests.get(url)
            response.raise_for_status()
            soup = BeautifulSoup(response.text, "html.parser")
            
            cards=soup.find('ul', class_='scrollPaginationNew__').find_all('li')
            print(f"\t--> Found {len(cards)} articles of {category}.")
            
            success_count = 0
            
            for card in cards:
                try:
                    div = card.find('div',class_='main-heading')
                    
                    headline = div.find('a').get_text(strip=True).replace('\xa0', ' ')

                    link = div.find('a')['href']

                    article_response = requests.get(link)
                    article_response.raise_for_status()
                    content_soup = BeautifulSoup(article_response.text, "html.parser")
                                        
                    paras = content_soup.find('div', class_='detail_view_content').find_all('p')

                    combined_text = " ".join(
                    p.get_text(strip=True).replace('\xa0', ' ').replace('\u200b', '')
                    for p in paras if p.get_text(strip=True)
                    )
                    
                    # Storing data
                    jang_df['id'].append(self.id)
                    jang_df['title'].append(headline)
                    jang_df['link'].append(link)
                    jang_df['gold_label'].append(category.replace('health-science','science-technology'))
                    jang_df['content'].append(combined_text)

                    # Increment ID and success count
                    self.id += 1
                    success_count += 1

                except Exception as e:
                    print(f"\t--> Failed to scrape an article of '{category}': {e}")

            print(f"\t--> Successfully scraped {success_count} articles of '{category}'.")
        
        return pd.DataFrame(jang_df)
             


    def get_express_articles(self, max_pages=7):
        express_df = {
            "id": [],
            "title": [],
            "link": [],
            "content": [],
            "gold_label": [],
        }
        base_url = 'https://www.express.pk'
        categories = ['saqafat', 'business', 'sports', 'science', 'world']   # saqafat is entertainment category

        # Iterating over the specified number of pages
        for category in categories:
            for page in range(1, max_pages + 1):
                print(f"Scraping page {page} of category '{category}'...")
                url = f"{base_url}/{category}/archives?page={page}"
                response = requests.get(url)
                response.raise_for_status()
                soup = BeautifulSoup(response.text, "html.parser")

                # Finding article cards
                cards = soup.find('ul', class_='tedit-shortnews listing-page').find_all('li')  # Adjust class as per actual site structure
                print(f"\t--> Found {len(cards)} articles on page {page} of '{category}'.")

                success_count = 0

                for card in cards:
                    try:
                        div = card.find('div',class_='horiz-news3-caption')

                        # Article Title
                        headline = div.find('a').get_text(strip=True).replace('\xa0', ' ')

                        # Article link
                        link = div.find('a')['href']
                        print('link in express is', link)

                        # Requesting the content from each article's link
                        article_response = requests.get(link)
                        article_response.raise_for_status()
                        content_soup = BeautifulSoup(article_response.text, "html.parser")


                        # Content arranged in paras inside <span> tags
                        paras = content_soup.find('span',class_='story-text').find_all('p')

                        combined_text = " ".join(
                        p.get_text(strip=True).replace('\xa0', ' ').replace('\u200b', '')
                        for p in paras if p.get_text(strip=True)
                        )

                        # Storing data
                        express_df['id'].append(self.id)
                        express_df['title'].append(headline)
                        express_df['link'].append(link)
                        express_df['gold_label'].append(category.replace('saqafat','entertainment').replace('science','science-technology'))
                        express_df['content'].append(combined_text)

                        # Increment ID and success count
                        self.id += 1
                        success_count += 1

                    except Exception as e:
                        print(f"\t--> Failed to scrape an article on page {page} of '{category}': {e}")

                print(f"\t--> Successfully scraped {success_count} articles from page {page} of '{category}'.")
            print('')

        return pd.DataFrame(express_df)

# %%
scraper = NewsScraper()

# %% [markdown]
# ### Output
# 
# - Getting the articles from all websites and combinig the results in a csv file
# - Created `articles.csv`

# %%
geo_df=scraper.get_geo_articles()
jang_df=scraper.get_jang_articles()
express_df=scraper.get_express_articles()

combined_df=pd.concat([geo_df, jang_df, express_df], ignore_index=True)

combined_df=combined_df.rename(columns={
    'id': 'Article IDs',
    'link': 'Links', 
    'title': 'Titles', 
    'content': 'Contents', 
    'gold_label': 'Gold Labels'
})

combined_df.to_csv('articles.csv', index=False)

# %% [markdown]
# ### Imports for data cleaning
# 
# 

# %%
import pandas as pd
import numpy as np
import re

import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score,confusion_matrix

import kagglehub


# %% [markdown]
# ### Data Cleaning
# 
# - `\u0600-\u06FF` specifies a Unicode range. This range includes characters from the Arabic script, which covers most of Urdu.
# - We have removed punctuations and numbers here.
# - Included Stopwords Cleaning

# %%
df = pd.read_csv(r"articles.csv")
df = df.dropna().reset_index(drop=True)
df = df.drop_duplicates(subset=['Contents']).reset_index(drop=True)

print(pd.value_counts(df["Gold Labels"]))
print("Total number of articles: " ,len(set(df["Contents"])))

# DOWNLOADED URDU STOPWORDS
# SEE urdu_stopwords.txt file

stopwords_file = "urdu_stopwords.txt" 
with open(stopwords_file, "r", encoding="utf-8") as f:
        urdu_stopwords = [line.strip() for line in f]

print(urdu_stopwords)

def clean_text(text):
    text = re.sub(r'[^\u0600-\u06FF\s]', '', text)
    text = ' '.join([word for word in text.split() if word not in urdu_stopwords])
    return text

df_cleaned = df.copy()
df_cleaned['Contents'] = df_cleaned['Contents'].apply(clean_text)


# %%

print("\n\nUncleaned data example")
print(df['Contents'][60:70])
print("--------"*7)
print("\n\n\n")

print("Cleaned data example")
print(df_cleaned['Contents'][60:70])
df_cleaned.to_csv('cleaned.csv', index=False)

# %% [markdown]
# ## Now you can see a `cleaned.csv` file! We will be using this for all our models.


