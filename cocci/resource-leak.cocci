// malloc without free on error path
@malloc_no_free@
expression E;
position p;
@@
  E = malloc(...)
  ... when != free(E)
      when != ldg_mem_dealloc(E)
      when != hw_mem_dealloc(E)
* return@p ...;

// posix_memalign without free on error path
@memalign_no_free@
expression ptr;
position p;
@@
  posix_memalign(&ptr, ...)
  ... when != free(ptr)
      when != ldg_mem_dealloc(ptr)
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
* return@p ...;
