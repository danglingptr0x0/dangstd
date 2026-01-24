// double free detection
@double_free@
expression E;
position p1, p2;
@@
* free@p1(E)
  ... when != E = ...
* free@p2(E)

// use after free
@use_after_free@
expression E, F;
position p;
@@
  free(E)
  ... when != E = ...
* E@p->F

// free then use
@free_then_use@
expression E;
position p;
@@
  free(E)
  ... when != E = ...
* E@p
