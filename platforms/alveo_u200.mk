#######################################################################################################################################
#
#   Basic Makefile for Vitis 2019.2
#   Davide Conficconi, Emanuele Del Sozzo
#   {davide.conficconi, emanuele.delsozzo}@polimi.it
#
# 
#  See https://www.xilinx.com/html_docs/xilinx2019_2/vitis_doc/Chunk1193338764.html#wrj1504034328013
#  for more information about Vitis compiler options:) 
#######################################################################################################################################
# /******************************************
# *MIT License
# *
# # *Copyright (c) [2022] [Davide Conficconi, Eleonora D'Arnese, Emanuele Del Sozzo, Donatella Sciuto, Marco Domenico Santambrogio]
# *
# *Permission is hereby granted, free of charge, to any person obtaining a copy
# *of this software and associated documentation files (the "Software"), to deal
# *in the Software without restriction, including without limitation the rights
# *to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# *copies of the Software, and to permit persons to whom the Software is
# *furnished to do so, subject to the following conditions:
# *
# *The above copyright notice and this permission notice shall be included in all
# *copies or substantial portions of the Software.
# *
# *THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# *IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# *FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# *AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# *LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# *OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# *SOFTWARE.
# */

VPP=v++
XCC=g++
JOBS=8
CORE_LIST_NR = $(shell seq 1 ${CORE_NR})



# #################TODO##################
# #Host code
# HOST_SRC=$(SRC_DIR)/sdx/code_multithread/main.cpp
# #HOST_SRC=./main_2.cpp xcl.c
# HOST_HDRS= $(SRC_DIR)/sdx/code_multithread/core/mutual_information_hw.cpp

# HOST_CFLAGS=-D FPGA_DEVICE -g -Wall -I${XILINX_XRT}/include/ \
# 	-D C_KERNEL -O3 -Wall -I${XILINX_VITIS}/include/ --std=c++1y
# HOST_LFLAGS=-L${XILINX_XRT}/lib/ -lxilinxopencl -lpthread -lopencv_core -lopencv_highgui -lopencv_imgproc \
# 	-L$(XILINX_VITIS)/lnx64/tools/opencv
# ifndef LD_LIBRARY_PATH
# 	LD_LIBRARY_PATH=$(XILINX_VITIS)/lnx64/tools/opencv:/usr/lib/:/usr/lib64/
# else
# 	LD_LIBRARY_PATH:=$(LD_LIBRARY_PATH):$(XILINX_VITIS)/lnx64/tools/opencv:/usr/lib:/usr/lib64/
# endif
# #name of host executable
# HOST_EXE=iron
# ################ENDTODO################



REPORT_FLAG = -R0 
# -R0 -R1 -R2 

#kernel
KERNEL_SRC=$(HLS_DIR)/mutual_info.cpp
KERNEL_HDRS= $(HLS_DIR)/
KERNEL_SRC_CONFIG = $(HLS_CONFIG_DIR)/mutual_info.cpp
KERNEL_HDRS_CONFIG = $(HLS_CONFIG_DIR)/
KERNEL_FLAGS= -D USING_XILINX_VITIS
KERNEL_EXE=mutual_information_master
KERNEL_NAME=mutual_information_master

#######################################################

FULL_DEBUG=true
ifdef FULL_DEBUG
KERNEL_ADDITIONAL_FLAGS= --save-temps --log_dir $(VTS_DST_DIR)/ \
	--temp_dir $(VTS_DST_DIR)/ --report_dir $(VTS_DST_DIR) \
	--debug
endif

#######################################################

 XO_LIST = $(foreach core, $(CORE_LIST_NR), $(VTS_DST_DIR)/$(KERNEL_NAME)_$(core).xo )


#Port mapping for Vitis version up to 2019.2 and other advanced options
krnl_map_lcdlflags = --connectivity.nk $(KERNEL_NAME)_$(1):1 \
	--connectivity.sp $(KERNEL_NAME)_$(1)_1.m_axi_gmem0:DDR[$(2)] \
	--connectivity.sp $(KERNEL_NAME)_$(1)_1.m_axi_gmem1:DDR[$(2)] \
	--connectivity.sp $(KERNEL_NAME)_$(1)_1.m_axi_gmem2:DDR[$(2)]

#advanced options not used
#   --connectivity.slr $(KERNEL_NAME)_$(1)_1:SLR$(3) \
#   --hls.memory_port_data_width 256
#	--hls.max_memory_ports $(KERNEL_NAME)_$(1) \
#--advanced.prop kernel.$(KERNEL_NAME)_$(1).kernel_flags="-std=c++11"

KRNL_LDCLFLAGS_MULTI_CORE = 

XO_GEN_FLAGS = -D KERNEL_NAME=mutual_information_master_$(1)

ifeq ($(CORE_NR),1)
KRNL_LDCLFLAGS_MULTI_CORE += $(call krnl_map_lcdlflags,1,0,0)
else ifeq ($(CORE_NR), 2)
KRNL_LDCLFLAGS_MULTI_CORE += $(call krnl_map_lcdlflags,1,0,0)
KRNL_LDCLFLAGS_MULTI_CORE += $(call krnl_map_lcdlflags,2,1,1)
else ifeq ($(CORE_NR), 3)
KRNL_LDCLFLAGS_MULTI_CORE += $(call krnl_map_lcdlflags,1,0,0)
KRNL_LDCLFLAGS_MULTI_CORE += $(call krnl_map_lcdlflags,2,1,1)
KRNL_LDCLFLAGS_MULTI_CORE += $(call krnl_map_lcdlflags,3,2,1)
else ifeq ($(CORE_NR), 4)
KRNL_LDCLFLAGS_MULTI_CORE += $(call krnl_map_lcdlflags,1,0,0)
KRNL_LDCLFLAGS_MULTI_CORE += $(call krnl_map_lcdlflags,2,1,1)
KRNL_LDCLFLAGS_MULTI_CORE += $(call krnl_map_lcdlflags,3,2,1)
KRNL_LDCLFLAGS_MULTI_CORE += $(call krnl_map_lcdlflags,4,3,2)
endif

#######################################################
#Optimization levels: 0 1 2 3 s quick
# 0: Default optimization. Reduces compilation time and makes debugging produce the expected results.
# 1: Optimizes to reduce power consumption. This takes more time to build the design.
# 2: Optimizes to increase kernel speed. This option increases build time, but also improves the performance of the generated kernel.
# 3: This optimization provides the highest level performance in the generated code, but compilation time can increase considerably.
# s: Optimizes for size. This reduces the logic resources of the device used by the kernel.
# quick: Reduces Vivado implementation time, but can reduce kernel performance, and increases the resources used by the kernel
OPT_LVL=
ifdef OPT_LVL
    KERNEL_ADDITIONAL_FLAGS += --optimize $(OPT_LVL)
endif

#--kernel_frequency <clockID>:<freq>|<clockID>:<freq>
ifdef CLK_FRQ
    ifdef KRNL_FRQ
KERNEL_LDCLFLAGS += --kernel_frequency "0:$(CLK_FRQ)|1:$(KRNL_FRQ)" #--optimize 3 
    else
KERNEL_LDCLFLAGS += --kernel_frequency "0:$(CLK_FRQ)" #|1:350"
KRNL_LDCLFLAGS_MULTI_CORE += --kernel_frequency "0:$(CLK_FRQ)"
    endif
else
    ifdef KRNL_FRQ
KERNEL_LDCLFLAGS+= --kernel_frequency "1:$(KRNL_FRQ)" #--optimize 3 
    else
        #KERNEL_LDCLFLAGS+= --k ernel_frequency "200"
    endif

endif

#######################################################
#
TARGET_DEVICE=xilinx_u200_xdma_201830_2
# TARGET DSA # 
#######################################################

#TARGET for compilation [sw_emu | hw_emu | hw]
TARGET=hw
REPORT_FLAG=n
REPORT=
ifeq (${TARGET}, sw_emu)
$(info software emulation)
TARGET=sw_emu
ifeq (${REPORT_FLAG}, y)
$(info creating REPORT for software emulation set to true. This is going to take longer at it will synthesize the kernel)
REPORT=-Restimate
else
$(info I am not creating a REPORT for software emulation, set REPORT_FLAG=y if you want it)
REPORT=
endif
else ifeq (${TARGET}, hw_emu)
$(info hardware emulation)
TARGET=hw_emu
REPORT= 
else ifeq (${TARGET}, hw)
$(info system build)
TARGET=hw
REPORT=
else
$(info no TARGET selected)
endif

#######################################################

PERIOD:= :
UNDERSCORE:= _
VTS_DST_DIR=$(VTS_BUILD_DIR)/$(TARGET)/$(subst $(PERIOD),$(UNDERSCORE),$(TARGET_DEVICE))

#######################################################

ifndef XILINX_VITIS
$(error XILINX_VITIS is not set. Please source the Vitis settings64.{csh,sh} first)
endif

ifndef XILINX_XRT
$(error XILINX_XRT is not set. Please source the XRT /opt/xilinx/xrt/setup.sh first)
endif

check_TARGET: curr_status
ifeq (${TARGET}, none)
    $(error Target can not be set to none)
endif

xo: check_TARGET
	mkdir -p $(VTS_DST_DIR)
	$(VPP) --platform $(TARGET_DEVICE) -t $(TARGET) \
	--jobs $(JOBS) --compile --include $(KERNEL_HDRS) $(REPORT) \
	--kernel $(KERNEL_NAME) $(KERNEL_FLAGS) \
	$(KERNEL_ADDITIONAL_FLAGS) -o '$(VTS_DST_DIR)/$(KERNEL_EXE).xo' \
	$(KERNEL_SRC)

xclbin:  check_TARGET xo
	$(VPP) --platform $(TARGET_DEVICE) -t $(TARGET) \
	--link --jobs $(JOBS) --include $(KERNEL_HDRS) $(REPORT) \
	 --kernel $(KERNEL_NAME) $(VTS_DST_DIR)/$(KERNEL_EXE).xo $(KERNEL_LDCLFLAGS) \
	$(KERNEL_FLAGS) $(KERNEL_ADDITIONAL_FLAGS) \
	-o '$(VTS_DST_DIR)/$(KERNEL_EXE).xclbin'

generate_vts_config: gen_hls_config_vts $(XO_LIST)
	for n in $(CORE_LIST_NR); do \
	make xo_config_$$n; \
	done; \

xo_config_%: check_TARGET 
	mkdir -p $(VTS_DST_DIR)
	$(VPP) --platform $(TARGET_DEVICE) -t $(TARGET) \
	--jobs $(JOBS) -c --include $(KERNEL_HDRS_CONFIG) \
	-k $(KERNEL_NAME)_$* $(call XO_GEN_FLAGS,$*) \
	$(KERNEL_ADDITIONAL_FLAGS) -o '$(VTS_DST_DIR)/$(KERNEL_EXE)_$*.xo' \
	$(KERNEL_SRC_CONFIG)

hw_gen: xclbin_config
	mkdir -p $(DEPLOY_DIR)
	cp $(VTS_DST_DIR)/$(KERNEL_EXE).xclbin $(DEPLOY_DIR)/
	
xclbin_config: check_TARGET generate_vts_config
	$(VPP) --platform $(TARGET_DEVICE) -t $(TARGET) \
	--link --jobs $(JOBS) $(REPORT) \
	 $(XO_LIST) $(KRNL_LDCLFLAGS_MULTI_CORE) \
	$(KERNEL_ADDITIONAL_FLAGS) \
	-o '$(VTS_DST_DIR)/$(KERNEL_EXE).xclbin'

xclbin_only: check_TARGET
	$(VPP) --platform $(TARGET_DEVICE) -t $(TARGET) \
	--link --jobs $(JOBS) $(REPORT) \
	$(XO_LIST) $(KRNL_LDCLFLAGS_MULTI_CORE) \
	$(KERNEL_ADDITIONAL_FLAGS) \
	-o '$(VTS_DST_DIR)/$(KERNEL_EXE).xclbin'


$(XO_LIST):

test_config_%:
	@echo ""
	@echo "[INFO] printg some mapping functions"
	@echo $(KRNL_LDCLFLAGS_MULTI_CORE)
	@echo $(call XO_GEN_FLAGS,$*)
	@echo ""


#python
sw:
	rm -rf $(DPLY_PY)
	mkdir -p $(DPLY_PY)
	cp $(PY_DIR)/$(PY_MI) $(DPLY_PY)/ 


#########################
#brd part
#xcu200-fsgd2104-2-e'


curr_status:
	@echo ""
	@echo "*****************************************************************"
	@echo "                      Alveo u200 make status                     "
	@echo "*****************************************************************"
	@echo ""
	@echo " [Help] curently using $(VPP), $(XCC), jobs=$(JOBS)"
	@echo " [Help] Target platform/xsa/dsa= $(TARGET_DEVICE)" 
	@echo " Remember to change it accordingly to the proper version"
	@echo ""
	@echo " [Help] Target for build=$(TARGET)" 
	@echo " possible targets = sw_emu, hw_emu, hw"
	@echo ""
	@echo ""
	@echo " [Help] Working with $(CORE_NR) core(s)"
	@echo ""
	@echo "*****************************************************************"
	@echo "               END of Alveo u200 make status                     "
	@echo "*****************************************************************"
	@echo ""
	
prepdeploy:
	@echo "[INFO] placeholder REMEMBER!!!!"
########################
helplat: curr_status 
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "                      Alveo u200 Specific helper                     "
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo " [INFO] 'make xo' generate the xo for the fixed code"
	@echo " [INFO] 'make xclbin' generate the xclbin for the fixed code"
	@echo ""
	@echo ""
	@echo " [INFO] 'make generate_vts_config' generate the xo for the target core number"
	@echo ""
	@echo ""
	@echo " [INFO] 'make xclbin_config' generate the xclbin using config genrated xo files"
	@echo ""
	@echo ""
	@echo " [INFO] 'make xclbin_only' create the xclbin only withou regenerating the xo, either config or not"
	@echo ""
	@echo ""
	@echo " [INFO] 'make test_config_%' testing make recipe"
	@echo ""
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "               END of Alveo u200 Specific helper                     "
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@make helpparam_alveo
########################

helpparam_alveo: 
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo " [Help] Follow some Makefile Parameter"
	@echo ""
	@echo " [Help] change REPORT_FLAG=<R0|R1|R2> to report detail levels"
	@echo ""
	@echo " [Help] change OPT_LVL=<0|1|2|3|s|quick> to optimization levels"
	@echo ""
	@echo " [Help] change CLK_FRQ=<target_mhz> to ClockID 0 (board) target frequency"
	@echo ""
	@echo " [Help] change KRNL_FRQ=<target_mhz> to ClockID 1 (kernel) target frequency"
	@echo ""
	@echo "*****************************************************************"


cleanvts:
	rm -rf .Xil emconfig.json 

clean_sw_emu: clean
	rm -rf sw_emu
clean_hw_emu: clean
	rm -rf hw_emu
clean_hw: clean
	rm -rf hw

cleanallvts: clean_sw_emu clean_hw_emu clean_hw
	rm -rf _sdx_* xcl_design_wrapper_* _* sdx_*
