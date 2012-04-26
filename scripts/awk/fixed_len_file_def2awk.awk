#!/bin/awk -f
# Generate awk parser script from a fixed length file format defination.
# by luojunqiang@gmail.com at 2012-04-25
#
# FILENAME.sql => create table sql file.
# FILENAME.ldr => sqlldr control file.
# awk_parse_fields() => awk function to parse line to fields.
# awk_gen_csv_str() => awk function to print CSV string.
# awk_gen_json_str() => awk function to print JSON string.

BEGIN {
  awk_0="#!/bin/awk -f\n"
  awk_trim="function trim(v, r){ r=v; gsub(/[ \\t]+$/, \"\", r); gsub(/^[ \\t]+/, \"\", r); return r; }\n"
  awk_gen_names="function gen_names(nl) {\n  nl=nl\"rownuim\";\n"
  awk_parse_fields="function parse_fields() {\n"
  awk_gen_csv_str="function gen_csv_str(s) {\n  s=\"\\\"\"NR\"\\\"\"\n" 
  awk_gen_json_str="function gen_json_str(s) {\n  s=\"{_rownum:\"NR;\n" 
  ldr_str="LOAD DATA\nAPPEND\nINTO TABLE ttt\n(\n"
  create_tab_str="create table ttt (\n"
}

$1 != "" {
  $1=tolower($1)   # change field name to lower case.
  awk_gen_names=awk_gen_names "  nl=nl\","$1"\"\n";
  awk_parse_fields=awk_parse_fields "  _RAW_"$1"=substr($0,"$2","$3"); v_"$1"=trim(_RAW_"$1"); #" NR "\n"
  awk_gen_csv_str=awk_gen_csv_str "  s=s\",\\\"\"v_"$1"\"\\\"\"; #"NR "\n"
  awk_gen_json_str=awk_gen_json_str "  s=s\", "$1":\\\"\"v_"$1"\"\\\"\"; #"NR "\n"
  ldr_str=ldr_str "  "$1"\tposition("$2":"$2+$3-1"),\n"
  create_tab_str=create_tab_str "  "$1"\tvarchar2("$3"),\n"
}

END {
  awk_gen_names=awk_gen_names "  return nl;\n}"
  awk_parse_fields=awk_parse_fields "}"
  awk_gen_csv_str=awk_gen_csv_str "  return s;\n}"
  awk_gen_json_str=awk_gen_json_str "  s=s\"}\"\n  return s;\n}"
  ldr_str=ldr_str "  line position(1:1) PRESERVE BLANKS\n)\n"
  create_tab_str=create_tab_str "  line varchar2\n)\n"
  ##########
  print awk_0
  print awk_trim
  print awk_gen_names
  print awk_parse_fields
  print awk_gen_csv_str
  print awk_gen_json_str
  print create_tab_str >FILENAME".sql"
  print ldr_str >FILENAME".ldr"
}

#awk 'BEGIN{FS=","}{for(i=1;i<=NF;++i) print "  "$i;print "-------"}'  ## use this to sep json attr.
