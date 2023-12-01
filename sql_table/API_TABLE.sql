-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Storing the error code
-----------------------------------------
create table t_api_error_code (
    pk_api_error_code       varchar2(50)    not null    default sys_guid(),
    c_code                  varchar2(50)    not null,
    c_type                  varchar2(50)    null,
    c_description           varchar2(200)   null,

    constraint pk_t_api_error_code primary key (pk_api_error_code)
);
/

-----------------------------------------
insert into t_api_error_code (c_code, c_type, c_description) values ('ERR_MGT_4_00000001', 'NOT_FOUND', 'User not found');
insert into t_api_error_code (c_code, c_type, c_description) values ('ERR_MGT_4_00000002', 'NOT_FOUND', 'Moudle not found');
insert into t_api_error_code (c_code, c_type, c_description) values ('ERR_MGT_4_00000003', 'VALIDATION', 'module_name and module_desc are required');
