create or replace PACKAGE PKG_COMMON AS 

    TYPE table_cursor IS REF CURSOR;
    
    function get_default_table_cursor return table_cursor;
    
    procedure raise_error (
        p_message varchar2
    );

    procedure raise_error_code (
        p_code varchar2
    );
    
    procedure create_api_logger (
        p_user      varchar2,
        p_data      varchar2,
        p_cmd       varchar2,
        p_error     varchar2
    );
    
    function split_string (
        p_string        varchar2,
        p_spliter       varchar2
    ) return table_cursor;

END PKG_COMMON;
/

create or replace PACKAGE BODY PKG_COMMON AS

    function get_default_table_cursor return table_cursor AS
        v_result        table_cursor;
    BEGIN
        open v_result for
            select 1 as result from dual; 
            
        return v_result;
    END get_default_table_cursor;
     
    procedure raise_error (
        p_message varchar2
    ) AS 
    
    BEGIN
        raise_application_error(-20999, p_message);
    END raise_error;
    
    procedure create_api_logger (
        p_user      varchar2,
        p_data      varchar2,
        p_cmd       varchar2,
        p_error     varchar2
    ) AS 
    
    BEGIN
        insert into t_api_logger (pk_api_logger, c_user, c_data, c_cmd, c_error, c_created_date)
        values (sys_guid(), p_user, p_data, p_cmd, p_error, sysdate);
    END create_api_logger;
    
    function split_string (
        p_string        varchar2,
        p_spliter       varchar2
    ) return table_cursor
    as 
        v_table_cursor  table_cursor;
    begin
        open v_table_cursor for
            SELECT trim(regexp_substr(str, '[^' || p_spliter || ']+', 1, LEVEL)) str_item
            FROM (SELECT p_string str FROM dual)
            CONNECT BY instr(str, p_spliter, 1, LEVEL - 1) > 0;
        return v_table_cursor;
    end split_string;

    function raise_error_code (
        p_code    varchar2,
    ) AS 
        v_str_res               varchar2(2000);
        v_cur_api_error_code    t_api_error_code%rowtype;
        
        v_int_check             integer;
    BEGIN
        select count(1) into v_int_check
        from t_api_error_code
        where c_code = p_code;

        if (v_int_check = 0) THEN
            raise_application_error(-20999, p_message);
        end if;

        select * into v_cur_api_error_code
        from t_api_error_code
        where c_code = p_code;

        v_str_res := '[' || v_cur_api_error_code.c_code || '-' || sys_guid() || ']:::[' || v_cur_api_error_code.c_type || ']:::[' || v_cur_api_error_code.c_description || ']';

        raise_application_error(-20999, v_str_res);
    END raise_error;
END PKG_COMMON;