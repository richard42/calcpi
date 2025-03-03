###############################################################################
## Makefile for Coco Pi Calculator

# paths
SRCDIR = ./src
SCRIPTDIR = ./scripts
BUILDDIR = ./build
TOOLDIR = ./tools
GENASMDIR = $(BUILDDIR)/asm
GENOBJDIR = $(BUILDDIR)/obj
GENLISTDIR = $(BUILDDIR)/list
GENDISKDIR = $(BUILDDIR)/disk

# paths to dependencies
COCODISKGEN = $(TOOLDIR)/file2dsk
ASSEMBLER = $(TOOLDIR)/lwasm
EMULATOR = $(TOOLDIR)/mess64

# make sure build products directories exist
$(shell mkdir -p $(GENASMDIR))
$(shell mkdir -p $(GENOBJDIR))
$(shell mkdir -p $(GENLISTDIR))
$(shell mkdir -p $(GENDISKDIR))

# assembly source files
LOADER63SRC = $(addprefix $(SRCDIR)/, calcpi63.asm)
LOADER68SRC = $(addprefix $(SRCDIR)/, calcpi68.asm)

# files to be added to Coco3 disk image
READMEBAS = $(GENDISKDIR)/README.BAS
LOADER63BIN = $(GENOBJDIR)/CALCPI63.BIN
LOADER63BAS = $(GENDISKDIR)/CALCPI63.BAS
LOADER68BIN = $(GENOBJDIR)/CALCPI68.BIN
LOADER68BAS = $(GENDISKDIR)/CALCPI68.BAS
DISKFILES = $(READMEBAS) $(LOADER63BAS) $(LOADER68BAS)

# core assembler pass outputs
ASM63_LIST = $(GENLISTDIR)/calcpi63.lst
ASM68_LIST = $(GENLISTDIR)/calcpi68.lst

# options
ifeq ($(CPU),6309)
  MAMESYSTEM = coco3h
else
  CPU = 6809
  MAMESYSTEM = coco3
endif
ifeq ($(MAMEDBG), 1)
  MAMEFLAGS += -debug
endif

# output disk image filename
TARGET = CALCPI.DSK

# build targets
targets:
	@echo "Pi Calculator makefile. "
	@echo "  Targets:"
	@echo "    all            == Build disk image"
	@echo "    clean          == remove binary and output files"
	@echo "    test           == run test in MAME"
	@echo "  Build Options:"
	@echo "    CPU=6309       == build with faster 6309-specific instructions"
	@echo "  Debugging Options:"
	@echo "    MAMEDBG=1      == run MAME with debugger window (for 'test' target)"

all: $(TARGET)

clean:
	rm -rf $(GENASMDIR) $(GENOBJDIR) $(GENDISKDIR) $(GENLISTDIR)

test:
	$(EMULATOR) $(MAMESYSTEM) -flop1 $(TARGET) $(MAMEFLAGS) -window -waitvsync -resolution 640x480 -video opengl -rompath /mnt/terabyte/pyro/Emulators/firmware/

# build rules

# 0. Build dependencies
$(COCODISKGEN): $(TOOLDIR)/src/file2dsk/main.c $(DISKFILES)
	gcc -o $@ $<

# 1. Run assembly of Pi Calculator
$(LOADER63BIN): $(LOADER63SRC)
	$(ASSEMBLER) $(ASMFLAGS) -b -I $(GENASMDIR)/ -o $@ --format=raw --list=$(ASM63_LIST) $<
$(LOADER68BIN): $(LOADER68SRC)
	$(ASSEMBLER) $(ASMFLAGS) -b -I $(GENASMDIR)/ -o $@ --format=raw --list=$(ASM68_LIST) $<

# 2. Generate the BASIC program to load the machine language
$(LOADER63BAS): $(LOADER63BIN)
	$(SCRIPTDIR)/build-loader.py $(LOADER63BIN) $(LOADER63BAS)
$(LOADER68BAS): $(LOADER68BIN)
	$(SCRIPTDIR)/build-loader.py $(LOADER68BIN) $(LOADER68BAS)

# 3. Generate the README.BAS document
$(READMEBAS): $(SCRIPTDIR)/build-readme.py $(SRCDIR)/readme-bas.txt
	$(SCRIPTDIR)/build-readme.py $(SRCDIR)/readme-bas.txt $(READMEBAS)

# 4. Create Coco disk image (file2dsk))
$(TARGET): $(COCODISKGEN) $(DISKFILES)
	rm -f $(TARGET)
	$(COCODISKGEN) $(TARGET) $(DISKFILES)

.PHONY: all clean test

