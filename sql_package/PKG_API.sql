create or replace PACKAGE PKG_API AS 

    PROCEDURE main_api (
        p_user      varchar2,
        p_cmd       varchar2,
        P_data      JSON_OBJECT_T,
        p_result    out     pkg_common.table_cursor 
    );
    
END PKG_API;
/

create or replace PACKAGE BODY PKG_API AS

    PROCEDURE main_api (
        p_user      varchar2,
        p_cmd       varchar2,
        p_data      JSON_OBJECT_T,
        p_result    out     pkg_common.table_cursor 
    ) as
        v_message   varchar2(4000);
        v_obj       JSON_OBJECT_T;
        
        v_count     number;
    begin
        -- set default result;
        p_result := pkg_common.get_default_table_cursor(); 
    
        v_obj := JSON_OBJECT_T.parse(p_data);
        
        case p_cmd
            when 'pkg_user.create_user' then                pkg_user.create_user(p_user, v_obj, p_result); 
            when 'pkg_user.get_refresh_token' then          pkg_user.get_refresh_token(p_user, v_obj, p_result); 
            when 'pkg_user.create_refresh_token' then       pkg_user.create_refresh_token(p_user, v_obj, p_result);
            when 'pkg_user.get_info_login' then             pkg_user.get_info_login(p_user, v_obj, p_result);
            when 'pkg_user.get_info' then                   pkg_user.get_info(p_user, v_obj, p_result);
            
            -- BUDGOOSE Website            
            when 'pkg_loan.create_holder' then              pkg_loan.create_holder(p_user, v_obj, p_result); 
            when 'pkg_loan.get_all_holder' then             pkg_loan.get_all_holder(p_user, v_obj, p_result); 
            when 'pkg_loan.get_detail_holder' then          pkg_loan.get_detail_holder(p_user, v_obj, p_result); 
            when 'pkg_loan.update_holder' then              pkg_loan.update_holder(p_user, v_obj, p_result);
                
            when 'pkg_loan_trans.create_trans' then         pkg_loan_trans.create_trans(p_user, v_obj, p_result); 
            when 'pkg_loan_trans.delete_trans' then         pkg_loan_trans.delete_trans(p_user, v_obj, p_result); 
            when 'pkg_loan_trans.get_all_trans' then        pkg_loan_trans.get_all_trans(p_user, v_obj, p_result); 
            when 'pkg_loan_trans.get_detail_trans' then     pkg_loan_trans.get_detail_trans(p_user, v_obj, p_result); 
            when 'pkg_loan_trans.update_trans' then         pkg_loan_trans.update_trans(p_user, v_obj, p_result); 
            
            -- DIARY Website
            when 'pkg_diary.get_info' then                  pkg_diary.get_info(p_user, v_obj, p_result);
            when 'pkg_diary.add_post' then                  pkg_diary.add_post(p_user, v_obj, p_result);
            when 'pkg_diary.get_all' then                   pkg_diary.get_all(p_user, v_obj, p_result);
            when 'pkg_diary.get_single' then                pkg_diary.get_single(p_user, v_obj, p_result);
            when 'pkg_diary.archive_post' then              pkg_diary.archive_post(p_user, v_obj, p_result);
            when 'pkg_diary.delete_post' then               pkg_diary.delete_post(p_user, v_obj, p_result);
            when 'pkg_diary.get_all_key' then               pkg_diary.get_all_key(p_user, v_obj, p_result);
                
            else pkg_common.raise_error('Không tồn tại service này');
        end case;
        
        v_message := SQLERRM();
        pkg_common.create_api_logger(p_user, p_data, p_cmd, v_message);
        
        commit;
        
        EXCEPTION 
            WHEN OTHERS 
            THEN 
                v_message := SQLERRM();
                pkg_common.create_api_logger(p_user, p_data, p_cmd, v_message);
                open p_result for
                    select v_message as message_error from dual;
    end main_api;
END PKG_API;