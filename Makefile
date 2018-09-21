arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso

linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg
assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
	build/arch/$(arch)/%.o, $(assembly_source_files))

forth_source_files := $(wildcard forth/*.fs)
forth_object_files := $(patsubst forth/%.fs, \
	build/arch/$(arch)/%.o, $(forth_source_files))

# builtin_files := $(patsubst src/arch/$(arch)/forth/builtin-files.asm)

.PHONY: all clean run iso

all: $(kernel)

clean:
	@rm -r build

debug: $(iso)
	@qemu-system-x86_64 -S -s -curses -cdrom $(iso)

run: $(iso)
	@qemu-system-x86_64 -s -curses -cdrom $(iso)

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.bin
	@cp $(grub_cfg) build/isofiles/boot/grub
	@grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	@rm -r build/isofiles

$(kernel): $(forth_object_files) builtin-files.asm $(assembly_object_files) $(linker_script)
	@x86_64-elf-ld -n -T $(linker_script) -m elf_x86_64 -o $(kernel) $(assembly_object_files) $(forth_object_files)

build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -f elf64 -i src/arch/$(arch)/  -g -F dwarf -l $@.lst $< -o $@

build/arch/$(arch)/%.o: forth/%.fs
	@echo "called still"
	@mkdir -p $(shell dirname $@)
	# @cp $< $<.bak
	# @tr '\n' ' ' < $<.bak > $<
	@x86_64-elf-objcopy -I binary -O elf64-x86-64 -Bi386 $< $@;
	# @mv $<.bak $<

builtin-files.asm: $(forth_source_files)
	sh generate-builtins.sh forth/$(shell basename $<)
	mv builtin-files.asm src/arch/$(arch)/include/builtin-files.asm
