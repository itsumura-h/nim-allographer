##  Copyright (c) 2000, 2023, Oracle and/or its affiliates.
##
##    This program is free software; you can redistribute it and/or modify
##    it under the terms of the GNU General Public License, version 2.0,
##    as published by the Free Software Foundation.
##
##    This program is also distributed with certain software (including
##    but not limited to OpenSSL) that is licensed under separate terms,
##    as designated in a particular file or component or in included license
##    documentation.  The authors of MySQL hereby grant you an additional
##    permission to link the program and your derivative works with the
##    separately licensed software that they have included with MySQL.
##
##    Without limiting anything contained in the foregoing, this file,
##    which is part of C Driver for MySQL (Connector/C), is also subject to the
##    Universal FOSS Exception, version 1.0, a copy of which can be found at
##    http://oss.oracle.com/licenses/universal-foss-exception.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License, version 2.0, for more details.
##
##    You should have received a copy of the GNU General Public License
##    along with this program; if not, write to the Free Software
##    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA
##
##   @file include/mysql.h
##   This file defines the client API to MySQL and also the ABI of the
##   dynamically linked libmysqlclient.
##
##   The ABI should never be changed in a released product of MySQL,
##   thus you need to take great care when changing the file. In case
##   the file is changed so the ABI is broken, you must also update
##   the SHARED_LIB_MAJOR_VERSION in cmake/mysql_version.cmake
##

var mysql_port*: cuint

var mysql_unix_port*: cstring

const
  CLIENT_NET_RETRY_COUNT* = 1
  CLIENT_NET_READ_TIMEOUT* = 365 * 24 * 3600
  CLIENT_NET_WRITE_TIMEOUT* = 365 * 24 * 3600

template IS_PRI_KEY*(n: untyped): untyped =
  ((n) and PRI_KEY_FLAG)

template IS_NOT_NULL*(n: untyped): untyped =
  ((n) and NOT_NULL_FLAG)

template IS_BLOB*(n: untyped): untyped =
  ((n) and BLOB_FLAG)

##
##    Returns true if the value is a number which does not need quotes for
##    the sql_lex.cc parser to parse correctly.
##

template IS_NUM*(t: untyped): untyped =
  (((t) <= MYSQL_TYPE_INT24 and (t) != MYSQL_TYPE_TIMESTAMP) or
      (t) == MYSQL_TYPE_YEAR or (t) == MYSQL_TYPE_NEWDECIMAL)

template IS_LONGDATA*(t: untyped): untyped =
  ((t) >= MYSQL_TYPE_TINY_BLOB and (t) <= MYSQL_TYPE_STRING)

type
  MYSQL_FIELD* {.bycopy.} = object
    name*: cstring
    ##  Name of column
    org_name*: cstring
    ##  Original column name, if an alias
    table*: cstring
    ##  Table of column if column was a field
    org_table*: cstring
    ##  Org table name, if table was an alias
    db*: cstring
    ##  Database for table
    catalog*: cstring
    ##  Catalog for table
    def*: cstring
    ##  Default value (set by mysql_list_fields)
    length*: culong
    ##  Width of column (create length)
    max_length*: culong
    ##  Max width for selected set
    name_length*: cuint
    org_name_length*: cuint
    table_length*: cuint
    org_table_length*: cuint
    db_length*: cuint
    catalog_length*: cuint
    def_length*: cuint
    flags*: cuint
    ##  Div flags
    decimals*: cuint
    ##  Number of decimals in field
    charsetnr*: cuint
    ##  Character set
    `type`*: enum_field_types
    ##  Type of field. See mysql_com.h for types
    extension*: pointer

  MYSQL_ROW* = cstringArray

##  return data as array of strings

type
  MYSQL_FIELD_OFFSET* = cuint

##  offset to current field

const
  MYSQL_COUNT_ERROR* = (not cast[uint64_t](0))

##  backward compatibility define - to be removed eventually

const
  ER_WARN_DATA_TRUNCATED* = WARN_DATA_TRUNCATED

type
  MYSQL_ROWS* {.bycopy.} = object
    next*: ptr MYSQL_ROWS
    ##  list of rows
    data*: MYSQL_ROW
    length*: culong

  MYSQL_ROW_OFFSET* = ptr MYSQL_ROWS

##  offset to current row

discard "forward decl of MEM_ROOT"
type
  MYSQL_DATA* {.bycopy.} = object
    data*: ptr MYSQL_ROWS
    alloc*: ptr MEM_ROOT
    rows*: uint64_t
    fields*: cuint

  mysql_option* = enum
    MYSQL_OPT_CONNECT_TIMEOUT, MYSQL_OPT_COMPRESS, MYSQL_OPT_NAMED_PIPE,
    MYSQL_INIT_COMMAND, MYSQL_READ_DEFAULT_FILE, MYSQL_READ_DEFAULT_GROUP,
    MYSQL_SET_CHARSET_DIR, MYSQL_SET_CHARSET_NAME, MYSQL_OPT_LOCAL_INFILE,
    MYSQL_OPT_PROTOCOL, MYSQL_SHARED_MEMORY_BASE_NAME, MYSQL_OPT_READ_TIMEOUT,
    MYSQL_OPT_WRITE_TIMEOUT, MYSQL_OPT_USE_RESULT, MYSQL_REPORT_DATA_TRUNCATION,
    MYSQL_OPT_RECONNECT, MYSQL_PLUGIN_DIR, MYSQL_DEFAULT_AUTH, MYSQL_OPT_BIND,
    MYSQL_OPT_SSL_KEY, MYSQL_OPT_SSL_CERT, MYSQL_OPT_SSL_CA, MYSQL_OPT_SSL_CAPATH,
    MYSQL_OPT_SSL_CIPHER, MYSQL_OPT_SSL_CRL, MYSQL_OPT_SSL_CRLPATH,
    MYSQL_OPT_CONNECT_ATTR_RESET, MYSQL_OPT_CONNECT_ATTR_ADD,
    MYSQL_OPT_CONNECT_ATTR_DELETE, MYSQL_SERVER_PUBLIC_KEY,
    MYSQL_ENABLE_CLEARTEXT_PLUGIN, MYSQL_OPT_CAN_HANDLE_EXPIRED_PASSWORDS,
    MYSQL_OPT_MAX_ALLOWED_PACKET, MYSQL_OPT_NET_BUFFER_LENGTH,
    MYSQL_OPT_TLS_VERSION, MYSQL_OPT_SSL_MODE, MYSQL_OPT_GET_SERVER_PUBLIC_KEY,
    MYSQL_OPT_RETRY_COUNT, MYSQL_OPT_OPTIONAL_RESULTSET_METADATA,
    MYSQL_OPT_SSL_FIPS_MODE, MYSQL_OPT_TLS_CIPHERSUITES,
    MYSQL_OPT_COMPRESSION_ALGORITHMS, MYSQL_OPT_ZSTD_COMPRESSION_LEVEL,
    MYSQL_OPT_LOAD_DATA_LOCAL_DIR, MYSQL_OPT_USER_PASSWORD,
    MYSQL_OPT_SSL_SESSION_DATA


##
##   @todo remove the "extension", move st_mysql_options completely
##   out of mysql.h
##

discard "forward decl of st_mysql_options_extention"
type
  st_mysql_options* {.bycopy.} = object
    connect_timeout*: cuint
    read_timeout*: cuint
    write_timeout*: cuint
    port*: cuint
    protocol*: cuint
    client_flag*: culong
    host*: cstring
    user*: cstring
    password*: cstring
    unix_socket*: cstring
    db*: cstring
    init_commands*: ptr Init_commands_array
    my_cnf_file*: cstring
    my_cnf_group*: cstring
    charset_dir*: cstring
    charset_name*: cstring
    ssl_key*: cstring
    ##  PEM key file
    ssl_cert*: cstring
    ##  PEM cert file
    ssl_ca*: cstring
    ##  PEM CA file
    ssl_capath*: cstring
    ##  PEM directory of CA-s?
    ssl_cipher*: cstring
    ##  cipher to use
    shared_memory_base_name*: cstring
    max_allowed_packet*: culong
    compress*: bool
    named_pipe*: bool
    ##
    ##     The local address to bind when connecting to remote server.
    ##
    bind_address*: cstring
    ##  0 - never report, 1 - always report (default)
    report_data_truncation*: bool
    ##  function pointers for local infile support
    local_infile_init*: proc (a1: ptr pointer; a2: cstring; a3: pointer): cint
    local_infile_read*: proc (a1: pointer; a2: cstring; a3: cuint): cint
    local_infile_end*: proc (a1: pointer)
    local_infile_error*: proc (a1: pointer; a2: cstring; a3: cuint): cint
    local_infile_userdata*: pointer
    extension*: ptr st_mysql_options_extention

  mysql_status* = enum
    MYSQL_STATUS_READY, MYSQL_STATUS_GET_RESULT, MYSQL_STATUS_USE_RESULT,
    MYSQL_STATUS_STATEMENT_GET_RESULT


type
  mysql_protocol_type* = enum
    MYSQL_PROTOCOL_DEFAULT, MYSQL_PROTOCOL_TCP, MYSQL_PROTOCOL_SOCKET,
    MYSQL_PROTOCOL_PIPE, MYSQL_PROTOCOL_MEMORY


type
  mysql_ssl_mode* = enum
    SSL_MODE_DISABLED = 1, SSL_MODE_PREFERRED, SSL_MODE_REQUIRED, SSL_MODE_VERIFY_CA,
    SSL_MODE_VERIFY_IDENTITY


type
  mysql_ssl_fips_mode* = enum
    SSL_FIPS_MODE_OFF = 0, SSL_FIPS_MODE_ON = 1, SSL_FIPS_MODE_STRICT


type
  MY_CHARSET_INFO* {.bycopy.} = object
    number*: cuint
    ##  character set number
    state*: cuint
    ##  character set state
    csname*: cstring
    ##  character set name
    name*: cstring
    ##  collation name
    comment*: cstring
    ##  comment
    dir*: cstring
    ##  character set directory
    mbminlen*: cuint
    ##  min. length for multibyte strings
    mbmaxlen*: cuint
    ##  max. length for multibyte strings


discard "forward decl of MYSQL_METHODS"
discard "forward decl of MYSQL_STMT"
type
  MYSQL* {.bycopy.} = object
    net*: NET
    ##  Communication parameters
    connector_fd*: ptr cuchar
    ##  ConnectorFd for SSL
    host*: cstring
    user*: cstring
    passwd*: cstring
    unix_socket*: cstring
    server_version*: cstring
    host_info*: cstring
    info*: cstring
    db*: cstring
    charset*: ptr CHARSET_INFO
    fields*: ptr MYSQL_FIELD
    field_alloc*: ptr MEM_ROOT
    affected_rows*: uint64_t
    insert_id*: uint64_t
    ##  id if insert on table with NEXTNR
    extra_info*: uint64_t
    ##  Not used
    thread_id*: culong
    ##  Id for connection in server
    packet_length*: culong
    port*: cuint
    client_flag*: culong
    server_capabilities*: culong
    protocol_version*: cuint
    field_count*: cuint
    server_status*: cuint
    server_language*: cuint
    warning_count*: cuint
    options*: st_mysql_options
    status*: mysql_status
    resultset_metadata*: enum_resultset_metadata
    free_me*: bool
    ##  If free in mysql_close
    reconnect*: bool
    ##  set to 1 if automatic reconnect
    ##  session-wide random string
    scramble*: array[SCRAMBLE_LENGTH + 1, char]
    stmts*: ptr LIST
    ##  list of all statements
    methods*: ptr MYSQL_METHODS
    thd*: pointer
    ##
    ##     Points to boolean flag in MYSQL_RES  or MYSQL_STMT. We set this flag
    ##     from mysql_stmt_close if close had to cancel result set of this object.
    ##
    unbuffered_fetch_owner*: ptr bool
    extension*: pointer

  MYSQL_RES* {.bycopy.} = object
    row_count*: uint64_t
    fields*: ptr MYSQL_FIELD
    data*: ptr MYSQL_DATA
    data_cursor*: ptr MYSQL_ROWS
    lengths*: ptr culong
    ##  column lengths of current row
    handle*: ptr MYSQL
    ##  for unbuffered reads
    methods*: ptr MYSQL_METHODS
    row*: MYSQL_ROW
    ##  If unbuffered read
    current_row*: MYSQL_ROW
    ##  buffer to current row
    field_alloc*: ptr MEM_ROOT
    field_count*: cuint
    current_field*: cuint
    eof*: bool
    ##  Used by mysql_fetch_row
    ##  mysql_stmt_close() had to cancel this result
    unbuffered_fetch_cancelled*: bool
    metadata*: enum_resultset_metadata
    extension*: pointer


##
##   Flag to indicate that COM_BINLOG_DUMP_GTID should
##   be used rather than COM_BINLOG_DUMP in the @sa mysql_binlog_open().
##

const
  MYSQL_RPL_GTID* = (1 shl 16)

##
##   Skip HEARBEAT events in the @sa mysql_binlog_fetch().
##

const
  MYSQL_RPL_SKIP_HEARTBEAT* = (1 shl 17)

##
##  Flag to indicate that the heartbeat_event being generated
##  is using the class Heartbeat_event_v2
##

const
  USE_HEARTBEAT_EVENT_V2* = (1 shl 1)

##
##   Struct for information about a replication stream.
##
##   @sa mysql_binlog_open()
##   @sa mysql_binlog_fetch()
##   @sa mysql_binlog_close()
##

type
  MYSQL_RPL* {.bycopy.} = object
    file_name_length*: csize_t
    ##  Length of the 'file_name' or 0
    file_name*: cstring
    ##  Filename of the binary log to read
    start_position*: uint64_t
    ##  Position in the binary log to
    ##   start reading from
    server_id*: cuint
    ##  Server ID to use when identifying
    ##   with the master
    flags*: cuint
    ##  Flags, e.g. MYSQL_RPL_GTID
    ##  Size of gtid set data
    gtid_set_encoded_size*: csize_t
    ##  Callback function which is called
    ##   from @sa mysql_binlog_open() to
    ##   fill command packet gtid set
    fix_gtid_set*: proc (rpl: ptr MYSQL_RPL; packet_gtid_set: ptr cuchar)
    gtid_set_arg*: pointer
    ##  GTID set data or an argument for
    ##   fix_gtid_set() callback function
    size*: culong
    ##  Size of the packet returned by
    ##   mysql_binlog_fetch()
    buffer*: ptr cuchar
    ##  Pointer to returned data


##
##   Set up and bring down the server; to ensure that applications will
##   work when linked against either the standard client library or the
##   embedded server library, these functions should be called.
##

proc mysql_server_init*(argc: cint; argv: cstringArray; groups: cstringArray): cint
proc mysql_server_end*()
##
##   mysql_server_init/end need to be called when using libmysqld or
##   libmysqlclient (exactly, mysql_server_init() is called by mysql_init() so
##   you don't need to call it explicitly; but you need to call
##   mysql_server_end() to free memory). The names are a bit misleading
##   (mysql_SERVER* to be used when using libmysqlCLIENT). So we add more general
##   names which suit well whether you're using libmysqld or libmysqlclient. We
##   intend to promote these aliases over the mysql_server* ones.
##

const
  mysql_library_init* = mysql_server_init
  mysql_library_end* = mysql_server_end

##
##   Set up and bring down a thread; these function should be called
##   for each thread in an application which opens at least one MySQL
##   connection.  All uses of the connection(s) should be between these
##   function calls.
##

proc mysql_thread_init*(): bool
proc mysql_thread_end*()
##
##   Functions to get information from the MYSQL and MYSQL_RES structures
##   Should definitely be used if one uses shared libraries.
##

proc mysql_num_rows*(res: ptr MYSQL_RES): uint64_t
proc mysql_num_fields*(res: ptr MYSQL_RES): cuint
proc mysql_eof*(res: ptr MYSQL_RES): bool
proc mysql_fetch_field_direct*(res: ptr MYSQL_RES; fieldnr: cuint): ptr MYSQL_FIELD
proc mysql_fetch_fields*(res: ptr MYSQL_RES): ptr MYSQL_FIELD
proc mysql_row_tell*(res: ptr MYSQL_RES): MYSQL_ROW_OFFSET
proc mysql_field_tell*(res: ptr MYSQL_RES): MYSQL_FIELD_OFFSET
proc mysql_result_metadata*(result: ptr MYSQL_RES): enum_resultset_metadata
proc mysql_field_count*(mysql: ptr MYSQL): cuint
proc mysql_affected_rows*(mysql: ptr MYSQL): uint64_t
proc mysql_insert_id*(mysql: ptr MYSQL): uint64_t
proc mysql_errno*(mysql: ptr MYSQL): cuint
proc mysql_error*(mysql: ptr MYSQL): cstring
proc mysql_sqlstate*(mysql: ptr MYSQL): cstring
proc mysql_warning_count*(mysql: ptr MYSQL): cuint
proc mysql_info*(mysql: ptr MYSQL): cstring
proc mysql_thread_id*(mysql: ptr MYSQL): culong
proc mysql_character_set_name*(mysql: ptr MYSQL): cstring
proc mysql_set_character_set*(mysql: ptr MYSQL; csname: cstring): cint
proc mysql_init*(mysql: ptr MYSQL): ptr MYSQL
proc mysql_ssl_set*(mysql: ptr MYSQL; key: cstring; cert: cstring; ca: cstring;
                   capath: cstring; cipher: cstring): bool
proc mysql_get_ssl_cipher*(mysql: ptr MYSQL): cstring
proc mysql_get_ssl_session_reused*(mysql: ptr MYSQL): bool
proc mysql_get_ssl_session_data*(mysql: ptr MYSQL; n_ticket: cuint; out_len: ptr cuint): pointer
proc mysql_free_ssl_session_data*(mysql: ptr MYSQL; data: pointer): bool
proc mysql_change_user*(mysql: ptr MYSQL; user: cstring; passwd: cstring; db: cstring): bool
proc mysql_real_connect*(mysql: ptr MYSQL; host: cstring; user: cstring;
                        passwd: cstring; db: cstring; port: cuint;
                        unix_socket: cstring; clientflag: culong): ptr MYSQL
proc mysql_select_db*(mysql: ptr MYSQL; db: cstring): cint
proc mysql_query*(mysql: ptr MYSQL; q: cstring): cint
proc mysql_send_query*(mysql: ptr MYSQL; q: cstring; length: culong): cint
proc mysql_real_query*(mysql: ptr MYSQL; q: cstring; length: culong): cint
proc mysql_store_result*(mysql: ptr MYSQL): ptr MYSQL_RES
proc mysql_use_result*(mysql: ptr MYSQL): ptr MYSQL_RES
proc mysql_real_connect_nonblocking*(mysql: ptr MYSQL; host: cstring; user: cstring;
                                    passwd: cstring; db: cstring; port: cuint;
                                    unix_socket: cstring; clientflag: culong): net_async_status
proc mysql_send_query_nonblocking*(mysql: ptr MYSQL; query: cstring; length: culong): net_async_status
proc mysql_real_query_nonblocking*(mysql: ptr MYSQL; query: cstring; length: culong): net_async_status
proc mysql_store_result_nonblocking*(mysql: ptr MYSQL; result: ptr ptr MYSQL_RES): net_async_status
proc mysql_next_result_nonblocking*(mysql: ptr MYSQL): net_async_status
proc mysql_select_db_nonblocking*(mysql: ptr MYSQL; db: cstring; error: ptr bool): net_async_status
proc mysql_get_character_set_info*(mysql: ptr MYSQL; charset: ptr MY_CHARSET_INFO)
proc mysql_session_track_get_first*(mysql: ptr MYSQL;
                                   `type`: enum_session_state_type;
                                   data: cstringArray; length: ptr csize_t): cint
proc mysql_session_track_get_next*(mysql: ptr MYSQL;
                                  `type`: enum_session_state_type;
                                  data: cstringArray; length: ptr csize_t): cint
##  local infile support

const
  LOCAL_INFILE_ERROR_LEN* = 512

proc mysql_set_local_infile_handler*(mysql: ptr MYSQL; local_infile_init: proc (
    a1: ptr pointer; a2: cstring; a3: pointer): cint; local_infile_read: proc (
    a1: pointer; a2: cstring; a3: cuint): cint; local_infile_end: proc (a1: pointer);
    local_infile_error: proc (a1: pointer; a2: cstring; a3: cuint): cint; a6: pointer)
proc mysql_set_local_infile_default*(mysql: ptr MYSQL)
proc mysql_shutdown*(mysql: ptr MYSQL; shutdown_level: mysql_enum_shutdown_level): cint
proc mysql_dump_debug_info*(mysql: ptr MYSQL): cint
proc mysql_refresh*(mysql: ptr MYSQL; refresh_options: cuint): cint
proc mysql_kill*(mysql: ptr MYSQL; pid: culong): cint
proc mysql_set_server_option*(mysql: ptr MYSQL; option: enum_mysql_set_option): cint
proc mysql_ping*(mysql: ptr MYSQL): cint
proc mysql_stat*(mysql: ptr MYSQL): cstring
proc mysql_get_server_info*(mysql: ptr MYSQL): cstring
proc mysql_get_client_info*(): cstring
proc mysql_get_client_version*(): culong
proc mysql_get_host_info*(mysql: ptr MYSQL): cstring
proc mysql_get_server_version*(mysql: ptr MYSQL): culong
proc mysql_get_proto_info*(mysql: ptr MYSQL): cuint
proc mysql_list_dbs*(mysql: ptr MYSQL; wild: cstring): ptr MYSQL_RES
proc mysql_list_tables*(mysql: ptr MYSQL; wild: cstring): ptr MYSQL_RES
proc mysql_list_processes*(mysql: ptr MYSQL): ptr MYSQL_RES
proc mysql_options*(mysql: ptr MYSQL; option: mysql_option; arg: pointer): cint
proc mysql_options4*(mysql: ptr MYSQL; option: mysql_option; arg1: pointer;
                    arg2: pointer): cint
proc mysql_get_option*(mysql: ptr MYSQL; option: mysql_option; arg: pointer): cint
proc mysql_free_result*(result: ptr MYSQL_RES)
proc mysql_free_result_nonblocking*(result: ptr MYSQL_RES): net_async_status
proc mysql_data_seek*(result: ptr MYSQL_RES; offset: uint64_t)
proc mysql_row_seek*(result: ptr MYSQL_RES; offset: MYSQL_ROW_OFFSET): MYSQL_ROW_OFFSET
proc mysql_field_seek*(result: ptr MYSQL_RES; offset: MYSQL_FIELD_OFFSET): MYSQL_FIELD_OFFSET
proc mysql_fetch_row*(result: ptr MYSQL_RES): MYSQL_ROW
proc mysql_fetch_row_nonblocking*(res: ptr MYSQL_RES; row: ptr MYSQL_ROW): net_async_status
proc mysql_fetch_lengths*(result: ptr MYSQL_RES): ptr culong
proc mysql_fetch_field*(result: ptr MYSQL_RES): ptr MYSQL_FIELD
proc mysql_list_fields*(mysql: ptr MYSQL; table: cstring; wild: cstring): ptr MYSQL_RES
proc mysql_escape_string*(to: cstring; `from`: cstring; from_length: culong): culong
proc mysql_hex_string*(to: cstring; `from`: cstring; from_length: culong): culong
proc mysql_real_escape_string*(mysql: ptr MYSQL; to: cstring; `from`: cstring;
                              length: culong): culong
proc mysql_real_escape_string_quote*(mysql: ptr MYSQL; to: cstring; `from`: cstring;
                                    length: culong; quote: char): culong
proc mysql_debug*(debug: cstring)
proc myodbc_remove_escape*(mysql: ptr MYSQL; name: cstring)
proc mysql_thread_safe*(): cuint
proc mysql_read_query_result*(mysql: ptr MYSQL): bool
proc mysql_reset_connection*(mysql: ptr MYSQL): cint
proc mysql_binlog_open*(mysql: ptr MYSQL; rpl: ptr MYSQL_RPL): cint
proc mysql_binlog_fetch*(mysql: ptr MYSQL; rpl: ptr MYSQL_RPL): cint
proc mysql_binlog_close*(mysql: ptr MYSQL; rpl: ptr MYSQL_RPL)
##
##   The following definitions are added for the enhanced
##   client-server protocol
##
##  statement state

type
  enum_mysql_stmt_state* = enum
    MYSQL_STMT_INIT_DONE = 1, MYSQL_STMT_PREPARE_DONE, MYSQL_STMT_EXECUTE_DONE,
    MYSQL_STMT_FETCH_DONE


##
##   This structure is used to define bind information, and
##   internally by the client library.
##   Public members with their descriptions are listed below
##   (conventionally `On input' refers to the binds given to
##   mysql_stmt_bind_param, `On output' refers to the binds given
##   to mysql_stmt_bind_result):
##
##   buffer_type    - One of the MYSQL_* types, used to describe
##                    the host language type of buffer.
##                    On output: if column type is different from
##                    buffer_type, column value is automatically converted
##                    to buffer_type before it is stored in the buffer.
##   buffer         - On input: points to the buffer with input data.
##                    On output: points to the buffer capable to store
##                    output data.
##                    The type of memory pointed by buffer must correspond
##                    to buffer_type. See the correspondence table in
##                    the comment to mysql_stmt_bind_param.
##
##   The two above members are mandatory for any kind of bind.
##
##   buffer_length  - the length of the buffer. You don't have to set
##                    it for any fixed length buffer: float, double,
##                    int, etc. It must be set however for variable-length
##                    types, such as BLOBs or STRINGs.
##
##   length         - On input: in case when lengths of input values
##                    are different for each execute, you can set this to
##                    point at a variable containing value length. This
##                    way the value length can be different in each execute.
##                    If length is not NULL, buffer_length is not used.
##                    Note, length can even point at buffer_length if
##                    you keep bind structures around while fetching:
##                    this way you can change buffer_length before
##                    each execution, everything will work ok.
##                    On output: if length is set, mysql_stmt_fetch will
##                    write column length into it.
##
##   is_null        - On input: points to a boolean variable that should
##                    be set to TRUE for NULL values.
##                    This member is useful only if your data may be
##                    NULL in some but not all cases.
##                    If your data is never NULL, is_null should be set to 0.
##                    If your data is always NULL, set buffer_type
##                    to MYSQL_TYPE_NULL, and is_null will not be used.
##
##   is_unsigned    - On input: used to signify that values provided for one
##                    of numeric types are unsigned.
##                    On output describes signedness of the output buffer.
##                    If, taking into account is_unsigned flag, column data
##                    is out of range of the output buffer, data for this column
##                    is regarded truncated. Note that this has no correspondence
##                    to the sign of result set column, if you need to find it out
##                    use mysql_stmt_result_metadata.
##   error          - where to write a truncation error if it is present.
##                    possible error value is:
##                    0  no truncation
##                    1  value is out of range or buffer is too small
##
##   Please note that MYSQL_BIND also has internals members.
##

type
  MYSQL_BIND* {.bycopy.} = object
    length*: ptr culong
    ##  output length pointer
    is_null*: ptr bool
    ##  Pointer to null indicator
    buffer*: pointer
    ##  buffer to get/put data
    ##  set this if you want to track data truncations happened during fetch
    error*: ptr bool
    row_ptr*: ptr cuchar
    ##  for the current data position
    store_param_func*: proc (net: ptr NET; param: ptr MYSQL_BIND)
    fetch_result*: proc (a1: ptr MYSQL_BIND; a2: ptr MYSQL_FIELD; row: ptr ptr cuchar)
    skip_result*: proc (a1: ptr MYSQL_BIND; a2: ptr MYSQL_FIELD; row: ptr ptr cuchar)
    ##  output buffer length, must be set when fetching str/binary
    buffer_length*: culong
    offset*: culong
    ##  offset position for char/binary fetch
    length_value*: culong
    ##  Used if length is 0
    param_number*: cuint
    ##  For null count and error messages
    pack_length*: cuint
    ##  Internal length for packed data
    buffer_type*: enum_field_types
    ##  buffer type
    error_value*: bool
    ##  used if error is 0
    is_unsigned*: bool
    ##  set if integer type is unsigned
    long_data_used*: bool
    ##  If used with mysql_send_long_data
    is_null_value*: bool
    ##  Used if is_null is 0
    extension*: pointer


discard "forward decl of MYSQL_STMT_EXT"
type
  MYSQL_STMT* {.bycopy.} = object
    mem_root*: ptr MEM_ROOT
    ##  root allocations
    list*: LIST
    ##  list to keep track of all stmts
    mysql*: ptr MYSQL
    ##  connection handle
    params*: ptr MYSQL_BIND
    ##  input parameters
    `bind`*: ptr MYSQL_BIND
    ##  output parameters
    fields*: ptr MYSQL_FIELD
    ##  result set metadata
    result*: MYSQL_DATA
    ##  cached result set
    data_cursor*: ptr MYSQL_ROWS
    ##  current row in cached result
    ##
    ##     mysql_stmt_fetch() calls this function to fetch one row (it's different
    ##     for buffered, unbuffered and cursor fetch).
    ##
    read_row_func*: proc (stmt: ptr MYSQL_STMT; row: ptr ptr cuchar): cint
    ##  copy of mysql->affected_rows after statement execution
    affected_rows*: uint64_t
    insert_id*: uint64_t
    ##  copy of mysql->insert_id
    stmt_id*: culong
    ##  Id for prepared statement
    flags*: culong
    ##  i.e. type of cursor to open
    prefetch_rows*: culong
    ##  number of rows per one COM_FETCH
    ##
    ##     Copied from mysql->server_status after execute/fetch to know
    ##     server-side cursor status for this statement.
    ##
    server_status*: cuint
    last_errno*: cuint
    ##  error code
    param_count*: cuint
    ##  input parameter count
    field_count*: cuint
    ##  number of columns in result set
    state*: enum_mysql_stmt_state
    ##  statement state
    last_error*: array[MYSQL_ERRMSG_SIZE, char]
    ##  error message
    sqlstate*: array[SQLSTATE_LENGTH + 1, char]
    ##  Types of input parameters should be sent to server
    send_types_to_server*: bool
    bind_param_done*: bool
    ##  input buffers were supplied
    bind_result_done*: cuchar
    ##  output buffers were supplied
    ##  mysql_stmt_close() had to cancel this result
    unbuffered_fetch_cancelled*: bool
    ##
    ##     Is set to true if we need to calculate field->max_length for
    ##     metadata fields when doing mysql_stmt_store_result.
    ##
    update_max_length*: bool
    extension*: ptr MYSQL_STMT_EXT

  enum_stmt_attr_type* = enum ##
                           ##     When doing mysql_stmt_store_result calculate max_length attribute
                           ##     of statement metadata. This is to be consistent with the old API,
                           ##     where this was done automatically.
                           ##     In the new API we do that only by request because it slows down
                           ##     mysql_stmt_store_result sufficiently.
                           ##
    STMT_ATTR_UPDATE_MAX_LENGTH, ##
                                ##     unsigned long with combination of cursor flags (read only, for update,
                                ##     etc)
                                ##
    STMT_ATTR_CURSOR_TYPE, ##
                          ##     Amount of rows to retrieve from server per one fetch if using cursors.
                          ##     Accepts unsigned long attribute in the range 1 - ulong_max
                          ##
    STMT_ATTR_PREFETCH_ROWS


proc mysql_bind_param*(mysql: ptr MYSQL; n_params: cuint; binds: ptr MYSQL_BIND;
                      names: cstringArray): bool
proc mysql_stmt_init*(mysql: ptr MYSQL): ptr MYSQL_STMT
proc mysql_stmt_prepare*(stmt: ptr MYSQL_STMT; query: cstring; length: culong): cint
proc mysql_stmt_execute*(stmt: ptr MYSQL_STMT): cint
proc mysql_stmt_fetch*(stmt: ptr MYSQL_STMT): cint
proc mysql_stmt_fetch_column*(stmt: ptr MYSQL_STMT; bind_arg: ptr MYSQL_BIND;
                             column: cuint; offset: culong): cint
proc mysql_stmt_store_result*(stmt: ptr MYSQL_STMT): cint
proc mysql_stmt_param_count*(stmt: ptr MYSQL_STMT): culong
proc mysql_stmt_attr_set*(stmt: ptr MYSQL_STMT; attr_type: enum_stmt_attr_type;
                         attr: pointer): bool
proc mysql_stmt_attr_get*(stmt: ptr MYSQL_STMT; attr_type: enum_stmt_attr_type;
                         attr: pointer): bool
proc mysql_stmt_bind_param*(stmt: ptr MYSQL_STMT; bnd: ptr MYSQL_BIND): bool
proc mysql_stmt_bind_result*(stmt: ptr MYSQL_STMT; bnd: ptr MYSQL_BIND): bool
proc mysql_stmt_close*(stmt: ptr MYSQL_STMT): bool
proc mysql_stmt_reset*(stmt: ptr MYSQL_STMT): bool
proc mysql_stmt_free_result*(stmt: ptr MYSQL_STMT): bool
proc mysql_stmt_send_long_data*(stmt: ptr MYSQL_STMT; param_number: cuint;
                               data: cstring; length: culong): bool
proc mysql_stmt_result_metadata*(stmt: ptr MYSQL_STMT): ptr MYSQL_RES
proc mysql_stmt_param_metadata*(stmt: ptr MYSQL_STMT): ptr MYSQL_RES
proc mysql_stmt_errno*(stmt: ptr MYSQL_STMT): cuint
proc mysql_stmt_error*(stmt: ptr MYSQL_STMT): cstring
proc mysql_stmt_sqlstate*(stmt: ptr MYSQL_STMT): cstring
proc mysql_stmt_row_seek*(stmt: ptr MYSQL_STMT; offset: MYSQL_ROW_OFFSET): MYSQL_ROW_OFFSET
proc mysql_stmt_row_tell*(stmt: ptr MYSQL_STMT): MYSQL_ROW_OFFSET
proc mysql_stmt_data_seek*(stmt: ptr MYSQL_STMT; offset: uint64_t)
proc mysql_stmt_num_rows*(stmt: ptr MYSQL_STMT): uint64_t
proc mysql_stmt_affected_rows*(stmt: ptr MYSQL_STMT): uint64_t
proc mysql_stmt_insert_id*(stmt: ptr MYSQL_STMT): uint64_t
proc mysql_stmt_field_count*(stmt: ptr MYSQL_STMT): cuint
proc mysql_commit*(mysql: ptr MYSQL): bool
proc mysql_rollback*(mysql: ptr MYSQL): bool
proc mysql_autocommit*(mysql: ptr MYSQL; auto_mode: bool): bool
proc mysql_more_results*(mysql: ptr MYSQL): bool
proc mysql_next_result*(mysql: ptr MYSQL): cint
proc mysql_stmt_next_result*(stmt: ptr MYSQL_STMT): cint
proc mysql_close*(sock: ptr MYSQL)
##  Public key reset

proc mysql_reset_server_public_key*()
##  status return codes

const
  MYSQL_NO_DATA* = 100
  MYSQL_DATA_TRUNCATED* = 101

template mysql_reload*(mysql: untyped): untyped =
  mysql_refresh((mysql), REFRESH_GRANT)

proc mysql_real_connect_dns_srv*(mysql: ptr MYSQL; dns_srv_name: cstring;
                                user: cstring; passwd: cstring; db: cstring;
                                client_flag: culong): ptr MYSQL
