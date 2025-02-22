use spotify;
show global variables like 'local_infile';
SET GLOBAL local_infile=1;

LOAD DATA LOCAL INFILE 'C:\\Users\\Admin\\Downloads\\Spotify\\spotify_stream.csv'
INTO TABLE spotify_streams
FIELDS terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

ALTER TABLE spotify_streams
CHANGE ï»¿spotify_track_uri track_url VARCHAR(500);

select * from spotify_streams;

create table spotify_stream as (SELECT *
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
    FROM spotify_streams
) t);

select * from spotify_stream;

select count(*) from spotify_stream;

ALTER TABLE spotify_stream ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY;

SELECT row_id 
FROM (
    SELECT row_id, 
           ROW_NUMBER() OVER (
               PARTITION BY track_url, ts,platform, ms_played, track_name, 
                            artist_name, album_name, reason_start, 
                            reason_end, shuffle, skipped
           ) AS rn 
    FROM spotify_stream
) t
WHERE rn > 1;

delete from spotify_stream where row_id in(
SELECT row_id 
FROM (
    SELECT row_id, 
           ROW_NUMBER() OVER (
               PARTITION BY track_url,ts, platform, ms_played, track_name, 
                            artist_name, album_name, reason_start, 
                            reason_end, shuffle, skipped
           ) AS rn 
    FROM spotify_stream
) t
WHERE rn > 1);


select track_url ,start_time,stop_time,
minutes,reason_start,reason_end ,shuffle ,skipped  from 
spotify_stream where track_url IS NULL OR ts IS NULL OR platform IS NULL 
OR track_name IS NULL or artist_name IS NULL OR album_name IS NULL OR reason_start IS NULL OR 
reason_end IS NULL OR shuffle IS NULL OR skipped IS NULL;

select distinct reason_start from spotify_stream;


update spotify_stream SET reason_start=
case when reason_start is null or reason_start='' then 'unknown' else reason_start end,
reason_end =case when reason_end is null or reason_end='' then 'unknown' else reason_end end;


-- Business Questions

-- 1.do users play a amore diverse range of tracks when shuffle mode is enabled --

select shuffle ,count(distinct track_name) as unique_tracks_played from spotify_stream  group by shuffle ;

--- what percentage of tracks played in shuffle mode are interrupted (reason_end) --

select shuffle ,count(*) as total_shuffle_plays ,sum(case when reason_end <> 'trackdone' then 1 else 0 end ) as interrupted_tracks ,
cast(round(sum(case when reason_end <> 'trackdone' then 1 else 0 end )*100.0 /count(*),2) as decimal (5,2)) as interruption_rate
from spotify_stream group by shuffle;


-- which platforms have the highest shuffle mode usage --

select platform ,shuffle ,count(shuffle) as total_play from spotify_stream group by platform,shuffle
order by total_play desc ;

-- what percentage of tracks are stopped early versus completed? --
select count(*) as total_tracks_played ,sum(case when reason_end='trackdone' then 1 else 0 end) as completed_tracks ,sum(case when reason_end<>'trackdone' then 1 else 0 end) as stopped_early,cast(round(sum(case when reason_end<>'trackdone' then 1 else 0 end)*100.0/count(*),2)
as decimal (5,2)) as stopped_early_percentage,
cast(round(sum(case when reason_end='trackdone' then 1 else 0 end)*100.0/count(*),2) as 
decimal (5,2)) as track_completed_percentage from spotify_stream ;

-- does the platform or shuffle mode influence track completion rates? --

select platform ,shuffle ,count(*) as total_played ,sum(case when reason_end='trackdone' then 1 else 0 end) as track_completed_count,cast(round(sum(case when reason_end='trackdone' then 1 else 0 end)*100.0/count(*),2) as 
decimal (5,2)) as track_completed_percentage from spotify_stream group by platform,shuffle order by track_completed_percentage desc;

-- which platforms have the longest average playback duration? --

select platform  ,round(avg(ms_played / 60000),2) as average_playback from spotify_stream 
group by platform order by average_playback desc limit 3;

-- Are there specific hours or days where platform usage peaks? --

select hour(ts) as hours,count(*) as total_usage from spotify_stream group by 
hour(ts) order by total_usage desc;

-- what are most popular hours for straming across diffrent platforms? --

-- sol1.
select platform ,hour(ts) as hours,count(*) as total_usage from spotify_stream group by platform,
hour(ts) order by total_usage desc;
 
-- sol2.
with most_usage as (select platform ,hour(ts) as peak_hour ,count(hour(ts)) as total_usage ,row_number() 
over(partition by platform order by count(*) desc) as 
rn from spotify_stream group by platform ,hour(ts))

select platform ,peak_hour,total_usage from most_usage where rn=1;

-- which tracks are most frequently played during peak hours?

with peakhours as (select hour(ts) as peak_hour from spotify_stream 
group by hour(ts) order by count(*) desc limit 1)
select track_name,count(*) as play_count from spotify_stream where hour(ts) =(select peak_hour from peakhours) 
group by track_name order by play_count desc;
