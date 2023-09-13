prefix       := $(or $(prefix),$(PREFIX),/usr/local)
datarootdir  := $(prefix)/share
datadir      := $(datarootdir)
sysconfdir   := /etc

CONF_DIR     := $(sysconfdir)/one-context.d
INITD_DIR    := $(sysconfdir)/init.d
SCRIPTS_DIR  := $(datadir)/one-context/scripts

GIT          := git
INSTALL      := install
LN_S         := ln -s
SED          := sed

MAKEFILE_PATH = $(lastword $(MAKEFILE_LIST))

# Names of scripts with a numeric prefix to be used in symlinks.
SCRIPTS      := 00-network 05-hostname 10-hosts 15-ntp 20-timezone 50-sudo-user 55-ssh-public-key 60-grow-fs 65-ssmtp 90-start-script

#: Print list of targets.
help:
	@printf '%s\n\n' 'List of targets:'
	@$(SED) -En '/^#:.*/{ N; s/^#: (.*)\n([A-Za-z0-9_-]+).*/\2 \1/p }' $(MAKEFILE_PATH) \
		| while read label desc; do printf '%-17s %s\n' "$$label" "$$desc"; done

#: Check shell scripts for syntax errors.
check:
	@rc=0; for f in scripts/*; do \
		if $(SHELL) -n $$f; then \
			printf "%-33s PASS\n" $$f; \
		else \
			rc=1; \
		fi; \
	done; \
	exit $$rc

#: Install files to $DESTDIR.
install: install-scripts install-symlinks install-init

#: Install contextualization scripts to ${DESTDIR}${SCRIPTS_DIR}/.
install-scripts:
	@$(INSTALL) -Dv -m 644 scripts/utils.sh $(DESTDIR)$(SCRIPTS_DIR)/utils.sh
	@for name in $(SCRIPTS); do \
		name=$${name#*-}; \
		$(INSTALL) -Dv -m 755 scripts/$$name $(DESTDIR)$(SCRIPTS_DIR)/$$name; \
	done

#: Install symlinks to contextualization scripts to ${DESTDIR}${CONF_DIR}/.
install-symlinks:
	@$(INSTALL) -dv $(DESTDIR)$(CONF_DIR)
	@for name in $(SCRIPTS); do \
		$(LN_S) -fv $(SCRIPTS_DIR)/$${name#*-} $(DESTDIR)$(CONF_DIR)/$$name; \
	done

#: Install the vmcontext init script to ${DESTDIR}/${INITD_DIR}/.
install-init:
	@$(INSTALL) -Dv -m 755 init.d/vmcontext $(DESTDIR)$(INITD_DIR)/vmcontext

#: Update version in utils.sh to $VERSION.
bump-version:
	test -n "$(VERSION)"  # $$VERSION
	$(SED) -E -i "s/^(readonly VERSION)=.*/\1='$(VERSION)'/" scripts/utils.sh

#: Bump version to $VERSION, create release commit and tag.
release: .check-git-clean | bump-version
	test -n "$(VERSION)"  # $$VERSION
	$(GIT) add .
	$(GIT) commit --allow-empty -m "Release version $(VERSION)"
	$(GIT) tag -s v$(VERSION) -m v$(VERSION)

.PHONY: help check install install-scripts install-symlinks install-init bump-version release


.check-git-clean:
	@test -z "$(shell $(GIT) status --porcelain)" \
		|| { echo 'You have uncommitted changes!' >&2; exit 1; }

.PHONY: .check-distro .check-git-clean
