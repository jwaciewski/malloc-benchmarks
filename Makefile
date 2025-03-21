#
# This makefile will build a small benchmarking utility for 'malloc' implementations and will
# run it with different implementations saving results into JSON files.
#
# Specifically this makefile downloads, configure and compiles 3 different software packages:
#  - GNU libc
#  - Google perftools (tcmalloc)
#  - jemalloc
#
# Tested with versions:
#  - GNU libc 2.26
#  - Google perftools (tcmalloc) 2.6.3
#  - jemalloc 5.0.1
#
#

#
# Parameters from command line
#

ifdef NTHREADS
benchmark_nthreads := $(NTHREADS)
else
# default value
benchmark_nthreads := 1 2 4 8 16
endif

ifdef CLONE_FROM_GIT
use_git := $(CLONE_FROM_GIT)
else
# default value
use_git := 1
endif

ifdef NUMPROC
parallel_flags := -j$(NUMPROC)
else
# default value
parallel_flags := -j4 
endif

ifdef POSTFIX
benchmark_postfix := $(POSTFIX)
else
# default value
benchmark_postfix := $(shell hostname)
endif

ifdef RESULT_DIRNAME
results_dir := $(RESULT_DIRNAME)
else
# default value
results_dir := results/$(shell date +%F)-$(benchmark_postfix)
endif

ifdef IMPLEMENTATIONS
implem_list := $(IMPLEMENTATIONS)
else
# default value
implem_list := glibc tcmalloc jemalloc laballoc
endif

#
# Constants
#

topdir=$(shell readlink -f .)

benchmark_result_json := results.json
benchmark_result_png := results.png

glibc_url := git://sourceware.org/git/glibc.git
tcmalloc_url := https://github.com/gperftools/gperftools.git
jemalloc_url := https://github.com/jemalloc/jemalloc.git

glibc_version := 2.26
glibc_alt_wget_url := https://ftpmirror.gnu.org/libc/glibc-$(glibc_version).tar.xz

glibc_build_dir := $(topdir)/glibc-build
glibc_install_dir := $(topdir)/glibc-install
tcmalloc_install_dir := $(topdir)/tcmalloc-install
jemalloc_install_dir := $(topdir)/jemalloc-install


#
# Functions
#

#
# Targets
#

.PHONY: all download build collect_results plot_results upload_results

all: download build collect_results plot_results

download:
	@echo "Downloading [$(implem_list)] malloc implementations"
ifeq ($(findstring glibc,$(implem_list)),glibc)
ifeq ($(use_git),1)
	@[ ! -d glibc ] && git clone $(glibc_url) || echo "glibc GIT repo seems to be already there"
else
	@[ ! -d glibc ] && ( wget $(glibc_alt_wget_url) && tar xvf glibc-$(glibc_version).tar.xz && mv glibc-$(glibc_version) glibc ) || echo "glibc GIT repo seems to be already there"
endif
endif
ifeq ($(findstring tcmalloc,$(implem_list)),tcmalloc)
	@[ ! -d gperftools ] && git clone $(tcmalloc_url) || echo "Google perftools GIT repo seems to be already there"
endif
ifeq ($(findstring jemalloc,$(implem_list)),jemalloc)
	@[ ! -d jemalloc ] && git clone $(jemalloc_url) || echo "Jemalloc GIT repo seems to be already there"
endif


#
# A couple of notes about GNU libc:
#  1) building in source dir is not supported... that's why we build in separate folder
#  2) building only benchmark utilities is not supported... that's why we build everything
#
$(glibc_install_dir)/lib/libc.so.6:
	@echo "Building GNU libc... go get a cup of coffee... this will take time!"
	mkdir -p $(glibc_build_dir)
	cd $(glibc_build_dir) && \
		../glibc/configure --prefix=$(glibc_install_dir) && \
		make $(parallel_flags) && \
		make install
	[ -x $(glibc_build_dir)/benchtests/bench-malloc-thread ] && echo "GNU libc benchmarking utility is ready!" || echo "Cannot find GNU libc benchmarking utility! Cannot collect benchmark results"

$(tcmalloc_install_dir)/lib/libtcmalloc.so:
	cd gperftools && \
		./autogen.sh && \
		./configure --prefix=$(tcmalloc_install_dir) && \
		make && \
		make install

$(jemalloc_install_dir)/lib/libjemalloc.so:
	cd jemalloc && \
		./autogen.sh && \
		./configure --prefix=$(jemalloc_install_dir) && \
		make && \
		( make install || true )
		
build:
	$(MAKE) -C benchmark-src
ifeq ($(findstring glibc,$(implem_list)),glibc)
	$(MAKE) $(glibc_install_dir)/lib/libc.so.6
endif
ifeq ($(findstring tcmalloc,$(implem_list)),tcmalloc)
	$(MAKE) $(tcmalloc_install_dir)/lib/libtcmalloc.so
endif
ifeq ($(findstring jemalloc,$(implem_list)),jemalloc)
	$(MAKE) $(jemalloc_install_dir)/lib/libjemalloc.so
endif
	@echo "Congrats! Successfully built all [$(implem_list)] malloc implementations to test."
	
collect_results:
	@echo "Collecting hardware information in $(results_dir)/hardware-inventory.txt"
	@sudo lshw -short -class memory -class processor	> $(results_dir)/hardware-inventory.txt
	@echo -n "Number of CPU cores: "					>>$(results_dir)/hardware-inventory.txt
	@grep "processor" /proc/cpuinfo | wc -l				>>$(results_dir)/hardware-inventory.txt
	@(which numactl >/dev/null 2>&1) && echo "NUMA informations:" >>$(results_dir)/hardware-inventory.txt
	@(which numactl >/dev/null 2>&1) && numactl -H >>$(results_dir)/hardware-inventory.txt
	number=2 ; while [[ $$number -le 10 ]] ; do \
		mkdir -p $(results_dir)/$$number ; \
		echo "Starting to collect performance benchmarks." ; \
		./bench_collect_results.py "$(implem_list)" $(results_dir)/$$number/$(benchmark_result_json) $(benchmark_nthreads) ; \
		((number = number + 1)) ; \
    	done

plot_results:
	#./bench_plot_results.py $(results_dir)/allaggreg.png $(results_dir)/*.json
	#./bench_plot_results.py $(results_dir)/laballocaggreg.png $(results_dir)/laballoc*.json
	./bench_plot_results.py $(results_dir)/allaggreg.png $(results_dir)/{1..10}/*.json
	./bench_plot_results.py $(results_dir)/laballocaggreg.png $(results_dir)/{1..10}/laballoc*.json
	./bench_plot_results.py $(results_dir)/commonaggreg.png $(results_dir)/{1..10}/{jemalloc*,tcmalloc*,glibc*}.json
	./bench_plot_results.py $(results_dir)/nextcommonaggreg.png $(results_dir)/{1..10}/{jemalloc*,tcmalloc*,glibc*,laballoc-next*}.json
	#./bench_plot_results.py $(results_dir)/commonaggreg.png $(results_dir)/jemalloc*.json $(results_dir)/tcmalloc*.json $(results_dir)/glibc*.json

# the following target is mostly useful only to the maintainer of the github project:
upload_results:
	git add -f $(results_dir)/*$(benchmark_result_json) $(results_dir)/*.png $(results_dir)/hardware-inventory.txt
	git commit -m "Adding results from folder $(results_dir) to the GIT repository"
	@echo "Run 'git push' to push online your results (required GIT repo write access)"

