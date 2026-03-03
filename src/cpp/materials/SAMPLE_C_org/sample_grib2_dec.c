/* -------------------------------------------------------------------------- */
/*  Last Updated Ver.1.3    2006.01.20                                        */
/*   Copyright (C) 2003-2006 Japan Meteorological Agency  All rights reserved */
/* -------------------------------------------------------------------------- */

#include "sample_decode.h"
#include "prr_template.h"
#include "pmf_template.h"

#ifdef IS_LITTLE_ENDIAN
#  define Fread fread_little_endian
#else
#  define Fread fread
#endif

void
fread_little_endian(void *d, int len, int num, FILE *fp)
{
  unsigned char uc[8], *ud;
  int i, j, k;

  ud = d;
  if (len==1)
    fread(d, len, num, fp);
  else {
    for(i=0, k=0; i<num; i++, k+=len) {
      fread(uc, len, 1, fp);
      for(j=0; j<len; j++)  *(ud+k+j) = uc[len-1-j];
    }
  }
}

void init_sect(ST_SECT ss[], int af)
{
  int i, j, k;
  char c[2];

  if (af==0) {
    k=0;
    while(strlen(sc_prr[k])!=0)
      ++k;
    for(i=0; i<k; ++i) {
      ss[i].num = strlen(sc_prr[i]);
      ss[i].len = (int *)malloc(sizeof(int *)*ss[i].num);
      for(j=0; j<ss[i].num; ++j) {
        strncpy(c, &sc_prr[i][j], 1);
        *(ss[i].len+j) = atoi(c);
      }
      ss[i].v = (unsigned char **)malloc(sizeof(unsigned char *)*ss[i].num);
      for(j=0; j<ss[i].num; j++) *(ss[i].v+j) = NULL;
    }
  } else {
    k=0;
    while(strlen(sc_pmf[k])!=0)
      ++k;
    for(i=0; i<k; ++i) {
      ss[i].num = strlen(sc_pmf[i]);
      ss[i].len = (int *)malloc(sizeof(int *)*ss[i].num);
      for(j=0; j<ss[i].num; ++j) {
        strncpy(c, &sc_pmf[i][j], 1);
        *(ss[i].len+j) = atoi(c);
      }
      ss[i].v = (unsigned char **)malloc(sizeof(unsigned char *)*ss[i].num);
      for(j=0; j<ss[i].num; ++j) *(ss[i].v+j) = NULL;
    }
  }
}

int read_sect(ST_SECT ss[], FILE *fp)
{
  int i, nn, mm, si;
  unsigned int  slen;
  unsigned short *us, ud;
  unsigned char sn;

  Fread(&slen, 4, 1, fp);
  if (memcmp(&slen, "7777", 4)==0) {
    si=8;
    return(si);
#ifdef IS_LITTLE_ENDIAN
  } else if (memcmp(&slen, "BIRG", 4)==0) {
#else
  } else if (memcmp(&slen, "GRIB", 4)==0) {
#endif
    si=0;
    slen = 16;
    Fread(&ud, 2, 1, fp);
    *(ss[si].v+0)=(unsigned char *)realloc(*(ss[si].v+0),sizeof(unsigned int));
    *(ss[si].v+1)=(unsigned char *)realloc(*(ss[si].v+1),sizeof(unsigned short));
    memcpy(*(ss[si].v+0), &slen, 4);
  } else {
    Fread(&sn, 1, 1, fp);
    si = (int)sn;
    if (si>=3)
      --si;
    *(ss[si].v+0)=(unsigned char *)realloc(*(ss[si].v+0),sizeof(unsigned int));
    *(ss[si].v+1)=(unsigned char *)realloc(*(ss[si].v+1),sizeof(unsigned char));
    memcpy(*(ss[si].v+0), &slen, 4);
    memcpy(*(ss[si].v+1), &sn, 1);
  }

  for(i=2; i<ss[si].num; i++) {
    if (*(ss[si].len+i)==0) {
      us = (unsigned short *)(*(ss[si].v+i-2));
      nn = (*(ss[si].len+i-2)==4) ? sizeof(unsigned char)
                                  : sizeof(unsigned short);
      mm = (*(ss[si].len+i-2)==4) ? slen-5 : *us;
    } else {
      nn = *(ss[si].len+i);
      mm = 1;
    }
    *(ss[si].v+i) = (unsigned char *)realloc(*(ss[si].v+i),(size_t)nn*mm);
    Fread(*(ss[si].v+i), nn, mm, fp);
  }

  return(si);
}

int dec_data(ST_SECT ss[], int **lv)
{
  int nin, nout, maxv, nbit, rt;
  unsigned int *ui;
  unsigned short *us;

  ui = (unsigned int *)*(ss[4].v+2);
  nout = *ui;
  nbit = **(ss[4].v+4);
  us = (unsigned short *)*(ss[4].v+5);
  maxv = *us;
  ui = (unsigned int *)*(ss[6].v+0);
  nin = *ui-5;

  *lv = (int*)malloc(sizeof(int)*nout);
  rt = decode_rlen_nbit(*lv, sizeof(int), *(ss[6].v+2), nin, nout, maxv, nbit);

  return(rt);
}

void print_info(ST_SECT ss[], int sn)
{
  int i, j, k;
  unsigned long long *ull;
  int *ii;
  unsigned short *us, *n;

  printf("========== SECTION %1.1d ===========\n", (sn>=2) ? sn+1 : sn);
  for(i=0, j=1; i<ss[sn].num; j+=*(ss[sn].len+i), ++i) {
    if (*(ss[sn].len+i)==1) {
      if (**(ss[sn].v+i)==0xff)
        printf("    %3d    : 0x%2.2x\n", j, **(ss[sn].v+i));
      else
        printf("    %3d    : %d\n", j, **(ss[sn].v+i));
    } else if (*(ss[sn].len+i)==8) {
      if (sn==0) {
        ull = (unsigned long long *)*(ss[sn].v+i);
        printf("%4d --%4d: %d\n", j,j+*(ss[sn].len+i)-1, (unsigned int)*ull);
      } else {
        printf("%4d --%4d: ", j,j+*(ss[sn].len+i)-1);
#ifdef IS_LITTLE_ENDIAN
        for(k=0; k<8; ++k) printf("%2.2x", *(*(ss[sn].v+i)+8-1-k)); printf("\n");
#else
        for(k=0; k<8; ++k) printf("%2.2x", *(*(ss[sn].v+i)+k)); printf("\n");
#endif
      }
    } else if (*(ss[sn].len+i)==4) {
      ii = (int *)*(ss[sn].v+i);
      if (*ii>=0)
        printf("%4d --%4d: %d\n", j,j+*(ss[sn].len+i)-1, *ii);
      else if(i==12 && sn==3) /* only fcst_time is signed int */
        printf("%4d --%4d: %d\n", j,j+*(ss[sn].len+i)-1,
	       (*ii > 0 ? *ii : ((*ii & 0x7fffffff)*(-1))));
      else
        printf("%4d --%4d: 0x%8.8x\n", j,j+*(ss[sn].len+i)-1, *ii);
    } else if (*(ss[sn].len+i)==2) {
      us = (unsigned short *)*(ss[sn].v+i);
      if (*us==0xffff)
        printf("%4d --%4d: 0x%4.4x\n", j,j+*(ss[sn].len+i)-1, *us);
      else
        printf("%4d --%4d: %d\n", j,j+*(ss[sn].len+i)-1, *us);
    } else if (sn==3 || sn==4) {
      n = (unsigned short *)*(ss[sn].v+i-2);
      us = (unsigned short *)*(ss[sn].v+i);
      for(k=0; k<*n; ++k) {
        if (*(us+k)==0xffff)
          printf("%4d --%4d: 0x%4.4x\n", j+2*k,j+2*k+1, *(us+k));
        else
          printf("%4d --%4d: %d\n", j+2*k,j+2*k+1, *(us+k));
      }
    }
  }
  fflush(stdout);
}

int main(int argc, char *argv[])
{
  ST_SECT ss[8];
  FILE *fp, *fpo;
  char fname[160], gname[160], suffix[160], fcs[160], ffm[160];
  int sn, *lv, gn, sff=0, *xs, *ys, maxv, fcnt=0, af, ll;


  unsigned short *us_maxv;

  if (argc==1) {
    fprintf(stderr, "\n\nusage: grib2_dec ***_grib2.bin (-xpm)\n\n");
    fprintf(stderr, "    This program decodes the grib2 file named ***_grib2.bin, and prints the\n  value of each section in GRIB2.  Also, this program puts out a raw (4 byte\n  integer) data file ***_int.bin as a rectangle grid dimension.  In case of\n  specifying -xpm options, an output file is to a picture image file ***.xpm\n  formatted as X-pixmap.\n\n");
    exit(1);
  } else if (argc==3 && strcmp(argv[2],"-xpm")==0) {
    strcpy(suffix, ".xpm");  sff = 1;
  } else
    strcpy(suffix, ".bin");

  strcpy(fname, argv[1]);
  if ((fp=fopen(fname,"rb"))==NULL) {
    fprintf(stderr, "grib2 file <%s> open error!!\n", fname);
    exit(1);
  }
  af = (strstr(fname, "_ANAL")==NULL && strstr(fname, "_NOWC")==NULL) ? 1 : 0;

  init_sect(ss, af);


  while((sn=read_sect(ss, fp))!=8) {
    if (sn==6) {
      print_info(ss, sn);
      gn = dec_data(ss, &lv);
      if (gn>0) {
        ll = strlen(fname)-strlen(strstr(fname,"_grib2.bin"));
        strncpy(gname, fname, ll); gname[ll] = '\0';
        sprintf(fcs, "_%1d", fcnt);
        strcpy(ffm, (sff==1) ? "" : "_int");
        strcat(gname, strcat(fcs, strcat(ffm, suffix)));
        if ((fpo=fopen(gname,"wb"))==NULL) {
          fprintf(stderr, "output file <%s> open error!!\n", gname);
          exit(1);
        }
        if (sff==0)
          fwrite(lv, sizeof(int), gn, fpo);
        else {
#if 1
	  i2pix_2(lv,ss,fpo);
#else
          xs = (int *)*(ss[2].v+14);
          ys = (int *)*(ss[2].v+15);
          us_maxv = (unsigned short *)*(ss[4].v+6);
          maxv = (int)*us_maxv;
          i2pix(lv, *xs, *ys, maxv, fpo);
#endif
        }
        fclose(fpo);
        ++fcnt;
      }
      free(lv);
    } else {
      print_info(ss, sn);
    }
  }

  fclose(fp);
  return 0;
}
