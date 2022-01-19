
all :
	cc -shared -fPIC -o src/kexpr.so -c src/kexpr.c
	crystal build src/bam-filter.cr

clean :
	rm src/kexpr.so
	rm bam-filter