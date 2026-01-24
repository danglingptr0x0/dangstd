// uninitialized local struct
@uninit_struct@
type T;
identifier s;
position p;
@@
* T s@p;
  ... when != s = ...
      when != memset(&s, ...)
      when != (void)memset(&s, ...)
  s

// pointer not initialized to NULL
@uninit_ptr@
type T;
identifier p;
position pos;
@@
* T *p@pos;
  ... when != p = ...
  p
