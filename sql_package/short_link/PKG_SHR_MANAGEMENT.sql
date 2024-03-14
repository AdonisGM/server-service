CREATE OR REPLACE PACKAGE PKG_SHR_MANAGEMENT AS 

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Get all short link
-----------------------------------------
procedure get_all(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Get detail short link
-----------------------------------------
procedure get_item(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Get detail short link by guest - require password
-----------------------------------------
procedure get_item_guest(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Add/update item
-----------------------------------------
procedure update_item(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Active/deactive item
-----------------------------------------
procedure active_item(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Add/update item
-----------------------------------------
procedure delete_item(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
);

END PKG_SHR_MANAGEMENT;
/

CREATE OR REPLACE PACKAGE BODY PKG_SHR_MANAGEMENT AS 

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Get all short link
-----------------------------------------
procedure get_all(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
) as
	v_int_number_page       NUMBER(5, 0);
    v_int_item_per_page     NUMBER(5, 0);

	v_str_name				varchar2(200);
	v_str_short_link		varchar2(200);
begin
	v_int_number_page		:=	p_data.get_number('page');
	v_int_item_per_page		:=	p_data.get_number('size_page');

	v_str_name				:=	upper(trunc(p_data.get_string('name')));
	v_str_short_link		:=	upper(trunc(p_data.get_string('short_link')));

	open p_table_cursor for
		with tb_temp as (
			select 
				pk_shr_link,
				c_username,
				c_name,
				c_short_link,
				c_original_link,
				c_is_custom_link,
				c_password,
				c_total_click,
				c_total_view,
				c_description,
				c_is_active,
				c_created_date,
				c_created_by,
				c_updated_date,
				c_updated_by
			from t_shr_link
			where c_username = p_user
				and (v_str_name is null or upper(c_name) like '%' || v_str_name || '%')
				and (v_str_short_link is null or upper(c_short_link) like '%' || v_str_short_link || '%')
		)

		select 
			t2.tb_total_row,
			t2.tb_row_num,
			t2.pk_shr_link,
			t2.c_username,
			t2.c_name,
			t2.c_short_link,
			t2.c_original_link,
			t2.c_is_custom_link,
			t2.c_password,
			t2.c_total_click,
			t2.c_total_view,
			t2.c_description,
			t2.c_is_active,
			t2.c_created_date,
			t2.c_created_by,
			t2.c_updated_date,
			t2.c_updated_by
		from (
			select 
				count(1) over() as tb_total_row,
				rownum as tb_row_num,
				t1.pk_shr_link,
				t1.c_username,
				t1.c_name,
				t1.c_short_link,
				t1.c_original_link,
				t1.c_is_custom_link,
				t1.c_password,
				t1.c_total_click,
				t1.c_total_view,
				t1.c_description,
				t1.c_is_active,
				t1.c_created_date,
				t1.c_created_by,
				t1.c_updated_date,
				t1.c_updated_by
			from tb_temp t1
		) t2
		where (v_int_number_page - 1) * v_int_item_per_page < t2.tb_row_num 
			and t2.tb_row_num <= v_int_number_page * v_int_item_per_page;
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Get detail short link
-----------------------------------------
procedure get_item(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
) as
	v_str_pk_shr_link		varchar2(50);
begin
	v_str_pk_shr_link		:=	trunc(p_data.get_string('pk_shr_link'));

	open p_table_cursor for
		select 
			pk_shr_link,
			c_username,
			c_name,
			c_short_link,
			c_original_link,
			c_is_custom_link,
			c_password,
			c_total_click,
			c_total_view,
			c_description,
			c_is_active,
			c_created_date,
			c_created_by,
			c_updated_date,
			c_updated_by
		from t_shr_link
		where c_username = p_user
			and pk_shr_link = v_str_pk_shr_link;
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Get detail short link by guest - require password
-----------------------------------------
procedure get_item_guest(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
) as
	v_str_short_link		varchar2(200);
	v_str_password			varchar2(50);
begin
	v_str_short_link		:=	trunc(p_data.get_string('short_link'));
	v_str_password			:=	trunc(p_data.get_string('password'));

	open p_table_cursor for
		select 
			pk_shr_link,
			c_username,
			c_name,
			c_short_link,
			c_original_link,
			c_is_custom_link,
			c_password,
			c_total_click,
			c_total_view,
			c_description,
			c_is_active,
			c_created_date,
			c_created_by,
			c_updated_date,
			c_updated_by
		from t_shr_link
		where c_short_link = v_str_short_link
			and (c_password = v_str_password or c_password is null);
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Add/update item
-----------------------------------------
procedure update_item(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
) as
	v_int_check			integer;

	v_str_name			varchar2(200);
	v_str_short_link	varchar2(200);
	v_str_original_link	varchar2(2000);
	v_str_password		varchar2(50);
	v_str_description	varchar2(200);

	v_int_is_active		number(1, 0);
begin
	v_str_name				:=	trunc(p_data.get_string('name'));
	v_str_short_link		:=	trunc(p_data.get_string('short_link'));
	v_str_original_link		:=	trunc(p_data.get_string('original_link'));
	v_str_password			:=	p_data.get_string('password');
	v_str_description		:=	trunc(p_data.get_string('description'));

	v_int_is_active			:=	p_data.get_number('is_active');

	-- Validate input
	if (v_str_name is null or v_str_original_link is null) then
		pkg_common.raise_error_code('ERR_SHR_1_00000001');
	end if;

	-- 
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Active/deactive item
-----------------------------------------
procedure active_item(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
) as

begin
	null;
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	04/03/2024
-- desc:	Add/update item
-----------------------------------------
procedure delete_item(
	p_user          VARCHAR2,
	p_data          JSON_OBJECT_T,
	p_table_cursor  OUT     pkg_common.table_cursor
) as

begin
	null;
end;

END PKG_SHR_MANAGEMENT;