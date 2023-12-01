create or replace PACKAGE PKG_MGT_INFO AS 

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Get information user 
-----------------------------------------
procedure get_user_info (
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
);

END PKG_MGT_INFO;
/

CREATE OR REPLACE PACKAGE BODY PKG_MGT_INFO AS 

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Get information user 
-----------------------------------------
procedure get_user_info (
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
) as 
    v_str_username      varchar2(50);

    v_int_check         integer;
BEGIN
    -- Get data from json body
    v_str_username := p_data.get_string('username');

    -- Check exist user
    select count(1) into v_int_check
    from t_mgt_user
    where c_username = v_str_username;
    if (v_int_check = 0) THEN
        pkg_common.raise_error_code('ERR_MGT_4_00000001');
    end if;

    open p_table_cursor for
        select  
            t2.C_USERNAME,
            t2.C_FULLNAME,
            t2.C_EMAIL
        from t_mgt_info t1
        left join t_user t2
            on t1.c_username = t2.c_username
        where t2.c_username = v_str_username;
END;

END PKG_MGT_INFO;