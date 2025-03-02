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
LOADERSRC = $(addprefix $(SRCDIR)/, calcpi.asm )

# files to be added to Coco3 disk image
READMEBAS = $(GENDISKDIR)/README.BAS
LOADERBIN = $(GENOBJDIR)/CALCPI.BIN
LOADERBAS = $(GENDISKDIR)/CALCPI.BAS
DISKFILES = $(READMEBAS) $(LOADERBAS)

# core assembler pass outputs
ASM_LIST = $(GENLISTDIR)/calcpi.lst

# options
ifeq ($(CPU),6309)
  ASMFLAGS += --define=CPU=6309
  MAMESYSTEM = coco3h
else
  CPU = 6809
  ASMFLAGS += --define=CPU=6809
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
$(COCODISKGEN): $(TOOLDIR)/src/file2dsk/main.c
	gcc -o $@ $<

# 1. Run assembly of Pi Calculator
$(LOADERBIN): $(LOADERSRC)
	$(ASSEMBLER) $(ASMFLAGS) -b -I $(GENASMDIR)/ -o $(LOADERBIN) --format=raw --list=$(ASM_LIST) $(SRCDIR)/calcpi.asm

# 2. Generate the BASIC program to load the machine language
$(LOADERBAS): $(LOADERBIN)
	$(SCRIPTDIR)/build-loader.py $(LOADERBIN) $(LOADERBAS)

# 3. Generate the README.BAS document
$(READMEBAS): $(SCRIPTDIR)/build-readme.py $(SRCDIR)/readme-bas.txt
	$(SCRIPTDIR)/build-readme.py $(SRCDIR)/readme-bas.txt $(READMEBAS)

# 4. Create Coco disk image (file2dsk))
$(TARGET): $(COCODISKGEN) $(DISKFILES)
	rm -f $(TARGET)
	$(COCODISKGEN) $(TARGET) $(DISKFILES)

.PHONY: all clean test

