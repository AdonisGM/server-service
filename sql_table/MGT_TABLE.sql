-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Storing the information user of subwebs Memorito
-----------------------------------------
create table t_MGT_INFO(
	pk_mgt_info				varchar2(50)	not null,
	c_username				varchar2(50)	not null,

	constraint pk_mgt_info primary key (pk_mgt_info)
);
/

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Storing the information module
-----------------------------------------
create table t_MGT_MODULE(
	pk_mgt_module			varchar2(50)	not null,
	c_username				varchar2(50)	not null,

	c_module_name			varchar2(100)	not null,
	c_module_desc			varchar2(1000)	not null,

	c_created_date			date			not null,
	c_created_by			varchar2(50)	not null,
	c_updated_date			date			null,
	c_updated_by			varchar2(50)	null,

	constraint pk_mgt_module primary key (pk_mgt_module)
);
/

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Storing the information question
-----------------------------------------
create table t_MGT_MODULE_QUESTION(
	pk_mgt_module_question	varchar2(50)	not null,
	fk_mgt_module			varchar2(50)	not null,

	c_question_value		varchar2(500)	not null,
	c_question_type			varchar2(50)	not null,
	c_question_answer		varchar2(50)	not null,
	c_question_order		number(10)		not null,

	c_created_date			date			not null,
	c_created_by			varchar2(50)	not null,
	c_updated_date			date			null,
	c_updated_by			varchar2(50)	null,

	constraint pk_mgt_module_question primary key (pk_mgt_module_question)
);
/

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Storing the information answer
-----------------------------------------
create table t_MGT_MODULE_ANSWER(
	pk_mgt_module_answer	varchar2(50)	not null,
	fk_mgt_module_question	varchar2(50)	not null,

	c_answer_value			varchar2(500)	not null,
	c_answer_order			number(10)		not null,

	c_created_date			date			not null,
	c_created_by			varchar2(50)	not null,
	c_updated_date			date			null,
	c_updated_by			varchar2(50)	null,

	constraint pk_mgt_module_answer primary key (pk_mgt_module_answer)
);
/