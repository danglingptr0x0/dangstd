// deref before null check
@deref_before_check@
expression E, F;
position p;
@@
* E@p->F
  ... when != E = ...
  \(E == NULL\|E != NULL\|!E\|UNLIKELY(!E)\|LDG_UNLIKELY(!E)\)

// deref without any null check after fallible call
@deref_no_check_malloc@
expression E, F;
position p;
@@
  E = \(malloc\|calloc\|realloc\|aligned_alloc\)(...)
  ... when != E == NULL
      when != E != NULL
      when != !E
      when != UNLIKELY(!E)
      when != LDG_UNLIKELY(!E)
* E@p->F

// deref without check after fopen
@deref_no_check_fopen@
expression fp, F, path, mode;
position p;
@@
  fp = fopen(path, mode)
  ... when != fp == NULL
      when != fp != NULL
      when != !fp
      when != UNLIKELY(!fp)
      when != LDG_UNLIKELY(!fp)
* fp@p->F
