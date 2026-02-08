// global/file-scope mutable variables are forbidden
// static const is permitted

// static mutable (not const)
@static_mutable@
position p;
identifier x;
expression E;
@@
(
* static@p uint8_t x;
|
* static@p uint8_t x = E;
|
* static@p uint16_t x;
|
* static@p uint16_t x = E;
|
* static@p uint32_t x;
|
* static@p uint32_t x = E;
|
* static@p uint64_t x;
|
* static@p uint64_t x = E;
|
* static@p uintptr_t x;
|
* static@p uintptr_t x = E;
|
* static@p float x;
|
* static@p float x = E;
|
* static@p double x;
|
* static@p double x = E;
)
