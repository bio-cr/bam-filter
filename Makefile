
CRYSTAL_BIN ?= crystal
SHARDS_BIN ?= shards
PREFIX ?= /usr/local
PROGRAM ?= bam-filter

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

src/kexpr.so: src/kexpr.c
	${SHARDS_BIN} install
	${CC} -O2 -shared -fPIC -o src/kexpr.so -c src/kexpr.c

${PROGRAM}: src/bam-filter.cr src/ke.cr src/kexpr.so
	${CRYSTAL_BIN} build src/bam-filter.cr --release

clean:
	${RM} ${PROGRAM}
	${RM} src/kexpr.so

cleanall: clean
	${RM} shard.lock
	${RM} -r lib

install: build
	mkdir -p ${PREFIX}/bin
	cp ./${PROGRAM} ${PREFIX}/bin

uninstall:
	rm ${PREFIX}/bin/${PROGRAM}
