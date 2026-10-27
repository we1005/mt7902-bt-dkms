# SPDX-License-Identifier: MIT
# Copyright (c) 2026 ljc
KVER ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVER)/build

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/src modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/src clean

.PHONY: all clean
