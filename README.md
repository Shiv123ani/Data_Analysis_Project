# Spotify_Dataset_Analysis_Project

Project Title:
Optimizing Shuffle Mode & Track Completion Rates for Enhanced User Engagement on Spotify

Project Overview:
The project aims to analyze user behavior on Spotify, specifically focusing on shuffle mode and track completion rates, to provide insights that will help Spotify improve user engagement and optimize the shuffle feature. By understanding the impact of shuffle mode, track interruptions, and platform usage trends, the goal is to identify areas for improvement that will encourage users to engage more with the platform, enhance track completion rates, and optimize the overall streaming experience.

Data Sources:
The dataset used for this analysis is the "Sportify_history.csv"

Tools:
MySQL to query the dataset
PowerBI to create dashboard

Data Dictionary:
The dictionary file is "Sportify_data_dictionary.csv"

Migration of Data in MySQL

 The dataset imported using below MySQL script and a total of 149,980 rows were imported.

 ![image](https://github.com/user-attachments/assets/b58afc8b-9706-43be-9d99-a43a22e18262)

 ![image](https://github.com/user-attachments/assets/132f5455-87db-47f5-8d20-3376bd52d8e3)


 Data Cleaning:

1. Change the column name 'ï»¿spotify_track_uri' to 'track_url' to make analysis easy
    ALTER TABLE spotify_history CHANGE ï»¿spotify_track_uri track_url VARCHAR(500);

   ![image](https://github.com/user-attachments/assets/b1b1b0c6-89ef-448e-96cf-4216d6fe0623)

3. Add stop_time column using ms_played column i.e songs played in milliseconds and row_number which is one of window function through 
   below MySQL script to look for duplicates in dataset.
     SELECT *
FROM (
    SELECT *,
           ts AS start_time,
           DATE_ADD(ts,interval floor(ms_played/1000) second) AS stop_time,
           round((ms_played / 60000),2) AS minutes,
           ROW_NUMBER() OVER (
               PARTITION BY track_url,ts, platform, ms_played, track_name, artist_name, album_name, 
               reason_start, reason_end, shuffle, skipped
               ORDER BY ts
           ) AS rn
    FROM spotify_history
) t;

You can see stop_time column added and cannot find duplicates as row_number for all rows is 1 .

   ![image](https://github.com/user-attachments/assets/1c6a3e9e-43e3-486b-aa01-9df52ce1b591)

  4. Add row_id column to give a specified number to each row.

     ALTER TABLE spotify_history ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY;
     ![image](https://github.com/user-attachments/assets/d3bb34b0-e8b3-429d-9e21-63f500b0fe49)

  5. Using row_id in combination with row_number to find number of duplicates in datasets .
     You can see in total 1185 dupliactes found.
     SELECT row_id 
FROM (
    SELECT row_id, 
           ROW_NUMBER() OVER (
               PARTITION BY track_url, ts,platform, ms_played, track_name, 
                            artist_name, album_name, reason_start, 
                            reason_end, shuffle, skipped
           ) AS rn 
    FROM spotify_history
) t
WHERE rn > 1;

     ![image](https://github.com/user-attachments/assets/f3c6817a-3326-40ec-aac1-feb779686719)

 7. Delete those duplicate rows using following script.
    delete from spotify_history where row_id in(
SELECT row_id 
FROM (
    SELECT row_id, 
           ROW_NUMBER() OVER (
               PARTITION BY track_url,ts, platform, ms_played, track_name, 
                            artist_name, album_name, reason_start, 
                            reason_end, shuffle, skipped
           ) AS rn 
    FROM spotify_history
) t
WHERE rn > 1);
   ![image](https://github.com/user-attachments/assets/6708a9f8-7225-4537-835d-69dcf5602ef6)



