# SPDX-License-Identifier: MIT
# Copyright (c) 2026 ljc
KVER ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVER)/build
ifeq ($(filter 6.17.% 7.0.%,$(KVER)),)
$(error Unsupported kernel $(KVER): use a 6.17.x or 7.0.x source baseline)
endif
MODULE_SRC = $(if $(filter 7.0.%,$(KVER)),src-7.0,src)

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/$(MODULE_SRC) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/$(MODULE_SRC) clean

.PHONY: all clean
