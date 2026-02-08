// §8.6.9: null pointers shall be expressed as 0x0

@null_assign@
position p;
expression E;
@@
* E =@p NULL

@null_compare@
position p;
expression E;
@@
(
* E ==@p NULL
|
* E !=@p NULL
|
* NULL@p == E
|
* NULL@p != E
)

@null_return@
position p;
@@
* return@p NULL;

@null_arg@
position p;
identifier fn;
expression list Es;
@@
* fn@p(..., NULL, ...)
