create or replace PACKAGE PKG_DIARY AS 

    procedure get_info (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );
    
    procedure add_post (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );
    
    procedure get_all (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );
    
    procedure get_single (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );
    
    procedure archive_post (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );
    
    procedure delete_post (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );

    procedure get_all_key (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );
END PKG_DIARY;
/

create or replace PACKAGE BODY       PKG_DIARY AS

    procedure get_info (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as 
        v_count         number;

        v_username      varchar2(100);   
        v_number_view   number;     
    begin
        v_username  :=  trim(p_data.get_string('username'));
    
        select count(1) into v_count
        from t_user where c_username = v_username;

        if (v_count = 0) then 
            pkg_common.raise_error('Không tồn tại');
        end if;

        select count(1) into v_count
        from t_diary_info where c_username = v_username;

        if (v_count = 0) then 
            insert into t_diary_info (pk_diary_info, c_username, c_number_post, c_number_view)
            values (sys_guid(), v_username, 0, 1);
        else 
            select c_number_view into v_number_view
            from t_diary_info
            where c_username = v_username;
            
            if (v_username != p_user) then
                v_number_view := v_number_view + 1;
            end if;

            update t_diary_info set c_number_view = v_number_view where c_username = v_username;
        end if;

        open p_table_cursor for
            select 
                u.c_fullname,
                u.c_username,
                u.c_is_admin,
                i.C_NUMBER_POST,
                i.C_NUMBER_VIEW
            from t_diary_info i
            left join t_user u
                on i.c_username = u.c_username
            where i.c_username = v_username;
    end get_info;

    procedure add_post (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as 
        v_count         number;

        v_title         varchar2(200);
        v_content       varchar2(20000);
        v_status        varchar2(50);
        v_fingerprint   varchar2(200);
        v_counter       varchar2(100);
        
        v_pk_diary_post varchar2(50);
    begin
        v_title         := p_data.get_string('title');
        v_content       := p_data.get_string('content');
        v_status        := p_data.get_string('status');
        v_fingerprint   := p_data.get_string('fingerprint');
        v_counter       := p_data.get_string('counter');

        if (v_title is null or v_content is null) then 
            pkg_common.raise_error('Nội dung và chủ đề là bắt buộc');
        end if;

        if (v_status not in ('PUBLIC', 'PRIVATE')) then 
            v_status := 'PRIVATE';
        end if;

        if (v_status = 'PRIVATE' and (v_fingerprint is null or v_counter is null)) then
            pkg_common.raise_error('Fingerprint là bắt buộc với trạng thái là PRIVATE');
        end if;
        
        v_pk_diary_post := sys_guid();

        insert into t_diary_post (PK_DIARY_POST, C_USERNAME, C_TITLE, C_CONTENT, C_STATUS, C_fingerprint, c_counter)
        values (v_pk_diary_post, p_user, v_title, v_content, v_status, v_fingerprint, v_counter);
        
        update t_diary_info
        set c_number_post = c_number_post + 1
        where p_user = c_username;
        
        if (v_status = 'PRIVATE') then 
            select count(1) into v_count
            from t_diary_key
            where c_fingerprint = v_fingerprint
                and c_username = p_user;
                
            if (v_count = 0) then 
                insert into t_diary_key (pk_diary_key, c_fingerprint, c_username)
                values (sys_guid(), v_fingerprint, p_user);
            end if;
        end if;

        open p_table_cursor for
            select v_pk_diary_post pk_diary_post from dual;
    end add_post;

    procedure get_all (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as 
        v_username      varchar2(100);

        v_start         number;
        v_to            number;

        v_list_fingerprint  varchar2(10000);
    begin
        v_username          := p_data.get_string('username');
        v_list_fingerprint  := p_data.get_string('listFingerprints');

        v_start     := p_data.get_number('start');
        v_to        := p_data.get_number('to');

        open p_table_cursor for
            select *
            from (
                select 
                    rownum stt,
                    p.pk_diary_post, 
                    p.c_username, 
                    p.c_title, 
                    p.c_content, 
                    p.c_status, 
                    p.c_fingerprint,
                    p.c_counter,
                    p.c_created_date
                from t_diary_post p
                where p.c_username = v_username
                    and (p.c_fingerprint is null or (v_list_fingerprint like '%' || p.c_fingerprint || '%'))
                    and (p_user = v_username or (p.c_status = 'PUBLIC'))
                    and p.c_is_archive = 0
                order by c_created_date desc
            ) x
            where x.stt > v_start and x.stt <= v_to;
    end get_all; 
    
    procedure get_single (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as 
        v_pk_diary_post     varchar2(50);
        v_username          varchar2(200);
        v_list_fingerprint  varchar2(10000);
    begin
        v_pk_diary_post     :=  p_data.get_string('pk_diary_post');
        v_username          :=  p_data.get_string('username');
        v_list_fingerprint  := p_data.get_string('listFingerprints');
        
        open p_table_cursor for
            select 
                rownum stt,
                p.pk_diary_post, 
                p.c_username, 
                p.c_title, 
                p.c_content, 
                p.c_status, 
                p.c_fingerprint,
                p.c_counter,
                p.c_created_date
            from t_diary_post p
            where p.c_username = v_username
                and (v_username = p_user or c_status = 'public')
                and (p.c_fingerprint is null or (v_list_fingerprint like '%' || p.c_fingerprint || '%'))
                and (p_user = v_username or (p.c_status = 'PUBLIC' and p.c_created_date + interval '5' minute < sysdate))
                and p.c_is_archive = 0;
    end get_single;
    
    procedure archive_post (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as
        v_pk_diary_post varchar2(50);
        
        v_count         number;
    begin
        v_pk_diary_post :=  p_data.get_string('pk_diary_post');
        
        select count(1) into v_count
        from t_diary_post
        where c_username = p_user
            and pk_diary_post = v_pk_diary_post;
            
        if (v_count = 0) then 
            pkg_common.raise_error('Nhật ký không tồn tại');
        end if;
        
        update t_diary_post
        set c_is_archive = (
            case when c_is_archive = 1 then 0 else 1 end
        )
        where c_username = p_user
            and pk_diary_post = v_pk_diary_post;
            
        open p_table_cursor for
            select * from dual;
    end archive_post;
    
    procedure delete_post (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as
        v_pk_diary_post varchar2(50);
        
        v_count         number;
    begin
        v_pk_diary_post :=  p_data.get_string('pk_diary_post');
        
        select count(1) into v_count
        from t_diary_post
        where c_username = p_user
            and pk_diary_post = v_pk_diary_post
            and c_is_archive = 1;
            
        if (v_count = 0) then 
            pkg_common.raise_error('Nhật ký không tồn tại hoặc phải thu hồi trước');
        end if;
        
        delete t_diary_post
        where c_username = p_user
            and pk_diary_post = v_pk_diary_post
            and c_is_archive = 1;
            
        update t_diary_info
        set c_number_post = c_number_post - 1
        where c_username = p_user;
        
        open p_table_cursor for
            select * from dual;
    end delete_post;
    
    procedure get_all_key (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as
    
    begin
        open p_table_cursor for
            select 
                *
            from t_diary_key
            where c_username = p_user;
    end get_all_key;
END PKG_DIARY;