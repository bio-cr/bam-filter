
CRYSTAL_BIN ?= crystal
SHARDS_BIN ?= shards
PREFIX ?= /usr/local
PROGRAM ?= bam-filter
CC ?= cc

# Detect OS for shared library extension
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    SHARED_EXT = dylib
    SHARED_FLAGS = -dynamiclib
    LIB_NAME = libkexpr.dylib
else
    SHARED_EXT = so
    SHARED_FLAGS = -shared
    LIB_NAME = kexpr.so
endif

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

src/${LIB_NAME}: src/kexpr.c
	${SHARDS_BIN} install
	${CC} -O2 ${SHARED_FLAGS} -fPIC -o src/${LIB_NAME} src/kexpr.c

${PROGRAM}: src/bam-filter.cr src/ke.cr src/${LIB_NAME}
	${CRYSTAL_BIN} build src/bam-filter.cr --release

clean:
	${RM} ${PROGRAM}
	${RM} src/kexpr.so src/kexpr.dylib src/libkexpr.dylib

cleanall: clean
	${RM} shard.lock
	${RM} -r lib

install: build
	mkdir -p ${PREFIX}/bin
	cp ./${PROGRAM} ${PREFIX}/bin

uninstall:
	rm ${PREFIX}/bin/${PROGRAM}
