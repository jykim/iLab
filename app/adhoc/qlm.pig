-- Query Phrase Popularity (Hadoop cluster)

-- This script processes a search query log file from the Excite search engine and finds search phrases that occur with particular high frequency during certain times of the day. 

-- Register the tutorial JAR file so that the included UDFs can be called in the script.
REGISTER ./tutorial.jar;

-- Use the  PigStorage function to load the excite log file into the ìrawî bag as an array of records.
-- Input: (user,time,query) 
qs = LOAD '/queries.txt.bz2' USING PigStorage('\t') AS (time,query,qid,sid,count);
cs = LOAD '/clicks.txt.bz2' USING PigStorage('\t') AS (qid,query,time,url,pos);

-- 
--qcs = COGROUP qs BY qid, cs BY qid;
qcs = JOIN qs BY qid, cs BY qid;
 

-- Use the  PigStorage function to store the results. 
STORE qcs INTO '/query_click' USING PigStorage();
