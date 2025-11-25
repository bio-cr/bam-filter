
CRYSTAL_BIN ?= crystal
SHARDS_BIN ?= shards
PREFIX ?= /usr/local
PROGRAM ?= bam-filter
CC ?= cc
AR ?= ar

.PHONY: help build clean cleanall install uninstall

all: build

help: ## Show this help message
	@echo "Available targets:"
	@echo "  build      - Build the ${PROGRAM} binary"
	@echo "  clean      - Remove built files"
	@echo "  cleanall   - Remove built files and dependencies"
	@echo "  install    - Install ${PROGRAM} to ${PREFIX}/bin"
	@echo "  uninstall  - Remove ${PROGRAM} from ${PREFIX}/bin"
	@echo "  help       - Show this help message"

build: ${PROGRAM}

src/libkexpr.a: src/kexpr.c
	${SHARDS_BIN} install
	${CC} -O2 -c -o src/kexpr.o src/kexpr.c
	${AR} rcs src/libkexpr.a src/kexpr.o

${PROGRAM}: src/bam-filter.cr src/ke.cr src/libkexpr.a
	${CRYSTAL_BIN} build src/bam-filter.cr --release

clean:
	${RM} ${PROGRAM}
	${RM} src/kexpr.o src/libkexpr.a

cleanall: clean
	${RM} shard.lock
	${RM} -r lib

install: build
	mkdir -p ${PREFIX}/bin
	cp ./${PROGRAM} ${PREFIX}/bin

uninstall:
	rm ${PREFIX}/bin/${PROGRAM}
