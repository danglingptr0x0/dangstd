// signed literals are forbidden; use unsigned types exclusively

@negative_assign@
position p;
expression E;
constant C;
@@
* E =@p -C

@negative_init@
position p;
type T;
identifier x;
constant C;
@@
* T x@p = -C;

@negative_return@
position p;
constant C;
@@
* return@p -C;

@negative_compare@
position p;
expression E;
constant C;
@@
(
* E <@p -C
|
* E <=@p -C
|
* E >@p -C
|
* E >=@p -C
|
* E ==@p -C
|
* E !=@p -C
)

@negative_arg@
position p;
identifier fn;
constant C;
@@
* fn@p(..., -C, ...)

@negative_arith@
position p;
expression E;
constant C;
@@
(
* E +@p -C
|
* E *@p -C
)
