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
         LOAD DATA LOCAL INFILE 'C:\\Users\\Admin\\Downloads\\Spotify\\spotify_history.csv' INTO TABLE spotify_history 
         FIELDS terminated by ',' enclosed by '"' lines terminated by '\n' ignore 1 rows;

 ![image](https://github.com/user-attachments/assets/b58afc8b-9706-43be-9d99-a43a22e18262)

 ![image](https://github.com/user-attachments/assets/132f5455-87db-47f5-8d20-3376bd52d8e3)


 Data Cleaning:

1. Change the column name 'ï»¿spotify_track_uri' to 'track_url' to make analysis easy

       ALTER TABLE spotify_history CHANGE ï»¿spotify_track_uri track_url VARCHAR(500);

   ![image](https://github.com/user-attachments/assets/b1b1b0c6-89ef-448e-96cf-4216d6fe0623)

3. Add stop_time column using ms_played column i.e songs played in milliseconds and row_number which is one of window function through 
   below MySQL script to look for duplicates in dataset.

           SELECT * FROM (SELECT *, ts AS start_time,
           DATE_ADD(ts,interval floor(ms_played/1000) second) AS stop_time,
           round((ms_played / 60000),2) AS minutes,ROW_NUMBER() OVER (PARTITION BY track_url,ts, platform, ms_played, track_name, 
           artist_name, album_name, 
           reason_start, reason_end, shuffle, skipped
           ORDER BY ts) AS rn FROM spotify_history) t;

   You can see stop_time column added and cannot find duplicates as row_number for all rows is 1 .

   ![image](https://github.com/user-attachments/assets/1c6a3e9e-43e3-486b-aa01-9df52ce1b591)

  4. Add row_id column to give a specified number to each row.

            ALTER TABLE spotify_history ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY;
     ![image](https://github.com/user-attachments/assets/d3bb34b0-e8b3-429d-9e21-63f500b0fe49)

  5. Using row_id in combination with row_number to find number of duplicates in datasets .
     You can see in total 1185 dupliactes found.

            SELECT row_id FROM (
            SELECT row_id, ROW_NUMBER() OVER (
               PARTITION BY track_url, ts,platform, ms_played, track_name, 
                            artist_name, album_name, reason_start, 
                            reason_end, shuffle, skipped) AS rn FROM spotify_history) t WHERE rn > 1;

     ![image](https://github.com/user-attachments/assets/f3c6817a-3326-40ec-aac1-feb779686719)

 7. Delete those duplicate rows using following script.
    1185 duplicates deleted

              delete from spotify_history where row_id in(
              SELECT row_id FROM (SELECT row_id, 
              ROW_NUMBER() OVER (PARTITION BY track_url,ts, platform, ms_played, track_name,artist_name, album_name, reason_start, 
              reason_end, shuffle, skipped) AS rn FROM spotify_history) t WHERE rn > 1);
   ![image](https://github.com/user-attachments/assets/6708a9f8-7225-4537-835d-69dcf5602ef6)

 8. Checking for null values in reason_start and reason_end and delete all null values.

        select distinct reason_start from spotify_history;
    ![image](https://github.com/user-attachments/assets/8ae3e158-9171-48e4-95e0-5922e80a68f1)

    
        update spotify_history SET reason_start=
        case when reason_start is null or reason_start='' then 'unknown' else reason_start end,
        reason_end =case when reason_end is null or reason_end='' then 'unknown' else reason_end end;
    ![image](https://github.com/user-attachments/assets/122fc55b-0745-4899-bfa3-88cac1f05ef6)

Again run same script to check for changes in both column.

         select distinct reason_start,distinct reason_start from spotify_history;

     Business Questions:
     
     Impact of shuffle mode on listening behaviour:

1. Do users play a more diverse range of tracks when shuffle mode is enabled?

         select shuffle ,count(distinct track_name) as unique_tracks_played from spotify_history  group by shuffle ;

     ![image](https://github.com/user-attachments/assets/95b7bd8e-f2d3-4afe-9e5b-1eda4e952858)

2. What percentage of tracks played in shuffle mode are interrupted (reason_end)?

       select shuffle ,count(*) as total_shuffle_plays ,sum(case when reason_end <> 'trackdone' then 1 else 0 end ) as 
       interrupted_tracks ,cast(round(sum(case when reason_end <> 'trackdone' then 1 else 0 end )*100.0 /count(*),2) as decimal (5,2)) 
       as interruption_rate from spotify_history group by shuffle;

   ![image](https://github.com/user-attachments/assets/75cc456c-48bb-4854-baef-1ef590a51a6c)

3. Which platforms have the highest shuffle mode usage?

        select platform ,count(shuffle) as total_play from spotify_history group by platform
        order by total_play desc ;
         
      ![image](https://github.com/user-attachments/assets/c82cfef9-322c-44d8-8126-6febb9b8f418)

4. What percentage of tracks are stopped early versus completed?

       select count(*) as total_tracks_played ,sum(case when reason_end='trackdone' then 1 else 0 end) as complated_tracks ,sum(case 
       when reason_end<>'trackdone' then 1 else 0 end) as stopped_early,cast(round(sum(case when reason_end<>'trackdone' then 1 else 0 
       end)*100.0/count(*),2) as decimal (5,2)) as stopped_early_percentage,cast(round(sum(case when reason_end='trackdone' then 1 else 
       0 end)*100.0/count(*),2) as decimal (5,2)) as track_completed_percentage from spotify_history ;

     ![image](https://github.com/user-attachments/assets/d6767084-f203-4892-bb22-5d55eb411ba6)

5. Does the platform or shuffle mode influence track completion rates? 

        select platform ,shuffle ,count(*) as total_played ,sum(case when reason_end='trackdone' then 1 else 0 end) as 
        track_completed_count,cast(round(sum(case when reason_end='trackdone' then 1 else 0 end)*100.0/count(*),2) as 
        decimal (5,2)) as track_completed_percentage from spotify_history group by platform,shuffle 
        order by track_completed_percentage desc;
        
   ![image](https://github.com/user-attachments/assets/ed05ef05-d3cd-46b1-8b72-336af48f0b2c)

6. Which platforms have the longest average playback duration?

          select platform  ,round(avg(ms_played / 60000),2) as average_playback from spotify_history 
          group by platform order by average_playback desc;

   You can also get only top 3 platformm by using limit 3.

          select platform  ,round(avg(ms_played / 60000),2) as average_playback from spotify_history 
          group by platform order by average_playback desc limit 3;
          
   ![image](https://github.com/user-attachments/assets/786a2ff3-2a81-4dfb-8f26-6bc155b8f4d1)


7. Are there specific hours or days where platform usage peaks?

          select hour(ts) as hours,count(*) as total_usage from spotify_history group by 
          hour(ts) order by total_usage desc;
          
   ![image](https://github.com/user-attachments/assets/80763d9b-391e-4c28-a759-57335f808b5f)

8. What are most popular hours for straming across diffrent platforms?

   Solution 1:
          
          select platform ,hour(ts) as hours,count(*) as total_usage from spotify_history group by platform,
          hour(ts) order by total_usage desc;

   ![image](https://github.com/user-attachments/assets/6d15e2c5-b287-411f-a674-5f3b39343806)

   Solution 2:
          In this solution 2 ,used CTE and row_number to get more accurate answer.

          with most_usage as (select platform ,hour(ts) as peak_hour ,count(hour(ts)) as total_usage ,row_number() 
          over(partition by platform order by count(*) desc) as rn from spotify_history group by platform ,hour(ts))

          select platform ,peak_hour,total_usage from most_usage where rn=1;
          
   ![image](https://github.com/user-attachments/assets/e6b51236-963f-4df1-b4ac-d2a9311070ce)

9. Which tracks are most frequently played during peak hours? 
   Again used CTE to find answer.
          
          with peakhours as (select hour(ts) as peak_hour from spotify_history 
          group by hour(ts) order by count(*) desc limit 1)
          
          select track_name,count(*) as play_count from spotify_history where hour(ts) =(select peak_hour from peakhours) 
          group by track_name order by play_count desc;

   ![image](https://github.com/user-attachments/assets/c6673402-6e28-40e2-ac3c-080bbd031001)


          


          





      


    

    
    
 



