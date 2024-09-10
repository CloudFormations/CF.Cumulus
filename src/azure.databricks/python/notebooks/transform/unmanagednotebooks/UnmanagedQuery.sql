-- Databricks notebook source
-- GET LATEST 100 TRIPS
CREATE OR REPLACE TABLE LatestTrips
AS 
SELECT *
FROM `samples`.`nyctaxi`.`trips`
ORDER BY tpep_pickup_datetime DESC
LIMIT 100
