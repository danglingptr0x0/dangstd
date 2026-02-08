// memory header without sentinel check before use
@no_sentinel_front@
expression hdr;
position p;
@@
* hdr@p->size
  ... when != hdr->sentinel_front == LDG_MEM_SENTINEL
      when != hdr->sentinel_front != LDG_MEM_SENTINEL
      when != hdr->sentinel_front == CUT_MEM_SENTINEL
      when != hdr->sentinel_front == HZ_MEM_SENTINEL

