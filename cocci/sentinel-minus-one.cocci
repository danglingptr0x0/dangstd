// §8.6.7: use UINT*_MAX for sentinel, not -1

@assign_minus_one@
position p;
identifier x;
@@
* x =@p -1

@compare_minus_one@
position p;
expression E;
@@
(
* E ==@p -1
|
* E !=@p -1
|
* -1@p == E
|
* -1@p != E
)

@init_minus_one@
position p;
type T;
identifier x;
@@
* T x@p = -1;
