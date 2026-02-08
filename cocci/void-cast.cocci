// (void) cast to discard function return values is prohibited
// return values shall be checked using LDG_UNLIKELY() or LDG_LIKELY()
// example: if (LDG_UNLIKELY(func() != expected)) { return ERR; }
// note: (void)param; for unused parameters is allowed

@void_cast@
identifier fn;
expression list args;
position p;
@@
* (void)@p fn(args);
