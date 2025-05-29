# === Tools === #
NASM    := nasm
AR      := ar
BUILD   := build
INCLUDE := include
MACROS  := src/macros

# === ANSI Colors === #
RESET := \033[0m
BOLD  := \033[1m
GREEN := \033[32m
CYAN  := \033[36m
RED   := \033[31m

# === User configuration === #
ALGOS := sha2
PLATFORM ?= auto

# === Determine platform format === #
ifeq ($(PLATFORM),auto)
  UNAME_S := $(shell uname -s 2>/dev/null || echo unknown)
  ifeq ($(UNAME_S),Linux)
    FORMAT := elf64
  else ifeq ($(UNAME_S),Darwin)
    FORMAT := macho64
  else
    FORMAT := win64
  endif
else ifeq ($(PLATFORM),linux)
  FORMAT := elf64
else ifeq ($(PLATFORM),macos)
  FORMAT := macho64
else ifeq ($(PLATFORM),windows)
  FORMAT := win64
else
  $(error Unknown PLATFORM value '$(PLATFORM)')
endif

# === Subalgorithm mapping === #
SHA2_SUBALGOS := sha2/sha256.asm

define ALGO_MAP
sha2-256 := sha2/sha256.asm
sha2     := $(SHA2_SUBALGOS)
endef
$(eval $(ALGO_MAP))

# === Files === #
SRC     := $(foreach algo,$(ALGOS),$(eval ALL_ASM_FILES += $($(algo))))
OBJ     := $(patsubst %.asm, $(BUILD)/%.o, $(ALL_ASM_FILES))
ARCHIVE := $(BUILD)/libcrypto.a

# === Default target === #
all: banner $(ARCHIVE)

banner:
	@printf " $(CYAN)$(BOLD)Building$(RESET)   asm-crypto for $(FORMAT) with algos/groups: $(ALGOS)\n"

# === Assemble === #
$(BUILD)/%.o: src/%.asm
	@if [ ! -d "$(dir $@)" ]; then mkdir -p "$(dir $@)"; fi; \
	if $(NASM) -f $(FORMAT) -o "$@" "$<"; then \
		printf " $(GREEN)$(BOLD)Assembled$(RESET)  $<\n"; \
	else \
		printf " $(RED)$(BOLD)Failed$(RESET)    $<\n"; \
		exit 1; \
	fi

# === Archive static library === #
$(ARCHIVE): $(OBJ)
	@printf " $(CYAN)$(BOLD)Archiving$(RESET)  $@\n"
	@if [ ! -d "$(dir $@)" ]; then \
		mkdir -p "$(dir $@)"; \
	fi
	@$(AR) rcs $@ $^
	@printf " $(GREEN)$(BOLD)Archived$(RESET)   at: $(ARCHIVE)\n"

# === Clean === #
clean:
	@if [ -d "build" ]; then \
		rm -rf build; \
	fi
	@printf " $(GREEN)$(BOLD)Cleaned$(RESET)\n"

.PHONY: all clean headers banner
