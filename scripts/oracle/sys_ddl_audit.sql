
drop trigger trg_sys_ddl_audit;
drop table sys_ddl_audit_log;

create table sys_ddl_audit_log (
    oper_user   VARCHAR2(30),
    oper_time   TIMESTAMP(3),
    oper_type   VARCHAR2(30),
    rejected    VARCHAR2(1),
    obj_owner   VARCHAR2(30),
    obj_type    VARCHAR2(30),
    obj_name    VARCHAR2(30),
    os_user     VARCHAR2(30),
    host        VARCHAR2(30),
    ip_addr     VARCHAR2(30),
    program     VARCHAR2(30),
    inst_name   VARCHAR2(30),
    sql_text    VARCHAR2(1000 char)
);

create or replace package pkg_sys_audit is
    check_danger_ddl boolean := true;

    procedure disable_check;
    procedure enable_check;
    procedure log_ddl(
        oper_user varchar2,
        oper_type varchar2, 
        obj_owner varchar2, 
        obj_type varchar2, 
        obj_name varchar2, 
        rejected varchar2 := 'N');
    procedure log_rejected_ddl(
        oper_user varchar2,
        oper_type varchar2, 
        obj_owner varchar2, 
        obj_type varchar2, 
        obj_name varchar2);
end pkg_sys_audit;
/
show errors

create or replace package body pkg_sys_audit is
    procedure disable_check
    is
    begin
        check_danger_ddl := false;
    end;
    
    procedure enable_check
    is
    begin
        check_danger_ddl := true;
    end;
    
    procedure log_ddl(
        oper_user varchar2,
        oper_type varchar2, 
        obj_owner varchar2, 
        obj_type varchar2, 
        obj_name varchar2, 
        rejected varchar2)
    is
        sql_text ora_name_list_t;
        sql_count pls_integer;
        sql_stmt varchar2(1000 char);
        sql_stmt_len pls_integer := 0;
        sql_inc_len pls_integer;
    begin
        sql_count := ora_sql_txt(sql_text);
        for i in 1..sql_count loop
            sql_inc_len := length(sql_text(i));
            if sql_stmt_len + sql_inc_len >= 1000 then
                sql_stmt := sql_stmt || substr(sql_text(i), 1, 1000 - sql_stmt_len);
                exit;
            end if;
            sql_stmt := sql_stmt || sql_text(i);
            sql_stmt_len := sql_stmt_len + sql_inc_len;
        end loop;
        
        insert into sys_ddl_audit_log
          (oper_user, oper_time, oper_type, rejected, 
           obj_owner, obj_type, obj_name, os_user, host, 
           ip_addr, program, inst_name, sql_text)
        values(
            oper_user,
            systimestamp,
            oper_type,
            rejected,
            obj_owner,
            obj_type,
            obj_name,
            sys_context('USERENV','OS_USER',30),
            sys_context('USERENV','HOST',30),
            sys_context('USERENV','IP_ADDRESS',30),
            sys_context('USERENV','MODULE',30),
            sys_context('USERENV','INSTANCE_NAME',30),
            sql_stmt --sys_context('USERENV','CURRENT_SQL',1000)
        );
    end;
    
    procedure log_rejected_ddl(
        oper_user varchar2,
        oper_type varchar2, 
        obj_owner varchar2, 
        obj_type varchar2, 
        obj_name varchar2)
    is
        PRAGMA AUTONOMOUS_TRANSACTION;
    begin
        log_ddl(oper_user, oper_type, obj_owner, obj_type, obj_name, 'Y');
        commit;
    end;
begin
    null;
end pkg_sys_audit;
/
show errors

create or replace trigger trg_sys_ddl_audit
    before ddl on schema 
declare
begin
    if pkg_sys_audit.check_danger_ddl 
        and ora_sysevent in ('DROP', 'TRUNCATE')
        and ora_login_user = ora_dict_obj_owner 
        and ora_dict_obj_type='TABLE' 
        and ora_dict_obj_name not like '%#%'
    then
        pkg_sys_audit.log_rejected_ddl(
            ora_login_user,
            ora_sysevent,
            ora_dict_obj_owner,
            ora_dict_obj_type,
            ora_dict_obj_name
        );
        RAISE_APPLICATION_ERROR(-20999, 'Attempt to '||ora_sysevent||' a production table denied. Please contact DBA!');
    else
        pkg_sys_audit.log_ddl(
            ora_login_user,
            ora_sysevent,
            ora_dict_obj_owner,
            ora_dict_obj_type,
            ora_dict_obj_name
        );
    end if;
end ddl_trigger;
/
show errors

CREATE TABLE TEST
 AS SELECT * FROM DUAL;
drop table test;
rename test to test#;
drop table test#;
select * from sys_ddl_audit_log;
