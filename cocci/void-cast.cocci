// memset return value not cast to void
@@
expression E1, E2, E3;
@@
- memset(E1, E2, E3);
+ (void)memset(E1, E2, E3);

// memcpy return value not cast to void
@@
expression E1, E2, E3;
@@
- memcpy(E1, E2, E3);
+ (void)memcpy(E1, E2, E3);

// memmove return value not cast to void
@@
expression E1, E2, E3;
@@
- memmove(E1, E2, E3);
+ (void)memmove(E1, E2, E3);

// fprintf return value not cast to void
@@
expression E1;
expression list Es;
@@
- fprintf(E1, Es);
+ (void)fprintf(E1, Es);

// fwrite return value not cast to void
@@
expression E1, E2, E3, E4;
@@
- fwrite(E1, E2, E3, E4);
+ (void)fwrite(E1, E2, E3, E4);

// fclose return value not cast to void
@@
expression E;
@@
- fclose(E);
+ (void)fclose(E);

// pthread_mutex_lock return value not cast to void
@@
expression E;
@@
- pthread_mutex_lock(E);
+ (void)pthread_mutex_lock(E);

// pthread_mutex_unlock return value not cast to void
@@
expression E;
@@
- pthread_mutex_unlock(E);
+ (void)pthread_mutex_unlock(E);

// pthread_mutex_destroy return value not cast to void
@@
expression E;
@@
- pthread_mutex_destroy(E);
+ (void)pthread_mutex_destroy(E);

// pthread_mutexattr_destroy return value not cast to void
@@
expression E;
@@
- pthread_mutexattr_destroy(E);
+ (void)pthread_mutexattr_destroy(E);

// clock_gettime return value not cast to void
@@
expression E1, E2;
@@
- clock_gettime(E1, E2);
+ (void)clock_gettime(E1, E2);
