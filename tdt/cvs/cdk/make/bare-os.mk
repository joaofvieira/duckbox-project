#
# FILESYSTEM
#
$(DEPDIR)/min-filesystem $(DEPDIR)/std-filesystem $(DEPDIR)/max-filesystem \
$(DEPDIR)/filesystem: \
$(DEPDIR)/%filesystem: bootstrap-cross
	$(INSTALL) -d $(targetprefix)/{bin,boot,dev,dev.static,etc,lib,mnt,opt,proc,root,sbin,sys,tmp,usr,var}
	$(INSTALL) -d $(targetprefix)/etc/{default,opt}
	$(INSTALL) -d $(targetprefix)/usr/{bin,include,lib,local,sbin,share,src}
	$(INSTALL) -d $(targetprefix)/usr/local/{bin,include,lib,man,sbin,share,src}
	$(INSTALL) -d $(targetprefix)/usr/local/man/{man1,man2,man3,man4,man5,man6,man7,man8}
	$(INSTALL) -d $(targetprefix)/usr/share/{aclocal,doc,info,locale,man,misc,nls}
	$(INSTALL) -d $(targetprefix)/usr/share/man/{man0p,man1,man1p,man2,man3,man3p,man4,man5,man6,man7,man8,man9}
	$(INSTALL) -d $(targetprefix)/var/{backups,cache,lib,local,lock,log,mail,opt,run,spool}
	ln -sf $(targetprefix)/lib $(targetprefix)/lib64
	ln -sf $(targetprefix)/usr/lib $(targetprefix)/usr/lib64
	$(INSTALL) -d $(targetprefix)/var/lib/misc
	$(INSTALL) -d $(targetprefix)/var/lock/subsys
	$(INSTALL) -d $(targetprefix)/etc/{init.d,rc.d,samba}
	$(INSTALL) -d $(targetprefix)/etc/rc.d/{rc3.d,rcS.d}
	ln -s ../init.d $(targetprefix)/etc/rc.d/init.d
	$(INSTALL) -d $(targetprefix)/etc/samba/private
	$(INSTALL) -d $(targetprefix)/media
	$(INSTALL) -d $(targetprefix)/var/bin
	[ "x$*" = "x" ] && touch $@ || true

#
# GLIBC
#
GLIBC := glibc
GLIBC_DEV := glibc-dev
if STM22
GLIBC_VERSION := 2.5-27
GLIBC_RAWVERSION := $(firstword $(subst -, ,$(GLIBC_VERSION)))
GLIBC_SPEC := stm-target-$(GLIBC)-sh4processed.spec
GLIBC_SPEC_PATCH := $(GLIBC_SPEC)22.diff
GLIBC_PATCHES := glibc-2.5.patch
else !STM22
if STM23
GLIBC_VERSION := 2.6.1-53
GLIBC_RAWVERSION := $(firstword $(subst -, ,$(GLIBC_VERSION)))
GLIBC_SPEC := stm-target-$(GLIBC).spec
GLIBC_SPEC_PATCH := $(GLIBC_SPEC)23.diff
GLIBC_PATCHES := stm-target-glibc-sysincludes.patch
else !STM23
# if STM24
GLIBC_VERSION := 2.10.2-38
GLIBC_RAWVERSION := $(firstword $(subst -, ,$(GLIBC_VERSION)))
GLIBC_SPEC := stm-target-$(GLIBC).spec
GLIBC_SPEC_PATCH :=
GLIBC_PATCHES :=
# endif STM24
endif !STM23
endif !STM22

GLIBC_RPM := RPMS/sh4/$(STLINUX)-sh4-$(GLIBC)-$(GLIBC_VERSION).sh4.rpm
GLIBC_DEV_RPM := RPMS/sh4/$(STLINUX)-sh4-$(GLIBC_DEV)-$(GLIBC_VERSION).sh4.rpm

$(GLIBC_RPM) $(GLIBC_DEV_RPM): \
		$(if $(GLIBC_SPEC_PATCH),Patches/$(GLIBC_SPEC_PATCH)) \
		$(if $(GLIBC_PATCHES),$(GLIBC_PATCHES:%=Patches/%)) \
		$(archivedir)/$(STLINUX)-target-$(GLIBC)-$(GLIBC_VERSION).src.rpm \
		| filesystem
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(GLIBC_SPEC_PATCH),( cd SPECS && patch -p1 $(GLIBC_SPEC) < $(buildprefix)/Patches/$(GLIBC_SPEC_PATCH) ) &&) \
	$(if $(GLIBC_PATCHES),cp $(GLIBC_PATCHES:%=Patches/%) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --nodeps --target=sh4-linux SPECS/$(GLIBC_SPEC)

$(DEPDIR)/min-$(GLIBC) $(DEPDIR)/std-$(GLIBC) $(DEPDIR)/max-$(GLIBC) \
$(DEPDIR)/$(GLIBC): \
$(DEPDIR)/%$(GLIBC): $(GLIBC_RPM) | $(DEPDIR)/%filesystem
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch --nodeps  -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^)
	[ "x$*" = "x" ] && touch $@ || true

$(DEPDIR)/min-$(GLIBC_DEV) $(DEPDIR)/std-$(GLIBC_DEV) $(DEPDIR)/max-$(GLIBC_DEV) \
$(DEPDIR)/$(GLIBC_DEV): \
$(DEPDIR)/%$(GLIBC_DEV): $(DEPDIR)/%$(GLIBC) $(GLIBC_DEV_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch --nodeps -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^)
	[ "x$*" = "x" ] && touch $@ || true

#
# BINUTILS
#
BINUTILS := binutils
BINUTILS_DEV := binutils-dev
if STM22
BINUTILS_VERSION := 2.17.50.0.4-14
BINUTILS_SPEC := stm-target-$(BINUTILS)-sh4processed.spec
BINUTILS_SPEC_PATCH :=
BINUTILS_PATCHES :=
else !STM22
if STM23
# Due to libtool errors of target-gcc, the stm24 version is used instead of stm23
BINUTILS_VERSION := 2.19.1-41
BINUTILS_SPEC := stm-target-$(BINUTILS).spec
BINUTILS_SPEC_PATCH :=
BINUTILS_PATCHES :=
else !STM23
# if STM24
BINUTILS_VERSION := 2.22-68
BINUTILS_SPEC := stm-target-$(BINUTILS).spec
BINUTILS_SPEC_PATCH := $(BINUTILS_SPEC).$(BINUTILS_VERSION).diff
BINUTILS_PATCHES :=
# endif STM24
endif !STM23
endif !STM22

BINUTILS_RPM := RPMS/sh4/$(STLINUX)-sh4-$(BINUTILS)-$(BINUTILS_VERSION).sh4.rpm
BINUTILS_DEV_RPM := RPMS/sh4/$(STLINUX)-sh4-$(BINUTILS_DEV)-$(BINUTILS_VERSION).sh4.rpm

$(BINUTILS_RPM) $(BINUTILS_DEV_RPM): \
		$(if $(BINUTILS_SPEC_PATCH),Patches/$(BINUTILS_SPEC_PATCH)) \
		$(if $(BINUTILS_PATCHES),$(BINUTILS_PATCHES:%=Patches/%)) \
		$(archivedir)/$(STLINUX:%23=%24)-target-$(BINUTILS)-$(BINUTILS_VERSION).src.rpm
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(BINUTILS_SPEC_PATCH),( cd SPECS && patch -p1 $(BINUTILS_SPEC) < $(buildprefix)/Patches/$(BINUTILS_SPEC_PATCH) ) &&) \
	$(if $(BINUTILS_PATCHES),cp $(BINUTILS_PATCHES:%=Patches/%) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(BINUTILS_SPEC)

$(BINUTILS): $(BINUTILS_RPM)
	@rpm $(DRPM) --ignorearch --nodeps -Uhv $< && \
	touch .deps/$(notdir $@)

$(BINUTILS_DEV): $(BINUTILS_DEV_RPM)
	@rpm $(DRPM) --ignorearch --nodeps --noscripts -Uhv $< && \
	touch .deps/$(notdir $@)

#
# GMP
#
if !STM22
GMP := gmp
if STM23
# Due to libtool errors of target-gcc, the stm24 version is used instead of stm23
GMP_VERSION := 4.3.2-3
GMP_SPEC := stm-target-$(GMP).spec
GMP_SPEC_PATCH :=
GMP_PATCHES :=
else !STM23
# if STM24
GMP_VERSION := 5.1.0-7
GMP_SPEC := stm-target-$(GMP).spec
GMP_SPEC_PATCH :=
GMP_PATCHES :=
# endif STM24
endif !STM23

GMP_RPM := RPMS/sh4/$(STLINUX)-sh4-$(GMP)-$(GMP_VERSION).sh4.rpm

$(GMP_RPM): \
		$(addprefix Patches/,$(GMP_SPEC_PATCH) $(GMP_PATCHES)) \
		$(archivedir)/$(STLINUX:%23=%24)-target-$(GMP)-$(GMP_VERSION).src.rpm
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(GMP_SPEC_PATCH),( cd SPECS && patch -p1 $(GMP_SPEC) < $(buildprefix)/Patches/$(GMP_SPEC_PATCH) ) &&) \
	$(if $(GMP_PATCHES),cp $(addprefix Patches/,$(GMP_PATCHES)) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(GMP_SPEC)

$(DEPDIR)/$(GMP): $(GMP_RPM)
	@rpm $(DRPM) --ignorearch --nodeps -Uhv $(lastword $^) && \
	sed -i "/^libdir/s|'/usr/lib'|'$(targetprefix)/usr/lib'|" $(targetprefix)/usr/lib/libgmp.la
	sed -i "/^dependency_libs/s|-L/usr/lib -L/lib ||" $(targetprefix)/usr/lib/libgmp.la
	touch $@
endif !STM22

#
# MPFR
#
if !STM22
MPFR := mpfr
if STM23
# Due to libtool errors of target-gcc, the stm24 version is used instead of stm23
MPFR_VERSION := 2.4.2-3
MPFR_SPEC := stm-target-$(MPFR).spec
MPFR_SPEC_PATCH :=
MPFR_PATCHES :=
else !STM23
# if STM24
MPFR_VERSION := 3.1.1-7
MPFR_SPEC := stm-target-$(MPFR).spec
MPFR_SPEC_PATCH :=
MPFR_PATCHES :=
# endif STM24
endif !STM23
MPFR_RPM := RPMS/sh4/$(STLINUX)-sh4-$(MPFR)-$(MPFR_VERSION).sh4.rpm

$(MPFR_RPM): \
		$(addprefix Patches/,$(MPFR_SPEC_PATCH) $(MPFR_PATCHES)) \
		$(archivedir)/$(STLINUX:%23=%24)-target-$(MPFR)-$(MPFR_VERSION).src.rpm \
		| $(DEPDIR)/$(GMP)
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(MPFR_SPEC_PATCH),( cd SPECS && patch -p1 $(MPFR_SPEC) < $(buildprefix)/Patches/$(MPFR_SPEC_PATCH) ) &&) \
	$(if $(MPFR_PATCHES),cp $(addprefix Patches/,$(MPFR_PATCHES)) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(MPFR_SPEC)

$(DEPDIR)/$(MPFR): $(MPFR_RPM)
	@rpm $(DRPM) --ignorearch --nodeps -Uhv $(lastword $^) && \
	sed -i "/^libdir/s|'/usr/lib'|'$(targetprefix)/usr/lib'|" $(targetprefix)/usr/lib/libmpfr.la
	sed -i "/^dependency_libs/s|-L/usr/lib -L/lib ||" $(targetprefix)/usr/lib/libmpfr.la
	touch .deps/$(notdir $@)
endif !STM22

#
# MPC
#
if STM24
MPC := mpc
MPC_VERSION := 1.0.1-4
MPC_SPEC := stm-target-$(MPC).spec
MPC_SPEC_PATCH :=
MPC_PATCHES :=

MPC_RPM := RPMS/sh4/$(STLINUX)-sh4-$(MPC)-$(MPC_VERSION).sh4.rpm

$(MPC_RPM): \
		$(addprefix Patches/,$(MPC_SPEC_PATCH) $(MPC_PATCHES)) \
		$(archivedir)/$(STLINUX:%23=%24)-target-$(MPC)-$(MPC_VERSION).src.rpm \
		| $(DEPDIR)/$(MPFR)
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(MPC_SPEC_PATCH),( cd SPECS && patch -p1 $(MPC_SPEC) < $(buildprefix)/Patches/$(MPC_SPEC_PATCH) ) &&) \
	$(if $(MPC_PATCHES),cp $(addprefix Patches/,$(MPC_PATCHES)) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(MPC_SPEC)

$(DEPDIR)/$(MPC): $(MPC_RPM)
	@rpm $(DRPM) --ignorearch --nodeps -Uhv $(lastword $^) && \
	sed -i "/^libdir/s|'/usr/lib'|'$(targetprefix)/usr/lib'|" $(targetprefix)/usr/lib/libmpc.la
	sed -i "/^dependency_libs/s|-L/usr/lib -L/lib ||" $(targetprefix)/usr/lib/libmpc.la
	touch $@
endif STM24

#
# GCC LIBSTDC++
#
GCC := gcc
LIBSTDC := libstdc++
LIBSTDC_DEV := libstdc++-dev
LIBGCC := libgcc
if STM22
GCC_VERSION := 4.1.1-26
GCC_SPEC := stm-target-$(GCC)-sh4processed.spec
GCC_SPEC_PATCH := $(GCC_SPEC)22.diff
GCC_PATCHES :=
else !STM22
if STM23
# Due to libtool errors of target-gcc, the stm24 version is used instead of stm23
GCC_VERSION := 4.3.4-66
GCC_SPEC := stm-target-$(GCC).spec
GCC_SPEC_PATCH :=
GCC_PATCHES :=
else !STM23
# if STM24
GCC_VERSION := 4.6.3-115
GCC_SPEC := stm-target-$(GCC).spec
GCC_SPEC_PATCH :=
GCC_PATCHES :=
# endif STM24
endif !STM23
endif !STM22

GCC_RPM := RPMS/sh4/$(STLINUX)-sh4-$(GCC)-$(GCC_VERSION).sh4.rpm
LIBSTDC_RPM := RPMS/sh4/$(STLINUX)-sh4-$(LIBSTDC)-$(GCC_VERSION).sh4.rpm
LIBSTDC_DEV_RPM := RPMS/sh4/$(STLINUX)-sh4-$(LIBSTDC_DEV)-$(GCC_VERSION).sh4.rpm
LIBGCC_RPM := RPMS/sh4/$(STLINUX)-sh4-$(LIBGCC)-$(GCC_VERSION).sh4.rpm

$(GCC_RPM) $(LIBSTDC_RPM) $(LIBSTDC_DEV_RPM) $(LIBGCC_RPM): \
		$(addprefix Patches/,$(GCC_SPEC_PATCH) $(GCC_PATCHES)) \
		$(archivedir)/$(STLINUX:%23=%24)-target-$(GCC)-$(GCC_VERSION).src.rpm \
		| $(DEPDIR)/$(GLIBC_DEV) $(MPFR) $(MPC)
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(GCC_SPEC_PATCH),( cd SPECS && patch -p1 $(GCC_SPEC) < $(buildprefix)/Patches/$(GCC_SPEC_PATCH) ) &&) \
	$(if $(GCC_PATCHES),cp $(addprefix Patches/,$(GCC_PATCHES)) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(GCC_SPEC)

$(DEPDIR)/min-$(GCC) $(DEPDIR)/std-$(GCC) $(DEPDIR)/max-$(GCC) $(DEPDIR)/$(GCC): \
$(DEPDIR)/%$(GCC): $(DEPDIR)/%$(GLIBC_DEV) $(GCC_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch --nodeps -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^)
	[ "x$*" = "x" ] && touch $@ || true

$(DEPDIR)/min-$(LIBSTDC) $(DEPDIR)/std-$(LIBSTDC) $(DEPDIR)/max-$(LIBSTDC) $(DEPDIR)/$(LIBSTDC): \
$(DEPDIR)/%$(LIBSTDC): $(DEPDIR)/%$(CROSS_LIBGCC) $(LIBSTDC_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch --nodeps -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^)
	[ "x$*" = "x" ] && touch $@ || true

$(DEPDIR)/min-$(LIBSTDC_DEV) $(DEPDIR)/std-$(LIBSTDC_DEV) $(DEPDIR)/max-$(LIBSTDC_DEV) $(DEPDIR)/$(LIBSTDC_DEV): \
$(DEPDIR)/%$(LIBSTDC_DEV): $(DEPDIR)/%$(LIBSTDC) $(LIBSTDC_DEV_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch --nodeps -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^)
	[ "x$*" = "x" ] && touch $@ || true
	sed -i "/^libdir/s|'/usr/lib'|'$(targetprefix)/usr/lib'|" $(targetprefix)/usr/lib/lib{std,sup}c++.la
	sed -i "/^dependency_libs/s|-L/usr/lib -L/lib ||" $(targetprefix)/usr/lib/lib{std,sup}c++.la

$(DEPDIR)/min-$(LIBGCC) $(DEPDIR)/std-$(LIBGCC) $(DEPDIR)/max-$(LIBGCC) $(DEPDIR)/$(LIBGCC): \
$(DEPDIR)/%$(LIBGCC): $(LIBGCC_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch --nodeps -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^)
	[ "x$*" = "x" ] && touch $@ || true

# END OF BOOTSTRAP

#
# LIBTERMCAP
#
LIBTERMCAP := libtermcap
LIBTERMCAP_DEV := libtermcap-dev
LIBTERMCAP_DOC := libtermcap-doc
if STM22
LIBTERMCAP_VERSION := 2.0.8-8
LIBTERMCAP_RAWVERSION := $(firstword $(subst -, ,$(LIBTERMCAP_VERSION)))
LIBTERMCAP_SPEC := stm-target-$(LIBTERMCAP).spec
LIBTERMCAP_SPEC_PATCH :=
LIBTERMCAP_PATCHES :=
else !STM22
if STM23
LIBTERMCAP_VERSION := 2.0.8-8
LIBTERMCAP_RAWVERSION := $(firstword $(subst -, ,$(LIBTERMCAP_VERSION)))
LIBTERMCAP_SPEC := stm-target-$(LIBTERMCAP).spec
LIBTERMCAP_SPEC_PATCH :=
LIBTERMCAP_PATCHES :=
else !STM23
# if STM24
LIBTERMCAP_VERSION := 2.0.8-10
LIBTERMCAP_RAWVERSION := $(firstword $(subst -, ,$(LIBTERMCAP_VERSION)))
LIBTERMCAP_SPEC := stm-target-$(LIBTERMCAP).spec
LIBTERMCAP_SPEC_PATCH :=
LIBTERMCAP_PATCHES :=
# endif STM24
endif !STM23
endif !STM22

LIBTERMCAP_RPM := RPMS/sh4/$(STLINUX)-sh4-$(LIBTERMCAP)-$(LIBTERMCAP_VERSION).sh4.rpm
LIBTERMCAP_DEV_RPM := RPMS/sh4/$(STLINUX)-sh4-$(LIBTERMCAP_DEV)-$(LIBTERMCAP_VERSION).sh4.rpm
LIBTERMCAP_DOC_RPM := RPMS/sh4/$(STLINUX)-sh4-$(LIBTERMCAP_DOC)-$(LIBTERMCAP_VERSION).sh4.rpm

$(LIBTERMCAP_RPM) $(LIBTERMCAP_DEV_RPM) $(LIBTERMCAP_DOC_RPM): \
		$(if $(LIBTERMCAP_SPEC_PATCH),Patches/$(LIBTERMCAP_SPEC_PATCH)) \
		$(if $(LIBTERMCAP_PATCHES),$(LIBTERMCAP_PATCHES:%=Patches/%)) \
		$(archivedir)/$(STM_SRC)-target-$(LIBTERMCAP)-$(LIBTERMCAP_VERSION).src.rpm \
		| $(DEPDIR)/$(GLIBC_DEV)
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(LIBTERMCAP_SPEC_PATCH),( cd SPECS && patch -p1 $(LIBTERMCAP_SPEC) < $(buildprefix)/Patches/$(LIBTERMCAP_SPEC_PATCH) ) &&) \
	$(if $(LIBTERMCAP_PATCHES),cp $(LIBTERMCAP_PATCHES:%=Patches/%) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(LIBTERMCAP_SPEC)

$(DEPDIR)/min-$(LIBTERMCAP) $(DEPDIR)/std-$(LIBTERMCAP) $(DEPDIR)/max-$(LIBTERMCAP) \
$(DEPDIR)/$(LIBTERMCAP): \
$(DEPDIR)/%$(LIBTERMCAP): bootstrap $(LIBTERMCAP_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch  -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^) && \
	ln -sf libtermcap.so.2 $(prefix)/$*cdkroot/usr/lib/libtermcap.so && \
	$(INSTALL) -m 644 $(buildprefix)/root/etc/termcap $(prefix)/$*cdkroot/etc && \
	[ "x$*" = "x" ] && touch $@ || true
	@TUXBOX_YAUD_CUSTOMIZE@

$(DEPDIR)/min-$(LIBTERMCAP_DEV) $(DEPDIR)/std-$(LIBTERMCAP_DEV) $(DEPDIR)/max-$(LIBTERMCAP_DEV) \
$(DEPDIR)/$(LIBTERMCAP_DEV): \
$(DEPDIR)/%$(LIBTERMCAP_DEV): $(DEPDIR)/%$(LIBTERMCAP) $(LIBTERMCAP_DEV_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch  -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^)
	[ "x$*" = "x" ] && touch $@ || true
	@TUXBOX_YAUD_CUSTOMIZE@

$(DEPDIR)/min-$(LIBTERMCAP_DOC) $(DEPDIR)/std-$(LIBTERMCAP_DOC) $(DEPDIR)/max-$(LIBTERMCAP_DOC) \
$(DEPDIR)/$(LIBTERMCAP_DOC): \
$(DEPDIR)/%$(LIBTERMCAP_DOC): $(LIBTERMCAP_DOC_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch  -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^)
	[ "x$*" = "x" ] && touch $@ || true
	@TUXBOX_YAUD_CUSTOMIZE@

#
# NCURSES
#
NCURSES := ncurses
NCURSES_BASE := ncurses-base
NCURSES_DEV := ncurses-dev
if STM22
NCURSES_VERSION := 5.5-9
NCURSES_SPEC := stm-target-$(NCURSES).spec
NCURSES_SPEC_PATCH :=
NCURSES_PATCHES :=
else !STM22
if STM23
NCURSES_VERSION := 5.5-9
NCURSES_SPEC := stm-target-$(NCURSES).spec
NCURSES_SPEC_PATCH :=
NCURSES_PATCHES :=
else !STM23
if STM24
NCURSES_VERSION := 5.5-10
NCURSES_SPEC := stm-target-$(NCURSES).spec
NCURSES_SPEC_PATCH :=
NCURSES_PATCHES :=
endif STM24
endif !STM23
endif !STM22

NCURSES_RPM := RPMS/sh4/$(STLINUX)-sh4-$(NCURSES)-$(NCURSES_VERSION).sh4.rpm
NCURSES_BASE_RPM := RPMS/sh4/$(STLINUX)-sh4-$(NCURSES_BASE)-$(NCURSES_VERSION).sh4.rpm
NCURSES_DEV_RPM := RPMS/sh4/$(STLINUX)-sh4-$(NCURSES_DEV)-$(NCURSES_VERSION).sh4.rpm

$(NCURSES_RPM) $(NCURSES_BASE_RPM) $(NCURSES_DEV_RPM): \
		$(if $(NCURSES_SPEC_PATCH),Patches/$(NCURSES_SPEC_PATCH)) \
		$(if $(NCURSES_PATCHES),$(NCURSES_PATCHES:%=Patches/%)) \
		$(archivedir)/$(STM_SRC)-target-$(NCURSES)-$(NCURSES_VERSION).src.rpm \
		| $(DEPDIR)/$(LIBSTDC_DEV)
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(NCURSES_SPEC_PATCH),( cd SPECS && patch -p1 $(NCURSES_SPEC) < $(buildprefix)/Patches/$(NCURSES_SPEC_PATCH) ) &&) \
	$(if $(NCURSES_PATCHES),cp $(NCURSES_PATCHES:%=Patches/%) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(NCURSES_SPEC)

$(DEPDIR)/min-$(NCURSES_BASE) $(DEPDIR)/std-$(NCURSES_BASE) $(DEPDIR)/max-$(NCURSES_BASE) \
$(DEPDIR)/$(NCURSES_BASE): \
$(DEPDIR)/%$(NCURSES_BASE): $(NCURSES_BASE_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch  -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $<)
	[ "x$*" = "x" ] && touch $@ || true
	@TUXBOX_YAUD_CUSTOMIZE@

$(DEPDIR)/min-$(NCURSES) $(DEPDIR)/std-$(NCURSES) $(DEPDIR)/max-$(NCURSES) \
$(DEPDIR)/$(NCURSES): \
$(DEPDIR)/%$(NCURSES): $(DEPDIR)/%$(NCURSES_BASE) $(NCURSES_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch  -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^)
	[ "x$*" = "x" ] && touch $@ || true
	@TUXBOX_YAUD_CUSTOMIZE@

$(DEPDIR)/min-$(NCURSES_DEV) $(DEPDIR)/std-$(NCURSES_DEV) $(DEPDIR)/max-$(NCURSES_DEV) \
$(DEPDIR)/$(NCURSES_DEV): \
$(DEPDIR)/%$(NCURSES_DEV): $(DEPDIR)/%$(NCURSES_BASE) $(NCURSES_DEV_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch --nodeps -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^)
	[ "x$*" = "x" ] && touch $@ || true
	@TUXBOX_YAUD_CUSTOMIZE@

#Wrote: RPMS/sh4/stlinux23-sh4-ncurses-dbg-5.5-9.sh4.rpm
#Wrote: RPMS/sh4/stlinux23-sh4-ncurses-pic-5.5-9.sh4.rpm
#Wrote: RPMS/sh4/stlinux23-sh4-ncurses-bin-5.5-9.sh4.rpm
#Wrote: RPMS/sh4/stlinux23-sh4-ncurses-term-5.5-9.sh4.rpm

#
# BASE-PASSWD
#
BASE_PASSWD := base-passwd
if STM22
BASE_PASSWD_VERSION := 3.5.9-6
BASE_PASSWD_SPEC := stm-target-$(BASE_PASSWD).spec
BASE_PASSWD_SPEC_PATCH :=
BASE_PASSWD_PATCHES :=
else !STM22
if STM23
BASE_PASSWD_VERSION := 3.5.9-7
BASE_PASSWD_SPEC := stm-target-$(BASE_PASSWD).spec
BASE_PASSWD_SPEC_PATCH :=
BASE_PASSWD_PATCHES :=
else !STM23
# if STM24
BASE_PASSWD_VERSION := 3.5.9-9
BASE_PASSWD_SPEC := stm-target-$(BASE_PASSWD).spec
BASE_PASSWD_SPEC_PATCH :=
BASE_PASSWD_PATCHES :=
# endif STM24
endif !STM23
endif !STM22

BASE_PASSWD_RPM := RPMS/sh4/$(STLINUX)-sh4-$(BASE_PASSWD)-$(BASE_PASSWD_VERSION).sh4.rpm

$(BASE_PASSWD_RPM): \
		$(if $(BASE_PASSWD_SPEC_PATCH),Patches/$(BASE_PASSWD_SPEC_PATCH)) \
		$(if $(BASE_PASSWD_PATCHES),$(BASE_PASSWD_PATCHES:%=Patches/%)) \
		$(archivedir)/$(STLINUX)-target-$(BASE_PASSWD)-$(BASE_PASSWD_VERSION).src.rpm
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(BASE_PASSWD_SPEC_PATCH),( cd SPECS && patch -p1 $(BASE_PASSWD_SPEC) < $(buildprefix)/Patches/$(BASE_PASSWD_SPEC_PATCH) ) &&) \
	$(if $(BASE_PASSWD_PATCHES),cp $(BASE_PASSWD_PATCHES:%=Patches/%) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(BASE_PASSWD_SPEC)

$(DEPDIR)/min-$(BASE_PASSWD) $(DEPDIR)/std-$(BASE_PASSWD) $(DEPDIR)/max-$(BASE_PASSWD) \
$(DEPDIR)/$(BASE_PASSWD): \
$(DEPDIR)/%$(BASE_PASSWD): $(BASE_FILES_ADAPTED_ETC_FILES:%=root/etc/%) \
		$(BASE_PASSWD_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch --nodeps  --nopost -Uhv \
		--replacepkgs --badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^) && \
		$(hostprefix)/bin/update-passwd -L -p $(prefix)/$*cdkroot/usr/share/base-passwd/passwd.master \
			-g $(prefix)/$*cdkroot/usr/share/base-passwd/group.master -P $(prefix)/$*cdkroot/etc/passwd \
			-S $(prefix)/$*cdkroot/etc/shadow -G $(prefix)/$*cdkroot/etc/group && \
	chmod 600 $(prefix)/$*cdkroot/etc/shadow && \
	( cd $(prefix)/$*cdkroot/etc && sed -e "s|/bin/bash|/bin/sh|g" -i passwd ) && \
	rm -f $(prefix)/$*cdkroot/etc/shadow
	[ "x$*" = "x" ] && touch $@ || true
	@TUXBOX_YAUD_CUSTOMIZE@

#
# MAKEDEV
#
MAKEDEV := makedev
if STM22
MAKEDEV_VERSION := 2.3.1-15
MAKEDEV_SPEC := stm-target-$(MAKEDEV).spec
MAKEDEV_SPEC_PATCH :=
MAKEDEV_PATCHES :=
else !STM22
if STM23
MAKEDEV_VERSION := 2.3.1-24
MAKEDEV_SPEC := stm-target-$(MAKEDEV).spec
MAKEDEV_SPEC_PATCH :=
MAKEDEV_PATCHES :=
else !STM23
# if STM24
MAKEDEV_VERSION := 2.3.1-26
MAKEDEV_SPEC := stm-target-$(MAKEDEV).spec
MAKEDEV_SPEC_PATCH :=
MAKEDEV_PATCHES :=
# endif STM24
endif !STM23
endif !STM22

MAKEDEV_RPM := RPMS/sh4/$(STLINUX)-sh4-$(MAKEDEV)-$(MAKEDEV_VERSION).sh4.rpm

$(MAKEDEV_RPM): \
		$(if $(MAKEDEV_SPEC_PATCH),Patches/$(MAKEDEV_SPEC_PATCH)) \
		$(if $(MAKEDEV_PATCHES),$(MAKEDEV_PATCHES:%=Patches/%)) \
		$(archivedir)/$(STLINUX)-target-$(MAKEDEV)-$(MAKEDEV_VERSION).src.rpm
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(MAKEDEV_SPEC_PATCH),( cd SPECS && patch -p1 $(MAKEDEV_SPEC) < $(buildprefix)/Patches/$(MAKEDEV_SPEC_PATCH) ) &&) \
	$(if $(MAKEDEV_PATCHES),cp $(MAKEDEV_PATCHES:%=Patches/%) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(MAKEDEV_SPEC)

$(DEPDIR)/min-$(MAKEDEV) $(DEPDIR)/std-$(MAKEDEV) $(DEPDIR)/max-$(MAKEDEV) \
$(DEPDIR)/$(MAKEDEV): \
$(DEPDIR)/%$(MAKEDEV): root/sbin/MAKEDEV $(MAKEDEV_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch --nodeps --nopost -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^)
	$(INSTALL) -m 755 root/sbin/MAKEDEV $(prefix)/$*cdkroot/sbin
	[ "x$*" = "x" ] && touch $@ || true
	@TUXBOX_YAUD_CUSTOMIZE@

#
# BASE-FILES
#
BASE_FILES := base-files
if STM22
BASE_FILES_VERSION := 2.0-4
BASE_FILES_SPEC := stm-target-$(BASE_FILES).spec
BASE_FILES_SPEC_PATCH :=
BASE_FILES_PATCHES :=
else !STM22
if STM23
BASE_FILES_VERSION := 2.0-7
BASE_FILES_SPEC := stm-target-$(BASE_FILES).spec
BASE_FILES_SPEC_PATCH :=
BASE_FILES_PATCHES :=
else !STM23
# if STM24
BASE_FILES_VERSION := 2.0-8
BASE_FILES_SPEC := stm-target-$(BASE_FILES).spec
BASE_FILES_SPEC_PATCH :=
BASE_FILES_PATCHES :=
# endif STM24
endif !STM23
endif !STM22
BASE_FILES_RPM := RPMS/sh4/$(STLINUX)-sh4-$(BASE_FILES)-$(BASE_FILES_VERSION).sh4.rpm

$(BASE_FILES_RPM): \
		$(if $(BASE_FILES_SPEC_PATCH),Patches/$(BASE_FILES_SPEC_PATCH)) \
		$(if $(BASE_FILES_PATCHES),$(BASE_FILES_PATCHES:%=Patches/%)) \
		$(archivedir)/$(STLINUX)-target-$(BASE_FILES)-$(BASE_FILES_VERSION).src.rpm
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(BASE_FILES_SPEC_PATCH),( cd SPECS && patch -p1 $(BASE_FILES_SPEC) < $(buildprefix)/Patches/$(BASE_FILES_SPEC_PATCH) ) &&) \
	$(if $(BASE_FILES_PATCHES),cp $(BASE_FILES_PATCHES:%=Patches/%) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(BASE_FILES_SPEC)

$(DEPDIR)/min-$(BASE_FILES) $(DEPDIR)/std-$(BASE_FILES) $(DEPDIR)/max-$(BASE_FILES) $(DEPDIR)/$(BASE_FILES): \
$(DEPDIR)/%$(BASE_FILES): $(BASE_FILES_ADAPTED_ETC_FILES:%=root/etc/%) \
		$(BASE_FILES_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch  -Uhv \
		--replacepkgs --badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^) && \
	( cd root/etc && for i in $(BASE_FILES_ADAPTED_ETC_FILES); do \
		[ -f $$i ] && $(INSTALL) -m644 $$i $(prefix)/$*cdkroot/etc/$$i || true; \
		[ "$${i%%/*}" = "init.d" ] && chmod 755 $(prefix)/$*cdkroot/etc/$$i || true; done ) && \
	echo "proc          /proc               proc    defaults                        0 0" >> $(prefix)/$*cdkroot/etc/fstab && \
	echo "tmpfs         /tmp                tmpfs   defaults                        0 0" >> $(prefix)/$*cdkroot/etc/fstab && \
	[ "x$*" = "x" ] && touch $@ || true
	@TUXBOX_YAUD_CUSTOMIZE@

#
# UDEV
#
UDEV := udev
if STM22
UDEV_VERSION := 054-6
UDEV_SPEC := stm-target-$(UDEV).spec
UDEV_SPEC_PATCH :=
UDEV_PATCHES :=
else !STM22
if STM23
UDEV_VERSION := 116-23
UDEV_SPEC := stm-target-$(UDEV).spec
UDEV_SPEC_PATCH :=
UDEV_PATCHES :=
else !STM23
# if STM24
UDEV_VERSION := 146-27
UDEV_SPEC := stm-target-$(UDEV).spec
UDEV_SPEC_PATCH :=
UDEV_PATCHES :=
# endif STM24
endif !STM23
endif !STM22
UDEV_RPM := RPMS/sh4/$(STLINUX)-sh4-$(UDEV)-$(UDEV_VERSION).sh4.rpm

$(UDEV_RPM): \
		$(if $(UDEV_SPEC_PATCH),Patches/$(UDEV_SPEC_PATCH)) \
		$(if $(UDEV_PATCHES),$(UDEV_PATCHES:%=Patches/%)) \
		$(archivedir)/$(STLINUX)-target-$(UDEV)-$(UDEV_VERSION).src.rpm
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(UDEV_SPEC_PATCH),( cd SPECS && patch -p1 $(UDEV_SPEC) < $(buildprefix)/Patches/$(UDEV_SPEC_PATCH) ) &&) \
	$(if $(UDEV_PATCHES),cp $(UDEV_PATCHES:%=Patches/%) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(UDEV_SPEC)

$(DEPDIR)/min-$(UDEV) $(DEPDIR)/std-$(UDEV) $(DEPDIR)/max-$(UDEV) $(DEPDIR)/$(UDEV): \
$(DEPDIR)/%$(UDEV): $(UDEV_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch --nodeps --noscripts -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^) && \
	( export HHL_CROSS_TARGET_DIR=$(prefix)/$*cdkroot && cd $(prefix)/$*cdkroot/etc/init.d && \
		for s in sysfs udev ; do \
			$(hostprefix)/bin/target-initdconfig --add $$s || \
			echo "Unable to enable initd service: $$s" ; done && rm *rpmsave 2>/dev/null || true )
	[ "x$*" = "x" ] && touch $@ || true
	@TUXBOX_YAUD_CUSTOMIZE@

#Wrote: /home/data/ufs/cvs/cdk/RPMS/sh4/stlinux20-sh4-udev-doc-054-5.sh4.rpm

#
# HOTPLUG
#
if STM22
HOTPLUG := hotplug
HOTPLUG_VERSION := 2004_09_23-4
HOTPLUG_SPEC := stm-target-$(HOTPLUG).spec
HOTPLUG_SPEC_PATCH :=
HOTPLUG_PATCHES :=
HOTPLUG_RPM := RPMS/sh4/$(STLINUX)-sh4-$(HOTPLUG)-$(HOTPLUG_VERSION).sh4.rpm

$(HOTPLUG_RPM): \
		$(if $(HOTPLUG_SPEC_PATCH),Patches/$(HOTPLUG_SPEC_PATCH)) \
		$(if $(HOTPLUG_PATCHES),$(HOTPLUG_PATCHES:%=Patches/%)) \
		$(archivedir)/$(STLINUX)-target-$(HOTPLUG)-$(HOTPLUG_VERSION).src.rpm
	rpm $(DRPM) --nosignature -Uhv $(lastword $^) && \
	$(if $(HOTPLUG_SPEC_PATCH),( cd SPECS && patch -p1 $(HOTPLUG_SPEC) < $(buildprefix)/Patches/$(HOTPLUG_SPEC_PATCH) ) &&) \
	$(if $(HOTPLUG_PATCHES),cp $(HOTPLUG_PATCHES:%=Patches/%) SOURCES/ &&) \
	export PATH=$(hostprefix)/bin:$(PATH) && \
	rpmbuild $(DRPMBUILD) -bb -v --clean --target=sh4-linux SPECS/$(HOTPLUG_SPEC)

$(DEPDIR)/min-$(HOTPLUG) $(DEPDIR)/std-$(HOTPLUG) $(DEPDIR)/max-$(HOTPLUG) $(DEPDIR)/$(HOTPLUG): \
$(DEPDIR)/%$(HOTPLUG): $(HOTPLUG_RPM)
	@rpm --dbpath $(prefix)/$*cdkroot-rpmdb $(DRPM) --ignorearch --nodeps --noscripts -Uhv \
		--badreloc --relocate $(targetprefix)=$(prefix)/$*cdkroot $(lastword $^) && \
	( export HHL_CROSS_TARGET_DIR=$(prefix)/$*cdkroot && cd $(prefix)/$*cdkroot/etc/init.d && \
		for s in hotplug ; do \
			$(hostprefix)/bin/target-initdconfig --add $$s || \
			echo "Unable to enable initd service: $$s" ; done && rm *rpmsave 2>/dev/null || true )
	[ "x$*" = "x" ] && touch $@ || true
	@TUXBOX_YAUD_CUSTOMIZE@
endif STM22
