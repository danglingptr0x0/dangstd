// pthread_mutex_lock without unlock on return path
@lock_no_unlock@
expression m;
position p;
@@
  pthread_mutex_lock(&m)
  ... when != pthread_mutex_unlock(&m)
* return@p ...;

// ldg_mut_lock without ldg_mut_unlock
@ldg_lock_no_unlock@
expression m;
position p;
@@
  ldg_mut_lock(m)
  ... when != ldg_mut_unlock(m)
* return@p ...;

// thread_sync_mut_lock without thread_sync_mut_unlock
@thread_sync_lock_no_unlock@
expression m;
position p;
@@
  thread_sync_mut_lock(m)
  ... when != thread_sync_mut_unlock(m)
* return@p ...;

// double lock without intermediate unlock
@double_lock@
expression m;
position p1, p2;
@@
* pthread_mutex_lock@p1(&m)
  ... when != pthread_mutex_unlock(&m)
* pthread_mutex_lock@p2(&m)
