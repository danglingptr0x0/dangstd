// §8.11.5: wrapper functions that only call another function shall not be used

@trivial_wrapper@
position p;
type T;
identifier fn, inner;
expression list Es;
@@
* T fn@p(...) { return inner(Es); }

@trivial_void_wrapper@
position p;
identifier fn, inner;
expression list Es;
@@
* void fn@p(...) { inner(Es); }
