// §8.7.4: goto and labels shall not be used

@goto_stmt@
position p;
identifier lbl;
@@
* goto@p lbl;

@label_decl@
position p;
identifier lbl;
@@
* lbl@p:
