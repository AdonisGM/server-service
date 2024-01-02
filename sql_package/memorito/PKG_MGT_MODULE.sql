create or replace PACKAGE PKG_MGT_MODULE AS 

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Get all modules 
-----------------------------------------
procedure get_all_modules(
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Get single module 
-----------------------------------------
procedure get_single_modules(
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Update or create module
-----------------------------------------
procedure update_modules(
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Delete module
-----------------------------------------
procedure delete_modules(
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
);

END PKG_MGT_MODULE;
/

create or replace PACKAGE BODY PKG_MGT_MODULE AS 

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Get all modules 
-----------------------------------------
procedure get_all_modules(
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
) as
    v_str_module_name   varchar2(100);

    v_int_begin         number;
    v_int_step          number;
    v_int_total         number;
BEGIN
    v_str_module_name   := upper(p_data.get_string('module_name'));

    v_int_begin := p_data.get_number('begin');
    v_int_step  := p_data.get_number('step');

    select count(1) into v_int_total
    from t_mgt_module
    where c_username = p_user
        and (v_str_module_name is null or upper(c_module_name) like '%' || v_str_module_name || '%');

    open p_table_cursor for
        select 
            v_int_total as total,
            c.*
        from (
            select rownum as row_number, b.*
            from (
                select *
                from t_mgt_module
                where c_username = p_user
                    and (v_str_module_name is null or upper(c_module_name) like '%' || v_str_module_name || '%')
                order by c_created_date desc
            ) b
        ) c
        where c.row_number between v_int_begin and v_int_begin + v_int_step - 1;
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Get single modules 
-----------------------------------------
procedure get_single_modules(
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
) as 
    v_str_pk        varchar2(50);

    v_int_check     number;
BEGIN
    v_str_pk := p_data.get_string('pk');

    select count(1) into v_int_check
    from t_mgt_module
    where c_username = p_user
        and pk_mgt_module = v_str_pk;

    if v_int_check = 0 then
        pkg_common.raise_error_code('ERR_MGT_4_00000002');
    end if;

    open p_table_cursor for
        select *
        from t_mgt_module
        where c_username = p_user
            and pk_mgt_module = v_str_pk;
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Update or create module
-----------------------------------------
procedure update_modules(
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
) AS
    v_str_pk            varchar2(50);
    v_str_module_name   varchar2(100);
    v_str_module_desc   varchar2(1000);

    v_int_check         integer;
BEGIN
    v_str_pk            := p_data.get_string('pk');
    v_str_module_name   := p_data.get_string('module_name');
    v_str_module_desc   := p_data.get_string('module_desc');

    if (v_str_module_name is null or v_str_module_desc is null) then 
        pkg_common.raise_error_code('ERR_MGT_4_00000003');
    end if;

    if v_str_pk is null then
        insert into t_mgt_module(
            pk_mgt_module,
            c_username,
            c_module_name,
            c_module_desc,
            c_created_date,
            c_created_by
        ) values (
            sys_guid(),
            p_user,
            v_str_module_name,
            v_str_module_desc,
            sysdate,
            p_user
        );
    else
        select count(1) into v_int_check
        from t_mgt_module
        where c_username = p_user
            and pk_mgt_module = v_str_pk;

        if v_int_check = 0 then
            pkg_common.raise_error_code('ERR_MGT_4_00000002');
        end if;

        update t_mgt_module
        set c_module_name = v_str_module_name,
            c_module_desc = v_str_module_desc,
            c_updated_date = sysdate,
            c_updated_by = p_user
        where c_username = p_user
            and pk_mgt_module = v_str_pk;
    end if;
END;

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Delete module
-----------------------------------------
procedure delete_modules(
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
) AS
    v_str_pk            varchar2(50);
    v_int_check         integer;

    v_tbl_question      pkg_common.table_cursor;
BEGIN
    v_str_pk := p_data.get_string('pk');

    select count(1) into v_int_check
    from t_mgt_module
    where c_username = p_user
        and pk_mgt_module = v_str_pk;

    if v_int_check = 0 then
        pkg_common.raise_error_code('ERR_MGT_4_00000002');
    end if;

    delete from t_mgt_module
    where c_username = p_user
        and pk_mgt_module = v_str_pk;

    open v_tbl_question for
        select pk_mgt_module_question
        from t_mgt_module_question
        where fk_mgt_module = v_str_pk;
    
    loop
        fetch v_tbl_question into v_str_pk;
        exit when v_tbl_question%notfound;

        delete from t_mgt_module_question
        where pk_mgt_module_question = v_str_pk;

        delete from t_mgt_module_answer
        where fk_mgt_module_question = v_str_pk;
    end loop;

    close v_tbl_question;
END;

END PKG_MGT_MODULE;
/