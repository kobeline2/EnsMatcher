CC	= cc
CFLAGS	= -O
MODULE	= grib2_dec
OBJS	= sample_grib2_dec.o rlencmp.o i2pix.o
HEADER  = sample_decode.h prr_template.h pmf_template.h

.c.o : $(HEADER)
	$(CC) $(CFLAGS) -c $< -o $@

$(MODULE) : $(OBJS)
	$(CC) $(OBJS) -o $(MODULE)

clean :
	rm $(OBJS) $(MODULE)
