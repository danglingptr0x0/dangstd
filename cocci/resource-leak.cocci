// ldg_mem_alloc without ldg_mem_dealloc on error path
@ldg_alloc_no_dealloc@
identifier I;
expression RC;
type T;
expression E;
position p;
@@
(
  RC = ldg_mem_alloc(..., (void **)&I)
|
  RC = ldg_mem_alloc(..., &I)
)
  ... when != ldg_mem_dealloc(I)
      when != ldg_mem_dealloc((void *)I)
      when != RC != LDG_ERR_AOK
      when != E = I
      when != E = (T)I
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
