
CRYSTAL_BIN ?= crystal
SHARDS_BIN ?= shards
PREFIX ?= /usr/local
PROGRAM ?= bam-filter

build: ${PROGRAM}

${PROGRAM}: src/bam-filter.cr
	${SHARDS_BIN} install
	${CC} -shared -fPIC -o src/kexpr.so -c src/kexpr.c
	${CRYSTAL_BIN} build src/bam-filter.cr

clean:
	rm src/kexpr.so
	rm ${PROGRAM}

install: build
	mkdir -p ${PREFIX}/bin
	cp ./${PROGRAM} ${PREFIX}/bin

uninstall:
	rm ${PREFIX}/bin/${PROGRAM}
