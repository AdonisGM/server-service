-- Table T_BUD_INFO
CREATE TABLE T_BUD_INFO (
	PK_BUD_INFO			VARCHAR2(50)	DEFAULT sys_guid() NOT NULL,
	C_USERNAME			VARCHAR2(50)	NOT NULL,

	C_CREATED_DATE		DATE			NOT NULL,
	C_CREATED_BY		VARCHAR2(50)	NOT NULL,
	C_UPDATED_DATE		DATE			NULL,
	C_UPDATED_BY		VARCHAR2(50)	NULL,

	CONSTRAINT T_BUD_INFO_PK PRIMARY KEY 
	(
		PK_BUD_INFO 
	)
	ENABLE 
);

CREATE UNIQUE INDEX IX_BUD_INFO_USERNAME ON T_BUD_INFO(C_USERNAME);

--  Table T_BUD_HOLDER
CREATE TABLE T_BUD_HOLDER (
	PK_BUD_HOLDER		VARCHAR2(50) 	DEFAULT sys_guid() NOT NULL,
	C_USERNAME			VARCHAR2(50)	NOT NULL,
	C_HOLDER_NAME		VARCHAR2(200)	NOT NULL,
	C_HOLDER_USERNAME	VARCHAR2(50)	NULL,
	C_CASH_BALANCE		NUMBER(20, 0)	DEFAULT	0 NOT NULL,
	C_NOTE				VARCHAR2(2000)	NULL,

	C_CREATED_DATE		DATE			NOT NULL,
	C_CREATED_BY		VARCHAR2(50)	NOT NULL,
	C_UPDATED_DATE		DATE			NULL,
	C_UPDATED_BY		VARCHAR2(50)	NULL,

	CONSTRAINT T_BUD_HOLDER_PK PRIMARY KEY 
	(
		PK_BUD_HOLDER 
	)
	ENABLE 
);

CREATE INDEX IX_BUD_HOLDER__USERNAME ON T_BUD_HOLDER(C_USERNAME);
CREATE INDEX IX_BUD_HOLDER__HOLDER_USERNAME ON T_BUD_HOLDER(C_HOLDER_USERNAME);

-- Table T_BUD_MANAGEMENT
CREATE TABLE T_BUD_MANAGEMENT (
	PK_BUD_MANAGEMENT	VARCHAR2(50)	DEFAULT sys_guid() NOT NULL,
	FK_BUD_HOLDER		VARCHAR2(50)	NOT NULL,
	C_USERNAME			VARCHAR2(50)	NOT NULL,
	C_TYPE				VARCHAR2(50)	NOT NULL,
	C_CASH_VALUE		NUMBER(20, 0)	DEFAULT 0	NOT NULL,
	C_CASH_RETURN		NUMBER(20, 0)	DEFAULT 0	NOT NULL,
	C_NOTE				VARCHAR2(2000)	NULL,
	c_IS_INSTALLMENT	NUMBER(1, 0)	DEFAULT 0	NOT NULL,

	C_CREATED_DATE		DATE			NOT NULL,
	C_CREATED_BY		VARCHAR2(50)	NOT NULL,
	C_UPDATED_DATE		DATE			NULL,
	C_UPDATED_BY		VARCHAR2(50)	NULL,

	CONSTRAINT T_BUD_MANAGEMENT_PK PRIMARY KEY 
	(
		PK_BUD_MANAGEMENT 
	)
	ENABLE 
);

CREATE INDEX IX_BUD_MANAGEMENT__BUD_HOLDER ON T_BUD_MANAGEMENT(FK_BUD_HOLDER);
CREATE INDEX IX_BUD_MANAGEMENT__USERNAME ON T_BUD_MANAGEMENT(C_USERNAME);
CREATE INDEX IX_BUD_MANAGEMENT__TYPE ON T_BUD_MANAGEMENT(C_TYPE);

-- Table T_BUD_TRANS
CREATE TABLE T_BUD_TRANS (
	PK_BUD_TRANS		VARCHAR2(50)	DEFAULT sys_guid() NOT NULL,
	FK_BUD_MANAGEMENT	VARCHAR2(50)	NOT NULL,
	C_USERNAME			VARCHAR2(50)	NOT NULL,
	C_TYPE				VARCHAR2(50)	NOT NULL,
	C_SUB_TYPE			VARCHAR2(50)	NOT NULL,
	C_CASH_IN			NUMBER(20, 0)	DEFAULT 0	NOT NULL,
	C_CASH_OUT			NUMBER(20, 0)	DEFAULT 0	NOT NULL,
	C_NOTE				VARCHAR2(2000)	NULL,

	C_CREATED_DATE		DATE			NOT NULL,
	C_CREATED_BY		VARCHAR2(50)	NOT NULL,
	C_UPDATED_DATE		DATE			NULL,
	C_UPDATED_BY		VARCHAR2(50)	NULL,

	CONSTRAINT T_BUD_TRANS_PK PRIMARY KEY 
	(
		PK_BUD_TRANS 
	)
	ENABLE 
);

CREATE INDEX IX_BUD_TRANS__BUD_MANAGEMENT ON T_BUD_TRANS(FK_BUD_MANAGEMENT);
CREATE INDEX IX_BUD_TRANS__USERNAME ON T_BUD_TRANS(C_USERNAME);
CREATE INDEX IX_BUD_TRANS__TYPE ON T_BUD_TRANS(C_TYPE);
CREATE INDEX IX_BUD_TRANS__SUB_TYPE ON T_BUD_TRANS(C_SUB_TYPE);
