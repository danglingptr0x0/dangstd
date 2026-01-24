// bare -1 return instead of named error code
@bare_minus_one@
position p;
@@
* return@p -1;

// bare -2 return
@bare_minus_two@
position p;
@@
* return@p -2;

// bare -3 return
@bare_minus_three@
position p;
@@
* return@p -3;

// bare 1 return for error (should use named code)
@bare_one_error@
position p;
@@
* if (...) { return@p 1; }
