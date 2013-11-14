PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
LIBEXECDIR ?= $(PREFIX)/libexec
LIBDIR ?= $(PREFIX)/lib
SITEDIR ?= $(LIBDIR)/python2.7/site-packages

all: pkgconfig_conversions.txt

pkgconfig_conversions.txt: pkgconfig-update.sed pkgconfig-update.sh
	@sh pkgconfig-update.sh 13.1 > $@

install: bin/spec-cleaner
	@echo "Installing package to $(DESTDIR)" ; \
	install -d $(DESTDIR)$(BINDIR) ; \
	install -m 755 bin/spec-cleaner $(DESTDIR)/$(BINDIR)
	@install -d $(DESTDIR)$(DATADIR)/spec-cleaner/ ; \
	install -m 644 data/licenses_changes.txt $(DESTDIR)$(DATADIR)/spec-cleaner/ ; \
	install -m 644 data/pkgconfig_conversions.txt $(DESTDIR)$(DATADIR)/spec-cleaner/ ; \
	install -m 644 data/excludes-bracketing.txt $(DESTDIR)$(DATADIR)/spec-cleaner/
	@install -d $(DESTDIR)$(LIBEXECDIR)/obs/service/ ; \
	install -m 755 obs/format_spec_file $(DESTDIR)$(LIBEXECDIR)/obs/service/ ; \
	install -m 644 obs/format_spec_file.service $(DESTDIR)$(LIBEXECDIR)/obs/service/
	@install -d $(DESTDIR)$(SITEDIR)/spec_cleaner ; \
	install -m 755 spec_cleaner/__init__.py  $(DESTDIR)$(SITEDIR)/spec_cleaner/

test: check

check: spec_cleaner/__init__.py
	@echo "Running tests:" ; \
	for i in tests/in/*.spec; do \
		CORRECT="`echo $$i | sed 's|^tests/in|tests/out|'`" ; \
		NEW="`    echo $$i | sed 's|^tests/in|tests/tmp|'`" ; \
		TEST="`   echo $$i | sed 's|^tests/in/\(.*\).spec|\1|'`" ; \
		python spec_cleaner/__init__.py -f $$i -o "$$NEW" ; \
		echo -n " * test '$$TEST': " ; \
		if [ "`diff "$$CORRECT" "$$NEW" 2>&1`" ]; then \
			echo "failed" ; \
			FAILED="$$FAILED $$TEST" ; \
		else \
			echo "passed" ; \
		fi ; \
	done ; \
	echo ; \
	if [ "$$FAILED" ]; then \
		echo "`echo $$FAILED | wc -w` tests out of `echo tests/in/*.spec | wc -w` failed:" ; \
		echo "  $$FAILED" ; \
		echo ; \
		exit 1 ; \
	else \
		echo "All tests passed!" ; \
		echo ; \
	fi

clean:
	rm -rf tests/tmp/*

.PHONY: install check test