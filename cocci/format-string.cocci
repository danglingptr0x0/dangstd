// printf with variable as format string (potential format string vuln)
@printf_var_fmt@
expression E;
position p;
@@
* printf@p(E)

// fprintf with variable as format string
@fprintf_var_fmt@
expression fp, E;
position p;
@@
* fprintf@p(fp, E)

// sprintf with variable as format string
@sprintf_var_fmt@
expression dst, E;
position p;
@@
* sprintf@p(dst, E)

// snprintf with variable as format string
@snprintf_var_fmt@
expression dst, size, E;
position p;
@@
* snprintf@p(dst, size, E)

// syslog with variable as format string
@syslog_var_fmt@
expression prio, E;
position p;
@@
* syslog@p(prio, E)
