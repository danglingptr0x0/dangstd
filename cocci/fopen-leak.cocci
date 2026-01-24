// fopen without NULL check
@fopen_no_check@
expression E, path, mode;
position p;
@@
* E@p = fopen(path, mode)
  ...
  E

// fopen without fclose on error path
@fopen_no_close@
expression fp, path, mode;
position p;
@@
  fp = fopen(path, mode);
  ... when != fclose(fp)
* return@p ...;

// fclose return value not cast to void
@fclose_no_void@
expression fp;
position p;
@@
* fclose@p(fp);
