// malloc/calloc/realloc used without NULL check before dereference
@alloc_no_check@
expression E;
expression F;
position p;
@@
  E = \(malloc\|calloc\|realloc\|aligned_alloc\)(...)
  ... when != E == NULL
      when != E != NULL
      when != !E
      when != UNLIKELY(!E)
      when != LDG_UNLIKELY(!E)
      when != if (...) { ... return ...; }
* E@p->F

// posix_memalign return not checked (returns int errno, not pointer)
@posix_memalign_no_check@
expression ptr, align, size;
position p;
@@
* posix_memalign@p(&ptr, align, size);
  ... when != != 0
      when != == 0
  ptr
