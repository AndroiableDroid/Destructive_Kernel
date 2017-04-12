hostprogs-y	:= modpost mk_elfconfig
always		:= $(hostprogs-y) empty.o

modpost-objs	:= modpost.o file2alias.o sumversion.o

devicetable-offsets-file := devicetable-offsets.h

# We use internal kbuild rules to avoid the "is up to date" message from make	
scripts/mod/devicetable-offsets.s: scripts/mod/devicetable-offsets.c FORCE	
	$(Q)mkdir -p $(dir $@)	
	$(call if_changed_dep,cc_s_c)

$(obj)/$(devicetable-offsets-file): scripts/mod/devicetable-offsets.s
	$(call cmd,offsets)

targets += $(devicetable-offsets-file)

# dependencies on generated files need to be listed explicitly

$(obj)/modpost.o $(obj)/file2alias.o $(obj)/sumversion.o: $(obj)/elfconfig.h
$(obj)/file2alias.o: $(obj)/$(devicetable-offsets-file)

quiet_cmd_elfconfig = MKELF   $@
      cmd_elfconfig = $(obj)/mk_elfconfig < $< > $@

$(obj)/elfconfig.h: $(obj)/empty.o $(obj)/mk_elfconfig FORCE
	$(call if_changed,elfconfig)

targets += elfconfig.h
