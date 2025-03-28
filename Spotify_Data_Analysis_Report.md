**Spotify Listening Behavior Analysis Using SQL**

**Author:**         Shivani Tiwari\
**Date:**           22 Feb 2025\
**Client/Company:** Spotify  

---

## **1. Executive Summary**

### **Objective:**

Spotify aims to enhance user engagement by optimizing shuffle mode and improving track completion rates. This analysis investigates how shuffle mode impacts listening behavior, identifies patterns in track interruptions, and explores platform-specific performance trends.

---

## **2. Introduction**

### **Business Problem:**

Spotify wants to enhance user engagement by optimizing shuffle mode and improving track completion rates. 

### **Data Source:**

Data was extracted from the **spotify\_history** table, which was imported from an Excel file (**spotify\_history.csv**). The dataset contains timestamped streaming data, including track name, artist, album, platform, shuffle mode usage, and reasons for starting/stopping a track.

---

## **3. Data and SQL Queries Used**

### **3.1 Dataset Description:**

- **Table Used:** spotify\_stream
- **Key Columns:**
  - **spotify_track_uri:** Spotify URI uniquely identifying each track.
  - **ts:** Timestamp indicating when the track stopped playing (UTC).
  - **platform:** Platform used for streaming.
  - **ms_played:** Milliseconds the track was played.
  - **track_name:** Name of the track.
  - **artist_name:** Name of the artist.
  - **album_name:** Name of the album.
  - **reason_start:** Why the track started.
  - **reason_end:** Why the track ended.
  - **shuffle:** Whether shuffle mode was used (TRUE/FALSE).
  - **skipped:** Whether the user skipped to the next song (TRUE/FALSE).

### **3.2 SQL Queries Used:**

#### **Shuffle Mode Analysis:**

- **Do users play a more diverse range of tracks when shuffle is enabled?**

```sql
SELECT shuffle, COUNT(DISTINCT track_name) AS unique_tracks_played
FROM spotify_stream
GROUP BY shuffle;
```

- **What percentage of tracks played in shuffle mode are interrupted?**

```sql
SELECT shuffle, COUNT(*) AS total_shuffle_plays,
SUM(CASE WHEN reason_end <> 'trackdone' THEN 1 ELSE 0 END) AS interrupted_tracks,
CAST(ROUND(SUM(CASE WHEN reason_end <> 'trackdone' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DECIMAL(5,2)) AS interruption_rate
FROM spotify_stream
GROUP BY shuffle;
```

- **Which platforms have the highest shuffle mode usage?**

```sql
SELECT platform, shuffle, COUNT(shuffle) AS total_play
FROM spotify_stream
GROUP BY platform, shuffle
ORDER BY total_play DESC;
```

#### **Track Completion Analysis:**

- **What percentage of tracks are stopped early versus completed?**

```sql
SELECT COUNT(*) AS total_tracks_played,
SUM(CASE WHEN reason_end = 'trackdone' THEN 1 ELSE 0 END) AS completed_tracks,
SUM(CASE WHEN reason_end <> 'trackdone' THEN 1 ELSE 0 END) AS stopped_early,
CAST(ROUND(SUM(CASE WHEN reason_end <> 'trackdone' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DECIMAL(5,2)) AS stopped_early_percentage,
CAST(ROUND(SUM(CASE WHEN reason_end = 'trackdone' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DECIMAL(5,2)) AS track_completed_percentage
FROM spotify_stream;
```

#### **Platform Usage Trends:**

- **Which platforms have the longest average playback duration?**

```sql
SELECT platform, ROUND(AVG(ms_played / 60000), 2) AS average_playback
FROM spotify_stream
GROUP BY platform
ORDER BY average_playback DESC
LIMIT 3;
```

#### **Timestamp-Based Insights:**

- **What are the most popular hours for streaming?**

```sql
SELECT HOUR(ts) AS hours, COUNT(*) AS total_usage
FROM spotify_stream
GROUP BY HOUR(ts)
ORDER BY total_usage DESC;
```

- **Which tracks are most frequently played during peak hours?**

```sql
WITH peak_hours AS (
  SELECT HOUR(ts) AS peak_hour
  FROM spotify_stream
  GROUP BY HOUR(ts)
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT track_name, COUNT(*) AS play_count
FROM spotify_stream
WHERE HOUR(ts) = (SELECT peak_hour FROM peak_hours)
GROUP BY track_name
ORDER BY play_count DESC;
```

---

## **4. Data Analysis & Findings**

### **Key Findings:**

- Users play a more diverse range of tracks when shuffle mode is **disabled**.
- The **interruption rate** is **higher when shuffle mode is enabled (54.03%)** compared to disabled mode (32.42%).
- **Android** has the highest shuffle mode usage (107,754 shuffle plays enabled, 31,808 disabled).
- **48.63% of tracks are stopped early**, while **51.37% are completed**.
- **Mac users have the highest average playback time (3:57 minutes).**
- **Midnight (0 hrs) records the highest streaming activity (10,443 plays on Android).**
- Most frequently played tracks during peak hours: **The Boxer, First Youth, and Not in Nottingham**.

---

## **5. Recommendations**

- **Enhance shuffle mode** by refining algorithms to reduce interruptions and improve track diversity.
- **Improve track completion rates** by implementing personalized recommendations at the end of each track.
- **Enhance platform-specific features**, particularly for Android users who engage heavily in shuffle mode.
- **Leverage peak listening hours** (midnight and late afternoons) by curating special playlists and notifications.
- **Promote frequently played tracks** during peak hours to boost engagement and retention.

---

## **6. Conclusion**

Through this SQL analysis, we identified key insights into Spotify’s shuffle mode, track interruptions, and platform-specific usage trends. The next steps include refining shuffle algorithms, optimizing platform experiences, and leveraging time-based personalization to enhance user engagement and track completion rates.

