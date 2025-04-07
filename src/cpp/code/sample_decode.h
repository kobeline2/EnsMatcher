/* **************************************** */
/* sample grib2 decode program include file */
/* **************************************** */


#define IS_LITTLE_ENDIAN


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct sect {
  int num;
  int *len;
  unsigned char **v;
} ST_SECT; 

int decode_rlen_nbit(void *udata, size_t utype, unsigned char *din, int nin,
                     int nout, int maxv, int nbit);
