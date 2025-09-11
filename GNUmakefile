
# Wrapper to run ./mk cmd [args] - w/o make(1) one can just run ./mk ...

# SPDX-License-Identifier: Unlicense

# This is done since 'make' is easier to type than './mk' (on some keyboards)

# W/o SHELL & .SHELLFLAGS "trivial" commands are executed w/o shell
# OTOH;  make ';' echo bar ;: is interesting. So not don't do that...
.NOTPARALLEL:
.SILENT:
.SUFFIXES:
MAKEFLAGS += --no-builtin-rules --no-builtin-variables
MAKEFLAGS += --warn-undefined-variables
unexport MAKEFLAGS

override CMD := $(firstword $(MAKECMDGOALS))
ifdef CMD
.PHONY: $(MAKECMDGOALS)
override ARGS := $(wordlist 2, 9999, $(MAKECMDGOALS))
else
.PHONY: help
override CMD := help
.DEFAULT_GOAL = help
endif

ifeq ($(CMD),help)
help:; ./mk
else
$(CMD):; sh mk ./. $(MAKE) $@ $(ARGS)
endif
