// malloc(sizeof(ptr)) instead of malloc(sizeof(*ptr))
@sizeof_ptr_malloc@
expression ptr;
type T;
position p;
@@
  ptr = (T)malloc@p(
* sizeof(ptr)
  )

// calloc with sizeof(ptr)
@sizeof_ptr_calloc@
expression ptr, n;
type T;
position p;
@@
  ptr = (T)calloc@p(n,
* sizeof(ptr)
  )

// memset with sizeof(ptr) instead of sizeof(*ptr)
@sizeof_ptr_memset@
expression ptr;
position p;
@@
* memset@p(ptr, ...,
  sizeof(ptr)
  )

// memcpy with sizeof(ptr)
@sizeof_ptr_memcpy@
expression dst, src;
position p;
@@
* memcpy@p(dst, src,
  sizeof(dst)
  )
