SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[LiveChat_ChatwiseData_Load] (@BeginDate AS DATETIME, @EndDate AS DATETIME) AS      
BEGIN      
  SELECT     
  Chats.chat_id, chat_owner, chat_owner_email, chat_client, chat_client_email, chat_start_time, chat_end_time,    
  chat_start_url, first_response_time, --message_first_response_time,    
  SUM(character_count_owner) character_count_owner, SUM(character_count_client) character_count_client, chat_rating,    
  avg_response_time, (SELECT chat_duration FROM BeaconFunding.dbo.Beacon_LiveChat_Chats chatsInner WHERE chatsInner.chat_id = chats.chat_id) chat_duration ,
  chats.chat_date 
 INTO #Chatwise_Status    
 FROM      
   (SELECT     
    DISTINCT Chats.chat_id, CONVERT(DATETIME,CONVERT(DATE,Chats.chat_start_datetime)) chat_date, Chats.agent_name chat_owner, Chats.agent_email chat_owner_email,    
    Chats.visitor_name chat_client, Chats.visitor_email chat_client_email, Chats.chat_start_datetime chat_start_time, Chats.chat_end_datetime chat_end_time,    
    Chats.chat_start_url, Chats.first_response_time,    
    CASE WHEN ChatContents.user_type = 'agent' THEN SUM(ChatContents.char_count) ELSE 0 END character_count_owner,    
    CASE WHEN ChatContents.user_type = 'visitor' THEN SUM(ChatContents.char_count) ELSE 0 END character_count_client,    
    CASE WHEN Chats.chat_rating = 'rated_good' THEN 'Good' ELSE 'Bad' END chat_rating        
   FROM BeaconFunding.dbo.Beacon_LiveChat_Chats Chats INNER JOIN BeaconFunding.dbo.Beacon_LiveChat_Chats_Content ChatContents ON ChatContents.chat_id = Chats.chat_id    
   WHERE CONVERT(DATE,chats.chat_start_datetime) BETWEEN @BeginDate AND @EndDate    
   GROUP BY Chats.chat_id, Chats.agent_name, Chats.visitor_name, Chats.chat_start_datetime, Chats.chat_end_datetime,    
    Chats.chat_start_url, Chats.first_response_time, ChatContents.user_type, Chats.chat_rating, Chats.visitor_email, Chats.agent_email) AS chats    
   INNER JOIN    
   (SELECT    
    chat_id, AVG(response_time) avg_response_time    
   FROM BeaconFunding.dbo.Beacon_LiveChat_Chats_Content    
   WHERE CONVERT(DATE,msg_datetime) BETWEEN @BeginDate AND @EndDate    
   GROUP BY chat_id) AS ResponseTime    
   ON ResponseTime.chat_id = chats.chat_id    
 GROUP BY Chats.chat_id, chat_owner, chat_client, chat_start_time, chat_end_time, chat_start_url, first_response_time, chat_rating, ResponseTime.avg_response_time,    
  chat_owner_email, chat_client_email, chats.chat_date
      
--SELECT * FROM #Chatwise_Status    
    
    
SELECT     
  AgentChats.chat_owner, AgentChats.chat_date, AgentChats.chat_owner_email, AgentChats.no_of_chats, ChatStatus.chat_duration / AgentChats.no_of_chats avg_chat_duration , ChatStatus.avg_first_response_time, ChatStatus.avg_response_time,    
  AgentChats.character_count_owner, AgentChats.character_count_client, AgentChats.character_count_owner + AgentChats.character_count_client character_count_total, CONVERT(FLOAT, 0) avg_chat_rating,    
  0 leadFlag    
 INTO #AgentWiseChatData    
FROM     
 (SELECT     
   chat_owner ,chat_date, chat_owner_email, ISNULL(SUM(no_of_chats),0) no_of_chats, SUM(character_count_owner) character_count_owner,     
   SUM(character_count_client) character_count_client,    
   SUM(rating_good) rating_good, SUM(rating_bad) rating_bad    
       
  --INTO #AgentWiseChatData    
  FROM    
   (SELECT    
    chat_owner, chat_date, chat_owner_email, ISNULL(COUNT(chat_id),0) no_of_chats, SUM(character_count_owner) character_count_owner, 
    SUM(character_count_client) character_count_client,    
    CASE WHEN chat_rating ='Good' THEN COUNT(chat_id) ELSE 0 END rating_good,    
    CASE WHEN chat_rating ='Bad' THEN COUNT(chat_id) ELSE 0 END rating_bad       
   FROM #Chatwise_Status --WHERE chat_rating = 'GOOD'    
   GROUP BY chat_owner, chat_owner_email, chat_rating, chat_date) AS AgentWiseChat      
  GROUP BY chat_owner, chat_owner_email, chat_date) AS AgentChats    
 INNER JOIN     
  (SELECT     
   chat_owner_email,SUM(chat_duration) chat_duration, ROUND(AVG(first_response_time),2) avg_first_response_time, ROUND(AVG(avg_response_time),2) avg_response_time      
   FROM     
   #Chatwise_Status    
   GROUP BY chat_owner_email    
   ) AS ChatStatus ON ChatStatus.chat_owner_email = AgentChats.chat_owner_email    
WHERE AgentChats.no_of_chats >0
 
SELECT     
  chat_owner, chat_date, chat_owner_email, no_of_chats,     
  RIGHT('00'+CONVERT(VARCHAR(2), avg_chat_duration / 3600),2) + ':' + RIGHT('00'+CONVERT(VARCHAR(2),((avg_chat_duration - (avg_chat_duration * (avg_chat_duration/3600))) / 60)),2) + ':' +     
  RIGHT('00'+CONVERT(VARCHAR(2), (avg_chat_duration % 60)),2) avg_chat_duration_time, avg_chat_duration, avg_first_response_time, avg_response_time, character_count_owner, character_count_client,     
  --character_count_total,     
  avg_chat_rating,     
  (SELECT ISNULL(COUNT(leadFlag),0) FROM #AgentWiseChatData agentDatainner WHERE agentDatainner.chat_owner_email = #AgentWiseChatData.chat_owner_email AND agentDatainner.leadFlag = 1) no_of_chat_leads    
FROM #AgentWiseChatData    
--SELECT * FROM #Chatwise_Status    
DROP TABLE #Chatwise_Status    
DROP TABLE #AgentWiseChatData    
END   
GO
