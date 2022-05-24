/* ------------------ Drops --------------- */
DROP TABLE USERS;
DROP SEQUENCE usrID;

DROP TABLE GROUP_INF;
DROP SEQUENCE grID;

DROP TABLE GROUP_MEMBERS;

DROP TABLE MESSAGES;
DROP SEQUENCE messID;

DROP TABLE FRIENDS;

DROP TABLE POSTS;
DROP SEQUENCE postIDseq;

DROP TABLE COMMENTS;
DROP SEQUENCE commIDseq;

DROP TABLE COMMENTS;
DROP SEQUENCE commIDseq;

DROP TABLE REACTIONS_POSTS;
DROP TABLE REACTIONS_COMMENTS;
DROP TABLE REACTIONS_MESSAGES;

DROP TABLE AD_GROUP;
DROP SEQUENCE adgroupIDseq;

DROP TABLE AD_GROUP_KEYWORDS;

DROP TABLE USER_ADS;

DROP TABLE AD_PROVIDERS;
DROP SEQUENCE CompanyIDseq;

/* ----------------------------- Code ------------------------------------- */

CREATE TABLE USERS(
UserID INT,
Username VARCHAR2(30 CHAR) NOT NULL,
Email VARCHAR2(50 CHAR) NOT NULL,
Password VARCHAR2(20 CHAR) NOT NULL,
CONSTRAINT users_pk PRIMARY KEY(UserID),
CONSTRAINT email_k UNIQUE(Email),
CONSTRAINT username_k UNIQUE(Username)
);

CREATE SEQUENCE usrID START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCYCLE;

CREATE OR REPLACE TRIGGER getIDuser 
BEFORE INSERT ON USERS FOR EACH ROW ENABLE
WHEN(new.UserID is NULL)
BEGIN
    SELECT usrID.nextval INTO :new.UserID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER UserUpdate 
BEFORE UPDATE ON USERS FOR EACH ROW ENABLE
WHEN (new.UserID != old.UserID)
BEGIN
    raise_application_error(-20010, 'Column UserID in table USERS cannot be updaten');
END;
/


CREATE TABLE GROUP_INF(
GroupID INT,
GroupName VARCHAR2(50 CHAR) DEFAULT NULL, /*If null than name is nickname of other person*/
CreationDate DATE NOT NULL,
Admin INT DEFAULT NULL, /*null = noone = everyone in group have admin privilages*/
CONSTRAINT GroupInf_pk PRIMARY KEY (GroupID),
CONSTRAINT admin_fk FOREIGN KEY (Admin) REFERENCES USERS(UserID) ON DELETE SET NULL
);

CREATE SEQUENCE grID START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCYCLE;

CREATE OR REPLACE TRIGGER getIDgroup_inf 
BEFORE INSERT ON GROUP_INF FOR EACH ROW ENABLE
WHEN (new.GroupID is NULL)
BEGIN
    SELECT grID.nextval INTO :new.GroupID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER getCreationDateGroup_inf 
BEFORE INSERT ON GROUP_INF FOR EACH ROW ENABLE
WHEN (new.CreationDate is NULL)
BEGIN
    SELECT sysdate INTO :new.CreationDate FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER Group_infUpdateID
BEFORE UPDATE ON GROUP_INF FOR EACH ROW ENABLE
WHEN (new.GroupID != old.GroupID)
BEGIN
    raise_application_error(-20010, 'Column GroupID in table GROUP_INF cannot be updaten');
END;
/


CREATE OR REPLACE TRIGGER Group_infUpdateDATE
BEFORE UPDATE ON GROUP_INF FOR EACH ROW ENABLE
WHEN (new.CreationDate != old.CreationDate)
BEGIN
    raise_application_error(-20001, 'Column CREATIOINDATE in table GROUP_INF cannot be updaten');
END;
/


CREATE TABLE GROUP_MEMBERS(
GroupID INT NOT NULL,
MemberID INT NOT NULL,
Nickname VARCHAR2(30) DEFAULT NULL, /*If null than username*/
CONSTRAINT Group_pk PRIMARY KEY (GroupID, MemberID),
CONSTRAINT group_fk FOREIGN KEY (GroupID) REFERENCES GROUP_INF(GroupID) ON DELETE CASCADE, /* If group is del than all of messages are deleted too*/
CONSTRAINT member_fk FOREIGN KEY (MemberID) REFERENCES USERS(UserID) ON DELETE CASCADE /* If account is deleted than we should also delete all messages*/
);

CREATE OR REPLACE TRIGGER Group_Members_Update
BEFORE UPDATE OF GroupID, MemberID ON GROUP_MEMBERS ENABLE
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint on table GROUP_MEMBERS is violated');
END;
/


CREATE TABLE MESSAGES(
MessageID INT,
FromUserID INT NOT NULL,
ToGroupID INT NOT NULL,
Text VARCHAR2(512 CHAR) NOT NULL,
SendTime DATE NOT NULL,
ReplyToMessageID INT DEFAULT NULL,
/*Image BFILE DEFAULT NULL,*/
CONSTRAINT Message_pk PRIMARY KEY(MessageID),
CONSTRAINT From_fk FOREIGN KEY(FromUserID) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT To_fk FOREIGN KEY(ToGroupID) REFERENCES GROUP_INF(GroupID) ON DELETE CASCADE,
CONSTRAINT Reply_fk FOREIGN KEY(ReplyToMessageID) REFERENCES MESSAGES(MessageID) ON DELETE SET NULL,
CONSTRAINT reply_to_different_message CHECK (ReplyToMessageID != MessageID)
);

CREATE OR REPLACE TRIGGER MESSAGES_Update
BEFORE UPDATE OF MessageID, FromUserID, ToGroupID, Text, SendTime ON MESSAGES ENABLE
BEGIN
    raise_application_error(-20002, 'Any Column in table MESSAGES cannot be updaten');
END;
/

CREATE OR REPLACE TRIGGER Message_del_reply
BEFORE UPDATE ON MESSAGES FOR EACH ROW ENABLE
WHEN (not(new.ReplyToMessageID is NULL))
BEGIN
    raise_application_error(-20003, 'ReplyToMessageID can only be updaten to NULL value');
END;
/

CREATE SEQUENCE messID START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCYCLE;

CREATE OR REPLACE TRIGGER getIDgmess
BEFORE INSERT ON MESSAGES FOR EACH ROW ENABLE
WHEN (new.MessageID is NULL)
BEGIN
    SELECT messID.nextval INTO :new.MessageID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER getSendTimeMessage
BEFORE INSERT ON MESSAGES FOR EACH ROW ENABLE
WHEN (new.SendTime is NULL)
BEGIN
    SELECT sysdate INTO :new.SendTime FROM DUAL;
END;
/


CREATE TABLE FRIENDS(
USERID1 INT,
USERID2 INT,
SENDID INT NOT NULL,
SINCE DATE, /*Nullable if someone sends friend request than table is created, if user accepts request than date != Null*/
CONSTRAINT Friends_pk PRIMARY KEY(USERID1, USERID2),
CONSTRAINT Different_users CHECK (USERID1 != USERID2),
CONSTRAINT User1_fk FOREIGN KEY(USERID1) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT User2_fk FOREIGN KEY(USERID2) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT send_fk FOREIGN KEY(SENDID) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT check_send_ID CHECK (SENDID = USERID1 or SENDID = USERID2)
);


CREATE OR REPLACE TRIGGER Friends_Update
BEFORE UPDATE OF UserID1, UserID2, SendID ON FRIENDS ENABLE
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint on table FRIENDS is violated');
END;
/


CREATE OR REPLACE TRIGGER friends_one_pair 
BEFORE INSERT ON FRIENDS FOR EACH ROW ENABLE
WHEN (new.USERID1 < new.USERID2)
DECLARE
TEMP INT;
BEGIN
    TEMP := :new.USERID1;
    SELECT :new.USERID2 INTO :new.USERID1 FROM DUAL;
    SELECT TEMP INTO :new.USERID2 FROM DUAL;
END;
/


CREATE TABLE POSTS(
PostID INT,
UserID INT NOT NULL,
Text VARCHAR2(512 CHAR) NOT NULL,
PostTime DATE NOT NULL,
/*Photo BFILE DEFAULT NULL,*/
CONSTRAINT post_pk PRIMARY KEY(PostID),
CONSTRAINT user_fk FOREIGN KEY(UserID) REFERENCES USERS(UserID) ON DELETE CASCADE
);

CREATE OR REPLACE TRIGGER POSTS_Update
BEFORE UPDATE ON POSTS FOR EACH ROW ENABLE
BEGIN
    raise_application_error(-20002, 'Any Column in table POSTS cannot be updaten');
END;
/

CREATE SEQUENCE postIDseq START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCYCLE;

CREATE OR REPLACE TRIGGER getIDpost 
BEFORE INSERT ON POSTS FOR EACH ROW ENABLE
WHEN (new.PostID is NULL)
BEGIN
    SELECT postIDseq.nextval INTO :new.PostID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER getPostTime
BEFORE INSERT ON POSTS FOR EACH ROW ENABLE
WHEN (new.PostTime is NULL)
BEGIN
    SELECT sysdate INTO :new.PostTime FROM DUAL;
END;
/


CREATE TABLE COMMENTS(
CommentID INT,
UserID INT NOT NULL,
ToPostID INT NOT NULL,
Text VARCHAR2(512 CHAR) NOT NULL,
CommentTime DATE NOT NULL,
ReplyToCommentID INT DEFAULT NULL,
CONSTRAINT comments_pk PRIMARY KEY(CommentID),
CONSTRAINT posts_fk FOREIGN KEY(ToPostID) REFERENCES POSTS(PostID) ON DELETE CASCADE,
CONSTRAINT c_user_fk FOREIGN KEY(UserID) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT comment_fk FOREIGN KEY(ReplyToCommentID) REFERENCES COMMENTS(CommentID) ON DELETE SET NULL
);

CREATE OR REPLACE TRIGGER COMMENTS_Update
BEFORE UPDATE OF CommentID, UserID, ToPostID, Text, CommentTime ON COMMENTS ENABLE
BEGIN
    raise_application_error(-20002, 'Any Column in table COMMENTS cannot be updaten');
END;
/

CREATE OR REPLACE TRIGGER Comments_del_reply
BEFORE UPDATE ON Comments FOR EACH ROW ENABLE
WHEN (not(new.ReplyToCommentID is NULL))
BEGIN
    raise_application_error(-20003, 'ReplyToCommentID can only be updaten to NULL value');
END;
/

CREATE SEQUENCE commIDseq START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCYCLE;

CREATE OR REPLACE TRIGGER getIDcomment
BEFORE INSERT ON COMMENTS FOR EACH ROW ENABLE
WHEN(new.CommentID is NULL)
BEGIN
    SELECT commIDseq.nextval INTO :new.CommentID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER getCommentTime
BEFORE INSERT ON COMMENTS FOR EACH ROW ENABLE
WHEN (new.CommentTime is NULL)
BEGIN
    SELECT sysdate INTO :new.CommentTime FROM DUAL;
END;
/


CREATE TABLE REACTIONS_POSTS(
UserID INT,
PostID INT,
TypeOfReaction INT NOT NULL,
CONSTRAINT reactions_posts_pk PRIMARY KEY(UserID, PostID),
CONSTRAINT reactions_posts_user_fk FOREIGN KEY(UserID) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT reactions_posts_post_fk FOREIGN KEY(PostID) REFERENCES POSTS(PostID) ON DELETE CASCADE
);

CREATE OR REPLACE TRIGGER Reactions_Post_Update
BEFORE UPDATE OF UserID, PostID ON REACTIONS_POSTS ENABLE
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint on table REACTIONS_POSTS is violated');
END;
/

CREATE TABLE REACTIONS_COMMENTS(
UserID INT,
CommentID INT,
TypeOfReaction INT NOT NULL,
CONSTRAINT reactions_comments_pk PRIMARY KEY(UserID, CommentID),
CONSTRAINT reactions_comments_user_fk FOREIGN KEY(UserID) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT reactions_comments_comment_fk FOREIGN KEY(CommentID) REFERENCES COMMENTS(CommentID) ON DELETE CASCADE
);

CREATE OR REPLACE TRIGGER Reactions_Comments_Update
BEFORE UPDATE OF UserID, CommentID ON REACTIONS_COMMENTS ENABLE
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint on table REACTIONS_COMMENTS is violated');
END;
/

CREATE TABLE REACTIONS_MESSAGES(
UserID INT,
MessageID INT,
TypeOfReaction INT NOT NULL,
CONSTRAINT reactions_messages_pk PRIMARY KEY(UserID, MessageID),
CONSTRAINT reactions_messages_user_fk FOREIGN KEY(UserID) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT reactions_messages_message_fk FOREIGN KEY(MessageID) REFERENCES MESSAGES(MessageID) ON DELETE CASCADE
);

CREATE OR REPLACE TRIGGER Reactions_Messages_Update
BEFORE UPDATE OF UserID, MessageID ON REACTIONS_MESSAGES ENABLE
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint on table REACTIONS is violated');
END;
/


CREATE TABLE AD_PROVIDERS(
CompanyID INT,
CompanyName VARCHAR2(30 CHAR),
CONSTRAINT AD_providers_pk PRIMARY KEY(CompanyID)
);

CREATE OR REPLACE TRIGGER AD_PROVIDERS_Update 
BEFORE UPDATE OF CompanyID ON AD_PROVIDERS ENABLE
BEGIN
    raise_application_error(-20010, 'Column CompanyID in table AD_PROVIDERS cannot be updaten');
END;
/

CREATE SEQUENCE CompanyIDseq START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCYCLE;

CREATE OR REPLACE TRIGGER getIDadproviders
BEFORE INSERT ON AD_PROVIDERS FOR EACH ROW ENABLE
WHEN (new.CompanyID is NULL)
BEGIN
    SELECT CompanyIDseq.nextval INTO :new.CompanyID FROM DUAL;
END;
/

CREATE TABLE AD_GROUP(
AdGroupID INT,
NameOfGroup VARCHAR2(30 CHAR) NOT NULL,
AdURL VARCHAR2(200 CHAR) NOT NULL,
CompanyID INT NOT NULL,
InteractionPrice NUMBER(10,9) NOT NULL,
SeenPrice NUMBER(10,9) NOT NULL,
SeenAdCount INT,
CONSTRAINT Ad_group_pk PRIMARY KEY(AdGroupID),
CONSTRAINT Ad_Group_CompanyID_fk FOREIGN KEY(CompanyID) REFERENCES AD_PROVIDERS(CompanyID) ON DELETE CASCADE
);


CREATE OR REPLACE TRIGGER AD_GROUP_UPDATE_ID
BEFORE UPDATE OF AdGroupID ON AD_GROUP ENABLE
BEGIN
    raise_application_error(-20010, 'Column AdGroupID in table AD_GROUP cannot be updaten');
END;
/

CREATE OR REPLACE TRIGGER AD_GROUP_UPDATE_COMPANYID
BEFORE UPDATE OF CompanyID ON AD_GROUP ENABLE
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint on table AD_GROUP is violated');
END;
/

CREATE SEQUENCE adgroupIDseq START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCYCLE;

CREATE OR REPLACE TRIGGER getIDadgroup
BEFORE INSERT ON AD_GROUP FOR EACH ROW ENABLE
WHEN (new.AdGroupID is NULL)
BEGIN
    SELECT adgroupIDseq.nextval INTO :new.AdGroupID FROM DUAL;
END;
/

CREATE TABLE AD_GROUP_KEYWORDS(
AdGroupID INT NOT NULL,
Adkeyword VARCHAR2(20 CHAR) NOT NULL,
CONSTRAINT ad_group_keywords_pk PRIMARY KEY(AdGroupID, Adkeyword),
CONSTRAINT ad_group_keyword_ad_fk FOREIGN KEY(AdGroupID) REFERENCES AD_GROUP(AdGroupID) ON DELETE CASCADE
);

CREATE OR REPLACE TRIGGER AD_GROUP_KEYWORDS_UPDATE
BEFORE UPDATE OF AdGroupID, Adkeyword ON AD_GROUP_KEYWORDS ENABLE
BEGIN
    raise_application_error(-20010, 'Any column in table AD_GROUP_KEYWORDS cannot be updaten');
END;
/

CREATE TABLE USER_ADS(
UserID INT,
AdGroupID INT,
Interactions INT DEFAULT 0,
CONSTRAINT user_ad_pk PRIMARY KEY(UserID, AdGroupID),
CONSTRAINT user_ad_user_fk FOREIGN KEY(UserID) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT user_ad_ad_fk FOREIGN KEY(AdGroupID) REFERENCES AD_GROUP(AdGroupID) ON DELETE CASCADE,
CONSTRAINT interactions_ads_user_min_value_0 check (Interactions >= 0)
);


CREATE OR REPLACE TRIGGER USER_ADS_Update
BEFORE UPDATE OF UserID, AdGroupID ON USER_ADS ENABLE
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint on table USER_ADS is violated');
END;
/


CREATE OR REPLACE FUNCTION usr_ID(get_username IN VARCHAR2)
    RETURN NUMBER IS resID INT;
    BEGIN
        SELECT UserID INTO resID FROM USERS WHERE username = get_username;
        RETURN resID;
    END;
/

/*SELECT usr_ID('Radoslaw') FROM DUAL;*/

/* ------------------------------ INSERT -------------------------------------- */
DELETE FROM USERS;
DELETE FROM FRIENDS;
DELETE FROM GROUP_INF;
DELETE FROM GROUP_MEMBERS;
DELETE FROM MESSAGES;

INSERT INTO USERS (Username, Email, password) VALUES ('Radoslaw', 'radoslaw@mail.com', '1234');
INSERT INTO USERS (Username, Email, password) VALUES ('Marcin', 'marcin@gmail.com', '2222');
INSERT INTO USERS (Username, Email, password) VALUES ('Mmmichal', 'Mmm@onet.pl', 'Totoototo');
INSERT INTO USERS (Username, Email, password) VALUES ('Adam01', 'Adam123@wp.pl', 'qwerty');
INSERT INTO USERS (Username, Email, password) VALUES ('Krzysztof', 'CrisJudge@gmail.com', 'imthebest');
INSERT INTO USERS (Username, Email, password) VALUES ('Danutka12', 'Danusia@mymail.com', 'youandme');
INSERT INTO USERS (Username, Email, password) VALUES ('Julia', 'Julia@mail.com', '4321');
INSERT INTO USERS (Username, Email, password) VALUES ('Zdzislaw', 'zdzislaw@wp.pl', '2222;');


INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Radoslaw'), usr_ID('Mmmichal'), usr_ID('Radoslaw'), TO_DATE('21/12/2021', 'DD/MM/YYYY'));
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Krzysztof'), usr_ID('Adam01'), usr_ID('Krzysztof'), Null);
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Julia'), usr_ID('Radoslaw'), usr_ID('Julia'), TO_DATE('01/12/2019', 'DD/MM/YYYY'));
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Danutka12'), usr_ID('Zdzislaw'), usr_ID('Danutka12'), Null);
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Mmmichal'), usr_ID('Adam01'), usr_ID('Mmmichal'), TO_DATE('02/11/2020', 'DD/MM/YYYY'));
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Mmmichal'), usr_ID('Marcin'), usr_ID('Mmmichal'), TO_DATE('13/07/2019', 'DD/MM/YYYY'));
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Marcin'), usr_ID('Julia'), usr_ID('Marcin'), TO_DATE('19/10/2021', 'DD/MM/YYYY'));
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Marcin'), usr_ID('Adam01'), usr_ID('Marcin'), Null);
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Marcin'), usr_ID('Danutka12'), usr_ID('Marcin'), TO_DATE('13/06/2020', 'DD/MM/YYYY'));
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Marcin'), usr_ID('Zdzislaw'), usr_ID('Marcin'), Null);
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Krzysztof'), usr_ID('Zdzislaw'), usr_ID('Zdzislaw'), TO_DATE('10/04/2020', 'DD/MM/YYYY'));
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Krzysztof'), usr_ID('Radoslaw'), usr_ID('Krzysztof'), TO_DATE('17/08/2010', 'DD/MM/YYYY'));
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Adam01'), usr_ID('Julia'), usr_ID('Adam01'), TO_DATE('02/02/2015', 'DD/MM/YYYY'));
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Adam01'), usr_ID('Danutka12'), usr_ID('Adam01'), TO_DATE('15/09/2020', 'DD/MM/YYYY'));
INSERT INTO FRIENDS (UserID1, UserID2, SendID, SINCE) VALUES(usr_ID('Adam01'), usr_ID('Zdzislaw'), usr_ID('Zdzislaw'), Null);


INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('21/12/2021', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (1, usr_ID('Radoslaw'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (1, usr_ID('Mmmichal'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('01/12/2019', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (2, usr_ID('Radoslaw'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (2, usr_ID('Julia'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('02/11/2020', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (3, usr_ID('Mmmichal'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (3, usr_ID('Adam01'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('19/10/2021', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (4, usr_ID('Marcin'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (4, usr_ID('Danutka12'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('13/06/2020', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (5, usr_ID('Marcin'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (5, usr_ID('Julia'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('10/04/2020', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (6, usr_ID('Krzysztof'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (6, usr_ID('Zdzislaw'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('17/08/2010', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (7, usr_ID('Krzysztof'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (7, usr_ID('Radoslaw'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('02/02/2015', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (8, usr_ID('Adam01'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (8, usr_ID('Julia'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('15/09/2020', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (9, usr_ID('Adam01'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (9, usr_ID('Danutka12'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('12/01/2022', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (10, usr_ID('Radoslaw'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (10, usr_ID('Marcin'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (10, usr_ID('Mmmichal'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (10, usr_ID('Adam01'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (10, usr_ID('Krzysztof'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (10, usr_ID('Danutka12'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (10, usr_ID('Julia'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('13/01/2022', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (11, usr_ID('Radoslaw'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (11, usr_ID('Julia'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (11, usr_ID('Mmmichal'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('14/01/2022', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (12, usr_ID('Radoslaw'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (12, usr_ID('Marcin'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (12, usr_ID('Mmmichal'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('15/01/2022', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (13, usr_ID('Marcin'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (13, usr_ID('Krzysztof'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (13, usr_ID('Zdzislaw'));
INSERT INTO GROUP_INF (creationdate) VALUES (TO_DATE('13/07/2015', 'DD/MM/YYYY'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (14, usr_ID('Marcin'));
INSERT INTO GROUP_MEMBERS (groupid, memberid) VALUES (14, usr_ID('Mmmichal'));


INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, MessageID) VALUES (usr_ID('Radoslaw'), 2, 'Hej :)', 1000); /*Message from user Radoslaw to user Julia*/
INSERT INTO MESSAGES (FromUserID, ToGroupID, ReplyToMessageID, TEXT, MessageID) VALUES (usr_ID('Julia'), 2, 1000, 'Hejka!', 1001); /*Message from user Julia to user Radoslaw replaying to previous message*/

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, MessageID, SendTime) VALUES (usr_ID('Marcin'), 14, 'Nie widzia³am ciê ju¿ od miesi¹ca.', 2000, to_date('19-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 14, 'I nic. Jestem mo¿e bledsza,', to_date('19-sty-2022 15:10:02','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 14, 'trochê œpi¹ca; trochê bardziej milcz¹ca,', to_date('19-sty-2022 15:10:03','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 14, 'lecz widaæ mo¿na ¿yæ bez powietrza!', to_date('19-sty-2022 15:10:04','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, MessageID, SendTime) VALUES (usr_ID('Mmmichal'), 14, 'Ok.', 2001, to_date('19-sty-2022 15:10:05','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 14, 'To w szyby deszcz dzwoni deszcz dzwoni jesienny', to_date('19-sty-2022 15:10:06','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 14, 'I pluszcze jednaki miarowy niezmienny', to_date('19-sty-2022 15:10:07','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 14, 'D¿d¿u krople padaj¹ i t³uk¹ w me okno', to_date('19-sty-2022 15:10:08','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 14, 'Jêk szklany p³acz szklany a szyby w mgle mokn¹', to_date('19-sty-2022 15:10:09','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 14, 'I œwiat³a szarego blask s¹czy siê senny', to_date('19-sty-2022 15:10:11','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 14, 'O szyby deszcz dzwoni deszcz dzwoni jesienny', to_date('19-sty-2022 15:10:12','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 14, 'Niech sobie ludzie bêd¹, jeœli chc¹,', to_date('19-sty-2022 15:10:13','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 14, 'a potem po kolei ka¿de z nich umiera,', to_date('19-sty-2022 15:10:14','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 14, 'im, chmurom, nic do tego', to_date('19-sty-2022 15:10:15','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 14, 'wszystkiego', to_date('19-sty-2022 15:10:16','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 14, 'bardzo dziwnego.', to_date('19-sty-2022 15:10:17','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 1, 'This is normal human convrsation', to_date('19-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 1, 'Im human', to_date('19-sty-2022 15:10:02','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 1, 'Im human too', to_date('19-sty-2022 15:10:03','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 1, 'Now we can talk', to_date('19-sty-2022 15:10:04','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 1, 'As real people do', to_date('19-sty-2022 15:10:05','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 1, 'Hello', to_date('19-sty-2022 15:10:06','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 1, 'Hello', to_date('19-sty-2022 15:10:07','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 1, 'Now we can talk', to_date('19-sty-2022 15:10:08','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 1, 'This is normal human convrsation', to_date('19-sty-2022 15:10:09','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 1, 'Im human', to_date('19-sty-2022 15:10:31','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 2, 'Hey', to_date('19-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 2, 'Hejo', to_date('19-sty-2022 15:10:02','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 2, 'Great to hear from u', to_date('19-sty-2022 15:10:03','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 2, 'u too', to_date('19-sty-2022 15:12:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 2, 'How are u', to_date('19-sty-2022 15:14:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 2, 'Im good', to_date('19-sty-2022 15:15:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 2, 'Doing some science stuff', to_date('19-sty-2022 16:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 2, 'And u?', to_date('19-sty-2022 17:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 2, 'Same there', to_date('19-sty-2022 18:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 2, 'Just in binary', to_date('19-sty-2022 19:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 2, 'Yay', to_date('19-sty-2022 22:10:01','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Adam01'), 3, 'I would like to generate this', to_date('19-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Adam01'), 3, 'Like in loop', to_date('19-sty-2022 15:10:02','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Adam01'), 3, 'But apparently there is no way to do that', to_date('19-sty-2022 15:10:03','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Adam01'), 3, 'coz u have to write it to get it', to_date('19-sty-2022 15:10:04','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Adam01'), 3, 'U know what i mean', to_date('19-sty-2022 15:10:05','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Adam01'), 3, 'buddy?', to_date('19-sty-2022 15:10:06','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 3, 'Yea', to_date('19-sty-2022 15:10:07','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 3, 'Ive got u', to_date('19-sty-2022 15:10:08','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 3, 'Human buddy', to_date('19-sty-2022 15:10:09','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 3, 'Coz Im human', to_date('19-sty-2022 15:10:12','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 3, 'Are u human?', to_date('19-sty-2022 15:10:13','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Adam01'), 3, 'Yea', to_date('19-sty-2022 16:10:01','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 4, 'Hey', to_date('19-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 4, 'Wanna gout somewhere?', to_date('19-sty-2022 15:10:02','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 4, 'Maybe?', to_date('19-sty-2022 15:10:03','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Danutka12'), 4, 'Heyyy', to_date('19-sty-2022 15:10:04','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Danutka12'), 4, 'Im not intrested', to_date('19-sty-2022 15:10:05','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 4, 'Oh', to_date('19-sty-2022 15:10:06','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 4, 'What a shame', to_date('19-sty-2022 15:10:07','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 5, 'Hey', to_date('19-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 5, 'Heyyy', to_date('19-sty-2022 15:10:02','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 5, 'Im watching dont look up', to_date('19-sty-2022 15:10:03','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 5, 'Great movie', to_date('19-sty-2022 15:10:04','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 5, 'Its analogy to the pandemic', to_date('19-sty-2022 15:10:05','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 5, 'But insted of virus', to_date('19-sty-2022 15:10:06','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 5, 'There is this gigant comet facing towards earth',to_date('19-sty-2022 15:10:07','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 5, 'Sounds nice', to_date('19-sty-2022 15:10:08','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 5, 'But also quite overreacted', to_date('19-sty-2022 15:10:09','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 5, 'Like all right good try', to_date('19-sty-2022 15:10:10','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 5, 'But the commet hits in brief moment', to_date('19-sty-2022 15:10:11','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 5, 'And pandemic is a long term event', to_date('19-sty-2022 15:10:12','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 5, 'But okay', to_date('19-sty-2022 15:10:13','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 5, 'I guess they try', to_date('19-sty-2022 15:10:14','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 5, 'I think u re too harsh', to_date('19-sty-2022 15:10:15','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 5, 'Its hard to talk about traumatic experiences', to_date('19-sty-2022 15:10:16','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 5, 'Which the pandemic is for everyone', to_date('19-sty-2022 15:10:17','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 5, 'And society', to_date('19-sty-2022 15:10:18','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 5, 'So we n=need to take small bites', to_date('19-sty-2022 15:10:19','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, MessageID, SendTime) VALUES (usr_ID('Marcin'), 5, 'And not try to digest it whole at once', 3000, to_date('19-sty-2022 15:11:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, MessageID, SendTime) VALUES (usr_ID('Marcin'), 5, 'We need those tries to get over it', 3001, to_date('19-sty-2022 15:12:01','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Krzysztof'), 6, 'Door', to_date('19-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Zdzislaw'), 6, 'Rollercoaster', to_date('19-sty-2022 15:10:02','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Krzysztof'), 6, 'Raddish', to_date('19-sty-2022 15:10:03','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Zdzislaw'), 6, 'Hamster', to_date('19-sty-2022 15:10:04','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Krzysztof'), 6, 'Rollerblades', to_date('19-sty-2022 15:10:06','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Krzysztof'), 7, 'Mountain', to_date('19-sty-2022 12:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 7, 'Snow', to_date('19-sty-2022 13:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Krzysztof'), 7, 'Water', to_date('19-sty-2022 14:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 7, 'Health', to_date('19-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Adam01'), 8, 'Coffee',to_date('18-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 8, 'Tea', to_date('19-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Adam01'), 8, 'Wine', to_date('20-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 8, 'Water', to_date('21-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Adam01'), 9, 'This night will be the end', to_date('19-sty-2022 15:00:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Danutka12'), 9, 'End?', to_date('19-sty-2022 15:08:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Adam01'), 9, 'End of project', to_date('19-sty-2022 15:09:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Danutka12'), 9, 'Deadline :o', to_date('21-sty-2022 15:11:01','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 10, 'Hey', to_date('19-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 10, 'Hey', to_date('19-sty-2022 15:10:02','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 10, 'Hey', to_date('19-sty-2022 15:10:03','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 10, 'Hey', to_date('19-sty-2022 15:10:04','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 11, 'we are humans', to_date('19-sty-2022 15:11:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 11, 'we are real', to_date('19-sty-2022 15:12:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 11, 'we need to stay together', to_date('19-sty-2022 15:13:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 11, 'we shall survive', to_date('19-sty-2022 15:14:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Julia'), 11, 'we will be together', to_date('19-sty-2022 15:15:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 11, 'in group we thrive', to_date('19-sty-2022 15:16:01','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 12, 'Advertisments', to_date('19-sty-2022 15:11:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 12, 'Market', to_date('19-sty-2022 15:12:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 12, 'money', to_date('19-sty-2022 15:13:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Radoslaw'), 12, 'sport', to_date('19-sty-2022 15:14:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 12, 'ocean', to_date('19-sty-2022 15:15:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Mmmichal'), 12, 'space', to_date('19-sty-2022 15:16:01','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Krzysztof'), 13, 'Atomic', to_date('19-sty-2022 15:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Marcin'), 13, 'values', to_date('19-sty-2022 16:10:01','dd-mm-yyyy hh24:mi:ss'));
INSERT INTO MESSAGES (FromUserID, ToGroupID, TEXT, SendTime) VALUES (usr_ID('Zdzislaw'), 13, 'we belive', to_date('19-sty-2022 17:10:01','dd-mm-yyyy hh24:mi:ss'));

INSERT INTO POSTS (UserID, Text) VALUES (usr_ID('Radoslaw'), 'Hello World!');
INSERT INTO POSTS (PostID, UserID, Text) VALUES (500, usr_ID('Radoslaw'), 'Im here');
INSERT INTO POSTS (PostID, UserID, Text) VALUES (501, usr_ID('Radoslaw'), 'You shoul watch howls moving castle');
INSERT INTO POSTS (PostID, UserID, Text) VALUES (502, usr_ID('Radoslaw'), 'Studio Ghibly rocks');

INSERT INTO POSTS (UserID, Text) VALUES (usr_ID('Mmmichal'), 'I like trains');
INSERT INTO POSTS (UserID, Text) VALUES (usr_ID('Mmmichal'), 'I like bugs');
INSERT INTO POSTS (UserID, Text) VALUES (usr_ID('Mmmichal'), 'I like planes');

INSERT INTO POSTS (PostID, UserID, Text) VALUES (300, usr_ID('Julia'), 'I like blue colour');

INSERT INTO POSTS (PostID, UserID, Text) VALUES (200, usr_ID('Adam01'), 'I like raddish');

INSERT INTO COMMENTS (UserID, ToPostID, Text) VALUES (usr_ID('Julia'), 500,'Im here too');
INSERT INTO COMMENTS (UserID, ToPostID, Text, CommentID) VALUES (usr_ID('Zdzislaw'), 500, 'Hello there', 555);
INSERT INTO COMMENTS (UserID, ToPostID, Text, ReplyToCommentID) VALUES (usr_ID('Radoslaw'), 500, 'Oh hello', 555);
INSERT INTO COMMENTS (UserID, ToPostID, Text, ReplyToCommentID) VALUES (usr_ID('Zdzislaw'), 500, 'Nice to be here', 555);

INSERT INTO COMMENTS (UserID, ToPostID, Text) VALUES (usr_ID('Julia'), 501,'Oh thx');
INSERT INTO COMMENTS (UserID, ToPostID, Text) VALUES (usr_ID('Zdzislaw'), 501, 'I agree totally');
INSERT INTO COMMENTS (UserID, ToPostID, Text) VALUES (usr_ID('Radoslaw'), 501, 'Its awesome dont u think');
INSERT INTO COMMENTS (UserID, ToPostID, Text) VALUES (usr_ID('Zdzislaw'), 501, 'Yea sure');

INSERT INTO COMMENTS (UserID, ToPostID, Text) VALUES (usr_ID('Julia'), 300,'Thoughts?');
INSERT INTO COMMENTS (UserID, ToPostID, Text) VALUES (usr_ID('Zdzislaw'), 300, 'Its ok');
INSERT INTO COMMENTS (UserID, ToPostID, Text, CommentID) VALUES (usr_ID('Radoslaw'), 300, 'Its the best colour!', 333);
INSERT INTO COMMENTS (UserID, ToPostID, Text, ReplyToCommentID) VALUES (usr_ID('Zdzislaw'), 300, 'Nah', 333);

INSERT INTO COMMENTS (UserID, ToPostID, Text) VALUES (usr_ID('Julia'), 200,'Me too');
INSERT INTO COMMENTS (UserID, ToPostID, Text) VALUES (usr_ID('Zdzislaw'), 200, 'so terrific');
INSERT INTO COMMENTS (UserID, ToPostID, Text) VALUES (usr_ID('Zdzislaw'), 200, 'Nah Nah');

INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Julia'), 500, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Adam01'), 500, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Zdzislaw'), 500, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Danutka12'), 500, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Mmmichal'), 500, 3);

INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Julia'), 501, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Adam01'), 501, 2);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Zdzislaw'), 501, 2);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Danutka12'), 501, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Mmmichal'), 501, 1);

INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Julia'), 502, 2);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Adam01'), 502, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Zdzislaw'), 502, 2);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Danutka12'), 502, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Mmmichal'), 502, 4);

INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Julia'), 300, 2);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Adam01'), 300, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Zdzislaw'), 300, 2);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Danutka12'), 300, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Mmmichal'), 300, 4);

INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Radoslaw'), 200, 2);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Adam01'), 200, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Zdzislaw'), 200, 2);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Danutka12'), 200, 1);
INSERT INTO REACTIONS_POSTS (UserID, POSTID, TypeOfReaction) VALUES (usr_ID('Mmmichal'), 200, 4);

INSERT INTO REACTIONS_COMMENTS (UserID, CommentID, TypeOfReaction) VALUES (usr_ID('Radoslaw'), 555, 2);
INSERT INTO REACTIONS_COMMENTS (UserID, CommentID, TypeOfReaction) VALUES (usr_ID('Adam01'), 555, 3);
INSERT INTO REACTIONS_COMMENTS (UserID, CommentID, TypeOfReaction) VALUES (usr_ID('Zdzislaw'), 555, 2);
INSERT INTO REACTIONS_COMMENTS (UserID, CommentID, TypeOfReaction) VALUES (usr_ID('Danutka12'), 555, 1);
INSERT INTO REACTIONS_COMMENTS (UserID, CommentID, TypeOfReaction) VALUES (usr_ID('Mmmichal'), 555, 2);

INSERT INTO REACTIONS_COMMENTS (UserID, CommentID, TypeOfReaction) VALUES (usr_ID('Radoslaw'), 333, 1);
INSERT INTO REACTIONS_COMMENTS (UserID, CommentID, TypeOfReaction) VALUES (usr_ID('Adam01'), 333, 1);
INSERT INTO REACTIONS_COMMENTS (UserID, CommentID, TypeOfReaction) VALUES (usr_ID('Zdzislaw'), 333, 2);
INSERT INTO REACTIONS_COMMENTS (UserID, CommentID, TypeOfReaction) VALUES (usr_ID('Danutka12'), 333, 1);
INSERT INTO REACTIONS_COMMENTS (UserID, CommentID, TypeOfReaction) VALUES (usr_ID('Mmmichal'), 333, 1);

INSERT INTO REACTIONS_MESSAGES (UserID, MessageID, TypeOfReaction) VALUES (usr_ID('Julia'), 3000, 1);
INSERT INTO REACTIONS_MESSAGES (UserID, MessageID, TypeOfReaction) VALUES (usr_ID('Julia'), 3001, 1);
INSERT INTO REACTIONS_MESSAGES (UserID, MessageID, TypeOfReaction) VALUES (usr_ID('Marcin'), 3001, 1);

INSERT INTO REACTIONS_MESSAGES (UserID, MessageID, TypeOfReaction) VALUES (usr_ID('Julia'), 1000, 1);
INSERT INTO REACTIONS_MESSAGES (UserID, MessageID, TypeOfReaction) VALUES (usr_ID('Radoslaw'), 1001, 1);

INSERT INTO REACTIONS_MESSAGES (UserID, MessageID, TypeOfReaction) VALUES (usr_ID('Marcin'), 2000, 1);
INSERT INTO REACTIONS_MESSAGES (UserID, MessageID, TypeOfReaction) VALUES (usr_ID('Mmmichal'), 2000, 1);

INSERT INTO Ad_Providers (CompanyID, CompanyName) VALUES (10, 'SportCompany');
INSERT INTO Ad_Providers (CompanyID, CompanyName) VALUES (20, 'GoodBigCorporation');
INSERT INTO Ad_Providers (CompanyID, CompanyName) VALUES (30, 'SmallBadBisnes');

INSERT INTO AD_Group (AdGroupID, NameOfGroup, AdURL, CompanyID, InteractionPrice, SeenPrice, SeenAdCount) 
VALUES (1, 'Sportish', 'https://www.sport-shop.pl/rolki-slalomowe-sk509-xride-black-white-p-95627.html', 10, 0.000021, 0.000001, 1202);

INSERT INTO AD_Group (AdGroupID, NameOfGroup, AdURL, CompanyID, InteractionPrice, SeenPrice, SeenAdCount) 
VALUES (2, 'food', 'https://www.shutterstock.com/pl/image-photo/selection-healthy-food-540997561', 20, 0.0001, 0.00001, 302);

INSERT INTO AD_Group (AdGroupID, NameOfGroup, AdURL, CompanyID, InteractionPrice, SeenPrice, SeenAdCount) 
VALUES (3, 'IT', 'https://www.shutterstock.com/pl/image-vector/set-clipart-elements-retro-obsolete-things-1896505720', 20, 0.000011, 0.000001, 65);

INSERT INTO AD_Group (AdGroupID, NameOfGroup, AdURL, CompanyID, InteractionPrice, SeenPrice, SeenAdCount) 
VALUES (4, 'WellBeing', 'https://www.shutterstock.com/pl/image-vector/meadow-wildflower-honeybee-vector-seamless-pattern-1934977544', 20, 0.000031, 0.000011, 4522);

INSERT INTO AD_Group (AdGroupID, NameOfGroup, AdURL, CompanyID, InteractionPrice, SeenPrice, SeenAdCount) 
VALUES (5, 'BadBeing', 'https://www.shutterstock.com/pl/image-photo/rock-pigeon-street-looking-food-pigeons-1684487635', 30, 0.000001, 0.0000001, 554);

INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (1, 'Sport');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (1, 'Fit');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (1, 'Life');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (1, 'Healthy');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (1, 'Snow');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (1, 'Water');

INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (2, 'Human');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (2, 'Raddish');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (2, 'hamster');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (2, 'hungry');

INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (3, 'space');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (3, 'end');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (3, 'human');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (3, 'binary');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (3, 'computer');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (3, 'hello');

INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (4, 'hey');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (4, 'how');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (4, 'feeling');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (4, 'happy');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (4, 'well');

INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (5, 'good morning');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (5, 'bad');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (5, 'pandemic');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (5, 'analogy');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (5, 'seems');
INSERT INTO AD_GROUP_KEYWORDS (ADGROUPID, AdKeyword) VALUES (5, 'right');

INSERT INTO User_Ads (UserID, AdGroupID, Interactions) VALUES (usr_ID('Radoslaw'), 3, 20);
INSERT INTO User_Ads (UserID, AdGroupID, Interactions) VALUES (usr_ID('Radoslaw'), 1, 2);
INSERT INTO User_Ads (UserID, AdGroupID, Interactions) VALUES (usr_ID('Julia'), 2, 13);
INSERT INTO User_Ads (UserID, AdGroupID, Interactions) VALUES (usr_ID('Julia'), 4, 4);
INSERT INTO User_Ads (UserID, AdGroupID, Interactions) VALUES (usr_ID('Danutka12'), 2, 1);
INSERT INTO User_Ads (UserID, AdGroupID, Interactions) VALUES (usr_ID('Danutka12'), 4, 18);
INSERT INTO User_Ads (UserID, AdGroupID, Interactions) VALUES (usr_ID('Adam01'), 5, 3);
INSERT INTO User_Ads (UserID, AdGroupID, Interactions) VALUES (usr_ID('Adam01'), 2, 22);
INSERT INTO User_Ads (UserID, AdGroupID, Interactions) VALUES (usr_ID('Zdzislaw'), 3, 6);
INSERT INTO User_Ads (UserID, AdGroupID, Interactions) VALUES (usr_ID('Zdzislaw'), 1, 1);

/* ------------------------------ Integrity nodes tests -------------------------- */

/* ------------------------------------- Update ---------------------------------- */
UPDATE USERS SET Username = 'Marcin' WHERE Username = 'Radoslaw'; /* Cannot update username for existing username */
UPDATE USERS SET UserID = 2 WHERE Username = 'Radoslaw'; /*Trigger UserID cannot be updaten*/

UPDATE GROUP_INF SET CREATIONDATE = to_date('01/12/2019', 'DD/MM/YYYY') WHERE GroupID = 1;
UPDATE GROUP_INF SET GROUPID = 10 WHERE GROUPID = 1;

UPDATE GROUP_MEMBERS SET GROUPID = 3 WHERE GROUPID = 1;
UPDATE GROUP_MEMBERS SET MEMBERID = 10 WHERE MEMBERID =1;

UPDATE MESSAGES SET MessageID = 2000 WHERE MessageID = 1000;
UPDATE MESSAGES SET FromUserID = 2000 WHERE MessageID = 1000;
UPDATE MESSAGES SET ToGroupID = 2000 WHERE MessageID = 1000;
UPDATE MESSAGES SET Text = '2000' WHERE MessageID = 1000;
UPDATE MESSAGES SET SendTime = to_date('01/12/2019', 'DD/MM/YYYY') WHERE MessageID = 1000;
UPDATE MESSAGES SET ReplyToMessageID = 2000 WHERE MessageID = 1000;

UPDATE FRIENDS SET USERID1 = 2000 WHERE UserID1 = 1 and UserID2 = 2;
UPDATE FRIENDS SET USERID2 = 2000 WHERE UserID1 = 1 and UserID2 = 2;
UPDATE FRIENDS SET SendID = 2000 WHERE UserID1 = 1 and UserID2 = 2;

UPDATE POSTS SET PostID = 2000 WHERE PostID = 500;
UPDATE POSTS SET UserID = 2000 WHERE PostID = 500;
UPDATE POSTS SET Text = '2000' WHERE PostID = 500;
UPDATE POSTS SET PostTime = to_date('01/12/2019', 'DD/MM/YYYY') WHERE PostID = 500;

UPDATE COMMENTS SET CommentID = 2000 WHERE CommentID = 555;
UPDATE COMMENTS SET UserID = 2000 WHERE CommentID = 555;
UPDATE COMMENTS SET ToPostID = 2000 WHERE CommentID = 555;
UPDATE COMMENTS SET Text = '2000' WHERE CommentID = 555;
UPDATE COMMENTS SET CommentTime = to_date('01/12/2019', 'DD/MM/YYYY') WHERE CommentID = 555;
UPDATE COMMENTS SET ReplyToCommentID = 2000 WHERE CommentID = 555;

UPDATE REACTIONS_POSTS SET UserID = 2000 WHERE USERID = usr_ID('Julia') and POSTID = 500;
UPDATE REACTIONS_POSTS SET PostID = 2000 WHERE USERID = usr_ID('Julia') and POSTID = 500;
UPDATE REACTIONS_COMMENTS SET UserID = 2000 WHERE USERID =usr_ID('Radoslaw') and CommentID = 555;
UPDATE REACTIONS_COMMENTS SET CommentID = 2000 WHERE USERID = usr_ID('Julia') and CommentID = 555;
UPDATE REACTIONS_MESSAGES SET UserID = 2000 WHERE USERID = usr_ID('Julia') and MessageID = 1000;
UPDATE REACTIONS_MESSAGES SET MessageID = 2000 WHERE USERID = usr_ID('Julia') and MessageID = 1000;

UPDATE AD_PROVIDERS SET CompanyID = 2000 WHERE CompanyName = 'SportCompany';

UPDATE AD_GROUP SET AdGroupID = 2000 WHERE NameOfGroup = 'BadBeing';
UPDATE AD_GROUP SET CompanyID = 2000 WHERE NameOfGroup = 'BadBeing';

UPDATE AD_GROUP_KEYWORDS SET AdGroupID = 2000 WHERE AdGroupID = 3 and AdKeyword = 'hello';
UPDATE AD_GROUP_KEYWORDS SET AdKeyword = 'Szynka' WHERE AdGroupID = 3 and AdKeyword = 'hello';

UPDATE USER_ADS SET USERID = 2000 WHERE UserID = usr_ID('Radoslaw') and AdGroupID = 3;
UPDATE USER_ADS SET AdGroupID = 2000 WHERE UserID = usr_ID('Radoslaw') and AdGroupID = 3;

/* ------------------------------------- Delete ---------------------------------- */
DELETE FROM USERS WHER Username = 'Krzysztof';
DELETE FROM FRIENDS WHERE USERID1 = usr_ID('Adam01') and USERID2 = usr_ID('Marcin'); /*friends cos nie dziala*/
DELETE FROM GROUP_INF WHERE GROUPID = 13;
DELETE FROM GROUP_MEMBERS WHERE GROUPID = 10 and MemberID = usr_ID('Mmmichal');

DELETE FROM MESSAGES WHERE MessageID = 2000;
DELETE FROM POSTS WHERE PostID = 502;
DELETE FROM COMMENTS WHERE CommentID = 333;

DELETE FROM REACTIONS_POSTS WHERE UserID = usr_ID('Mmmichal') and PostID = 501;
DELETE FROM REACTIONS_COMMENTS WHERE UserID = usr_ID('Radoslaw') and CommentID = 333;
DELETE FROM REACTIONS_MESSAGES WHERE USerID = usr_ID('Marcin') and MessageId = 3001;

DELETE FROM AD_GROUP_KEYWORDS WHERE AdGroupID = 5 and AdKeyword = 'seems';
DELETE FROM AD_PROVIDERS WHERE CompanyName = 'SmallBadBisnes';
DELETE FROM AD_GROUP WHERE AdGroupID = 4;
,0
DELETE FROM USER_ADS WHERE UserID = usr_ID('Radoslaw') and AdGroupID = 1;E

/* ------------------------------------ VIEWS ------------------------------------ */


SELECT * FROM MESSAGES WHERE ToGroupID in (select GroupID from Group_members where MemberID = usr_ID('Radoslaw'));
SELECT * FROM MESSAGES inner join Group_MEmbers on Messages.ToGroupID = Group_Members.GroupID where MemberID = usr_ID('Radoslaw');
SELECT * FROM MESSAGES ORDER BY sendtime asc FETCH FIRST 1 ROWS ONLY;
SELECT * FROM MESSAGES WHERE ToGroupID in (select GroupID from Group_members where MemberID = usr_ID('Radoslaw'));
SELECT * FROM MESSAGES inner join Group_MEmbers on Messages.ToGroupID = Group_Members.GroupID where MemberID = usr_ID('Radoslaw') order by ToGroupID;

SELECT ToGroupID, MAX(sendtime) as LAST FROM MESSAGES inner join Group_MEmbers on Messages.ToGroupID = Group_Members.GroupID where MemberID = usr_ID('Radoslaw') group by TogroupID;
JOIN Messages M ON foo.ToGroupID = M.ToGroupID and foo.last = M.sendtime);

select GroupID from Group_members where MemberID = usr_ID('Radoslaw')
SELECT * FROM MESSAGES WHERE ToGroupID in (select GroupID from Group_members where MemberID = usr_ID('Radoslaw'));
SELECT * FROM MESSAGES inner join Group_MEmbers on Messages.ToGroupID = Group_Members.GroupID where MemberID = usr_ID('Radoslaw');
SELECT * FROM MESSAGES INNER JOIN (SELECT ToGroupID, MAX(sendtime) as LAST FROM MESSAGES group by ToGroupID) LastM ON Messages.TogroupID = LastM.TogroupID and lastM.Last = Messages.Sendtime;

SELECT * FROM MESSAGES INNER JOIN (SELECT ToGroupID, MAX(sendtime) as LAST FROM MESSAGES inner join Group_MEmbers on Messages.ToGroupID = Group_Members.GroupID where MemberID = usr_ID('Radoslaw') group by ToGroupID) LastM ON M.TogroupID = LastM.TogroupID and lastM.Last = M.Sendtime;
SELECT * FROM MESSAGES INNER JOIN (SELECT ToGroupID, MAX(sendtime) as LAST FROM MESSAGES WHERE ToGroupID in (select GroupID from Group_members where MemberID = usr_ID('Radoslaw')) group by ToGroupID) LastM ON M.TogroupID = LastM.TogroupID and lastM.Last = M.Sendtime;

SELECT * FROM MESSAGES M INNER JOIN (SELECT ToGroupID, MAX(sendtime) as LAST FROM MESSAGES inner join Group_MEmbers on Messages.ToGroupID = Group_Members.GroupID where MemberID = usr_ID('Radoslaw') group by ToGroupID) LastM ON M.TogroupID = LastM.TogroupID and lastM.Last = M.Sendtime;
SELECT * FROM MESSAGES M INNER JOIN (SELECT ToGroupID, MAX(sendtime) as LAST FROM MESSAGES WHERE ToGroupID in (select GroupID from Group_members where MemberID = usr_ID('Radoslaw')) group by ToGroupID) LastM ON M.TogroupID = LastM.TogroupID and lastM.Last = M.Sendtime;

create view Last_messages_user as SELECT M.* FROM MESSAGES M INNER JOIN (SELECT ToGroupID, MAX(sendtime) as LAST FROM MESSAGES inner join Group_MEmbers on Messages.ToGroupID = Group_Members.GroupID where MemberID = usr_ID('Radoslaw') group by ToGroupID) LastM ON M.TogroupID = LastM.TogroupID and lastM.Last = M.Sendtime;
select * from Last_messages_user;

join Group_members on ..TogroupID = Group_members.GroupID and ..FromUserID = Group_members.MemberID /* add nickname */
join Users on ..FromUserID = Users.UserID /* add username */



SELECT U.Username, UserM.* FROM Users U inner join (SELECT * FROM MESSAGES M inner join Group_Members GM on M.ToGroupID = GM.GroupID where MemberID = usr_ID('Radoslaw')) UserM on U.UserID = UserM.FromUserID;

SELECT GNick.Nickname, UserM.* FROM Group_Members GNick inner join (SELECT * FROM MESSAGES M inner join Group_Members GM on M.ToGroupID = GM.GroupID where MemberID = usr_ID('Radoslaw')) UserM on GNick.GroupID = UserM.TogroupID and GNick.MemberId = UserM.FromUserID;

SELECT U.Username, UserM.* FROM Users U inner join (SELECT * FROM MESSAGES M inner join Group_Members GM on M.ToGroupID = GM.GroupID where MemberID = usr_ID('Radoslaw')) UserM on U.UserID = UserM.FromUserID;

SELECT GNick.Nickname, R.* FROM Group_members GNick inner join (SELECT U.Username, UserM.* FROM Users U inner join (SELECT M.* FROM MESSAGES M inner join Group_Members GM on M.ToGroupID = GM.GroupID where GM.MemberID = usr_ID('Radoslaw')) UserM on U.UserID = UserM.FromUserID) R on GNick.MemberID = R.FromUserID and GNick.GroupID = R.ToGroupID order by R.ToGroupID, R.SendTime;

create view user_messages as SELECT GNick.Nickname, R.* FROM Group_members GNick inner join (SELECT U.Username, UserM.* FROM Users U inner join (SELECT M.* FROM MESSAGES M inner join Group_Members GM on M.ToGroupID = GM.GroupID where GM.MemberID = usr_ID('Radoslaw')) UserM on U.UserID = UserM.FromUserID) R on GNick.MemberID = R.FromUserID and GNick.GroupID = R.ToGroupID order by R.ToGroupID, R.SendTime;

select* from user_messages;

SELECT AllM.* FROM user_messages AllM inner join (SELECT UM.ToGroupID, MAX(UM.sendtime) as LAST FROM user_messages UM GROUP BY UM.ToGroupID) LastM on LastM.ToGroupID = AllM.ToGroupID and LastM.last = AllM.sendTime order by LastM.last desc;
select * from messages order by sendtime desc;

create or replace view Last_messages_user as SELECT AllM.* FROM user_messages AllM inner join (SELECT UM.ToGroupID, MAX(UM.sendtime) as LAST FROM user_messages UM GROUP BY UM.ToGroupID) LastM on LastM.ToGroupID = AllM.ToGroupID and LastM.last = AllM.sendTime order by LastM.last desc;

select * from last_messages_user


select UserID1 from FRIENDS where usr_ID('Radoslaw') = USERID2 and not(since is Null) union select UserID2 from FRIENDS where usr_ID('Radoslaw') = USERID1 and not(since is Null);
select UserID1 from FRIENDS where 3 = USERID2 and not(since is Null) union select UserID2 from FRIENDS where 3 = USERID1 and not(since is Null);

select username, Wee.MaybeFriend, Wee.PowerOfFriendship from users inner join (select MyID.MaybeFriend, count(*) as PowerOfFriendship from
(select UserID1 MaybeFriend from Friends F inner join (select UserID1 UserID from FRIENDS where 3 = USERID2 and not(since is Null) union select UserID2 USerID from FRIENDS where 3 = USERID1 and not(since is Null)) MyF 
on MyF.UserID = F.UserID2 and F.UserID1 != 3 and not (F.since is Null) union all 
select UserID2 MaybeFriend from Friends F inner join (select UserID1 UserID from FRIENDS where 3 = USERID2 and not(since is Null) union select UserID2 USerID from FRIENDS where 3 = USERID1 and not(since is Null)) MyF 
on MyF.UserID = F.UserID1 and F.UserID2 != 3 and not (F.since is Null)) MyID group by(MyID.maybefriend) order by PowerOfFriendship desc) Wee on users.UserID = Wee.MaybeFriend;


select P.* from Posts P inner join (
select UserID1 UserID from FRIENDS where 3 = USERID2 and not(since is Null) union select UserID2 USerID from FRIENDS where 3 = USERID1 and not(since is Null)) MyFriends
on P.UserID = MyFriends.UserID order by P.posttime desc;

select FriendsPosts.*, R.TypeOfReaction from reactions_posts R right join (
select P.* from Posts P inner join (
select UserID1 UserID from FRIENDS where 3 = USERID2 and not(since is Null) union select UserID2 USerID from FRIENDS where 3 = USERID1 and not(since is Null)) MyFriends
on P.UserID = MyFriends.UserID) FriendsPosts
on FriendsPosts.PostID = R.PostID;


select FriendsPosts.*, Count(case when R.TypeOfReaction = 1 then 1 end) reaction1 from reactions_posts R right join (
select P.* from Posts P inner join (
select UserID1 UserID from FRIENDS where 3 = USERID2 and not(since is Null) union select UserID2 USerID from FRIENDS where 3 = USERID1 and not(since is Null)) MyFriends
on P.UserID = MyFriends.UserID) FriendsPosts
on FriendsPosts.PostID = R.PostID group by R.TypeOfReaction;

select A.AdGroupID, A.NameOfGroup, A.CompanyID, A.SeenCost, (A.interactionPrice * U.interactions) InteractedCost from User_Ads U inner join (
select AdGroupID, NameOfGroup, CompanyID, (seenprice * seenadcount) SeenCost, interactionPrice from Ad_Group ) A
on U.AdGroupID = A.AdGroupID;

select A.AdGroupID, A.NameOfGroup, A.CompanyID, A.SeenCost, A.interactionPrice, U.interactions from User_Ads U inner join (
select AdGroupID, NameOfGroup, CompanyID, (seenprice * seenadcount) SeenCost, interactionPrice from Ad_Group ) A
on U.AdGroupID = A.AdGroupID;

select Z.AdGroupID, Z.NameOfGroup, Z.CompanyID, Z.SeenCost, Z.interactionPrice, sum(Z.interactions) from (
select A.AdGroupID, A.NameOfGroup, A.CompanyID, A.SeenCost, A.interactionPrice, U.interactions from User_Ads U inner join (
select AdGroupID, NameOfGroup, CompanyID, (seenprice * seenadcount) SeenCost, interactionPrice from Ad_Group ) A
on U.AdGroupID = A.AdGroupID) Z 
group by Z.AdGroupID;

select AdGroupID, sum(interactions) from User_Ads group by AdGroupID;

select Ad.CompanyID, C.CompanyName, Ad.AdGroupID, Ad.NameOfGroup, Ad.SeenCost, Ad.InteractionCost from Ad_Providers C inner join (
select A.AdGroupID, A.NameOfGroup, A.CompanyID, (A.seenPrice * A.seenAdCount) SeenCost, (A.interactionPrice * U.interactions) interactionCost from Ad_Group A inner join (
select AdGroupID, sum(interactions) interactions from User_Ads group by AdGroupID) U
on A.AdGroupID = U.AdGroupID) Ad 
on C.CompanyID = Ad.CompanyID;

select A.AdGroupID, A.NameOfGroup, A.CompanyID, (A.seenprice * A.seenadcount) SeenCost A.interactionPrice from User_Ads U inner join
(select AdGroupID, NameOfGroup, CompanyID, seenprice, seenadcount, interactionPrice from Ad_Group) A
on U.AdGroupID = A.AdGroupID;

select Ppp.Postid, Ppp.text, Ppp.commentid, Ppp.commenttext, count(1) from reactions_comments Rcom natural join 
(select MyPosts.Postid, MyPosts.text C.commentid, C.text as commenttext from comments C natural join 
(select Postid, text from Posts where userID = usr_ID('Radoslaw') order by posttime desc) MyPosts on C.PostID = MyPosts.PostID) MypostC on MypostC. group by CommentID) Ppp on Rcom.CommentID = Ppp.commentID group by Rcom.CommentID;


select MyPosts.Postid, MyPosts.text, C.commentid from comments C right join 
(select Postid, text from Posts where userID = usr_ID('Radoslaw')) MyPosts 
on C.ToPostID = MyPosts.PostID;

select PC.PostID, PC.text, PC.commentID, PC.CommentText, PC.UserID, RC.TypeOfReaction from reactions_comments RC right join 
(select MyPosts.Postid, MyPosts.text, C.commentid, C.text commenttext, C.userID from comments C right join 
(select Postid, text from Posts where userID = usr_ID('Radoslaw')) MyPosts on C.ToPostID = MyPosts.PostID) PC on PC.commentID = RC.commentID;

select PC.PostID, PC.text, PC.commentID, PC.CommentText, PC.UserID, rp.TypeOfReaction from Reactions_Posts RP right join 
(select MyPosts.Postid, MyPosts.text, C.commentid, C.text commenttext, C.userID, C.commentTime from comments C right join 
(select Postid, text from Posts where userID = usr_ID('Radoslaw')) MyPosts on C.ToPostID = MyPosts.PostID order by C.commentTime) PC on PC.PostID = Rp.PostID;


SELECT CommentID, count(TypeOfReaction) FROM Reactions_Comments GROUP BY CommentID;

select P.Postid, R.TypeOfReaction from reactions_posts R right join ( 
select Postid from Posts where userID = usr_ID('Radoslaw') order by PostTime desc) P
on P.PostId = R.PostID;

select RP.PostID, count(ALL RP.TypeOfReaction) from (
select P.Postid, R.TypeOfReaction from reactions_posts R right join ( 
select Postid from Posts where userID = usr_ID('Radoslaw') order by PostTime desc) P
on P.PostId = R.PostID) RP
group by RP.PostId;

select PCR.PostID, PCR.commentID, count(ALL PCR.TypeOfReaction) from (
select PC.PostId, PC.CommentID, R.TypeOfReaction from reactions_comments R right join (
select P.Postid, C.CommentID from comments C right join ( 
select Postid from Posts where userID = usr_ID('Radoslaw') order by PostTime desc) P
on P.PostId = C.ToPostID) PC
on PC.CommentID = R.CommentID) PCR
group by PCR.CommentID;


select PCR.PostID, PCR.commentID, PCR.TypeOfReaction from (
select PC.PostId, PC.CommentID, R.TypeOfReaction from reactions_comments R right join (
select P.Postid, C.CommentID from comments C right join ( 
select Postid from Posts where userID = usr_ID('Radoslaw') order by PostTime desc) P
on P.PostId = C.ToPostID) PC
on PC.CommentID = R.CommentID) PCR;

select P.Postid, C.CommentTime from comments C right join ( 
select Postid from Posts where userID = usr_ID('Radoslaw') order by PostTime desc) P on P.PostId = C.ToPostID)group by PostID;

/* ---------------------------- actual views ------------------------------------------ */
create or replace view user_messages as SELECT GNick.Nickname, R.* FROM Group_members GNick inner join 
(SELECT U.Username, UserM.* FROM Users U inner join 
(SELECT M.* FROM MESSAGES M inner join Group_Members GM on M.ToGroupID = GM.GroupID where GM.MemberID = usr_ID('Radoslaw')) UserM 
on U.UserID = UserM.FromUserID) R on 
GNick.MemberID = R.FromUserID and GNick.GroupID = R.ToGroupID order by R.ToGroupID asc, R.SendTime desc;

select* from user_messages;


create or replace view Last_messages_user as SELECT AllM.* FROM user_messages AllM inner join 
(SELECT UM.ToGroupID, MAX(UM.sendtime) as LAST FROM user_messages UM GROUP BY UM.ToGroupID) LastM on LastM.ToGroupID = AllM.ToGroupID and LastM.last = AllM.sendTime order by LastM.last desc;

select * from last_messages_user;


create or replace view SuggestedFriends as select username, Wee.MaybeFriend, Wee.PowerOfFriendship from users inner join 
(select MyID.MaybeFriend, count(*) as PowerOfFriendship from
(select UserID1 MaybeFriend from Friends F inner join (select UserID1 UserID from FRIENDS where usr_ID('Mmmichal') = USERID2 and not(since is Null) union select UserID2 USerID from FRIENDS where usr_ID('Mmmichal') = USERID1 and not(since is Null)) MyF 
on MyF.UserID = F.UserID2 and F.UserID1 != usr_ID('Mmmichal') and not (F.since is Null) union all 
select UserID2 MaybeFriend from Friends F inner join (select UserID1 UserID from FRIENDS where usr_ID('Mmmichal') = USERID2 and not(since is Null) union select UserID2 USerID from FRIENDS where usr_ID('Mmmichal') = USERID1 and not(since is Null)) MyF 
on MyF.UserID = F.UserID1 and F.UserID2 != usr_ID('Mmmichal') and not (F.since is Null)) MyID group by(MyID.maybefriend) order by PowerOfFriendship desc) Wee 
on users.UserID = Wee.MaybeFriend;

select * from SuggestedFriends;


create or replace view Feed as 
select U.username, Posted.Text from Users U inner join (
select P.* from Posts P inner join (
select UserID1 UserID from FRIENDS where usr_ID('Mmmichal') = USERID2 and not(since is Null) union select UserID2 USerID from FRIENDS where usr_ID('Mmmichal') = USERID1 and not(since is Null)) MyFriends
on P.UserID = MyFriends.UserID order by P.posttime desc) Posted
on U.UserID = Posted.UserID;

select * from Feed;


create or replace view AdSummary as
select Ad.CompanyID, C.CompanyName, Ad.AdGroupID, Ad.NameOfGroup, Ad.SeenCost, Ad.InteractionCost from Ad_Providers C inner join (
select A.AdGroupID, A.NameOfGroup, A.CompanyID, (A.seenPrice * A.seenAdCount) SeenCost, (A.interactionPrice * U.interactions) interactionCost from Ad_Group A inner join (
select AdGroupID, sum(interactions) interactions from User_Ads group by AdGroupID) U
on A.AdGroupID = U.AdGroupID) Ad 
on C.CompanyID = Ad.CompanyID;

select * from AdSummary;
