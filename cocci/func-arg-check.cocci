// pointer param dereferenced without null check at function entry
@func_arg_deref_no_check@
identifier fn, param;
identifier fld;
type T, R;
position p;
@@
  R fn(..., T *param, ...)
  {
  ... when != param == NULL
      when != param != NULL
      when != !param
      when != UNLIKELY(!param)
      when != LDG_UNLIKELY(!param)
* param@p->fld
  ...
  }

// pointer param direct deref without null check
@func_arg_star_no_check@
identifier fn, param;
type T, R;
position p;
@@
  R fn(..., T *param, ...)
  {
  ... when != param == NULL
      when != param != NULL
      when != !param
      when != UNLIKELY(!param)
      when != LDG_UNLIKELY(!param)
* *param@p
  ...
  }
