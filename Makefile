PACKAGES := $(wildcard packages/*)
TARGET_DIR = ncs-run
TARGET_SETUP = $(TARGET_DIR)
NCS_SETUP = ncs-setup
NCS_CLI = ncs_cli
ENV_VARS = 
NCS = ncs
NETSIM = ncs-netsim

all: build test

clean: clean_packages
	rm -rf ncs-run
	rm -rf netsim
	rm -f netsim_init.xml
.PHONY: clean

build: make_packages $(TARGET_SETUP) link_packages setup_netsim
.PHONY: build

$(TARGET_SETUP):
	$(NCS_SETUP) --dest $(TARGET_DIR)

make_packages: $(PACKAGES)
	$(foreach pkg, $(PACKAGES), \
	  if [ -d "$(pkg)" ]; then $(MAKE) -C"$(pkg)/src" all; fi &&) true
.PHONY: make_packages

cli:
	$(ENV_VARS) $(NCS_CLI) -u admin -g admin
.PHONY: cli

clean_packages:
	$(foreach pkg, $(PACKAGES), \
	  if [ -d "$(pkg)" ]; then $(MAKE) -C $(pkg)/src clean; fi; )
.PHONY: clean_packages

link_packages:
	$(foreach pkg, $(PACKAGES), \
	  if [ -d "$(pkg)" ]; then ln -sf ../../$(pkg) $(TARGET_DIR)/packages/ ; fi &&) true
.PHONY: link_packages 

clean_cdb:
	rm -f $(TARGET_DIR)/ncs-cdb/*.cdb
.PHONY: clean_cdb

start: start_netsim
	(cd $(TARGET_DIR); $(NCS))
	printf "request devices sync-from\n" | ncs_cli -u admin
	printf "configure\nload merge init.xml\ncommit\n" | ncs_cli -u admin
.PHONY: start

stop: stop_netsim
	$(NCS) --stop || true
.PHONY: stop

start_netsim:
	$(NETSIM) start
.PHONY: start_netsim

stop_netsim:
	$(NETSIM) stop || true
.PHONY: stop_netsim

setup_netsim:
	$(NETSIM) create-network ./packages/router 3 ex --dir ./netsim
	$(NETSIM) ncs-xml-init > $(TARGET_DIR)/ncs-cdb/netsim_init.xml
.PHONY: setup_netsim 