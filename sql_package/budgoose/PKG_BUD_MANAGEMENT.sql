CREATE OR REPLACE PACKAGE PKG_BUD_HOLDER AS 

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Get all item in account
-----------------------------------------
PROCEDURE get_all(
    p_user          VARCHAR2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  OUT     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Get detail item in account
-----------------------------------------
PROCEDURE get_detail(
    p_user          VARCHAR2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  OUT     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Add item to account
-----------------------------------------
PROCEDURE add_item(
    p_user          VARCHAR2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  OUT     pkg_common.table_cursor
);

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Delete item to account
-----------------------------------------
PROCEDURE delete_item(
    p_user          VARCHAR2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  OUT     pkg_common.table_cursor
);

END;
/

CREATE OR REPLACE PACKAGE BODY PKG_BUD_HOLDER AS 

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Get all item in account
-----------------------------------------
PROCEDURE get_all(
    p_user          VARCHAR2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  OUT     pkg_common.table_cursor
) as 
	v_int_number_page       NUMBER(5, 0);
    v_int_item_per_page     NUMBER(5, 0);
	v_int_is_installment	NUMBER(1, 0);

	v_str_type				VARCHAR2(200);
	v_str_holder_name		VARCHAR2(200);
begin
	v_str_type				:=	trunc(p_data.get_string('type'));
	v_str_holder_name		:=	trunc(p_data.get_number('holder_name'));
	v_int_is_installment	:=	p_data.get_number('is_installment');

	v_int_number_page		:=	p_data.get_number('page');
	v_int_item_per_page		:=	p_data.get_number('size_page');

	open p_table_cursor for
		with tb_temp as (
			select 
				t1.pk_bud_management,
				t1.fk_bud_holder,
				t1.c_username,
				t1.c_type,
				t1.c_cash_value,
				t1.c_cash_return,
				t1.c_note,
				t1.c_created_date,
				t1.c_created_by,
				t1.c_updated_date,
				t1.c_updated_by,
				t1.c_is_installment
			from t_bud_management t1
			left join t_bud_holder t2
				on t1.fk_bud_holder = t2.pk_bud_holder
			where (v_str_type is null or v_str_type = t1.c_type)
				and t1.c_username = p_user
				and (v_int_is_installment is null or v_int_is_installment = t1.c_is_installment)
				and (v_str_holder_name is null or upper(t3.c_holder_name) like '%' || v_str_holder_name || '%')
		)

		select
			t2.tb_total_row,
			t2.tb_row_num,
			t2.pk_bud_management,
			t2.fk_bud_holder,
			t2.c_username,
			t2.c_type,
			t2.c_cash_value,
			t2.c_cash_return,
			t2.c_note,
			t2.c_created_date,
			t2.c_created_by,
			t2.c_updated_date,
			t2.c_updated_by,
			t2.c_is_installment
		from (
			select 
				count(1) over() as tb_total_row,
				rownum as tb_row_num,
				t1.pk_bud_management,
				t1.fk_bud_holder,
				t1.c_username,
				t1.c_type,
				t1.c_cash_value,
				t1.c_cash_return,
				t1.c_note,
				t1.c_created_date,
				t1.c_created_by,
				t1.c_updated_date,
				t1.c_updated_by,
				t1.c_is_installment
			from tb_temp t1
		) t2
		where (v_int_number_page - 1) * v_int_item_per_page < t2.tb_row_num 
			and t2.tb_row_num <= v_int_number_page * v_int_item_per_page
	;
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Get detail item in account
-----------------------------------------
PROCEDURE get_detail(
    p_user          VARCHAR2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  OUT     pkg_common.table_cursor
) as
	v_str_pk_bud_management		VARCHAR2(50);
begin
	v_str_pk_bud_management		:=	p_data.get_string('pk_bud_management');

	open p_table_cursor for
		select 
			t1.pk_bud_management,
			t1.fk_bud_holder,
			t1.c_username,
			t1.c_type,
			t1.c_cash_value,
			t1.c_cash_return,
			t1.c_note,
			t1.c_created_date,
			t1.c_created_by,
			t1.c_updated_date,
			t1.c_updated_by,
			t1.c_is_installment
		from t_bud_management t1
		where t1.pk_bud_management = v_str_pk_bud_management
			and t2.c_username = p_user;
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Add item to account
-----------------------------------------
PROCEDURE add_item(
    p_user          VARCHAR2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  OUT     pkg_common.table_cursor
) as 
	v_str_pk_bud_management	varchar2(50);
	v_str_fk_bud_holder		varchar2(50);
	v_str_type				varchar2(50);
	v_int_cash				number(20, 0);
	v_int_cash_type			number(20, 0);
	v_str_note				varchar2(2000);
	v_int_is_installment	number(1, 0);

	v_int_check 			integer;

	v_cur_bud_management	t_bud_management%rowtype;
begin
	v_str_pk_bud_management	:=	trunc(p_data.get_string('pk_bud_management'));
	v_str_fk_bud_holder		:=	trunc(p_data.get_string('fk_bud_holder'));
	v_str_type				:=	trunc(p_data.get_string('type'));
	v_int_cash				:=	p_data.get_number('cash');
	v_str_note				:=	trunc(p_data.get_string('note'));
	v_int_is_installment	:=	p_data.get_number('is_installment');

	-- Validate
	if (v_str_fk_bud_holder is null 
		or v_str_type is null
		or v_int_cash is null
	) then
		pkg_common.raise_error_code('ERR_BUD_1_00000001');
	end if;

	if (v_str_type not in ('BORROW', 'LOAN')) then
		pkg_common.raise_error_code('ERR_BUD_1_00000002');
	end if;

	if (v_int_cash <= 0) then
		pkg_common.raise_error_code('ERR_BUD_1_00000003');
	end if;

	if (v_int_is_installment is null or v_int_is_installment not in (0, 1)) then
		pkg_common.raise_error_code('ERR_BUD_1_00000006');
	end if;

	-- Check exist bud_holder
	select count(1) into v_int_check
	from t_bud_holder
	where pk_bud_holder = v_str_fk_bud_holder
		and c_username = p_user;

	if (v_int_check = 0) then
		pkg_common.raise_error_code('ERR_BUD_1_00000004');
	end if;

	if (v_str_pk_bud_management is null) then
		-- Create
		insert into t_bud_management (
			pk_bud_management,
			fk_bud_holder,
			c_username,
			c_type,
			c_cash_value,
			c_cash_return,
			c_note,
			c_created_date,
			c_created_by,
			c_updated_date,
			c_updated_by,
			c_is_installment
		)
		values (
			sys_guid(),
			v_str_fk_bud_holder,
			p_user,
			v_str_type,
			v_int_cash,
			0,
			v_str_note,
			sysdate,
			p_user,
			null,
			null,
			v_int_is_installment
		);

		-- Add transaction
		if (v_str_type = 'BORROW') then
			PKG_BUD_TRANS.create_item(
				p_user          		=>	p_user,
				p_str_fk_bud_management	=>	v_str_fk_bud_holder,
				p_str_username			=>	p_user,
				p_str_type				=>	v_str_type,
				p_str_sub_type			=>	'ADD_BORROW',
				p_int_cash_in			=>	v_int_cash,
				p_int_cash_out			=>	0,
				p_str_note				=>	v_str_note
			);
		else
			PKG_BUD_TRANS.create_item(
				p_user          		=>	p_user,
				p_str_fk_bud_management	=>	v_str_fk_bud_holder,
				p_str_username			=>	p_user,
				p_str_type				=>	v_str_type,
				p_str_sub_type			=>	'ADD_LOAN',
				p_int_cash_in			=>	0,
				p_int_cash_out			=>	v_int_cash,
				p_str_note				=>	v_str_note
			);
		end if;
	else 
		-- Check exist
		select count(1) into v_int_check
		from t_bud_management
		where pk_bud_management = v_str_pk_bud_management
			and c_username = p_user;

		if (v_int_check = 0) then
			pkg_common.raise_error_code('ERR_BUD_1_00000007');
		end if;

		-- Get infomation
		select * into v_cur_bud_management
		from t_bud_management
		where pk_bud_management = v_str_pk_bud_management
			and rownum < 2;

		if (v_cur_bud_management.c_is_installment = 1) then
			-- Check exist trans
			select count(1) into v_int_check
			from t_bud_trans
			where fk_bud_management = v_str_pk_bud_management;

			if (v_int_check > 1) then
				pkg_common.raise_error_code('ERR_BUD_1_00000008');
			end if;
		end if;

		-- Update
		update t_bud_management
		set fk_bud_holder	=	v_str_fk_bud_holder,
			c_username		=	p_user,
			c_type			=	v_str_type,
			c_cash_value	=	v_int_cash,
			c_cash_return	=	0,
			c_note			=	v_str_note,
			c_updated_date	=	sysdate,
			c_updated_by	=	p_user
		where pk_bud_management = v_str_pk_bud_management;

		-- Delete transaction
		PKG_BUD_TRANS.delete_by_entry(
			p_user						=>	p_user,
			p_str_pk_bud_management		=>	v_str_pk_bud_management
		);

		-- Add transaction
		if (v_str_type = 'BORROW') then
			PKG_BUD_TRANS.create_item(
				p_user          		=>	p_user,
				p_str_fk_bud_management	=>	v_str_fk_bud_holder,
				p_str_username			=>	p_user,
				p_str_type				=>	v_str_type,
				p_str_sub_type			=>	'ADD_BORROW',
				p_int_cash_in			=>	v_int_cash,
				p_int_cash_out			=>	0,
				p_str_note				=>	v_str_note
			);
		else
			PKG_BUD_TRANS.create_item(
				p_user          		=>	p_user,
				p_str_fk_bud_management	=>	v_str_fk_bud_holder,
				p_str_username			=>	p_user,
				p_str_type				=>	v_str_type,
				p_str_sub_type			=>	'ADD_LOAN',
				p_int_cash_in			=>	0,
				p_int_cash_out			=>	v_int_cash,
				p_str_note				=>	v_str_note
			);
		end if;
	end if;
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Delete item to account
-----------------------------------------
PROCEDURE delete_item(
    p_user          VARCHAR2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  OUT     pkg_common.table_cursor
) as
	v_str_pk_bud_management		VARCHAR2(50);

	v_int_check					integer;
begin
	v_str_pk_bud_management		:=	p_data.get_string('pk_bud_management');

	-- Check exist
	select count(1) into v_int_check
	from t_bud_management
	where c_username = p_user
		and pk_bud_management = v_str_pk_bud_management;

	if (v_int_check = 0) then
		pkg_common.raise_error_code('ERR_BUD_1_00000005');
	end if;

	-- Delete trans
	PKG_BUD_TRANS.delete_by_entry(
		p_user						=>	p_user,
		p_str_pk_bud_management		=>	v_str_pk_bud_management
	);

	-- Delete entry
	delete from t_bud_management
	where pk_bud_management = v_str_pk_bud_management;
end;

-----------------------------------------
-- author:	Adonis Willer
-- date:	26/02/2024
-- desc:	Checkout item
-----------------------------------------
PROCEDURE checkout_item(
    p_user          VARCHAR2,
    p_data          JSON_OBJECT_T,
    p_table_cursor  OUT     pkg_common.table_cursor
) as 
	v_int_check 		integer;

	v_str_pk_bud_holder			varchar2(50);
	v_str_pk_bud_management		varchar2(50);
	v_int_cash					number(20, 0);
	v_str_type					varchar2(50);
	v_str_note					varchar2(2000);

	v_int_total_need_checkout	number(20, 6);
	v_int_total_checkout		number(20, 6);
	v_int_checkout_item			number(20, 6);
	v_int_temp					number(20, 6);
begin	
	v_str_pk_bud_holder			:=	trunc(p_data.get_string('pk_bud_holder'));
	v_str_pk_bud_management		:=	trunc(p_data.get_string('pk_bud_management'));
	v_int_cash					:=	p_data.get_number('cash');
	v_str_type					:=	trunc(p_data.get_number('type'));
	v_str_note					:=	trunc(p_data.get_number('note'));

	-- Validate input
	if ((v_int_type is null) or (v_int_type not in ('CHECKOUT_BORROW', 'CHECKOUT_LOAN'))) then
		pkg_common.raise_error_code('ERR_BUD_1_00000009');
	end if;

	if (v_int_cash <= 0 is null or v_int_cash <= 0) then
		pkg_common.raise_error_code('ERR_BUD_1_00000010');
	end if;

	if (v_str_pk_bud_holder is not null) then
		-- Checkout by holder

		-- Check exist
		select count(1) into v_int_check
		from t_bud_holder
		where pk_bud_holder = v_str_pk_bud_holder
			and c_username = p_user;

		if (v_int_check = 0) then
			pkg_common.raise_error_code('ERR_BUD_1_00000011');
		end if;
		
		-- Check total need checkout
		select sum(c_cash_value - c_cash_return) into v_int_total_need_checkout
		from t_bud_management
		where c_username = p_user
			and c_cash_value != c_cash_return
			and (
				(v_int_type = 'CHECKOUT_BORROW' and c_type = 'BORROW') or
				(v_int_type = 'CHECKOUT_LOAN' and c_type = 'LOAN')
			) 
			and c_is_installment != 1;

		if (v_int_total_need_checkout > v_int_cash) then
			pkg_common.raise_error_code('ERR_BUD_1_00000012');
		end if;

		-- Init cash checkout
		v_int_total_checkout	:=	0;

		for v_loop_item in 
			select pk_bud_management, c_type
			from t_bud_management
			where c_username = p_user
				and c_cash_value != c_cash_return
				and (
					(v_int_type = 'CHECKOUT_BORROW' and c_type = 'BORROW') or
					(v_int_type = 'CHECKOUT_LOAN' and c_type = 'LOAN')
				) 
				and c_is_installment != 1
			order by c_created_date asc
		loop

			-- Process each item
			select c_cash_checkout - c_cash_return into v_int_checkout_item
			from t_bud_management
			where pk_bud_management = v_loop_item.pk_bud_management
				and rownum < 2;

			if (v_int_total_need_checkout != v_int_total_checkout) then
				v_int_temp	:=	v_int_total_need_checkout - v_int_total_checkout;

				if (v_int_temp > v_int_checkout_item) then
					v_int_temp	:=	v_int_checkout_item;
				end if;

				-- Update entry
				update t_bud_management
				set c_cash_return = c_cash_return + v_int_temp,
					c_updated_by = p_user,
					c_updated_date = sysdate
				where pk_bud_management = v_loop_item.pk_bud_management;

				-- Create trans checkout cash
				if (v_loop_item.c_type = 'BORROW') then
					PKG_BUD_TRANS.create_item(
						p_user          		=>	p_user,
						p_str_fk_bud_management	=>	v_loop_item.pk_bud_management,
						p_str_username			=>	p_user,
						p_str_type				=>	v_str_type,
						p_str_sub_type			=>	v_str_type,
						p_int_cash_in			=>	0,
						p_int_cash_out			=>	v_int_temp,
						p_str_note				=>	v_str_note
					);
				else
					PKG_BUD_TRANS.create_item(
						p_user          		=>	p_user,
						p_str_fk_bud_management	=>	v_loop_item.pk_bud_management,
						p_str_username			=>	p_user,
						p_str_type				=>	v_str_type,
						p_str_sub_type			=>	v_str_type,
						p_int_cash_in			=>	v_int_temp,
						p_int_cash_out			=>	0,
						p_str_note				=>	v_str_note
					);
				end if;

				v_int_total_checkout	:=	v_int_total_checkout + v_int_temp;
			end if;
		end loop;

	elsif (v_str_pk_bud_management is not null) then
		-- Checkout by entry

		-- Check exist
		select count(1) into v_int_check
		from t_bud_management
		where pk_bud_management = v_str_pk_bud_management
			and c_username = p_user;

		if (v_int_check = 0) then
			pkg_common.raise_error_code('ERR_BUD_1_00000013');
		end if;

		-- Get data
		select * into v_cur_bud_management
		from t_bud_management
		where pk_bud_management = p_str_pk_bud_management
			and rownum < 2;

		if (v_int_cash > v_cur_bud_management.c_cash_value - v_cur_bud_management.c_cash_return) then
			pkg_common.raise_error_code('ERR_BUD_1_00000014');
		end if;

		-- Update entry
		update t_bud_management
		set c_cash_return = c_cash_return + v_int_cash,
			c_updated_by = p_user,
			c_updated_date = sysdate
		where pk_bud_management = v_str_pk_bud_management;

		-- Create trans checkout cash
		if (v_cur_bud_management.c_type = 'BORROW') then
			PKG_BUD_TRANS.create_item(
				p_user          		=>	p_user,
				p_str_fk_bud_management	=>	v_str_fk_bud_holder,
				p_str_username			=>	p_user,
				p_str_type				=>	'CHECKOUT_BORROW',
				p_str_sub_type			=>	'CHECKOUT_BORROW',
				p_int_cash_in			=>	0,
				p_int_cash_out			=>	v_int_cash,
				p_str_note				=>	v_str_note
			);
		else
			PKG_BUD_TRANS.create_item(
				p_user          		=>	p_user,
				p_str_fk_bud_management	=>	v_str_fk_bud_holder,
				p_str_username			=>	p_user,
				p_str_type				=>	'CHECKOUT_LOAN',
				p_str_sub_type			=>	'CHECKOUT_LOAN',
				p_int_cash_in			=>	v_int_cash,
				p_int_cash_out			=>	0,
				p_str_note				=>	v_str_note
			);
		end if;
		
	end if;
end;

END PKG_BUD_HOLDER;
