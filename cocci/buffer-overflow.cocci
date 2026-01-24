// strcpy (always dangerous)
@strcpy_usage@
position p;
@@
* strcpy@p(...)

// strcat (always dangerous)
@strcat_usage@
position p;
@@
* strcat@p(...)

// sprintf (usually dangerous)
@sprintf_usage@
position p;
@@
* sprintf@p(...)

// gets (always dangerous, deprecated)
@gets_usage@
position p;
@@
* gets@p(...)

// scanf %s without width limit
@scanf_no_width@
expression fp;
position p;
@@
* \(scanf\|fscanf\)@p(..., "%s", ...)

// strncpy without null termination guarantee
@strncpy_no_term@
expression dst, src, n;
position p;
@@
* strncpy@p(dst, src, n)
  ... when != dst[...] = '\0'
      when != dst[...] = 0
