// gcc -I/usr/include/postgresql -I/usr/local/include/curl -o test test.c -lpq -lcurl && ./test

#include <stdio.h>
#include <stdlib.h>
#include <libpq-fe.h>
#include <string.h>
#include <curl/curl.h>

struct MemoryStruct
{
  unsigned char *memory;
  size_t size;
};

static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp)
{
  size_t realsize = size * nmemb;
  struct MemoryStruct *mem = (struct MemoryStruct *)userp;

  mem->memory = realloc(mem->memory, mem->size + realsize);
  if (mem->memory == NULL)
  {
    /* out of memory! */
    printf("not enough memory (realloc returned NULL)\n");
    return 0;
  }

  memcpy(&(mem->memory[mem->size]), contents, realsize);
  mem->size += realsize;

  return realsize;
}

void exit_nicely(PGconn *conn)
{
  PQfinish(conn);
  exit(1);
}

int main()
{

  // ##################################################
  // # Binary image
  // ##################################################

  CURL *curl_handle;
  CURLcode curlRes;

  struct MemoryStruct chunk;

  chunk.memory = malloc(1); /* will be grown as needed by the realloc above */
  chunk.size = 0;           /* no data at this point */

  curl_global_init(CURL_GLOBAL_ALL);

  /* init the curl session */
  curl_handle = curl_easy_init();

  /* specify URL to get */
  curl_easy_setopt(curl_handle, CURLOPT_URL, "https://nim-lang.org/assets/img/twitter_banner.png");

  /* send all data to this function  */
  curl_easy_setopt(curl_handle, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);

  /* we pass our 'chunk' struct to the callback function */
  curl_easy_setopt(curl_handle, CURLOPT_WRITEDATA, (void *)&chunk);

  /* some servers don't like requests that are made without a user-agent
     field, so we provide one */
  curl_easy_setopt(curl_handle, CURLOPT_USERAGENT, "libcurl-agent/1.0");

  /* get it! */
  curlRes = curl_easy_perform(curl_handle);

  /* check for errors */
  if (curlRes != CURLE_OK)
  {
    fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(curlRes));
  }
  else
  {
    printf("%lu bytes retrieved\n", (long)chunk.size);
  }

  /* cleanup curl stuff */
  curl_easy_cleanup(curl_handle);

  /* we're done with libcurl, so clean it up */
  curl_global_cleanup();

  // ##################################################
  // # Postgres
  // ##################################################
  const char *conninfo;
  PGconn *conn;
  PGresult *res;

  // Specify your connection info
  conninfo = "dbname=database user=user password=pass hostaddr=postgres port=5432";

  // Make a connection to the database
  // conn = PQconnectdb(conninfo);
  conn = PQsetdbLogin("postgres", "5432", NULL, NULL, "database", "user", "pass");

  // Check to see that the backend connection was successfully made
  if (PQstatus(conn) != CONNECTION_OK)
  {
    fprintf(stderr, "Connection to database failed: %s", PQerrorMessage(conn));
    exit_nicely(conn);
  }

  // Your binary data
  // unsigned char binary_data[] = {0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x57, 0x6f, 0x72, 0x6c, 0x64, 0x21};
  unsigned char binary_data[chunk.size];
  memcpy(binary_data, chunk.memory, chunk.size);
  int binary_data_size = sizeof(binary_data) / sizeof(binary_data[0]);

  // INSERT query
  const char *query = "INSERT INTO image (data) VALUES ($1)";

  const char *paramValues[1];
  int paramLengths[1];
  int paramFormats[1];

  paramValues[0] = (char *)binary_data;
  paramLengths[0] = binary_data_size;
  paramFormats[0] = 1; // binary

  // Execute the INSERT statement
  res = PQexecParams(conn, query, 1, NULL, paramValues, paramLengths, paramFormats, 1);

  if (PQresultStatus(res) != PGRES_COMMAND_OK)
  {
    fprintf(stderr, "INSERT command failed: %s", PQerrorMessage(conn));
    PQclear(res);
    exit_nicely(conn);
  }

  // Clear result
  PQclear(res);

  // Close connection
  PQfinish(conn);

  return 0;
}
