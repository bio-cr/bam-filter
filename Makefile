
all :
	cc -shared -fPIC -o kexpr.so -c kexpr.c
	crystal build bam-filter.cr

clean :
	rm kexpr.so
	rm bam-filter