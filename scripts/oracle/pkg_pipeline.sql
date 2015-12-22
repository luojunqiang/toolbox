create or replace package pkg_pipeline is

    -- Author  : Junqiang Luo
    -- Created : 2015-12-21 23:11:04
    -- Purpose : sample of pipelined table

    -- https://oracle-base.com/articles/misc/pipelined-table-functions
    -- NO_DATA_NEEDED exception.

    type str_list is table of varchar2(500);

    type tab_info_type is record (
         table_name varchar2(30),
         tablespace_name varchar2(30),
         last_analyzed date
    );
    type tab_info_type_set is table of tab_info_type;

    -- Public function and procedure declarations

    function to_list(a_str_list in varchar2, a_sep in varchar2 :=',') return str_list pipelined;

    function tab_info_list return tab_info_type_set pipelined;
    function dyna_list(a_limit number) return tab_info_type_set pipelined;
    function dyna_bulk_list(a_limit number) return tab_info_type_set pipelined;

    function test_dml return str_list pipelined;

end pkg_pipeline;
/
create or replace package body pkg_pipeline is

    function to_list(a_str_list in varchar2, a_sep in varchar2) return str_list pipelined
    is
        buf long default a_str_list || a_sep;
        n number;
    begin
        loop
            exit when buf is null;
            n := instr(buf, a_sep);
            pipe row(ltrim(rtrim(substr(buf, 1, n-1))));
            buf := substr(buf, n+1);
        end loop;
        return;
    end;

    function tab_info_list return tab_info_type_set pipelined
    is
    begin
        for r in (select table_name, tablespace_name, last_analyzed
            from user_tables
            where rownum<100
        ) loop
            pipe row(r);
        end loop;
        return;
    end;

    function dyna_bulk_list(a_limit number) return tab_info_type_set pipelined
    is
        cur sys_refcursor;
        -- rec gsm_cdr_type;
        rs tab_info_type_set;
    begin
        open cur for 'select table_name, tablespace_name, last_analyzed from user_tables where rownum<:v_limit'
             using a_limit;
        loop
            /*fetch cur into rec;
            exit when cur%notfound;
            pipe row(rec);*/
            fetch cur bulk collect into rs limit 100;
            exit when rs.count = 0;
            for i in 1 .. rs.count loop
                pipe row(rs(i));
            end loop;
        end loop;
        close cur;
        return;
    exception
        when NO_DATA_NEEDED then
        close cur;
    end;

    function dyna_list(a_limit number) return tab_info_type_set pipelined
    is
        cur sys_refcursor;
        rec tab_info_type;
    begin
        open cur for 'select table_name, tablespace_name, last_analyzed from user_tables where rownum<:v_limit'
             using a_limit;
        loop
            fetch cur into rec;
            exit when cur%notfound;
            pipe row(rec);
        end loop;
        close cur;
        return;
    exception
        when NO_DATA_NEEDED then
        close cur;
    end;
    
    function test_dml return str_list pipelined
    is
        PRAGMA AUTONOMOUS_TRANSACTION;
    begin
        pipe row('begin.');
        --execute immediate 'create table tmp#test_dml (val varchar2(50))';
        pipe row('step 1.');
        execute immediate 'insert into tmp#test_dml values (1)';
        commit;
        pipe row('step 2.');
        --execute immediate 'drop table tmp#test_dml';
        pipe row('end.');
    end;
    
begin
    null;
end pkg_pipeline;
/

select * from table(pkg_pipeline.test_dml);
