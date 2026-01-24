// multiplication before allocation (potential overflow)
@mult_before_alloc@
expression a, b;
position p;
@@
* malloc@p(a * b)

// addition before allocation
@add_before_alloc@
expression a, b;
position p;
@@
* malloc@p(a + b)

// unchecked size multiplication in calloc-like pattern
@unchecked_mult@
expression n, size;
type T;
position p;
@@
* (T)malloc@p(n * size)
