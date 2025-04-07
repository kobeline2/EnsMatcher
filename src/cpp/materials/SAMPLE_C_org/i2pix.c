/* -------------------------------------------------------------------------- */
/*  Last Updated Ver.1.3    2006.01.20                                        */
/*   Copyright (C) 2003-2006 Japan Meteorological Agency  All rights reserved */
/* -------------------------------------------------------------------------- */

#include "sample_decode.h"

#define COLOR_IE_NUM 16
#define COLOR_HE_NUM 10

static const unsigned char color_IE[COLOR_IE_NUM][3] = {
  { 192,192,192, },
  { 255,255,255, },
  {   0,255,255, },
  {   0,119,198, },
  {   0, 60,108, },
  {   0,  6,240, },
  {   0,147,117, },
  {   0,179, 71, },
  {   0,255, 12, },
  {  70,255,  9, },
  { 124,206,  2, },
  { 255,255,  0, },
  { 255,128,  0, },
  { 255,134,255, },
  { 254, 69,162, },
  { 255,  0,  0, },
};

static const unsigned char color_HE[COLOR_HE_NUM][3] = {
  { 192,192,192, },
  { 255,255,255, },
  {   0,255,255, },
  {   0,  0,255, },
  {   0,147, 17, },
  { 127,255,  0, },
  { 255,255,  0, },
  { 255,127,  0, },
  { 255,  0,255, },
  { 255,  0,  0, },
};

static const int rank_IE[COLOR_IE_NUM -1] = {
  -1, 0, 1, 2, 4, 8, 12, 16, 24, 32, 40, 48, 56, 64, 80,
};
static const int rank_HE[COLOR_IE_NUM -1] = {
  -1, 0, 2, 4, 6, 8, 10, 12, 14,
};

static int get_level(unsigned char level, const short ispc[],
		     short max_level, const int rank[], int rank_num)
{
  short rain;
  int i;
  if(level > max_level) return -1;

  rain = ispc[level];

  if(rain < 0) {
    return 0;
  } else if(rain == 0){
    return 1;
  }

  for(i = 2; i < rank_num; ++i){
    if(rain < rank[i]) return i;
  }
  return rank_num;
}

void i2pix_2(const int *fd, /* original data array */
	     const ST_SECT ss[],
	     FILE *fp /* output file pointer */
	     )
{
  int i, j, k;
  int r, g, b;
  char *line, *p;
  unsigned char parm_num; /* parameger number
			    echo intensity: 201 echo top: 192 */
  unsigned char bg_id;    /* Background generating process identifier
			     JMA: 201, ITGRAD: 200 */
  int max_level, rank_num;
  const int *org_rank;
  int *rank;
  unsigned char color[COLOR_IE_NUM][3];
  short *ispc;
  unsigned char scale_index;
  int scale;

  int cl;
  int ix,iy;

  short *stmp;
  int *itmp;

  parm_num = *(*(ss[3].v+5));
  bg_id = *(*(ss[3].v+7));

  itmp = (int *)*(ss[2].v+14);
  ix = *itmp;
  itmp = (int *)*(ss[2].v+15);
  iy = *itmp;

  if(parm_num == 192 && bg_id == 201){ /* echo top */
    rank_num = COLOR_HE_NUM -1;
    memcpy(color, color_HE, (rank_num+1)*3);
    org_rank = rank_HE;
  } else {
    rank_num = COLOR_IE_NUM -1;
    memcpy(color, color_IE, (rank_num+1)*3);
    org_rank = rank_IE;
  }

  stmp = (short *)*(ss[4].v + 6);
  max_level = (short)*stmp;
  if((ispc = (short *)malloc(sizeof(short)*(max_level+1))) == NULL){
    fprintf(stderr, "malloc error!\n");
    exit(-1);
  }

  stmp = (short *)*(ss[4].v + 8);
  ispc[0] = -1;
  memcpy(ispc+1, stmp, max_level*sizeof(short));
  scale_index = *(*(ss[4].v + 7));
  scale = 1;
  while(scale_index != 0){
    scale *= 10;
    --scale_index;
  }
  if((rank = (int*)malloc((rank_num+1)*sizeof(int))) == NULL){
    fprintf(stderr, "malloc error!\n");
    exit(-1);
  }
  for(i = 1; i < rank_num; ++i){
    rank[i] = org_rank[i]*scale;
  }

  line = (char*)malloc(sizeof(char)*ix+1);
  fprintf(fp, "static char *no_xpm[] = {\n");
  fprintf(fp, "\"%d %d %d 1\",\n", ix, iy, rank_num+2);
  fprintf(fp, "\"# c #000000\",\n");
  for(i = 0; i < rank_num+1; ++i){
    r = color[i][0];
    g = color[i][1];
    b = color[i][2];
    fprintf(fp, "\"%c c #%02X%02X%02X\",\n", i+'$', r, g, b);
  };

  for(j = 0; j < iy - iy/50; ++j){
    p = line;
    for(i = 0; i < ix; ++i){
      k = i + j*ix;
      cl = get_level(fd[k], ispc, max_level, rank, rank_num);
      if(cl < 0){
        cl = 0;
      }
      *p++ = (char)((int)'$' + cl);
    }
    *p = '\0';
    fprintf(fp, "\"%s\",\n", line);
  }

/* color bar */
  for(j = iy - iy/50; j < iy; ++j){
    p = line;
    for(i = 0; i < ix; ++i){
      *p++ = (char)((int)'$' + i*(rank_num+1)/ix);
    }
    *p = '\0';
    fprintf(fp, "\"%s\",\n", line);
  }
  fprintf(fp, "};\n");
  free(rank);
  free(ispc);
  free(line);
  return;
}
