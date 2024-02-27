create or replace PACKAGE PKG_BUD_TRANS AS 

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Get all transaction in account
-----------------------------------------
PROCEDURE get_all(
    p_user          VARCHAR2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  OUT     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Create transaction and change balance
-----------------------------------------
PROCEDURE create_item(
    p_user          		VARCHAR2,
	p_str_fk_bud_management	VARCHAR2,
	p_str_username			VARCHAR2,
	p_str_type				VARCHAR2,
	p_str_sub_type			VARCHAR2,
	p_int_cash_in			NUMBER,
	p_int_cash_out			NUMBER,
	p_str_note				VARCHAR2
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Delete transaction and change balance
-----------------------------------------
PROCEDURE delete_item(
    p_user          		VARCHAR2,
	p_str_pk_bud_management	VARCHAR2,
	p_str_pk_bud_trans		VARCHAR2
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Delete all transaction by entry and change balance
-----------------------------------------
PROCEDURE delete_by_entry(
    p_user          		VARCHAR2,
	p_str_pk_bud_management	VARCHAR2
);

END PKG_BUD_TRANS;

/

create or replace PACKAGE BODY PKG_BUD_TRANS AS 

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Get all transaction in account
-----------------------------------------
PROCEDURE get_all(
    p_user          VARCHAR2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  OUT     pkg_common.table_cursor
) AS
    v_int_number_page       NUMBER(5, 0);
    v_int_item_per_page     NUMBER(5, 0);

    v_str_fk_bud_management VARCHAR2(50);
    v_str_fk_bud_holder		VARCHAR2(50);
    v_str_holder_name		VARCHAR2(50);
BEGIN
	v_int_number_page		:=	p_data.get_number('page');
	v_int_item_per_page		:=	p_data.get_number('size_page');

	v_str_fk_bud_management	:=	trunc(p_data.get_string('fk_bud_management'));
	v_str_fk_bud_holder		:=	trunc(p_data.get_string('fk_bud_holder'));
	v_str_holder_name		:=	upper(trunc(p_data.get_string('holder_name')));

	open p_table_cursor for
		with tb_temp as (
			select 
				t1.pk_bud_trans,
				t1.fk_bud_management,
				t1.c_username,
				t1.c_type,
				t1.c_sub_type,
				t1.c_cash_in,
				t1.c_cash_out,
				t1.c_note,
				t1.c_created_date,
				t1.c_created_by,
				t1.c_updated_date,
				t1.c_updated_by
			from t_bud_trans t1
			left join t_bud_management t2
				on t1.fk_bud_management = t2.pk_bud_management
			left join t_bud_holder t3
				on t2.fk_bud_holder = t3.pk_bud_holder
			where (v_str_fk_bud_management is null or v_str_fk_bud_management = t1.fk_bud_management)
				and (v_str_fk_bud_holder is null or v_str_fk_bud_holder = t2.fk_bud_holder)
				and (v_str_holder_name is null or upper(t3.c_holder_name) like '%' || v_str_holder_name || '%')
		)

		select
			t2.tb_total_row,
			t2.tb_row_num,
			t2.pk_bud_trans,
			t2.fk_bud_management,
			t2.c_username,
			t2.c_type,
			t2.c_sub_type,
			t2.c_cash_in,
			t2.c_cash_out,
			t2.c_note,
			t2.c_created_date,
			t2.c_created_by,
			t2.c_updated_date,
			t2.c_updated_by
		from (
			select 
				count(1) over() as tb_total_row,
				rownum as tb_row_num,
				t1.pk_bud_trans,
				t1.fk_bud_management,
				t1.c_username,
				t1.c_type,
				t1.c_sub_type,
				t1.c_cash_in,
				t1.c_cash_out,
				t1.c_note,
				t1.c_created_date,
				t1.c_created_by,
				t1.c_updated_date,
				t1.c_updated_by
			from tb_temp t1
		) t2
		where (v_int_number_page - 1) * v_int_item_per_page < t2.tb_row_num 
			and t2.tb_row_num <= v_int_number_page * v_int_item_per_page
	;
END;

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Create transaction and change balance
-----------------------------------------
PROCEDURE create_item(
    p_user          		VARCHAR2,
	p_str_fk_bud_management	VARCHAR2,
	p_str_username			VARCHAR2,
	p_str_type				VARCHAR2,
	p_str_sub_type			VARCHAR2,
	p_int_cash_in			NUMBER,
	p_int_cash_out			NUMBER,
	p_str_note				VARCHAR2
) AS
	v_int_check				integer;

	v_cur_bud_management	t_bud_management%rowtype;
BEGIN
	select count(1) into v_int_check
	from t_bud_management
	where p_str_fk_bud_management = pk_bud_management;

	if (v_int_check > 0) then
		select * into v_cur_bud_management
		from t_bud_management
		where p_str_fk_bud_management = pk_bud_management;

		insert into t_bud_trans (
			PK_BUD_TRANS,
			FK_BUD_MANAGEMENT,
			C_USERNAME,
			C_TYPE,
			C_SUB_TYPE,
			C_CASH_IN,
			C_CASH_OUT,
			C_NOTE,
			C_CREATED_DATE,
			C_CREATED_BY,
			C_UPDATED_DATE,
			C_UPDATED_BY
		)
		values (
			sys_guid(),
			p_str_fk_bud_management,
			p_str_username,
			p_str_type,
			p_str_sub_type,
			p_int_cash_in,
			p_int_cash_out,
			p_str_note,
			sysdate,
			p_user,
			null,
			null
		);

		update t_bud_holder
		set c_cash_balance = c_cash_balance + p_int_cash_in - p_int_cash_out
		where pk_bud_holder = v_cur_bud_management.fk_bud_holder;
	end if;
END;

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Delete transaction and change balance
-----------------------------------------
PROCEDURE delete_item(
    p_user          		VARCHAR2,
	p_str_pk_bud_management	VARCHAR2,
	p_str_pk_bud_trans		VARCHAR2
) AS
	v_int_check				integer;
	v_cur_bud_management	t_bud_management%rowtype;
	v_cur_bud_trans			t_bud_trans%rowtype;
BEGIN
	select count(1) into v_int_check
	from t_bud_management
	where p_str_pk_bud_management = pk_bud_management;

	if (v_int_check > 0) then
		select * into v_cur_bud_management
		from t_bud_management
		where p_str_pk_bud_management = pk_bud_management;

		select * into v_cur_bud_trans
		from t_bud_trans
		where pk_bud_trans = p_str_pk_bud_trans;

		delete t_bud_trans
		where pk_bud_trans = p_str_pk_bud_trans;

		update t_bud_holder
		set c_cash_balance = c_cash_balance - v_cur_bud_trans.c_cash_in + v_cur_bud_trans.c_cash_out
		where pk_bud_holder = v_cur_bud_management.fk_bud_holder;
	end if;
END;

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Delete all transaction by entry and change balance
-----------------------------------------
PROCEDURE delete_by_entry(
    p_user          		VARCHAR2,
	p_str_pk_bud_management	VARCHAR2
) AS
	v_int_check		integer;
BEGIN
	select count(1) into v_int_check
	from t_bud_management
	where pk_bud_management = p_str_pk_bud_management;

	if (v_int_check > 0) then
		for v_for_item in (
			select 
				pk_bud_trans
			from t_bud_trans
			where fk_bud_management = p_str_pk_bud_management
		) loop
			PKG_BUD_TRANS.delete_item(
				p_user          		=>	p_user,
				p_str_pk_bud_management	=>	p_str_pk_bud_management,
				p_str_pk_bud_trans		=>	v_for_item.pk_bud_trans
			);
		end loop;
	end if;
END;

END PKG_BUD_TRANS;