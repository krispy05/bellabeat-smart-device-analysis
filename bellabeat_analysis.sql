-- =====================================================
-- BELLABEAT SMART DEVICE USAGE ANALYSIS
-- Google Data Analytics Capstone
-- =====================================================

-- =====================================================
-- 1. DATA QUALITY CHECKS
-- =====================================================

-- Check for duplicate daily activity records
SELECT
  Id,
  ActivityDate,
  COUNT(*) AS duplicate_count
FROM `capstone-509417.daily_activity.daily_activity_raw`
GROUP BY Id, ActivityDate
HAVING COUNT(*) > 1;


-- Check for missing values in key daily activity fields
SELECT
  COUNTIF(Id IS NULL) AS missing_id,
  COUNTIF(ActivityDate IS NULL) AS missing_date,
  COUNTIF(TotalSteps IS NULL) AS missing_steps,
  COUNTIF(TotalDistance IS NULL) AS missing_distance,
  COUNTIF(Calories IS NULL) AS missing_calories
FROM `capstone-509417.daily_activity.daily_activity_raw`;


-- Check for invalid negative values
SELECT
  COUNTIF(TotalSteps < 0) AS negative_steps,
  COUNTIF(TotalDistance < 0) AS negative_distance,
  COUNTIF(Calories < 0) AS negative_calories,
  COUNTIF(VeryActiveMinutes < 0) AS negative_very_active,
  COUNTIF(FairlyActiveMinutes < 0) AS negative_fairly_active,
  COUNTIF(LightlyActiveMinutes < 0) AS negative_lightly_active,
  COUNTIF(SedentaryMinutes < 0) AS negative_sedentary
FROM `capstone-509417.daily_activity.daily_activity_raw`;


-- Check for zero-step days
SELECT
  COUNT(*) AS zero_step_days,
  COUNT(DISTINCT Id) AS users_with_zero_step_days
FROM `capstone-509417.daily_activity.daily_activity_raw`
WHERE TotalSteps = 0;


-- Check for zero-calorie days
SELECT
  COUNT(*) AS zero_calorie_days,
  COUNT(DISTINCT Id) AS users_with_zero_calorie_days
FROM `capstone-509417.daily_activity.daily_activity_raw`
WHERE Calories = 0;


-- =====================================================
-- 2. SLEEP DATA CLEANING
-- =====================================================

-- Check duplicate sleep records
SELECT
  Id,
  SleepDay,
  COUNT(*) AS duplicate_count
FROM `capstone-509417.daily_activity.sleep_merged_raw`
GROUP BY Id, SleepDay
HAVING COUNT(*) > 1;


-- Create cleaned sleep table
CREATE OR REPLACE TABLE
`capstone-509417.daily_activity.sleep_clean` AS
SELECT DISTINCT
  Id,
  DATE(SAFE.PARSE_TIMESTAMP('%m/%d/%Y %I:%M:%S %p', SleepDay)) AS SleepDate,
  TotalSleepRecords,
  TotalMinutesAsleep,
  TotalTimeInBed
FROM `capstone-509417.daily_activity.sleep_merged_raw`;


-- Validate cleaned sleep data
SELECT
  COUNT(*) AS records,
  COUNT(DISTINCT Id) AS users,
  MIN(SleepDate) AS first_date,
  MAX(SleepDate) AS last_date
FROM `capstone-509417.daily_activity.sleep_clean`;


-- Check for invalid sleep values
SELECT
  COUNTIF(TotalMinutesAsleep < 0) AS negative_sleep,
  COUNTIF(TotalTimeInBed < 0) AS negative_time_in_bed,
  COUNTIF(TotalMinutesAsleep > TotalTimeInBed) AS sleep_greater_than_bed
FROM `capstone-509417.daily_activity.sleep_clean`;


-- =====================================================
-- 3. CREATE COMBINED ANALYSIS TABLE
-- =====================================================

CREATE OR REPLACE TABLE
`capstone-509417.daily_activity.daily_analysis` AS
SELECT
  A.Id,
  A.ActivityDate,
  A.TotalSteps,
  A.TotalDistance,
  A.VeryActiveDistance,
  A.ModeratelyActiveDistance,
  A.LightActiveDistance,
  A.VeryActiveMinutes,
  A.FairlyActiveMinutes,
  A.LightlyActiveMinutes,
  A.SedentaryMinutes,
  A.Calories,
  S.TotalSleepRecords,
  S.TotalMinutesAsleep,
  S.TotalTimeInBed
FROM `capstone-509417.daily_activity.daily_activity_raw` AS A
LEFT JOIN `capstone-509417.daily_activity.sleep_clean` AS S
ON CAST(A.Id AS STRING) = S.Id
AND A.ActivityDate = S.SleepDate;


-- Verify combined table
SELECT
  COUNT(*) AS total_records,
  COUNT(DISTINCT Id) AS users,
  COUNTIF(TotalMinutesAsleep IS NOT NULL) AS records_with_sleep
FROM `capstone-509417.daily_activity.daily_analysis`;


-- =====================================================
-- 4. ANALYSIS
-- =====================================================

-- Basic activity summary
SELECT
  COUNT(*) AS activity_days,
  COUNT(DISTINCT Id) AS users,
  ROUND(AVG(TotalSteps), 0) AS avg_daily_steps,
  ROUND(AVG(TotalDistance), 2) AS avg_daily_distance,
  ROUND(AVG(Calories), 0) AS avg_daily_calories,
  ROUND(AVG(VeryActiveMinutes), 1) AS avg_very_active_minutes,
  ROUND(AVG(FairlyActiveMinutes), 1) AS avg_fairly_active_minutes,
  ROUND(AVG(LightlyActiveMinutes), 1) AS avg_lightly_active_minutes,
  ROUND(AVG(SedentaryMinutes), 1) AS avg_sedentary_minutes
FROM `capstone-509417.daily_activity.daily_activity_raw`;


-- Sleep summary
SELECT
  COUNT(*) AS sleep_records,
  COUNT(DISTINCT Id) AS users,
  ROUND(AVG(TotalMinutesAsleep), 0) AS avg_minutes_asleep,
  ROUND(AVG(TotalTimeInBed), 0) AS avg_minutes_in_bed
FROM `capstone-509417.daily_activity.sleep_clean`;


-- Weekday vs weekend
SELECT
  CASE
    WHEN EXTRACT(DAYOFWEEK FROM ActivityDate) IN (1, 7)
      THEN 'Weekend'
    ELSE 'Weekday'
  END AS day_type,
  COUNT(*) AS activity_days,
  ROUND(AVG(TotalSteps), 0) AS avg_steps,
  ROUND(AVG(TotalDistance), 2) AS avg_distance,
  ROUND(AVG(VeryActiveMinutes), 1) AS avg_very_active_minutes,
  ROUND(AVG(FairlyActiveMinutes), 1) AS avg_fairly_active_minutes,
  ROUND(AVG(LightlyActiveMinutes), 1) AS avg_lightly_active_minutes,
  ROUND(AVG(SedentaryMinutes), 1) AS avg_sedentary_minutes
FROM `capstone-509417.daily_activity.daily_activity_raw`
GROUP BY day_type
ORDER BY day_type;


-- Activity levels based on daily steps
SELECT
  CASE
    WHEN TotalSteps < 5000 THEN 'Low activity'
    WHEN TotalSteps < 10000 THEN 'Moderate activity'
    ELSE 'High activity'
  END AS activity_level,
  COUNT(*) AS activity_days,
  ROUND(AVG(TotalSteps), 0) AS avg_steps,
  ROUND(AVG(SedentaryMinutes), 1) AS avg_sedentary_minutes,
  ROUND(AVG(Calories), 0) AS avg_calories
FROM `capstone-509417.daily_activity.daily_activity_raw`
GROUP BY activity_level
ORDER BY
  CASE
    WHEN activity_level = 'Low activity' THEN 1
    WHEN activity_level = 'Moderate activity' THEN 2
    WHEN activity_level = 'High activity' THEN 3
  END;


-- Hourly activity
SELECT
  EXTRACT(
    HOUR FROM PARSE_DATETIME(
      '%m/%d/%Y %I:%M:%S %p',
      ActivityHour
    )
  ) AS hour,
  ROUND(AVG(HourlyIntensity), 2) AS avg_hourly_intensity,
  COUNT(*) AS records
FROM `capstone-509417.daily_activity.hourly_intensities_raw`
GROUP BY hour
ORDER BY hour;


-- Sleep vs activity
SELECT
  CASE
    WHEN a.TotalSteps < 5000 THEN 'Low activity'
    WHEN a.TotalSteps < 10000 THEN 'Moderate activity'
    ELSE 'High activity'
  END AS activity_level,
  COUNT(*) AS sleep_records,
  ROUND(AVG(a.TotalSteps), 0) AS avg_steps,
  ROUND(AVG(s.TotalMinutesAsleep), 0) AS avg_minutes_asleep,
  ROUND(AVG(s.TotalTimeInBed), 0) AS avg_minutes_in_bed
FROM `capstone-509417.daily_activity.daily_activity_raw` AS a
INNER JOIN `capstone-509417.daily_activity.sleep_clean` AS s
  ON CAST(a.Id AS STRING) = s.Id
  AND a.ActivityDate = s.SleepDate
GROUP BY activity_level
ORDER BY
  CASE
    WHEN activity_level = 'Low activity' THEN 1
    WHEN activity_level = 'Moderate activity' THEN 2
    WHEN activity_level = 'High activity' THEN 3
  END;


-- Steps vs sleep correlation
SELECT
  CORR(a.TotalSteps, s.TotalMinutesAsleep) AS steps_sleep_correlation
FROM `capstone-509417.daily_activity.daily_activity_raw` AS a
INNER JOIN `capstone-509417.daily_activity.sleep_clean` AS s
  ON CAST(a.Id AS STRING) = s.Id
  AND a.ActivityDate = s.SleepDate;


-- Distance vs calories correlation
SELECT
  CORR(TotalDistance, Calories) AS distance_calories_correlation
FROM `capstone-509417.daily_activity.daily_activity_raw`;


-- Steps vs calories correlation
SELECT
  CORR(TotalSteps, Calories) AS steps_calories_correlation
FROM `capstone-509417.daily_activity.daily_activity_raw`;