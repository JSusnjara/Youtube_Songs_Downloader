# Youtube_Songs_Downloader
Android app for searching and downloading Youtube videos in mp3 format, made in Flutter.

Contains following screens / activities:
- **Search** - searching for Youtube videos based on user's input. Search results are scraped from google search engine opened in hidden WebView, with 
modifications to the url so only Youtube video results are fetched. It fetches 10 results per page
- **Downloads** - shows the list of all previously downloaded songs using this app. Data is saved in a local SQLite database
- **Settings** - empty for now

## Demonstration
![](https://github.com/JSusnjara/Youtube_Songs_Downloader/blob/master/Demonstration.gif)
