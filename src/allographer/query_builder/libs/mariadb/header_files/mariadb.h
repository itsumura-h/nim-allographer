#define FFI_SCOPE "mariadb"
#define FFI_LIB "libmariadb.so"

//this header file is copied from
//https://github.com/katajakasa/async-mariadb-c-testing/blob/29919ef8cca8622fb7bf21e9924596cd84ce8e03/mariadb.h
//https://github.com/luapower/mysql/blob/master/mysql_h.lua

typedef char my_bool;

typedef char ** MYSQL_ROW;
typedef struct st_mysql MYSQL;
typedef struct st_mysql_res MYSQL_RES;
typedef struct st_mysql_stmt MYSQL_STMT;

enum enum_field_types {
    MYSQL_TYPE_DECIMAL,
    MYSQL_TYPE_TINY,
    MYSQL_TYPE_SHORT,
    MYSQL_TYPE_LONG,
    MYSQL_TYPE_FLOAT,
    MYSQL_TYPE_DOUBLE,
    MYSQL_TYPE_NULL,
    MYSQL_TYPE_TIMESTAMP,
    MYSQL_TYPE_LONGLONG,
    MYSQL_TYPE_INT24,
    MYSQL_TYPE_DATE,
    MYSQL_TYPE_TIME,
    MYSQL_TYPE_DATETIME,
    MYSQL_TYPE_YEAR,
    MYSQL_TYPE_NEWDATE,
    MYSQL_TYPE_VARCHAR,
    MYSQL_TYPE_BIT,
    MYSQL_TYPE_NEWDECIMAL = 246,
    MYSQL_TYPE_ENUM = 247,
    MYSQL_TYPE_SET = 248,
    MYSQL_TYPE_TINY_BLOB = 249,
    MYSQL_TYPE_MEDIUM_BLOB = 250,
    MYSQL_TYPE_LONG_BLOB = 251,
    MYSQL_TYPE_BLOB = 252,
    MYSQL_TYPE_VAR_STRING = 253,
    MYSQL_TYPE_STRING = 254,
    MYSQL_TYPE_GEOMETRY = 255,
    MAX_NO_FIELD_TYPES
 };

typedef struct st_mysql_field {
    char *name;
    char *org_name;
    char *table;
    char *org_table;
    char *db;
    char *catalog;
    char *def;
    unsigned long length;
    unsigned long max_length;
    unsigned int name_length;
    unsigned int org_name_length;
    unsigned int table_length;
    unsigned int org_table_length;
    unsigned int db_length;
    unsigned int catalog_length;
    unsigned int def_length;
    unsigned int flags;
    unsigned int decimals;
    unsigned int charsetnr;
    enum enum_field_types type;
    void *extension;
} MYSQL_FIELD;

#define MYSQL_WAIT_READ      1
#define MYSQL_WAIT_WRITE     2
#define MYSQL_WAIT_EXCEPT    4
#define MYSQL_WAIT_TIMEOUT   8

enum mysql_option {
    MYSQL_OPT_CONNECT_TIMEOUT,
    MYSQL_OPT_COMPRESS,
    MYSQL_OPT_NAMED_PIPE,
    MYSQL_INIT_COMMAND,
    MYSQL_READ_DEFAULT_FILE,
    MYSQL_READ_DEFAULT_GROUP,
    MYSQL_SET_CHARSET_DIR,
    MYSQL_SET_CHARSET_NAME,
    MYSQL_OPT_LOCAL_INFILE,
    MYSQL_OPT_PROTOCOL,
    MYSQL_SHARED_MEMORY_BASE_NAME,
    MYSQL_OPT_READ_TIMEOUT,
    MYSQL_OPT_WRITE_TIMEOUT,
    MYSQL_OPT_USE_RESULT,
    MYSQL_OPT_USE_REMOTE_CONNECTION,
    MYSQL_OPT_USE_EMBEDDED_CONNECTION,
    MYSQL_OPT_GUESS_CONNECTION,
    MYSQL_SET_CLIENT_IP,
    MYSQL_SECURE_AUTH,
    MYSQL_REPORT_DATA_TRUNCATION,
    MYSQL_OPT_RECONNECT,
    MYSQL_OPT_SSL_VERIFY_SERVER_CERT,
    MYSQL_PLUGIN_DIR,
    MYSQL_DEFAULT_AUTH,
    MYSQL_OPT_BIND,
    MYSQL_OPT_SSL_KEY,
    MYSQL_OPT_SSL_CERT,
    MYSQL_OPT_SSL_CA,
    MYSQL_OPT_SSL_CAPATH,
    MYSQL_OPT_SSL_CIPHER,
    MYSQL_OPT_SSL_CRL,
    MYSQL_OPT_SSL_CRLPATH,

    MYSQL_OPT_CONNECT_ATTR_RESET,
    MYSQL_OPT_CONNECT_ATTR_ADD,
    MYSQL_OPT_CONNECT_ATTR_DELETE,
    MYSQL_SERVER_PUBLIC_KEY,
    MYSQL_ENABLE_CLEARTEXT_PLUGIN,

    MYSQL_PROGRESS_CALLBACK=5999,
    MYSQL_OPT_NONBLOCK
};

// Custom code
//int wait_for_mysql(MYSQL *mysql, int status);

// Init, connect and close
MYSQL* mysql_init(MYSQL *mysql);
int	mysql_options(MYSQL *mysql, enum mysql_option option, const void *arg);
MYSQL * mysql_real_connect(MYSQL *mysql, const char *host,
        const char *user,
        const char *passwd,
        const char *db,
        unsigned int port,
        const char *unix_socket,
        unsigned long clientflag);

int mysql_real_connect_start(
    MYSQL **ret, MYSQL *mysql,
    const char *host, const char *user, const char *passwd, const char *db, unsigned int port,
    const char *unix_socket, unsigned long client_flag);
int mysql_real_connect_cont(MYSQL **ret, MYSQL *mysql, int status);
int mysql_close_start(MYSQL *sock);
int mysql_close_cont(MYSQL *sock, int status);

// Error handling
unsigned int mysql_errno(MYSQL *mysql);
const char* mysql_error(MYSQL *mysql);

// Querying
int mysql_query(MYSQL *mysql, const char *q);
int mysql_real_query_start(int *ret, MYSQL *mysql, const char *q, unsigned long length);
int mysql_real_query_cont(int *ret, MYSQL *mysql, int status);

// Result handling
MYSQL_RES* mysql_store_result(MYSQL *mysql);
MYSQL_RES* mysql_use_result(MYSQL *mysql);
int mysql_free_result_start(MYSQL_RES *result);
int mysql_free_result_cont(MYSQL_RES *result, int status);
unsigned int mysql_num_fields(MYSQL_RES *result);
unsigned long* mysql_fetch_lengths(MYSQL_RES *result);
MYSQL_FIELD* mysql_fetch_fields(MYSQL_RES * result);

MYSQL_ROW mysql_fetch_row(MYSQL_RES *result);
// Row handling
int mysql_fetch_row_start(MYSQL_ROW *ret, MYSQL_RES *result);
int mysql_fetch_row_cont(MYSQL_ROW *ret, MYSQL_RES *result, int status);

// Transactions
int mysql_commit_start(my_bool *ret, MYSQL * mysql);
int mysql_commit_cont(my_bool *ret, MYSQL * mysql, int status);
int mysql_rollback_start(my_bool *ret, MYSQL * mysql);
int mysql_rollback_cont(my_bool *ret, MYSQL * mysql, int status);
int mysql_autocommit_start(my_bool *ret, MYSQL * mysql, my_bool auto_mode);
int mysql_autocommit_cont(my_bool *ret, MYSQL * mysql, int status);

int mysql_next_result_start(int *ret, MYSQL *mysql);
int mysql_next_result_cont(int *ret, MYSQL *mysql, int status);
int mysql_select_db_start(int *ret, MYSQL *mysql, const char *db);
int mysql_select_db_cont(int *ret, MYSQL *mysql, int ready_status);

int mysql_set_character_set_start(int *ret, MYSQL *mysql, const char *csname);
int mysql_set_character_set_cont(int *ret, MYSQL *mysql, int status);
int mysql_change_user_start(my_bool *ret, MYSQL *mysql, const char *user, const char *passwd, const char *db);
int mysql_change_user_cont(my_bool *ret, MYSQL *mysql, int status);

int mysql_send_query_start(int *ret, MYSQL *mysql, const char *q, unsigned long length);
int mysql_send_query_cont(int *ret, MYSQL *mysql, int status);

int mysql_store_result_start(MYSQL_RES **ret, MYSQL *mysql);
int mysql_store_result_cont(MYSQL_RES **ret, MYSQL *mysql, int status);
int mysql_shutdown_start(int *ret, MYSQL *mysql, enum mysql_enum_shutdown_level shutdown_level);
int mysql_shutdown_cont(int *ret, MYSQL *mysql, int status);
int mysql_refresh_start(int *ret, MYSQL *mysql, unsigned int refresh_options);
int mysql_refresh_cont(int *ret, MYSQL *mysql, int status);
int mysql_kill_start(int *ret, MYSQL *mysql, unsigned long pid);
int mysql_kill_cont(int *ret, MYSQL *mysql, int status);
int mysql_set_server_option_start(int *ret, MYSQL *mysql, enum enum_mysql_set_option option);
int mysql_set_server_option_cont(int *ret, MYSQL *mysql, int status);
int mysql_ping_start(int *ret, MYSQL *mysql);
int mysql_ping_cont(int *ret, MYSQL *mysql, int status);
int mysql_stat_start(const char **ret, MYSQL *mysql);
int mysql_stat_cont(const char **ret, MYSQL *mysql, int status);

int mysql_read_query_result_start(my_bool *ret, MYSQL *mysql);
int mysql_read_query_result_cont(my_bool *ret, MYSQL *mysql, int status);

// Statements
MYSQL_STMT* mysql_stmt_init(MYSQL *mysql);
int mysql_stmt_next_result_start(int *ret, MYSQL_STMT *stmt);
int mysql_stmt_next_result_cont(int *ret, MYSQL_STMT *stmt, int status);
int mysql_stmt_close_start(my_bool *ret, MYSQL_STMT *stmt);
int mysql_stmt_close_cont(my_bool *ret, MYSQL_STMT * stmt, int status);
int mysql_stmt_prepare_start(int *ret, MYSQL_STMT *stmt, const char *query, unsigned long length);
int mysql_stmt_prepare_cont(int *ret, MYSQL_STMT *stmt, int status);
int mysql_stmt_execute_start(int *ret, MYSQL_STMT *stmt);
int mysql_stmt_execute_cont(int *ret, MYSQL_STMT *stmt, int status);
int mysql_stmt_fetch_start(int *ret, MYSQL_STMT *stmt);
int mysql_stmt_fetch_cont(int *ret, MYSQL_STMT *stmt, int status);
int mysql_stmt_store_result_start(int *ret, MYSQL_STMT *stmt);
int mysql_stmt_store_result_cont(int *ret, MYSQL_STMT *stmt,int status);
int mysql_stmt_reset_start(my_bool *ret, MYSQL_STMT * stmt);
int mysql_stmt_reset_cont(my_bool *ret, MYSQL_STMT *stmt, int status);
int mysql_stmt_free_result_start(my_bool *ret, MYSQL_STMT *stmt);
int mysql_stmt_free_result_cont(my_bool *ret, MYSQL_STMT *stmt, int status);
int mysql_stmt_send_long_data_start(my_bool *ret, MYSQL_STMT *stmt, unsigned int param_number, const char *data, unsigned long len);
int mysql_stmt_send_long_data_cont(my_bool *ret, MYSQL_STMT *stmt, int status);

void mysql_free_result(MYSQL_RES *result);
void mysql_close(MYSQL *sock);
