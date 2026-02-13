// fopen without NULL check
@fopen_guarded@
expression E, path, mode;
position p;
@@
E@p = fopen(path, mode)
... when any
(
if (\(!E\|E == NULL\|E == 0x0\)) { ... return ...; }
|
if (LDG_UNLIKELY(\(!E\|E == NULL\|E == 0x0\))) { ... return ...; }
)

@fopen_no_check@
expression E, path, mode;
position p != fopen_guarded.p;
@@
* E@p = fopen(path, mode)
  ...
  E

// fopen without fclose on error path
@null_return@
expression fp, path, mode;
position p;
@@
fp = fopen(path, mode)
... when any
(
if (\(!fp\|fp == NULL\|fp == 0x0\)) { ... return@p ...; }
|
if (LDG_UNLIKELY(\(!fp\|fp == NULL\|fp == 0x0\))) { ... return@p ...; }
)

@fopen_no_close@
expression fp, path, mode;
position p != null_return.p;
@@
  fp = fopen(path, mode)
  ... when != fclose(fp)
* return@p ...;

// fclose return value not cast to void
@fclose_no_void@
expression fp;
position p;
@@
* fclose@p(fp);
