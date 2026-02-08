// ldg_mem_alloc without ldg_mem_dealloc on error path
@ldg_alloc_no_dealloc@
expression E;
position p;
@@
  E = ldg_mem_alloc(...)
  ... when != !E
      when != E == NULL
      when != ldg_mem_dealloc(E)
* return@p ...;

// socket without close
@socket_no_close@
expression fd;
position p;
@@
  fd = socket(...)
  ... when != close(fd)
* return@p ...;

// open without close
@open_no_close@
expression fd, path, flags;
position p;
@@
  fd = open(path, flags, ...)
  ... when != close(fd)
      when != fd < 0
* return@p ...;
