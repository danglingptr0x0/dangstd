// fread/fwrite count not checked
@fread_no_check@
expression buf, size, nmemb, fp;
position p;
@@
* fread@p(buf, size, nmemb, fp);

// fseek return not checked
@fseek_no_check@
expression fp, offset, whence;
position p;
@@
* fseek@p(fp, offset, whence);

// pthread_create return not checked
@pthread_create_no_check@
position p;
@@
* pthread_create@p(...);

// pthread_join return not checked
@pthread_join_no_check@
position p;
@@
* pthread_join@p(...);

// close() return not checked (usually fine but worth noting)
@close_no_check@
position p;
@@
* close@p(...);
