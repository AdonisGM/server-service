create or replace PACKAGE PKG_MGT_QUESTION AS

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Get all question in module
-----------------------------------------
procedure get_all_question_in_module(
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
);

END PKG_MGT_QUESTION;
/

create or replace PACKAGE BODY PKG_MGT_QUESTION AS

-----------------------------------------
-- author:	Adonis Willer
-- date:	12/02/2023
-- desc:	Get all question in module
-----------------------------------------
procedure get_all_question_in_module(
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
) as 
    v_str_pk_module     varchar2(50);

    v_int_begin         number;
    v_int_step          number;
    v_int_total         number; 
BEGIN
    v_str_pk_module     := p_data.get_string('pk_module');

    v_int_begin         := p_data.get_number('begin');
    v_int_step          := p_data.get_number('step');

    select count(1) into v_int_total 
    from t_mgt_module_question
    where fk_mgt_module = v_str_pk_module;

    open p_table_cursor for
    select 
        v_int_total as total,
        c.*
    from (
        select rownum as row_number, b.*
        from (
            select *
            from t_mgt_module_question
            where fk_mgt_module = v_str_pk_module
            order by pk_mgt_module_question
        ) b
    ) c
    where row_number between v_int_begin and v_int_begin + v_int_step - 1;
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	Create question and answer
-----------------------------------------
procedure create_question_and_answer(
    p_user          varchar2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  out     pkg_common.table_cursor
) as
    v_str_pk_module     varchar2(50);
    v_str_question      JSON_ARRAY_T;
    v_str_question_type varchar2(50);

    v_arr_answer        JSON_ARRAY_T;
    v_str_answer        varchar2(500);
    v_int_answer_order  number;
BEGIN
    v_str_pk_module     := p_data.get_string('pkModule');
    v_str_question

    case v_str_question_type
        when '1' then 

        when '2' then 

        when '3' then 

    end case;
end;

END PKG_MGT_QUESTION;