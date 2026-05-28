USE IPL_DATA_2008_25;

SELECT * FROM deliveries_upto_2025;
SELECT * FROM matches_upto_2025;

-- TOTAL MATCHES PLAYED BY EACH MATCHES TILL 2025
SELECT team,COUNT(*) AS Total_Matches
FROM
(SELECT team1 AS team FROM matches_upto_2025
UNION ALL 
SELECT team2 AS team FROM matches_upto_2025) t
GROUP BY team
ORDER BY Total_Matches DESC;


--TOTAL MATCHES WON BY EACH TEAM
SELECT Winner AS Team,COUNT(winner) AS Total_Wins
FROM matches_upto_2025
GROUP BY winner
ORDER BY Total_Wins DESC;


--TOTAL MATCHES WIN BY TEAM EACH SEASON
SELECT season,Winner AS Team,COUNT(winner) AS Total_Wins
FROM matches_upto_2025
WHERE winner IS NOT NULL
GROUP BY winner,season
ORDER BY season;

-- TOTAL TOSS WIN BY EACH TEAM TILL 2025
SELECT toss_winner AS Team,
COUNT(toss_winner) AS Total_Toss_Wins
FROM matches_upto_2025
GROUP BY toss_winner
ORDER BY Total_Toss_Wins DESC;

-- EACH SEASON FINAL MACTH SUMMARY
SELECT season,team1,team2,winner,date 
FROM (SELECT season,team1,team2,winner,date,
ROW_NUMBER() OVER(PARTITION BY season ORDER BY date DESC) AS Final_Date
FROM matches_upto_2025)t
WHERE Final_Date = 1;

-- TOTAL FINAL PLAYED BY EACH TEAM
WITH FINAL_MATCH AS 
(SELECT season,team1,team2,winner,date,
ROW_NUMBER() OVER(PARTITION BY season ORDER BY date DESC) AS Final_Date
FROM matches_upto_2025)
SELECT team,
COUNT(*) AS Total_Final FROM 
(SELECT team1 AS team FROM FINAL_MATCH
WHERE Final_Date = 1
UNION ALL
SELECT team2 AS team FROM FINAL_MATCH
WHERE Final_Date = 1)t
GROUP BY team
ORDER BY Total_Final DESC;


-- TOTAL TROPHY WON BY EACH TEAM IN IPL
WITH FINAL_MATCH AS 
(SELECT season,winner,date,
ROW_NUMBER() OVER(PARTITION BY season ORDER BY date DESC) AS Final_Date
FROM matches_upto_2025)

SELECT winner AS Team,COUNT(winner) Total_Trophy FROM FINAL_MATCH
WHERE Final_Date = 1
GROUP BY winner
ORDER BY Total_Trophy DESC;

-- TOTAL MATCHES PLAYED BY EACH PLAYER
SELECT player,COUNT(matchid) AS Total_Matches FROM 
(SELECT batsman AS player,matchid FROM deliveries_upto_2025
UNION
SELECT bowler AS player,matchid FROM deliveries_upto_2025)t
GROUP BY player
ORDER BY Total_Matches DESC;

-- TOTAL RUNS BY PLYAERS IN IPL CARRER 
SELECT batsman,SUM(batsman_runs) AS Total_ipl_runs
FROM deliveries_upto_2025
GROUP BY batsman
ORDER BY Total_ipl_runs DESC;

-- TOTAL WICKETS BY PLYAERS IN IPL CARRER 
SELECT bowler,COUNT(player_dismissed) AS Total_Wickets
FROM deliveries_upto_2025
WHERE player_dismissed IS NOT NULL
GROUP BY bowler
ORDER BY Total_Wickets DESC;

-- TOTAL IPL CENTURIES BY EACH PLAYER
WITH century AS (SELECT distinct(matchid),batsman,SUM(batsman_runs) AS Runs
FROM deliveries_upto_2025
GROUP BY matchid,batsman
HAVING SUM(batsman_runs) >= 100)

SELECT batsman,COUNT(Runs) AS Total_centuries FROM century
GROUP BY batsman
ORDER BY Total_centuries DESC;

-- NUMBER OF HALF CENTURIES BY EACH PLAYER
WITH century AS (SELECT distinct(matchid),batsman,SUM(batsman_runs) AS Runs
FROM deliveries_upto_2025
GROUP BY matchid,batsman
HAVING SUM(batsman_runs) >= 50 AND SUM(batsman_runs) < 100 )

SELECT batsman,COUNT(Runs) AS Total_Half_centuries FROM century
GROUP BY batsman
ORDER BY Total_Half_centuries DESC;


-- ORANGE CAP WINNER EACH SEASON
SELECT season,batsman,Total_runs
FROM 
(SELECT m.season,d.batsman,SUM(d.batsman_runs) AS Total_runs,
ROW_NUMBER() OVER(PARTITION BY season ORDER BY SUM(d.batsman_runs) DESC) AS Orange_cap
FROM deliveries_upto_2025 d
JOIN matches_upto_2025 m ON d.matchid = m.matchid GROUP BY m.season,d.batsman)t
WHERE Orange_cap = 1;

-- PURPLE CAP WINNER EACH SEASON 
SELECT season,bowler,Total_Wickets FROM (SELECT m.season,d.bowler,COUNT(d.player_dismissed) AS Total_Wickets,
DENSE_RANK() OVER(PARTITION BY m.season ORDER BY COUNT(d.player_dismissed) DESC) AS RNK
FROM deliveries_upto_2025 d
JOIN matches_upto_2025 m ON d.matchid = m.matchid
WHERE d.player_dismissed IS NOT NULL
GROUP BY m.season,d.bowler)t
WHERE RNK = 1;

-- STRIKE_RATE OF ALL BATSMAN IN IPL.
SELECT batsman,ROUND((Runs*100/Ball),2) AS Strike_Rate FROM
(SELECT batsman,SUM(batsman_runs) AS Runs,
COUNT(ball) AS Ball
FROM deliveries_upto_2025
GROUP BY batsman)t
ORDER BY Strike_Rate DESC;

-- BATTING AVERAGE OF ALL BATSMAN IN THE IPL CARRER
SELECT batsman,ROUND(runs*1.0/NULLIF (out_count,0),1) AS Batting_Average FROM 
(SELECT batsman,
SUM(batsman_runs) AS runs,
COUNT(player_dismissed) AS out_count
FROM deliveries_upto_2025
GROUP BY batsman)t
ORDER BY Batting_Average DESC;


-- HIGHEST BATTING STRIKE_RATE PLAYER EACH SEASON MINIMUN 100 BALL FACED
WITH CTE1 AS (SELECT m.season,d.batsman,SUM(d.batsman_runs) AS Runs,
COUNT(d.ball) AS Ball 
FROM deliveries_upto_2025 d
JOIN matches_upto_2025 m ON d.matchid = m.matchId
GROUP BY m.season,d.batsman
HAVING COUNT(d.ball) >=100)

SELECT season,batsman,Strike_Rate FROM (SELECT season,batsman,(Runs*100/Ball) AS Strike_Rate,
DENSE_RANK() OVER(PARTITION BY SEASON ORDER BY ROUND((Runs*100.0/Ball),2) DESC) rnk
FROM CTE1)t
WHERE rnk = 1;

-- BOWLING_ECONOMY OF ALL BOWLERS IN THE IPL
WITH Bowler_stats AS 
(SELECT bowler,
COUNT(ball) AS ball_bolwed,
SUM(batsman_runs) AS runs_conceed,
SUM(iswide) AS Total_Wid,
SUM(isnoball) AS Total_Noball
FROM deliveries_upto_2025
GROUP BY bowler)
SELECT bowler,ROUND(Total_Runs_con*6.0/ball_bolwed,2) AS Bowling_Economy FROM
(SELECT bowler,ball_bolwed,SUM(runs_conceed + ISNULL(Total_Wid,0) + ISNULL(Total_Noball,0)) AS Total_Runs_con
FROM Bowler_stats
GROUP BY bowler,ball_bolwed)t
ORDER BY Bowling_Economy;


-- BEST BOWLING FIGURE OF IPL TILL 2025
WITH bowling_stats AS (SELECT matchid,bowler,COUNT(player_dismissed) As Wickets,
SUM(batsman_runs) AS Run_with_bat,
SUM(extras) AS extras
FROM deliveries_upto_2025
GROUP BY matchid,bowler
HAVING COUNT(player_dismissed) >= 5)

SELECT bowler,wickets,(Run_with_bat + extras) AS Run_con 
FROM bowling_stats
ORDER BY wickets DESC;

-- NUMBER OF MATCHES PLAYED ON THE EACH GROUND TILL 2025
SELECT venue,COUNT(venue) AS Number_of_matches 
FROM matches_upto_2025
GROUP BY venue
ORDER BY Number_of_matches DESC;

-- NUMBER OF FINAL PLAYED ON THE EACH GROUND
WITH Final_Date AS (SELECT season,MAX(DATE) AS final_date
FROM matches_upto_2025
GROUP BY season)

SELECT m.venue,COUNT(*) AS Number_of_Final FROM matches_upto_2025 m
JOIN final_date f ON m.season = f.season AND m.date = f.final_date
GROUP BY m.venue
ORDER BY Number_of_Final DESC;

