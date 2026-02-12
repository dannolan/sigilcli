PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

.PHONY: build release install uninstall clean

build:
	swift build

release:
	swift build -c release --disable-sandbox

install: release
	install -d $(BINDIR)
	install .build/release/sigil $(BINDIR)/sigil

uninstall:
	rm -f $(BINDIR)/sigil

clean:
	swift package clean
