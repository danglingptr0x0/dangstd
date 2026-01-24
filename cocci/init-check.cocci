// using context without is_init check
@ctx_no_init_check@
expression ctx;
identifier field;
position p;
@@
(
* ctx@p->field
  ... when != ctx->is_init
|
* ctx@p.field
  ... when != ctx.is_init
)

// mutex use without is_init check
@mutex_no_init@
expression m;
position p;
@@
* pthread_mutex_lock@p(&m.mtx)
  ... when != m.is_init

// ldg_mut use without init check
@ldg_mut_no_init@
expression m;
position p;
@@
* ldg_mut_lock@p(m)
  ... when != m->is_init
