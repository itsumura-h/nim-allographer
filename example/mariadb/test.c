// gcc ./test.c -lmariadb -o test && ./test

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mariadb/mysql.h>

int main() {
    MYSQL *conn;
    MYSQL_STMT *stmt;
    int execute_result;
    int status;

    char *server = "localhost";
    char *user = "username";
    char *password = "password";
    char *database = "testdb";

    // MariaDBへの接続
    conn = mysql_init(NULL);
    if (!conn) {
        fprintf(stderr, "mysql_init() failed\n");
        exit(1);
    }

    if (mysql_real_connect_start(&conn, conn, server, user, password, database, 0, NULL, 0) != 0) {
        fprintf(stderr, "mysql_real_connect_start() failed\n");
        mysql_close(conn);
        exit(1);
    }

    // ここで非同期接続操作が完了するまで待機や他の処理を行うことができます。
    MYSQL *ret_conn;
    while (status == -1) {
        status = mysql_real_connect_cont(&ret_conn, conn, mysql_get_socket(conn));
        // 何らかの待機処理、例えばsleepなど
    }

    char *query = "CREATE TABLE test(id int)";
    stmt = mysql_stmt_init(conn);
    if (!stmt) {
        fprintf(stderr, "mysql_stmt_init() failed\n");
        mysql_close(conn);
        exit(1);
    }

    if (mysql_stmt_prepare(stmt, query, strlen(query))) {
        fprintf(stderr, "mysql_stmt_prepare() failed\n");
        mysql_stmt_close(stmt);
        mysql_close(conn);
        exit(1);
    }

    status = mysql_stmt_execute_start(&execute_result, stmt);

    // ここで非同期操作が完了するまで待機や他の処理を行うことができます。
    while (status == -1) {
        // 何らかの待機処理、例えばsleepなど
        status = mysql_stmt_execute_cont(&execute_result, stmt, mysql_get_socket(conn));
    }

    if (execute_result) {
        fprintf(stderr, "mysql_stmt_execute_start() failed\n");
        mysql_stmt_close(stmt);
        mysql_close(conn);
        exit(1);
    }

    // 終了処理
    mysql_stmt_close(stmt);
    mysql_close(conn);

    return 0;
}
