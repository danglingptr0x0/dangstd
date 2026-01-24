// error return without UNLIKELY wrapper
@error_no_unlikely@
position p;
@@
* if@p (!...) { return \(-1\|-2\|-3\|-4\|-5\|LDG_ERR_FUNC_ARG_NULL\|LDG_ERR_FUNC_ARG_INVALID\|LDG_ERR_ALLOC_NULL\|CUT_ERR_FUNC_ARG_NULL\|CUT_ERR_FUNC_ARG_INVALID\|CUT_ERR_ALLOC_NULL\|HZ_ERR_FUNC_ARG_NULL\|HZ_ERR_FUNC_ARG_INVALID\|HZ_ERR_ALLOC\); }

// NULL return without UNLIKELY wrapper
@null_return_no_unlikely@
position p;
@@
* if@p (!...) { return NULL; }
