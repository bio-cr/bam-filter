
CRYSTAL_BIN ?= crystal
SHARDS_BIN ?= shards
PREFIX ?= /usr/local
PROGRAM ?= bam-filter

.PHONY: help build test clean cleanall install uninstall

all: build

help: ## Show this help message
	@echo "Available targets:"
	@echo "  build      - Build the ${PROGRAM} binary"
	@echo "  test       - Run smoke tests"
	@echo "  clean      - Remove built files"
	@echo "  cleanall   - Remove built files and dependencies"
	@echo "  install    - Install ${PROGRAM} to ${PREFIX}/bin"
	@echo "  uninstall  - Remove ${PROGRAM} from ${PREFIX}/bin"
	@echo "  help       - Show this help message"

build: ${PROGRAM}

${PROGRAM}: src/bam-filter.cr src/ke.cr shard.yml
	${SHARDS_BIN} install
	${CRYSTAL_BIN} build src/bam-filter.cr --release

test: build
	./test.sh

clean:
	${RM} ${PROGRAM}

cleanall: clean
	${RM} shard.lock
	${RM} -r lib

install: build
	mkdir -p ${PREFIX}/bin
	cp ./${PROGRAM} ${PREFIX}/bin

uninstall:
	rm ${PREFIX}/bin/${PROGRAM}
