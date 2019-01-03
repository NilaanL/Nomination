--
-- NOMINATION V2.6.0
--
DROP DATABASE IF EXISTS EC_NOMINATION;

CREATE DATABASE IF NOT EXISTS EC_NOMINATION CHARACTER SET UTF8MB4 COLLATE UTF8MB4_UNICODE_CI;

USE EC_NOMINATION;




--
-- ELECTION MODULES
-- mainly regarding to maintain the configs
--


-- election_module file to maintain election types
CREATE TABLE IF NOT EXISTS ELECTION_MODULE(
    ID VARCHAR(36) PRIMARY KEY,
    NAME VARCHAR(100) NOT NULL, 		/* eg value: 'parliamentary', 'provincial' */
    DIVISION_COMMON_NAME VARCHAR(20) 	/* eg value: 'district', 'province' */
)ENGINE=INNODB;

-- manage approval status of election module
CREATE TABLE IF NOT EXISTS ELECTION_MODULE_APPROVAL(
	ID VARCHAR(36) PRIMARY KEY,
	STATUS ENUM('PENDING','APPROVE','REJECT'),
	CREATED_DATE BIGINT,
	CREATED_BY VARCHAR(50),
	
	MODULE_ID VARCHAR(36),
    FOREIGN KEY(MODULE_ID) REFERENCES ELECTION_MODULE(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

-- defines all configs required
CREATE TABLE IF NOT EXISTS ELECTION_CONFIG(
    ID VARCHAR(36) PRIMARY KEY,
    DESCRIPTION VARCHAR(50)
)ENGINE=INNODB;

-- keep values for defined configs
CREATE TABLE IF NOT EXISTS ELECTION_CONFIG_DATA(
	VALUE VARCHAR(100) NOT NULL,
	
	ELECTION_CONFIG_ID VARCHAR(36),
	FOREIGN KEY(ELECTION_CONFIG_ID) REFERENCES ELECTION_CONFIG(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
	
	MODULE_ID VARCHAR(36),
	FOREIGN KEY(MODULE_ID) REFERENCES ELECTION_MODULE(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
	
	PRIMARY KEY(ELECTION_CONFIG_ID, MODULE_ID)
)ENGINE=INNODB;

-- where you store all eligibity criteria of nominations
CREATE TABLE IF NOT EXISTS ELIGIBILITY_CONFIG(
    ID VARCHAR(36) PRIMARY KEY,
    DESCRIPTION TEXT NOT NULL,
    
    MODULE_ID VARCHAR(36),
    FOREIGN KEY(MODULE_ID) REFERENCES ELECTION_MODULE(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS SUPPORT_DOC_CONFIG(
	ID VARCHAR(36) PRIMARY KEY,
	KEY_NAME VARCHAR(50) NOT NULL, /* eg: 'NIC', 'Birth Certificate' */
	DESCRIPTION VARCHAR(100),
	DOC_CATEGORY ENUM('NOMINATION', 'CANDIDATE', 'OBJECTION')
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS SUPPORT_DOC_CONFIG_DATA(	
	SUPPORT_DOC_CONFIG_ID VARCHAR(36),
	FOREIGN KEY (SUPPORT_DOC_CONFIG_ID) REFERENCES SUPPORT_DOC_CONFIG(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
	
	MODULE_ID VARCHAR(36),
    FOREIGN KEY(MODULE_ID) REFERENCES ELECTION_MODULE(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
    
	SELECT_FLAG BOOLEAN,
    
    PRIMARY KEY(SUPPORT_DOC_CONFIG_ID, MODULE_ID)
)ENGINE=INNODB;




--
-- ELECTION 
--

CREATE TABLE IF NOT EXISTS ELECTION(
    ID VARCHAR(36) PRIMARY KEY,
    NAME VARCHAR(100) NOT NULL,
    
    MODULE_ID VARCHAR(36),
    FOREIGN KEY(MODULE_ID) REFERENCES ELECTION_MODULE(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS ELECTION_TIMELINE_CONFIG(
	ID VARCHAR(36) PRIMARY KEY,
	KEY_NAME VARCHAR(50) NOT NULL,
	DESCRIPTION VARCHAR(100)
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS ELECTION_TIMELINE_CONFIG_DATA(
	ELECTION_TIMELINE_CONFIG_ID VARCHAR(36),
	FOREIGN KEY (ELECTION_TIMELINE_CONFIG_ID) REFERENCES ELECTION_TIMELINE_CONFIG(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
	
	ELECTION_ID VARCHAR(36),
	FOREIGN KEY(ELECTION_ID) REFERENCES ELECTION(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
	
	VALUE BIGINT,
	PRIMARY KEY(ELECTION_TIMELINE_CONFIG_ID, ELECTION_ID)
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS ELECTION_APPROVAL(
	ID VARCHAR(36) PRIMARY KEY,
	STATUS ENUM('PENDING','APPROVE','REJECT'),
	CREATED_DATE BIGINT,
	CREATED_BY VARCHAR(50),
	
	ELECTION_ID VARCHAR(36),
	FOREIGN KEY(ELECTION_ID) REFERENCES ELECTION(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS ELECTION_TEAM(
	ID VARCHAR(36) PRIMARY KEY,
	
	TEAM_ID VARCHAR(36),
	
	ELECTION_ID VARCHAR(36),
	FOREIGN KEY(ELECTION_ID) REFERENCES ELECTION(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;





--
-- DIVISION DATA
--

CREATE TABLE IF NOT EXISTS DIVISION_CONFIG(
	ID VARCHAR(36) PRIMARY KEY,
	NAME VARCHAR(100) NOT NULL,
	CODE VARCHAR(10) NOT NULL,
	NO_OF_CANDIDATES INT(5) NOT NULL,
	
	MODULE_ID VARCHAR(36),
    FOREIGN KEY(MODULE_ID) REFERENCES ELECTION_MODULE(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS DIVISION_CONFIG_DATA(
	ELECTION_ID VARCHAR(36),
	FOREIGN KEY(ELECTION_ID) REFERENCES ELECTION(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
	
	DIVISION_CONFIG_ID VARCHAR(36),
	FOREIGN KEY (DIVISION_CONFIG_ID) REFERENCES DIVISION_CONFIG(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
	
	SELECT_FLAG BOOLEAN,
	
	PRIMARY KEY(ELECTION_ID, DIVISION_CONFIG_ID)
)ENGINE=INNODB;




--
-- NOMINATION 
--

CREATE TABLE IF NOT EXISTS NOMINATION(
    ID VARCHAR(36) PRIMARY KEY,
    STATUS ENUM('DRAFT','APPROVE','REJECT','SUBMIT'),
    
    TEAM_ID VARCHAR(36),
    
    ELECTION_ID VARCHAR(36) NOT NULL,
    FOREIGN KEY (ELECTION_ID) REFERENCES ELECTION(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
    
    DIVISION_CONFIG_DATA_ID VARCHAR(36),
    FOREIGN KEY (DIVISION_CONFIG_DATA_ID) REFERENCES DIVISION_CONFIG_DATA(DIVISION_CONFIG_ID) ON UPDATE CASCADE ON DELETE RESTRICT
    
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS NOMINATION_SUPPORT_DOC(
    ID VARCHAR(36) PRIMARY KEY,
	FILE_PATH VARCHAR(200),
	
	SUPPORT_DOC_CONFIG_DATA_ID VARCHAR(36),
	FOREIGN KEY (SUPPORT_DOC_CONFIG_DATA_ID) REFERENCES SUPPORT_DOC_CONFIG_DATA(SUPPORT_DOC_CONFIG_ID) ON UPDATE CASCADE ON DELETE RESTRICT,
	
	NOMINATION_ID VARCHAR(36),
    FOREIGN KEY (NOMINATION_ID) REFERENCES NOMINATION(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS NOMINATION_APPROVAL(
	ID VARCHAR(36) PRIMARY KEY,	
	APPROVAL_DATE BIGINT,
	APPROVAL_BY VARCHAR(100),
	STATUS ENUM('APPROVE','REJECT'),
	REVIEW_NOTE TEXT,
	
	NOMINATION_ID VARCHAR(36),
    FOREIGN KEY (NOMINATION_ID) REFERENCES NOMINATION(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

-- nomination allowed teams
CREATE TABLE IF NOT EXISTS NOMINATION_ALLOWED_TEAM(
    ID VARCHAR(36) PRIMARY KEY,
    SELECT_FLAG BOOLEAN DEFAULT FALSE,
    
    -- TEAM ID is taken from Team MicroService
	TEAM_ID VARCHAR(36),
	
	DIVISION_ID VARCHAR(36),
	FOREIGN KEY (DIVISION_ID) REFERENCES DIVISION_CONFIG(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
	
    ELECTION_ID VARCHAR(36),
    FOREIGN KEY(ELECTION_ID) REFERENCES ELECTION(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS OBJECTION(
    ID VARCHAR(36) PRIMARY KEY,
    DESCRIPTION TEXT,
    CREATE_DATE BIGINT,
    CREATE_BY VARCHAR(100),
    CREATE_BY_TEAM_ID VARCHAR(36),
    
    NOMINATION_ID VARCHAR(36),
    FOREIGN KEY (NOMINATION_ID) REFERENCES NOMINATION(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS OBJECTION_REVIEW(
	ID VARCHAR(36) PRIMARY KEY,
	CREATE_BY VARCHAR(100), /* plans is store use logged user id */
	CREATE_DATE BIGINT,
	NOTE TEXT,
	
	OBJECTION_ID VARCHAR(36),
    FOREIGN KEY (OBJECTION_ID) REFERENCES OBJECTION(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS OBJECTION_SUPPORT_DOC(
    ID VARCHAR(36) PRIMARY KEY,
    FILE_PATH VARCHAR(300),
    
    SUPPORT_DOC_CONFIG_DATA_ID VARCHAR(36),
	FOREIGN KEY (SUPPORT_DOC_CONFIG_DATA_ID) REFERENCES SUPPORT_DOC_CONFIG_DATA(SUPPORT_DOC_CONFIG_ID) ON UPDATE CASCADE ON DELETE RESTRICT,
    
    OBJECTION_ID VARCHAR(36),
    FOREIGN KEY (OBJECTION_ID) REFERENCES OBJECTION(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

-- payment for nomination
CREATE TABLE IF NOT EXISTS PAYMENT(
    ID VARCHAR(36) PRIMARY KEY,
    DEPOSITOR VARCHAR(100),
    DEPOSIT_DATE BIGINT,
    AMOUNT DECIMAL(13,4),
    FILE_PATH VARCHAR(300),
    STATUS ENUM('PENDING','APPROVE','REJECT'),
    
    NOMINATION_ID VARCHAR(36),
    FOREIGN KEY (NOMINATION_ID) REFERENCES NOMINATION(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;






-- 
-- CANDIDATE 
--

CREATE TABLE IF NOT EXISTS CANDIDATE(
    ID VARCHAR(36) PRIMARY KEY,
    FULL_NAME VARCHAR(200),
    PREFERRED_NAME VARCHAR(50),
    NIC VARCHAR(15),
    DATE_OF_BIRTH BIGINT,
    GENDER VARCHAR(5),
    ADDRESS VARCHAR(300),
    OCCUPATION VARCHAR(20),
    ELECTORAL_DIVISION_NAME VARCHAR(50),
    ELECTORAL_DIVISION_CODE VARCHAR(10),
    COUNSIL_NAME VARCHAR(20),
    
    NOMINATION_ID VARCHAR(36),
    FOREIGN KEY(NOMINATION_ID) REFERENCES NOMINATION(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS CANDIDATE_CONFIG(
    ID VARCHAR(36) PRIMARY KEY,
    FULL_NAME BOOLEAN,
    PREFERRED_NAME BOOLEAN,
    NIC BOOLEAN,
    DATE_OF_BIRTH BOOLEAN,
    GENDER BOOLEAN,
    ADDRESS BOOLEAN,
    OCCUPATION BOOLEAN,
    ELECTORAL_DIVISION_NAME BOOLEAN,
    ELECTORAL_DIVISION_CODE BOOLEAN,
    COUNSIL_NAME BOOLEAN,
    
    MODULE_ID VARCHAR(36),
    FOREIGN KEY (MODULE_ID) REFERENCES ELECTION_MODULE(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS CANDIDATE_SUPPORT_DOC(
    ID VARCHAR(36) PRIMARY KEY,
	FILE_PATH VARCHAR(200),
	
	SUPPORT_DOC_CONFIG_DATA_ID VARCHAR(36),
	FOREIGN KEY (SUPPORT_DOC_CONFIG_DATA_ID) REFERENCES SUPPORT_DOC_CONFIG_DATA(SUPPORT_DOC_CONFIG_ID) ON UPDATE CASCADE ON DELETE RESTRICT,
    
    CANDIDATE_ID VARCHAR(36),
    FOREIGN KEY(CANDIDATE_ID) REFERENCES CANDIDATE(ID) ON UPDATE CASCADE ON DELETE RESTRICT
)ENGINE=INNODB;







--
-- Table structure fsor table `USER`
--

DROP TABLE IF EXISTS `USER`;

CREATE TABLE `USER` (
  `ID` VARCHAR(36) NOT NULL,
  `NAME` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`ID`)
)ENGINE=INNODB;

INSERT INTO USER VALUES ('123', 'CLEMENT');




-- 
-- EC-NOMINATION DATA DUMP FOR V2.5.3
-- 

-- USE EC_NOMINATION;


INSERT INTO ELECTION_MODULE 
	(ID, NAME, DIVISION_COMMON_NAME) 
VALUES 
('455cd89e-269b-4b69-96ce-8d7c7bf44ac2', 'parliamentary', 'DISTRICT'),
('7404a229-6274-43d0-b3c5-740c3c2e1256', 'presidential', 'ALL'),
('27757873-ed40-49f7-947b-48b432a1b062', 'provincial', 'PROVINCE');

INSERT INTO SUPPORT_DOC_CONFIG
	(ID, KEY_NAME, DESCRIPTION, DOC_CATEGORY)
VALUES
('59f4d9df-006b-4d7c-82dc-736041e97f37', 'Objection Support Document', 'Submit any type of document related to objection', 'OBJECTION'),
('b20dd58c-e5bb-469d-98c9-8711d6da1879', 'Nomination Form', 'Nomination form with signature', 'NOMINATION'),
('3fac66f2-302c-4d27-b9ae-1d004037a9ba', 'Female Declaration Form', 'Declaration form that denotes the precentage of female representation for the nomination', 'NOMINATION'),
('fe2c2d7e-66de-406a-b887-1143023f8e72', 'NIC', 'National Identification Card', 'CANDIDATE'),
('ff4c6768-bdbe-4a16-b680-5fecb6b1f747', 'Birth Certificate', 'Birth Certification', 'CANDIDATE'),
('15990459-2ea4-413f-b1f7-29a138fd7a97', 'Affidavit', 'Affidavit', 'CANDIDATE');

INSERT INTO SUPPORT_DOC_CONFIG_DATA
	(SUPPORT_DOC_CONFIG_ID, MODULE_ID, SELECT_FLAG)
VALUES
('59f4d9df-006b-4d7c-82dc-736041e97f37', '455cd89e-269b-4b69-96ce-8d7c7bf44ac2', TRUE),
('b20dd58c-e5bb-469d-98c9-8711d6da1879', '455cd89e-269b-4b69-96ce-8d7c7bf44ac2', TRUE),
('fe2c2d7e-66de-406a-b887-1143023f8e72', '455cd89e-269b-4b69-96ce-8d7c7bf44ac2', TRUE),
('ff4c6768-bdbe-4a16-b680-5fecb6b1f747', '455cd89e-269b-4b69-96ce-8d7c7bf44ac2', TRUE),
('15990459-2ea4-413f-b1f7-29a138fd7a97', '455cd89e-269b-4b69-96ce-8d7c7bf44ac2', TRUE);


INSERT INTO ELECTION 
	(ID, NAME, MODULE_ID) 
VALUES 
-- parliamentary
('43680f3e-97ac-4257-b27a-5f3b452da2e6', 'Parliamentary Election 2019', '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),

-- presidentail
('9b85a650-709e-4cdc-83e1-ba4a2ad97cbc', 'Presidentail Election 2020', '7404a229-6274-43d0-b3c5-740c3c2e1256'),

-- provincial
('293d67ea-5898-436d-90d9-27177387be6a', 'Provincial Election 2019', '27757873-ed40-49f7-947b-48b432a1b062');

/*
INSERT INTO ELECTION_APPROVAL 
	(ID, STATUS, CREATED_DATE, CREATED_BY, ELECTION_ID)
VALUES
()
*/


INSERT INTO ELECTION_TIMELINE_CONFIG 
	(ID, KEY_NAME, DESCRIPTION)
VALUES 
('0f62755e-9784-4046-9804-8d4deed36f2a', 'nomination_start_date', 'Start date of Nomination in UNIX TIMESTAMP'),
('c06a789c-405c-4e7a-8df2-66766284589b','nomination_end_date', 'End date of Nomination in UNIX TIMESTAMP'),
('675ec08b-2937-4222-94a6-0143a94763f1', 'objection_start_date', 'Start date of Objection in UNIX TIMESTAMP'),
('64ae3e95-591a-4bf9-8a5b-10803e0eca82','objection_end_date', 'End date of Objection in UNIX TIMESTAMP');

INSERT INTO ELECTION_TIMELINE_CONFIG_DATA 
	(ELECTION_TIMELINE_CONFIG_ID, ELECTION_ID, VALUE)
VALUES
-- parliamentary '43680f3e-97ac-4257-b27a-5f3b452da2e6'
('0f62755e-9784-4046-9804-8d4deed36f2a', '43680f3e-97ac-4257-b27a-5f3b452da2e6', 1546713528),
('c06a789c-405c-4e7a-8df2-66766284589b', '43680f3e-97ac-4257-b27a-5f3b452da2e6', 1548873528),
('675ec08b-2937-4222-94a6-0143a94763f1', '43680f3e-97ac-4257-b27a-5f3b452da2e6', 1549046328),
('64ae3e95-591a-4bf9-8a5b-10803e0eca82', '43680f3e-97ac-4257-b27a-5f3b452da2e6', 1550255928),

-- presidential '9b85a650-709e-4cdc-83e1-ba4a2ad97cbc'
('0f62755e-9784-4046-9804-8d4deed36f2a', '9b85a650-709e-4cdc-83e1-ba4a2ad97cbc', 1581791928),
('c06a789c-405c-4e7a-8df2-66766284589b', '9b85a650-709e-4cdc-83e1-ba4a2ad97cbc', 1585593528),
('675ec08b-2937-4222-94a6-0143a94763f1', '9b85a650-709e-4cdc-83e1-ba4a2ad97cbc', 1585766328),
('64ae3e95-591a-4bf9-8a5b-10803e0eca82', '9b85a650-709e-4cdc-83e1-ba4a2ad97cbc', 1586975928);

INSERT INTO DIVISION_CONFIG 
	(ID, NAME, CODE, NO_OF_CANDIDATES, MODULE_ID) 
VALUES
-- divisions for parliamentary ('455cd89e-269b-4b69-96ce-8d7c7bf44ac2') therefore all possible districts available here..
('65fa860e-2928-4602-9b1e-2a7cb09ea83e', 'Colombo', '1', 22, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('21b9752f-8641-40c3-8205-39a612bf5244', 'Gampaha', '2', 21, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('c9c710e6-cf9c-496c-9b53-2fce36598ea1', 'Kaluthara', '3', 13, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('f15ae97b-8e95-4f38-93d9-fb97fabdcf22', 'Kandy', '4', 15, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('3ab3cf77-a468-41a8-821a-8aa6f38222ad', 'Matale', '5', 08, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('437bd796-597f-4d9e-9b09-874ecded15bf', 'Nuwaraeliya', '6', 11, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('44424777-9888-44cb-90ed-f4742e687ca6', 'Galle', '7', 13, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('e6af28f3-c12e-4202-bc4a-883895db0c4d', 'Matara', '8', 10, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('ea950ed0-525a-4f6e-bb7a-478e36983d90', 'Hambantota', '9', 10, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('7740f20e-363f-4e10-bc1f-a67d2b9cfecd', 'Jaffna', '10', 10, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('561f4c0b-e278-496d-a740-f1dd7c1f4f70', 'Vanni', '11', 09, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('9c1e3ae2-c78b-4f03-8b0c-8d636a36589f', 'Batticaloa', '12', 08, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('682a2b2c-3d78-4fe7-8c25-4c04a7f75328', 'Digamulla', '13', 10, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('1a29913e-3bc4-4a48-a35e-88f8a874e623', 'Trincomalee', '14', 07, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('6541f00c-abf6-4f26-a8b0-a46599fceaeb', 'Kurunegala', '15', 18, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('5aa87f72-90c5-4a4d-8160-be750b15ed7b', 'Puttalam', '16', 11, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('4875b722-fa52-4a6f-a339-ed2fdf86fbcb', 'Anuradhapura', '17', 12, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('bf6d8e67-bb79-41c6-8647-1424ef4d6103', 'Polonnaruwa', '18', 08, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('16ab500d-31b1-4176-bfa3-42e766e9d691', 'Badulla', '19', 11, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('482ddfa5-b6d3-4701-8f17-2e92f9e02774', 'Monaragala', '20', 09, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('9c2a87ca-1a5e-425b-9965-a2b7e469f647', 'Ratnapura', '21', 14, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),
('f0cbfece-4c96-44ac-b493-f10a45753229', 'Kegalle', '22', 12, '455cd89e-269b-4b69-96ce-8d7c7bf44ac2'),

-- divisions for presidential module ('7404a229-6274-43d0-b3c5-740c3c2e1256') therefore there will be only one division as 'all-island'
('f04e4732-83c3-4444-a706-78b3928afd33', 'Island-wide', '00A', 1, '7404a229-6274-43d0-b3c5-740c3c2e1256');

INSERT INTO DIVISION_CONFIG_DATA
	(ELECTION_ID, DIVISION_CONFIG_ID, SELECT_FLAG)
VALUES
-- division approval for 'Parliamentary Election 2019' 
('43680f3e-97ac-4257-b27a-5f3b452da2e6', '65fa860e-2928-4602-9b1e-2a7cb09ea83e', TRUE),
('43680f3e-97ac-4257-b27a-5f3b452da2e6', '21b9752f-8641-40c3-8205-39a612bf5244', TRUE),
('43680f3e-97ac-4257-b27a-5f3b452da2e6', 'c9c710e6-cf9c-496c-9b53-2fce36598ea1', TRUE),
('43680f3e-97ac-4257-b27a-5f3b452da2e6', 'f15ae97b-8e95-4f38-93d9-fb97fabdcf22', TRUE),
('43680f3e-97ac-4257-b27a-5f3b452da2e6', '44424777-9888-44cb-90ed-f4742e687ca6', TRUE),
('43680f3e-97ac-4257-b27a-5f3b452da2e6', '7740f20e-363f-4e10-bc1f-a67d2b9cfecd', TRUE),
('43680f3e-97ac-4257-b27a-5f3b452da2e6', '9c1e3ae2-c78b-4f03-8b0c-8d636a36589f', TRUE),
('43680f3e-97ac-4257-b27a-5f3b452da2e6', '1a29913e-3bc4-4a48-a35e-88f8a874e623', TRUE),
('43680f3e-97ac-4257-b27a-5f3b452da2e6', '16ab500d-31b1-4176-bfa3-42e766e9d691', TRUE),
('43680f3e-97ac-4257-b27a-5f3b452da2e6', 'f0cbfece-4c96-44ac-b493-f10a45753229', FALSE),
('43680f3e-97ac-4257-b27a-5f3b452da2e6', 'ea950ed0-525a-4f6e-bb7a-478e36983d90', FALSE),

-- division approval for 'Presidentail Election 2020'
('9b85a650-709e-4cdc-83e1-ba4a2ad97cbc', 'f04e4732-83c3-4444-a706-78b3928afd33', TRUE);


INSERT INTO NOMINATION_ALLOWED_TEAM
	(ID, SELECT_FLAG, TEAM_ID, DIVISION_ID, ELECTION_ID)
VALUES
-- parliamentary election 2019 / team: '5eedb70e-a4da-48e0-b971-e06cd19ecc70'
('4ae73202-6202-4529-a94b-6e69066b951f', TRUE, '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '65fa860e-2928-4602-9b1e-2a7cb09ea83e', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- colombo
('22f90f10-9da1-4eb0-985a-7ab0f1357c1f', TRUE, '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '21b9752f-8641-40c3-8205-39a612bf5244', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- gampaha
('32daa158-821a-4e82-8a7a-57f9b5a4a7ed', TRUE, '5eedb70e-a4da-48e0-b971-e06cd19ecc70', 'c9c710e6-cf9c-496c-9b53-2fce36598ea1', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- kaluthara
('e3787269-d098-43a9-9a1f-fe122032f2af', FALSE, '5eedb70e-a4da-48e0-b971-e06cd19ecc70', 'f15ae97b-8e95-4f38-93d9-fb97fabdcf22', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- kandy
('8ee18f45-5364-411f-9515-3e1ccdd20085', TRUE, '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '3ab3cf77-a468-41a8-821a-8aa6f38222ad', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- matale
('6b60d7fd-1cd8-4531-a0ae-74ef225e8f5f', TRUE, '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '437bd796-597f-4d9e-9b09-874ecded15bf', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- nuwaraeliya
('b7ee6f99-fb03-4560-a550-a61d72590427', TRUE, '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '44424777-9888-44cb-90ed-f4742e687ca6', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- galle
('af9db0d6-0be6-4ac4-9278-790dc3a18f5c', TRUE, '5eedb70e-a4da-48e0-b971-e06cd19ecc70', 'e6af28f3-c12e-4202-bc4a-883895db0c4d', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- matara
('f1e425d1-499f-448e-9511-39d0bfa2d3c7', TRUE, '5eedb70e-a4da-48e0-b971-e06cd19ecc70', 'ea950ed0-525a-4f6e-bb7a-478e36983d90', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- hambantota
('4bbef7d1-1623-4c57-bba0-f42a310629d5', FALSE, '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '7740f20e-363f-4e10-bc1f-a67d2b9cfecd', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- jaffna
('98e562db-6b83-475d-acad-e6dee611f094', TRUE, '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '561f4c0b-e278-496d-a740-f1dd7c1f4f70', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- vanni

-- parliamentary election 2019 / team: '7404a229-6274-43d0-b3c5-740c3c2e1256'
('65bb2670-23eb-45a9-9f19-2ba25c94c850', TRUE, '7404a229-6274-43d0-b3c5-740c3c2e1256', '65fa860e-2928-4602-9b1e-2a7cb09ea83e', '43680f3e-97ac-4257-b27a-5f3b452da2e6'), -- colombo
('eb8b4ffe-1fdf-4c79-978e-4adcc6b79b1b', TRUE, '7404a229-6274-43d0-b3c5-740c3c2e1256', '21b9752f-8641-40c3-8205-39a612bf5244', '43680f3e-97ac-4257-b27a-5f3b452da2e6'); -- gampaha



INSERT INTO NOMINATION
	(ID, STATUS, TEAM_ID, ELECTION_ID, DIVISION_CONFIG_DATA_ID)
VALUES
-- nominations for parlimentary election and team ('5eedb70e-a4da-48e0-b971-e06cd19ecc70')
('135183e2-a0ca-44a0-9577-0d2b16c3217f', 'APPROVE', '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '43680f3e-97ac-4257-b27a-5f3b452da2e6', '65fa860e-2928-4602-9b1e-2a7cb09ea83e'),
('416e0c20-b274-4cf2-9531-8167d2f35bf7', 'DRAFT', '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '43680f3e-97ac-4257-b27a-5f3b452da2e6', '21b9752f-8641-40c3-8205-39a612bf5244'),
('a0e4a9c9-4841-45df-9600-f7a607400ab6', 'APPROVE', '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '43680f3e-97ac-4257-b27a-5f3b452da2e6', 'c9c710e6-cf9c-496c-9b53-2fce36598ea1'),
('ed7e455c-eb95-4ccc-b090-32c1616c6d0c', 'REJECT', '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '43680f3e-97ac-4257-b27a-5f3b452da2e6', 'f15ae97b-8e95-4f38-93d9-fb97fabdcf22'),
('c1313d6d-bac3-48f6-afd7-ce7899f1714a', 'APPROVE', '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '43680f3e-97ac-4257-b27a-5f3b452da2e6', '7740f20e-363f-4e10-bc1f-a67d2b9cfecd'),
('07d4d5d9-fd83-473f-836c-a5a565d75ed1', 'APPROVE', '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '43680f3e-97ac-4257-b27a-5f3b452da2e6', '1a29913e-3bc4-4a48-a35e-88f8a874e623'),
('358f0d3c-5632-4046-9abb-f0aeab5bfe9e', 'APPROVE', '62fcdfa7-3c5a-405f-b344-79089131dd8e', '43680f3e-97ac-4257-b27a-5f3b452da2e6', '16ab500d-31b1-4176-bfa3-42e766e9d691'),

-- nominations for presidential election and 2 teams
('6fb66fbb-acd2-4b2e-94ac-12bee6468f5f', 'APPROVE', '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '9b85a650-709e-4cdc-83e1-ba4a2ad97cbc', 'f04e4732-83c3-4444-a706-78b3928afd33'),
('ad78d32d-dd5a-41ac-a410-aa8500c04102', 'APPROVE', '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '9b85a650-709e-4cdc-83e1-ba4a2ad97cbc', 'f04e4732-83c3-4444-a706-78b3928afd33'),
('7db3d4ba-c8a0-4340-8d6e-2d9096de7d2e', 'DRAFT', '62fcdfa7-3c5a-405f-b344-79089131dd8e', '9b85a650-709e-4cdc-83e1-ba4a2ad97cbc', 'f04e4732-83c3-4444-a706-78b3928afd33');

INSERT INTO OBJECTION
	(ID, DESCRIPTION, CREATE_DATE, CREATE_BY, CREATE_BY_TEAM_ID, NOMINATION_ID)
VALUES
-- objections for praliamentary election nominations
('417c0d5d-d417-4333-b334-56d40f725c8a', 'Objection Description 1', 1550342328, 'UsernameFromIS-1', '62fcdfa7-3c5a-405f-b344-79089131dd8e', '135183e2-a0ca-44a0-9577-0d2b16c3217f'),
('1ecbc3f5-7802-483b-9ff4-61dd4cbc7e91', 'Objection Description 2', 1550428728, 'UsernameFromIS-1', '62fcdfa7-3c5a-405f-b344-79089131dd8e', 'a0e4a9c9-4841-45df-9600-f7a607400ab6'),
('36f6062e-356a-4d14-84c6-2da68c962287', 'Objection Description 3', 1587148728, 'UsernameFromIS-3', '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '358f0d3c-5632-4046-9abb-f0aeab5bfe9e'),
('e0093c7d-8636-4467-931c-1fbc4f2053b8', 'Objection Description 5', 1550428728, 'UsernameFromIS-1', '62fcdfa7-3c5a-405f-b344-79089131dd8e', 'ed7e455c-eb95-4ccc-b090-32c1616c6d0c'),

-- objections for presidential election nominations
('4ebac898-0e6f-11e9-ab14-d663bd873d93', 'Objection Description 4', 1550428728, 'UsernameFromIS-1', '62fcdfa7-3c5a-405f-b344-79089131dd8e', 'ad78d32d-dd5a-41ac-a410-aa8500c04102'),
('27a74411-ed86-484b-9904-7146183135dc', 'Objection Description 6', 1587235128, 'UsernameFromIS-4', '5eedb70e-a4da-48e0-b971-e06cd19ecc70', '7db3d4ba-c8a0-4340-8d6e-2d9096de7d2e');

INSERT INTO OBJECTION_REVIEW
	(ID, CREATE_BY, CREATE_DATE, NOTE, OBJECTION_ID)
VALUES
('2f3ea8b3-a21e-497f-ab91-8e9eafdcd922', 'UsernameFromIS-EC-Admin1', 1550428728, 'this is a review note.', '417c0d5d-d417-4333-b334-56d40f725c8a' ),
('7048cc45-6dab-44aa-818f-5030a93daa26', 'UsernameFromIS-EC-Admin1', 1550428728, 'this is a review note.', '1ecbc3f5-7802-483b-9ff4-61dd4cbc7e91' );

INSERT INTO OBJECTION_SUPPORT_DOC
	(ID, FILE_PATH, SUPPORT_DOC_CONFIG_DATA_ID, OBJECTION_ID)
VALUES
('999af464-ac5a-4b48-bdbc-fcea2840bf5b', 'url/resource/to/file/server/file1.pdf', '59f4d9df-006b-4d7c-82dc-736041e97f37', '417c0d5d-d417-4333-b334-56d40f725c8a' ),
('bce0ba43-1098-4570-953a-81cb09e27d55', 'url/resource/to/file/server/file2.pdf', '59f4d9df-006b-4d7c-82dc-736041e97f37', '417c0d5d-d417-4333-b334-56d40f725c8a' ),
('03d71aee-880b-4898-b04f-da21f8f095bb', 'url/resource/to/file/server/file3.pdf', '59f4d9df-006b-4d7c-82dc-736041e97f37', '36f6062e-356a-4d14-84c6-2da68c962287' ),
('7d70a34f-bce6-4a29-a693-c1ace2075a81', 'url/resource/to/file/server/file4.pdf', '59f4d9df-006b-4d7c-82dc-736041e97f37', '27a74411-ed86-484b-9904-7146183135dc' );










