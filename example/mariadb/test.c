// gcc test.c -o test -lmariadb -lcurl && ./test

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mariadb/mysql.h>
#include <curl/curl.h>

struct MemoryStruct {
    char *memory;
    size_t size;
};

static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    struct MemoryStruct *mem = (struct MemoryStruct *)userp;

    mem->memory = realloc(mem->memory, mem->size + realsize + 1);
    if (mem->memory == NULL) {
        fprintf(stderr, "Not enough memory (realloc returned NULL)\n");
        exit(EXIT_FAILURE);
    }

    memcpy(&(mem->memory[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->memory[mem->size] = 0;

    return realsize;
}

int main() {
    MYSQL *conn;
    MYSQL_STMT *stmt;
    MYSQL_BIND bind[5];
    my_bool is_null[5] = {0};
    unsigned long length[5];

    // MariaDBに接続するための設定
    const char *host = "mariadb";
    const char *user = "user";
    const char *password = "pass";
    const char *database = "database";

    conn = mysql_init(NULL);
    if (conn == NULL) {
        fprintf(stderr, "mysql_init() failed\n");
        exit(EXIT_FAILURE);
    }

    if (mysql_real_connect(conn, host, user, password, database, 0, NULL, 0) == NULL) {
        fprintf(stderr, "mysql_real_connect() failed\n");
        mysql_close(conn);
        exit(EXIT_FAILURE);
    }

    // テーブルを削除
    if (mysql_query(conn, "DROP TABLE IF EXISTS `test`")) {
        fprintf(stderr, "DROP TABLE failed. Error: %s\n", mysql_error(conn));
        exit(EXIT_FAILURE);
    }
    
    // テーブルを作成
    if (mysql_query(conn, "CREATE TABLE IF NOT EXISTS `test` ("
                           "`bool` BOOLEAN,"
                           "`int` INT,"
                           "`float` DOUBLE,"
                           "`str` VARCHAR(255),"
                           "`data` BLOB)")) {
        fprintf(stderr, "CREATE TABLE failed. Error: %s\n", mysql_error(conn));
        exit(EXIT_FAILURE);
    }

    CURL *curl;
    CURLcode res;
    struct MemoryStruct chunk;
    chunk.memory = malloc(1);
    chunk.size = 0;

    curl_global_init(CURL_GLOBAL_DEFAULT);
    curl = curl_easy_init();
    if(curl) {
        curl_easy_setopt(curl, CURLOPT_URL, "https://nim-lang.org/assets/img/twitter_banner.png");
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);

        res = curl_easy_perform(curl);
        if(res != CURLE_OK) {
            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
            exit(EXIT_FAILURE);
        }

        curl_easy_cleanup(curl);
    }
    curl_global_cleanup();

    // データを挿入
    stmt = mysql_stmt_init(conn);
    if (!stmt) {
        fprintf(stderr, "mysql_stmt_init() failed\n");
        exit(EXIT_FAILURE);
    }

    const char *insert_query = "INSERT INTO `test` (`bool`, `int`, `float`, `str`, `data`) VALUES (?, ?, ?, ?, ?)";
    if (mysql_stmt_prepare(stmt, insert_query, strlen(insert_query))) {
        fprintf(stderr, "mysql_stmt_prepare() failed. Error: %s\n", mysql_stmt_error(stmt));
        exit(EXIT_FAILURE);
    }

    memset(bind, 0, sizeof(bind));

    my_bool bool_value = 1;
    int int_value = 1;
    double float_value = 1.1;
    char str_value[255] = "alice";
    length[0] = sizeof(bool_value);
    length[1] = sizeof(int_value);
    length[2] = sizeof(float_value);
    length[3] = strlen(str_value);
    length[4] = chunk.size;

    bind[0].buffer_type = MYSQL_TYPE_TINY;
    bind[0].buffer = (char *)&bool_value;
    bind[0].is_null = &is_null[0];
    bind[0].length = &length[0];

    bind[1].buffer_type = MYSQL_TYPE_LONG;
    bind[1].buffer = (char *)&int_value;
    bind[1].is_null = &is_null[1];
    bind[1].length = &length[1];

    bind[2].buffer_type = MYSQL_TYPE_DOUBLE;
    bind[2].buffer = (char *)&float_value;
    bind[2].is_null = &is_null[2];
    bind[2].length = &length[2];

    bind[3].buffer_type = MYSQL_TYPE_STRING;
    bind[3].buffer = (char *)str_value;
    bind[3].buffer_length = sizeof(str_value);
    bind[3].is_null = &is_null[3];
    bind[3].length = &length[3];

    bind[4].buffer_type = MYSQL_TYPE_BLOB;
    bind[4].buffer = (char *)chunk.memory;
    bind[4].buffer_length = chunk.size;
    bind[4].is_null = &is_null[4];
    bind[4].length = &length[4];

    if (mysql_stmt_bind_param(stmt, bind)) {
        fprintf(stderr, "mysql_stmt_bind_param() failed. Error: %s\n", mysql_stmt_error(stmt));
        exit(EXIT_FAILURE);
    }

    if (mysql_stmt_execute(stmt)) {
        fprintf(stderr, "mysql_stmt_execute() failed. Error: %s\n", mysql_stmt_error(stmt));
        exit(EXIT_FAILURE);
    }

    mysql_stmt_close(stmt);
    mysql_close(conn);
    free(chunk.memory);

    return 0;
}
