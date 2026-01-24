// atomic load without explicit ordering
@atomic_load_relaxed@
expression x;
position p;
@@
* __atomic_load_n@p(&x, __ATOMIC_RELAXED)

// atomic store without explicit ordering
@atomic_store_relaxed@
expression x, val;
position p;
@@
* __atomic_store_n@p(&x, val, __ATOMIC_RELAXED)

// raw volatile access instead of atomic (data race prone)
@volatile_instead_of_atomic@
identifier v;
position p;
@@
* volatile ... v@p;
