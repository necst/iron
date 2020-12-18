#/******************************************
#*MIT License
#*
#*Copyright (c) [2020] [Davide Conficconi, Eleonora D'Arnese, Emanuele Del Sozzo, Donatella Sciuto, Marco Domenico Santambrogio]
#*
#*Permission is hereby granted, free of charge, to any person obtaining a copy
#*of this software and associated documentation files (the "Software"), to deal
#*in the Software without restriction, including without limitation the rights
#*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#*copies of the Software, and to permit persons to whom the Software is
#*furnished to do so, subject to the following conditions:
#*
#*The above copyright notice and this permission notice shall be included in all
#*copies or substantial portions of the Software.
#*
#*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#*FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#*AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#*LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#*OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#*SOFTWARE.
#*/
#/***************************************************************
#*
#* Makefile
#*
#****************************************************************/

##############################################################
#directory stuffs
SHELL = /bin/bash
TOP := $(shell pwd)
MAIN_PRJ=iron

PYTHON=python3.6

#Configuration stuffs
D=512
IB=8
HT=float
PE=2

PE_ENTROP=1
CACHING=false
URAM=false

CORE_NR = 1

##############################################################
BV=0
ACC_SIZES=16

GEN_CONFIG_DESIGN_OPTS= -ht ${HT} -pe ${PE} -ib ${IB} -id ${D} -bv ${BV} -es ${ACC_SIZES} -pen ${PE_ENTROP}
CONF_CACHING=false
CONF_URAM=false
ifeq "$(CACHING)" "true"
	GEN_CONFIG_DESIGN_OPTS += -mem
	CONF_CACHING=true
endif

ifeq "$(URAM)" "true"
	GEN_CONFIG_DESIGN_OPTS += -uram
	CONF_URAM=true
endif


CURR_CONFIG ?= ${CORE_NR}-${D}-${IB}-${HT}-${PE}-${PE_ENTROP}-${CONF_CACHING}-${CONF_URAM}
##############################################################

##############################################################
#Target boards 

TRGT_PLATFORM ?= ultra96_v2

SUPPORTED_ZYNQ=("pynqz2" "ultra96_v2" "zcu104")
SUPPORTED_ALVEO=("alveo_u200")

##############################################################

##############################################################
#Directories stuff 
SRC_DIR:=$(TOP)/src
BUILD_DIR=$(TOP)/build
BUILD_PLAT_DIR ?= ${BUILD_DIR}/${TRGT_PLATFORM}
CURR_BUILD_DIR=$(BUILD_PLAT_DIR)/$(CURR_CONFIG)
HLS_CONFIG_DIR ?= $(CURR_BUILD_DIR)/src/hls
SDX_BUILD_DIR ?= $(CURR_BUILD_DIR)
VTS_BUILD_DIR ?= $(CURR_BUILD_DIR)


HLS_DIR=$(SRC_DIR)/hls
HLS_DIR_SDX=$(HLS_DIR)
HLS_TB_DIR=$(HLS_DIR)/testbench

SCRIPT_DIR=$(SRC_DIR)/scripts
DRVR_DIR=$(SRC_DIR)/driver
DEPLOY_DIR=$(CURR_BUILD_DIR)/deploy

#############################################################

#HLS stuffs

HLS_INCL ?= $(XILINX_VIVADO)/include   

VIVADO_VERSION = $(shell vivado -version | grep Vivado)
VIVADO_SCRIPT_DIR ?= $(SCRIPT_DIR)/$(TRGT_PLATFORM)/

#######################################################

HLS_CONF_LOGGER = hls_verification.csv
 
#######################################################

LD_LIBRARY_PATH:=$(LD_LIBRARY_PATH):/usr/local/lib64

MI_GENERATOR=generator.py
#######################################################
#hls stuffs
hls_code := $(wildcard $(HLS_DIR)/*.cpp)
hls_code += $(wildcard $(HLS_DIR)/*.hpp)
hls_code += $(wildcard $(HLS_DIR)/*.h)

hls_header := $(wildcard $(HLS_DIR)/*.hpp)
hls_header += $(wildcard $(HLS_DIR)/*.h)

hls_tb_code += $(wildcard $(HLS_TB_DIR)/*.cpp)
hls_tb_code += $(wildcard $(HLS_DIR)/*_testbench.cpp)


HLS_CLK=10
HLS_TB_NAME=hls_mi_testbench
HLS_TB?=$(HLS_TB_DIR)/$(HLS_TB_NAME).cpp
################
hls_curr_tb = $(HLS_TB_DIR)/hls_mi_testbench.cpp

hls_code_filtered := $(filter-out $(hls_tb_code), $(hls_code))
#######################################################
#variables for SDX gen
hls_vts_code := $(wildcard $(HLS_DIR_SDX)/*.hpp)
hls_vts_code += $(wildcard $(HLS_DIR_SDX)/*.h)
hls_vts_code += $(wildcard $(HLS_DIR_SDX)/mutual_info.cpp)
#######################################################
#variables for hls gen
hls_gen_code := $(wildcard $(HLS_CONFIG_DIR)/*.cpp)
hls_gen_code += $(wildcard $(HLS_CONFIG_DIR)/*.hpp)
hls_gen_code += $(wildcard $(HLS_CONFIG_DIR)/*.h)
hls_tb_code_gen := $(wildcard $(HLS_CONFIG_DIR)/${HLS_TB_NAME}.cpp)
HLS_GEN_CODE_RUN_WITH_TB := $(shell echo $(HLS_CONFIG_DIR)/*pp )
HLS_GEN_CODE_RUN_WITH_TB +=  $(shell echo $(HLS_CONFIG_DIR)/*.h )
HLS_GEN_CODE_RUN := $(filter-out $(hls_tb_code_gen), $(HLS_GEN_CODE_RUN_WITH_TB))
#######################################################
PRJ_NAME?=iron-hls

TOP_LVL_FN=mutual_information_master

HLS_OPTS ?= 5 
# 0 for only project build; 1 for sim only; 2 synth; 3 cosim; 4 synth and ip downto impl; 5 synth and ip; 6 for ip export
#######################################################
#vivado stuffs
IP_REPO ?= $(CURR_BUILD_DIR)/$(PRJ_NAME)/solution1/impl/ip
VIVADO_MODE ?= batch # or gui
FREQ_MHZ ?= 150

KERNEL = iron
#######################################################
#deploying parameters
BRD_IP?=192.168.3.1
BRD_DIR?=/home/xilinx/iron/
BRD_USR?=xilinx
#######################################################
DPLY_PY ?= $(BUILD_DIR)/sw_py
PY_DIR := $(SRC_DIR)/python
PY_MI ?= test-single-mi.py
######################################################
.PHONY:help test_recipes test_recipes print_config gen_hls_config gen_hls_config_vts

help:
	@echo "*****************************************************************"
	@echo "*****************************************************************"
	@echo "*****************************************************************"
	@echo "                      Makefile helper                       "
	@echo "*****************************************************************"
	@echo "*****************************************************************"
	@echo "*****************************************************************"
	@echo ""
	@echo " [HELP] 'make' shows this helper"
	@echo ""
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo " [HELP] 'make helpall' to print all helpers"
	@echo " [HELP] 'make helptargets' to print target boards helper"
	@echo " [HELP] 'make helplat' to print specific platform helpers"
	@echo " [HELP] 'make helparam' to print  some make parameters"
	@echo " [HELP] 'make helpmakeinfo' to print  some make utilities"
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo "                     Clean utilities                             "
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo "[INFO] 'make cleanhls' cleans hls project "
	@echo "[INFO] 'make cleanvivado' cleans vivado project, only for Zynq"
	@echo "[INFO] 'make cleanall' cleans everything in the build folder"
	@echo "[INFO] 'make cleanplat' cleans everything in the plat folder"
	@echo ""
	@echo ""
	@echo "*****************************************************************"
	@echo "*****************************************************************"
	@echo "*****************************************************************"
	@echo ""
	@echo "              End of general makefile helper                "
	@echo ""
	@echo "*****************************************************************"
	@echo "*****************************************************************"
	@echo "*****************************************************************"


helpall:
	@make help
	@make helplat
	@make helpmakeinfo
	@make helparam
	@make helptargets


#######################################################
# platform-specific Makefile include for bitfile synthesis
include platforms/$(TRGT_PLATFORM).mk


################################################################
# HLS config stuffs
################################################################

print_config:
	@echo $(CURR_CONFIG)

gen_hls_config:
	mkdir -p $(HLS_CONFIG_DIR)
	cp $(hls_code_filtered) $(HLS_CONFIG_DIR)
	cp $(hls_curr_tb) $(HLS_CONFIG_DIR)
	rm -f $(HLS_CONFIG_DIR)/*_testbench.cpp
	$(PYTHON) $(SCRIPT_DIR)/$(MI_GENERATOR) -c -op $(HLS_CONFIG_DIR)/ $(GEN_CONFIG_DESIGN_OPTS)


gen_hls_config_vts:
	mkdir -p $(HLS_CONFIG_DIR)
	cp $(hls_curr_tb) $(HLS_CONFIG_DIR)
	cp $(hls_vts_code) $(HLS_CONFIG_DIR)/
	rm -f $(HLS_CONFIG_DIR)/*_testbench.cpp
	$(PYTHON) $(SCRIPT_DIR)/$(MI_GENERATOR) -c -op $(HLS_CONFIG_DIR)/ $(GEN_CONFIG_DESIGN_OPTS) -vts

all: | sw hls hw

all_gen: | sw hw_gen

resyn_extr_zynq_%:
	$(SCRIPT_DIR)/extract_all_synt_res.sh $* false true ${FREQ_MHZ}

resyn_extr_vts_%:
	$(SCRIPT_DIR)/extract_all_synt_res.sh $* true true ${FREQ_MHZ}


deploy: deploypy
	rsync -avz $(DEPLOY_DIR) $(BRD_USR)@$(BRD_IP):$(BRD_DIR)

deploypy: sw
	rsync -avz $(DPLY_PY) $(BRD_USR)@$(BRD_IP):$(BRD_DIR)

curr_config: print_config
	@echo $(GEN_CONFIG_DESIGN_OPTS)

## clean facilities 
cleanconfig:
	rm -rf $(CURR_BUILD_DIR)

cleanvivado:
	rm -rf $(PRJDIR)

cleanhls:
	rm -rf $(CURR_BUILD_DIR)/$(PRJ_NAME)

clean: cleanhls cleanvivado
	rm -f $(CURR_BUILD_DIR)/*.log $(CURR_BUILD_DIR)/*.jou

cleanall:
	rm -rf $(BUILD_DIR)/*

cleanplat:
	rm -rf $(BUILD_PLAT_DIR)/*


helparam:
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "                 Makefile parameters  helpers               "
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo " [INFO] using shell=$(SHELL), top directory=$(TOP)"
	@echo " [INFO] py version=$(PYTHON)"
	@echo ""
	@echo ""
	@echo " [PARAM] Image dimension (D) = $(D)"
	@echo " [PARAM] Image bit size (IB) = $(IB)"
	@echo " [PARAM] Computation type (HT) = $(HT)"
	@echo " [PARAM] Histogram PE (PE) = $(PE)"
	@echo " [PARAM] Entropy PE (PE_ENTROP) = $(PE_ENTROP)"
	@echo " [PARAM] Use caching (CACHING) = $(CACHING)"
	@echo " [PARAM] Use URAM caching (URAM) = $(URAM)"
	@echo " [PARAM] Core Number (CORE_NR) = $(CORE_NR)"
	@echo ""
	@echo ""
	@echo " [Help] Change those values for accelerator generation"
	@echo ""
	@echo ""
	@echo " [PARAM] HLS_CLK=$(HLS_CLK) clock period for hls"
	@echo " [PARAM] FREQ_MHZ=$(FREQ_MHZ) clock frequency for vivado bitstream"
	@echo ""
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "               END of Makefile parameters helper                     "
	@echo ""
	@echo "*****************************************************************"
	@echo ""


helptargets:
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "                 Target platforms helper               "
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo " [HELP] Currently using Vivado version $(VIVADO_VERSION)"
	@echo ""
	@echo " [HELP] Supported Zynq boards: $(SUPPORTED_ZYNQ)"
	@echo ""
	@echo " [HELP] Supported Alveo boards: $(SUPPORTED_ALVEO)"
	@echo ""
	@echo " [HELP] add TRGT_PLATFORM=<one_of_the_previous_platform> to a command"
	@echo " [HELP] For example 'make TRGT_PLATFORM=zcu104'"
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "               END of Target platforms helper                   "
	@echo ""
	@echo "*****************************************************************"
	@echo ""

helpmakeinfo:
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "                 Make info helper               "
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo " [INFO] build an accelerator"
	@echo " 'make hw_gen TRGT_PLATFORM=< a target platform>' "
	@echo ""
	@echo " [INFO] extract specific board results"
	@echo " 'make resyn_extr_zynq_%' or 'make resyn_extr_vts_%'"
	@echo " subsitutite the % with a target platform"
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo " [INFO] 'make all_gen' prepare everything, sw and hw"
	@echo ""
	@echo "[INFO] 'make gen_hls_config'  generate the HLS configuration source files"
	@echo "[INFO] 'make gen_hls_config_vts'  generate Vitis configuration source files"
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo " [INFO] 'make deploy' copy the deployable to the target dir"
	@echo ""	
	@echo " default configuration: micro-usb addr 'BRD_IP?=192.168.3.1'"
	@echo " default target directory on the board 'BRD_DIR?=/home/xilinx/iron/'"
	@echo " default target user on the board 'BRD_USR?=xilinx'"
	@echo ""	
	@echo " [HELP] 'make print_config'  print iron current config generation"
	@echo ""
	@echo " [HELP] 'make curr_config'  print iron config generation parameters"
	@echo ""	
	@echo "*****************************************************************"
	@echo "" 
	@echo "               END of Target platforms helpers                   "
	@echo ""
	@echo "*****************************************************************"
	@echo ""
