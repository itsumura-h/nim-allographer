const
  FFI_SCOPE* = "mariadb"
  FFI_LIB* = "libmariadb.so"

## this header file is copied from
## https://github.com/katajakasa/async-mariadb-c-testing/blob/29919ef8cca8622fb7bf21e9924596cd84ce8e03/mariadb.h
## https://github.com/luapower/mysql/blob/master/mysql_h.lua

type
  my_bool* = char
  MYSQL_ROW* = cstringArray
  MYSQL* = st_mysql
  MYSQL_RES* = st_mysql_res
  MYSQL_STMT* = st_mysql_stmt
  enum_field_types* = enum
    MYSQL_TYPE_DECIMAL, MYSQL_TYPE_TINY, MYSQL_TYPE_SHORT, MYSQL_TYPE_LONG,
    MYSQL_TYPE_FLOAT, MYSQL_TYPE_DOUBLE, MYSQL_TYPE_NULL, MYSQL_TYPE_TIMESTAMP,
    MYSQL_TYPE_LONGLONG, MYSQL_TYPE_INT24, MYSQL_TYPE_DATE, MYSQL_TYPE_TIME,
    MYSQL_TYPE_DATETIME, MYSQL_TYPE_YEAR, MYSQL_TYPE_NEWDATE, MYSQL_TYPE_VARCHAR,
    MYSQL_TYPE_BIT, MYSQL_TYPE_NEWDECIMAL = 246, MYSQL_TYPE_ENUM = 247,
    MYSQL_TYPE_SET = 248, MYSQL_TYPE_TINY_BLOB = 249, MYSQL_TYPE_MEDIUM_BLOB = 250,
    MYSQL_TYPE_LONG_BLOB = 251, MYSQL_TYPE_BLOB = 252, MYSQL_TYPE_VAR_STRING = 253,
    MYSQL_TYPE_STRING = 254, MYSQL_TYPE_GEOMETRY = 255, MAX_NO_FIELD_TYPES


type
  MYSQL_FIELD* {.bycopy.} = object
    name*: cstring
    org_name*: cstring
    table*: cstring
    org_table*: cstring
    db*: cstring
    catalog*: cstring
    def*: cstring
    length*: culong
    max_length*: culong
    name_length*: cuint
    org_name_length*: cuint
    table_length*: cuint
    org_table_length*: cuint
    db_length*: cuint
    catalog_length*: cuint
    def_length*: cuint
    flags*: cuint
    decimals*: cuint
    charsetnr*: cuint
    `type`*: enum_field_types
    extension*: pointer


const
  MYSQL_WAIT_READ* = 1
  MYSQL_WAIT_WRITE* = 2
  MYSQL_WAIT_EXCEPT* = 4
  MYSQL_WAIT_TIMEOUT* = 8

type
  mysql_option* = enum
    MYSQL_OPT_CONNECT_TIMEOUT, MYSQL_OPT_COMPRESS, MYSQL_OPT_NAMED_PIPE,
    MYSQL_INIT_COMMAND, MYSQL_READ_DEFAULT_FILE, MYSQL_READ_DEFAULT_GROUP,
    MYSQL_SET_CHARSET_DIR, MYSQL_SET_CHARSET_NAME, MYSQL_OPT_LOCAL_INFILE,
    MYSQL_OPT_PROTOCOL, MYSQL_SHARED_MEMORY_BASE_NAME, MYSQL_OPT_READ_TIMEOUT,
    MYSQL_OPT_WRITE_TIMEOUT, MYSQL_OPT_USE_RESULT,
    MYSQL_OPT_USE_REMOTE_CONNECTION, MYSQL_OPT_USE_EMBEDDED_CONNECTION,
    MYSQL_OPT_GUESS_CONNECTION, MYSQL_SET_CLIENT_IP, MYSQL_SECURE_AUTH,
    MYSQL_REPORT_DATA_TRUNCATION, MYSQL_OPT_RECONNECT,
    MYSQL_OPT_SSL_VERIFY_SERVER_CERT, MYSQL_PLUGIN_DIR, MYSQL_DEFAULT_AUTH,
    MYSQL_OPT_BIND, MYSQL_OPT_SSL_KEY, MYSQL_OPT_SSL_CERT, MYSQL_OPT_SSL_CA,
    MYSQL_OPT_SSL_CAPATH, MYSQL_OPT_SSL_CIPHER, MYSQL_OPT_SSL_CRL,
    MYSQL_OPT_SSL_CRLPATH, MYSQL_OPT_CONNECT_ATTR_RESET,
    MYSQL_OPT_CONNECT_ATTR_ADD, MYSQL_OPT_CONNECT_ATTR_DELETE,
    MYSQL_SERVER_PUBLIC_KEY, MYSQL_ENABLE_CLEARTEXT_PLUGIN,
    MYSQL_PROGRESS_CALLBACK = 5999, MYSQL_OPT_NONBLOCK


##  Custom code
## int wait_for_mysql(MYSQL *mysql, int status);
##  Init, connect and close

proc mysql_init*(mysql: ptr MYSQL): ptr MYSQL {.importc.}
proc mysql_options*(mysql: ptr MYSQL; option: mysql_option; arg: pointer): cint
proc mysql_real_connect*(mysql: ptr MYSQL; host: cstring; user: cstring;
                        passwd: cstring; db: cstring; port: cuint;
                        unix_socket: cstring; clientflag: culong): ptr MYSQL
proc mysql_real_connect_start*(ret: ptr ptr MYSQL; mysql: ptr MYSQL; host: cstring;
                              user: cstring; passwd: cstring; db: cstring;
                              port: cuint; unix_socket: cstring; client_flag: culong): cint
proc mysql_real_connect_cont*(ret: ptr ptr MYSQL; mysql: ptr MYSQL; status: cint): cint
proc mysql_close_start*(sock: ptr MYSQL): cint
proc mysql_close_cont*(sock: ptr MYSQL; status: cint): cint
##  Error handling

proc mysql_errno*(mysql: ptr MYSQL): cuint
proc mysql_error*(mysql: ptr MYSQL): cstring
##  Querying

proc mysql_query*(mysql: ptr MYSQL; q: cstring): cint
proc mysql_real_query_start*(ret: ptr cint; mysql: ptr MYSQL; q: cstring; length: culong): cint
proc mysql_real_query_cont*(ret: ptr cint; mysql: ptr MYSQL; status: cint): cint
##  Result handling

proc mysql_store_result*(mysql: ptr MYSQL): ptr MYSQL_RES
proc mysql_use_result*(mysql: ptr MYSQL): ptr MYSQL_RES
proc mysql_free_result_start*(result: ptr MYSQL_RES): cint
proc mysql_free_result_cont*(result: ptr MYSQL_RES; status: cint): cint
proc mysql_num_fields*(result: ptr MYSQL_RES): cuint
proc mysql_fetch_lengths*(result: ptr MYSQL_RES): ptr culong
proc mysql_fetch_fields*(result: ptr MYSQL_RES): ptr MYSQL_FIELD
proc mysql_fetch_row*(result: ptr MYSQL_RES): MYSQL_ROW
##  Row handling

proc mysql_fetch_row_start*(ret: ptr MYSQL_ROW; result: ptr MYSQL_RES): cint
proc mysql_fetch_row_cont*(ret: ptr MYSQL_ROW; result: ptr MYSQL_RES; status: cint): cint
##  Transactions

proc mysql_commit_start*(ret: ptr my_bool; mysql: ptr MYSQL): cint
proc mysql_commit_cont*(ret: ptr my_bool; mysql: ptr MYSQL; status: cint): cint
proc mysql_rollback_start*(ret: ptr my_bool; mysql: ptr MYSQL): cint
proc mysql_rollback_cont*(ret: ptr my_bool; mysql: ptr MYSQL; status: cint): cint
proc mysql_autocommit_start*(ret: ptr my_bool; mysql: ptr MYSQL; auto_mode: my_bool): cint
proc mysql_autocommit_cont*(ret: ptr my_bool; mysql: ptr MYSQL; status: cint): cint
proc mysql_next_result_start*(ret: ptr cint; mysql: ptr MYSQL): cint
proc mysql_next_result_cont*(ret: ptr cint; mysql: ptr MYSQL; status: cint): cint
proc mysql_select_db_start*(ret: ptr cint; mysql: ptr MYSQL; db: cstring): cint
proc mysql_select_db_cont*(ret: ptr cint; mysql: ptr MYSQL; ready_status: cint): cint
proc mysql_set_character_set_start*(ret: ptr cint; mysql: ptr MYSQL; csname: cstring): cint
proc mysql_set_character_set_cont*(ret: ptr cint; mysql: ptr MYSQL; status: cint): cint
proc mysql_change_user_start*(ret: ptr my_bool; mysql: ptr MYSQL; user: cstring;
                             passwd: cstring; db: cstring): cint
proc mysql_change_user_cont*(ret: ptr my_bool; mysql: ptr MYSQL; status: cint): cint
proc mysql_send_query_start*(ret: ptr cint; mysql: ptr MYSQL; q: cstring; length: culong): cint
proc mysql_send_query_cont*(ret: ptr cint; mysql: ptr MYSQL; status: cint): cint
proc mysql_store_result_start*(ret: ptr ptr MYSQL_RES; mysql: ptr MYSQL): cint
proc mysql_store_result_cont*(ret: ptr ptr MYSQL_RES; mysql: ptr MYSQL; status: cint): cint
proc mysql_shutdown_start*(ret: ptr cint; mysql: ptr MYSQL;
                          shutdown_level: mysql_enum_shutdown_level): cint
proc mysql_shutdown_cont*(ret: ptr cint; mysql: ptr MYSQL; status: cint): cint
proc mysql_refresh_start*(ret: ptr cint; mysql: ptr MYSQL; refresh_options: cuint): cint
proc mysql_refresh_cont*(ret: ptr cint; mysql: ptr MYSQL; status: cint): cint
proc mysql_kill_start*(ret: ptr cint; mysql: ptr MYSQL; pid: culong): cint
proc mysql_kill_cont*(ret: ptr cint; mysql: ptr MYSQL; status: cint): cint
proc mysql_set_server_option_start*(ret: ptr cint; mysql: ptr MYSQL;
                                   option: enum_mysql_set_option): cint
proc mysql_set_server_option_cont*(ret: ptr cint; mysql: ptr MYSQL; status: cint): cint
proc mysql_ping_start*(ret: ptr cint; mysql: ptr MYSQL): cint
proc mysql_ping_cont*(ret: ptr cint; mysql: ptr MYSQL; status: cint): cint
proc mysql_stat_start*(ret: cstringArray; mysql: ptr MYSQL): cint
proc mysql_stat_cont*(ret: cstringArray; mysql: ptr MYSQL; status: cint): cint
proc mysql_read_query_result_start*(ret: ptr my_bool; mysql: ptr MYSQL): cint
proc mysql_read_query_result_cont*(ret: ptr my_bool; mysql: ptr MYSQL; status: cint): cint
##  Statements

proc mysql_stmt_init*(mysql: ptr MYSQL): ptr MYSQL_STMT
proc mysql_stmt_next_result_start*(ret: ptr cint; stmt: ptr MYSQL_STMT): cint
proc mysql_stmt_next_result_cont*(ret: ptr cint; stmt: ptr MYSQL_STMT; status: cint): cint
proc mysql_stmt_close_start*(ret: ptr my_bool; stmt: ptr MYSQL_STMT): cint
proc mysql_stmt_close_cont*(ret: ptr my_bool; stmt: ptr MYSQL_STMT; status: cint): cint
proc mysql_stmt_prepare_start*(ret: ptr cint; stmt: ptr MYSQL_STMT; query: cstring;
                              length: culong): cint
proc mysql_stmt_prepare_cont*(ret: ptr cint; stmt: ptr MYSQL_STMT; status: cint): cint
proc mysql_stmt_execute_start*(ret: ptr cint; stmt: ptr MYSQL_STMT): cint
proc mysql_stmt_execute_cont*(ret: ptr cint; stmt: ptr MYSQL_STMT; status: cint): cint
proc mysql_stmt_fetch_start*(ret: ptr cint; stmt: ptr MYSQL_STMT): cint
proc mysql_stmt_fetch_cont*(ret: ptr cint; stmt: ptr MYSQL_STMT; status: cint): cint
proc mysql_stmt_store_result_start*(ret: ptr cint; stmt: ptr MYSQL_STMT): cint
proc mysql_stmt_store_result_cont*(ret: ptr cint; stmt: ptr MYSQL_STMT; status: cint): cint
proc mysql_stmt_reset_start*(ret: ptr my_bool; stmt: ptr MYSQL_STMT): cint
proc mysql_stmt_reset_cont*(ret: ptr my_bool; stmt: ptr MYSQL_STMT; status: cint): cint
proc mysql_stmt_free_result_start*(ret: ptr my_bool; stmt: ptr MYSQL_STMT): cint
proc mysql_stmt_free_result_cont*(ret: ptr my_bool; stmt: ptr MYSQL_STMT; status: cint): cint
proc mysql_stmt_send_long_data_start*(ret: ptr my_bool; stmt: ptr MYSQL_STMT;
                                     param_number: cuint; data: cstring; len: culong): cint
proc mysql_stmt_send_long_data_cont*(ret: ptr my_bool; stmt: ptr MYSQL_STMT;
                                    status: cint): cint
proc mysql_free_result*(result: ptr MYSQL_RES)
proc mysql_close*(sock: ptr MYSQL)
