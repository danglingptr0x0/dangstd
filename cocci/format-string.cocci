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
