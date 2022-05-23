/* */
DROP TABLE USERS;
DROP TABLE GROUP_INF;
DROP TABLE GROUP_MEMBERS;
DROP TABLE MESSAGES;

CREATE SEQUENCE usrID START WITH 1 INCREMENT BY 1 CACHE 100;

CREATE TABLE USERS(
UserID INT,
Username VARCHAR2(30 CHAR) NOT NULL,
Email VARCHAR2(50 CHAR) NOT NULL,
Password VARCHAR2(20 CHAR) NOT NULL,
Status NUMBER(1),
CONSTRAINT users_pk PRIMARY KEY(UserID),
CONSTRAINT email_k UNIQUE(Email),
CONSTRAINT username_k UNIQUE(Username)
);

CREATE SEQUENCE grID START WITH 1 INCREMENT BY 1 CACHE 100;

CREATE TABLE GROUP_INF(
GroupID INT,
Name VARCHAR2(50 CHAR) DEFAULT NULL, /*If null than name is nickname of other person*/
CreationDate DATE NOT NULL,
Admin INT DEFAULT NULL, /*null = noone = everyone in group have admin privilages*/
CONSTRAINT GroupInf_pk PRIMARY KEY (GroupID),
CONSTRAINT admin_fk FOREIGN KEY (Admin) REFERENCES USERS(UserID) ON DELETE SET NULL
);

CREATE TABLE GROUP_MEMBERS(
GroupID INT NOT NULL,
MemberID INT NOT NULL,
Nickname VARCHAR2(30) DEFAULT NULL, /*If null than username*/
CONSTRAINT Group_pk PRIMARY KEY (GroupID, MemberID),
CONSTRAINT group_fk FOREIGN KEY (GroupID) REFERENCES GROUP_INF(GroupID) ON DELETE CASCADE, /* If group is del than all of messages are deleted too*/
CONSTRAINT member_fk FOREIGN KEY (MemberID) REFERENCES USERS(UserID) ON DELETE CASCADE /* If account is deleted than we should also delete all messages*/
);

CREATE SEQUENCE messID START WITH 1 INCREMENT BY 1 CACHE 100;

CREATE TABLE MESSAGES(
MessageID INT,
FromID INT NOT NULL,
ToID INT NOT NULL,
ReplyMessID INT DEFAULT NULL,
Text VARCHAR2(512 CHAR),
Image BFILE DEFAULT NULL,
CONSTRAINT Message_pk PRIMARY KEY(MessageID),
CONSTRAINT From_fk FOREIGN KEY(FromID) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT To_fk FOREIGN KEY(ToID) REFERENCES GROUP_INF(GroupID) ON DELETE CASCADE,
CONSTRAINT Reply_fk FOREIGN KEY(ReplyMessID) REFERENCES MESSAGES(MessageID) ON DELETE SET NULL
/*CONSTRAINT not_empty CHECK((Text != NULL) or (Image != NULL))*//*                                                         <--- check that (bfile)*/
);

DROP TABLE FRIENDS;
CREATE TABLE FRIENDS(
USERID1 INT,
USERID2 INT,
SENDID INT,
SINCE DATE, /*Nullable if someone sends friend request than table is created, if user accepts request than date != Null*/
CONSTRAINT Friends_pk PRIMARY KEY(USERID1, USERID2),
CONSTRAINT Different_users CHECK (USERID1 != USERID2),
CONSTRAINT User1_fk FOREIGN KEY(USERID1) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT User2_fk FOREIGN KEY(USERID2) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT send_fk FOREIGN KEY(SENDID) REFERENCES USERS(UserID) ON DELETE CASCADE
);

CREATE OR REPLACE TRIGGER friends_one_pair 
BEFORE INSERT 
ON FRIENDS
FOR EACH ROW
ENABLE
DECLARE
TEMP INT;
BEGIN
IF :new.USERID1 < :new.USERID2 THEN 
TEMP := :new.USERID1;
:new.USERID1 := :new.USERID2;
:new.USERID2 := TEMP;
END IF;
END;

CREATE TABLE POSTS(
PostID INT,
UserID INT NOT NULL,
Text VARCHAR2(512 CHAR),
Photo BFILE DEFAULT NULL,
CONSTRAINT post_pk PRIMARY KEY(PostID),
CONSTRAINT user_fk FOREIGN KEY(UserID) REFERENCES USERS(UserID) ON DELETE CASCADE
/*CONSTRAINT not_empty CHECK(Text != Null or Photo != Null)                                                                <---- check that (bfile)*/
);

CREATE TABLE COMMENTS(
CommentID INT,
UserID INT NOT NULL,
ToPost INT NOT NULL,
Text VARCHAR2(512 CHAR) NOT NULL,
ReplyToComment INT DEFAULT NULL,
CONSTRAINT comments_pk PRIMARY KEY(CommentID),
CONSTRAINT posts_fk FOREIGN KEY(ToPost) REFERENCES POSTS(PostID) ON DELETE CASCADE,
CONSTRAINT c_user_fk FOREIGN KEY(UserID) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT comment_fk FOREIGN KEY(ReplyToComment) REFERENCES COMMENTS(CommentID) ON DELETE SET NULL
);


CREATE TABLE REACTIONS(
UserID INT NOT NULL,
MessageID INT DEFAULT 0, /* ZERO insted of NULL (becouse its part of primary key)*/
PostID INT DEFAULT 0,    /* ZERO insted of NULL (becouse its part of primary key)*/
CommentID INT DEFAULT 0, /* ZERO insted of NULL (becouse its part of primary key)*/
Rtype INT NOT NULL,
CONSTRAINT reactions_pk PRIMARY KEY(MessageID, PostID, CommentID, UserID),
CONSTRAINT r_user_fk FOREIGN KEY(UserID) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT r_mess_fk FOREIGN KEY(MessageID) REFERENCES MESSAGES(MessageID) ON DELETE CASCADE,
CONSTRAINT r_post_fk FOREIGN KEY(PostID) REFERENCES POSTS(PostID) ON DELETE CASCADE,
CONSTRAINT r_comment_fk FOREIGN KEY(CommentID) REFERENCES COMMENTS(CommentID) ON DELETE CASCADE,
CONSTRAINT r_not_empty CHECK(MessageID != 0 or PostID != 0 or CommentID != 0)
);

CREATE OR REPLACE TRIGGER reactions_only_one 
BEFORE INSERT 
ON REACTIONS
FOR EACH ROW
ENABLE
DECLARE
BEGIN
IF :new.MessageID != 0 and :new.PostID != 0 and :new.CommentID != 0 THEN 
:new.MessageID := 0;
:new.PostID := 0;
:new.CommentID := 0;
ELSIF :new.MessageID != 0 and :new.PostID != 0 THEN
:new.MessageID := 0;
:new.PostID := 0;
ELSIF :new.MessageID != 0 and :new.CommentID != 0 THEN
:new.MessageID := 0;
:new.CommentID := 0;
ELSIF :new.PostID != 0 and :new.CommentID != 0 THEN
:new.PostID := 0;
:new.CommentID := 0;
END IF;
END;

CREATE TABLE AD_GROUP(
AdGroupID INT,
Name VARCHAR2(30 CHAR) NOT NULL,
UrlAd VARCHAR2(200 CHAR) NOT NULL,
CONSTRAINT Ad_group_pk PRIMARY KEY(AdGroupID)
);

CREATE TABLE AD_GROUP_KEYWORDS(
AdGroupID INT NOT NULL,
Adkeyword VARCHAR2(20 CHAR) NOT NULL,
CONSTRAINT ad_group_keywords_pk PRIMARY KEY(AdGroupID, Adkeyword),
CONSTRAINT ad_group_keyword_ad_fk FOREIGN KEY(AdGroupID) REFERENCES AD_GROUP(AdGroupID) ON DELETE CASCADE
);

CREATE TABLE USER_ADS(
UserID INT,
AdGroupID INT,
Count INT DEFAULT 0,
Interactions INT DEFAULT 0,
CONSTRAINT user_ad_pk PRIMARY KEY(UserID, AdGroupID),
CONSTRAINT user_ad_user_fk FOREIGN KEY(UserID) REFERENCES USERS(UserID) ON DELETE CASCADE,
CONSTRAINT user_ad_ad_fk FOREIGN KEY(AdGroupID) REFERENCES AD_GROUP(AdGroupID) ON DELETE CASCADE
);

CREATE TABLE AD_PROVIDERS(
IDcompany_group INT,
CompanyName VARCHAR2(30 CHAR),
AdGroupID INT NOT NULL,
CONSTRAINT AD_prov_group_pk PRIMARY KEY(IDcompany_group),
CONSTRAINT AD_prov_group_fk FOREIGN KEY(AdGroupID) REFERENCES AD_GROUP(AdGroupID) ON DELETE CASCADE
);


INSERT INTO FRIENDS VALUES(1, 2, 1, NULL);
INSERT INTO FRIENDS VALUES(2, 1, 2, NULL);


INSERT INTO USERS VALUES (1, 'Radke', 'radke@mail.com', '1234', 1);
INSERT INTO USERS VALUES (2, 'Juju', 'juju@mail.com', '1111', 1);

INSERT INTO GROUP_INF VALUES (1, Null, TO_DATE('21/12/21', 'DD/MM/YY'), Null);

INSERT INTO GROUP_MEMBERS VALUES (1, 1, Null);
INSERT INTO GROUP_MEMBERS VALUES (1, 2, Null);

INSERT INTO MESSAGES VALUES (1, 1, 1, Null, 'Hej :)', Null); /*Message from user Radke to user Juju*/
INSERT INTO MESSAGES VALUES (2, 2, 1, 1, 'Hejka?', Null); /*Message from user Juju to user Radke replaying to previous message*/

describe users;
describe group_inf;
describe group_members;
describe messages;

SELECT * FROM users;
SELECT * FROM GROUP_INF;
SELECT * FROM GROUP_MEMBERS;
SELECT * FROM MESSAGES;

DELETE FROM USERS WHERE userid = 2;
DELETE FROM group_inf WHERE GROUPID = 1;
