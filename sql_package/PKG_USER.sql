create or replace PACKAGE PKG_USER AS 

    procedure create_user (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );
    
    procedure create_refresh_token (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );
    
    procedure get_refresh_token (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );
    
    procedure get_info_login (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );
    
    procedure get_info (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    );

END PKG_USER;
/

create or replace PACKAGE BODY PKG_USER AS

    procedure create_user (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as
        v_username          varchar2(200);
        v_fullname          varchar2(200);
        v_email             varchar2(200);
        v_password          varchar2(200);
        
        v_count             number;
    begin
        v_username := p_data.get_string('username');
        v_fullname := p_data.get_string('fullname');
        v_email := p_data.get_string('email');
        v_password := p_data.get_string('password');
        
        if (v_username is null or 
            v_fullname is null or 
            v_email is null or 
            v_password is null
        ) then 
            pkg_common.raise_error('Thiếu thông tin cần thiết.');
        end if;
        
        select count(1) into v_count   
        from t_user where c_email = v_email;
        
        if (v_count != 0) then 
            pkg_common.raise_error('Email này đã tồn tại trong hệ thống.');
        end if;
    
        select count(1) into v_count   
        from t_user where c_username = v_username;
        
        if (v_count != 0) then 
            pkg_common.raise_error('Username đã tồn tại trong hệ thống.');
        end if;
    
        insert into t_user (PK_USER,C_USERNAME,C_FULLNAME,C_EMAIL,C_PASSWORD,C_CREATED_DATE,C_CREATED_BY)
        VALUES (sys_guid(),v_username,v_fullname,v_email,v_password,sysdate,p_user);
    end create_user;
    
    procedure create_refresh_token (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as
        v_refresh_token     varchar2(300);
        v_refresh_token_old varchar2(300);
        v_date              date;
    begin
        v_refresh_token     :=  p_data.get_string('refreshToken');
        v_refresh_token_old :=  p_data.get_string('refreshTokenOld');
        v_date              :=  sysdate + 30;
         
        if (v_refresh_token is null) then 
            pkg_common.raise_error('Thiếu token.');
        end if;
        
        if (v_refresh_token_old is not null) then 
            delete t_user_refresh_token where c_refresh_token = v_refresh_token_old;
        end if;
        
        insert into t_user_refresh_token (pk_user_refresh_token, c_username, c_refresh_token, c_exp_date, c_created_date)
        values (sys_guid(), p_user, v_refresh_token, v_date, sysdate);
        
        delete t_user_refresh_token where c_username = p_user and c_exp_date < sysdate;
        
        open p_table_cursor for
            select * from dual;
    end create_refresh_token;
    
    procedure get_refresh_token (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as
        v_refresh_token     varchar2(300);
        v_date              date;
        v_count             number;
    begin
        v_refresh_token :=  p_data.get_string('refreshToken');
    
        select count(1) into v_count from t_user_refresh_token
        where c_refresh_token = v_refresh_token;
        if (v_count = 0) then 
            pkg_common.raise_error('Không tồn tại refresh token này');
        end if;
        
        select c_exp_date into v_date from t_user_refresh_token
        where c_refresh_token = v_refresh_token;
        
        if (v_date < sysdate) then 
            delete t_user_refresh_token where c_refresh_token = v_refresh_token;
            pkg_common.raise_error('Không tồn tại refresh token này');
        end if;
        
        open p_table_cursor for
            select * from t_user_refresh_token
            where c_refresh_token = v_refresh_token;
        
    end get_refresh_token;
    
    procedure get_info_login (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as
        v_count             number;
        v_username          varchar2(100);
    begin
        v_username  :=  p_data.get_string('username');
    
        select count(1) into v_count from t_user
        where v_username = c_username;
        
        if (v_count = 0) then
            pkg_common.raise_error('Tài khoản không tồn tại');
        end if;
        
        open p_table_cursor for
            select c_username, c_password from t_user
            where v_username = c_username;
    end get_info_login;
    
    procedure get_info (
        p_user          varchar2,
        p_data          JSON_OBJECT_T,
        p_table_cursor  out     pkg_common.table_cursor
    ) as
        v_count             number;
    begin    
        open p_table_cursor for
            select
                PK_USER,
                C_USERNAME,
                C_FULLNAME,
                C_EMAIL,
                C_IS_ADMIN
            from t_user
            where c_username = p_user;
    end get_info;
END PKG_USER;