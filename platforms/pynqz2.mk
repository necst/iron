# /******************************************
# *MIT License
# *
# # *Copyright (c) [2020] [Davide Conficconi, Eleonora D'Arnese, Emanuele Del Sozzo, Donatella Sciuto, Marco Domenico Santambrogio]
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
VIVADO_PRJNAME = ${KERNEL}-vivado
PRJDIR = $(CURR_BUILD_DIR)/$(VIVADO_PRJNAME)
BITSTREAM = $(PRJDIR)/$(VIVADO_PRJNAME).runs/impl_1/${KERNEL}_wrapper.bit
VVD_SCRIPT = $(VIVADO_SCRIPT_DIR)/create_vivado_project.tcl
VVD_SYNTH_SCRIPT = $(VIVADO_SCRIPT_DIR)/synth_vivado_project.tcl
BRD_PARTS= "xc7z020clg400-1"

.PHONY: hls hls_config hw_gen hw gen_vivado_prj bitfile launch_vivado_gui sw helplat
hls: $(hls_code) $(hls_tb_code) $(SCRIPT_DIR)/hls.tcl
	mkdir -p $(CURR_BUILD_DIR)
	cd $(CURR_BUILD_DIR); vivado_hls -f $(SCRIPT_DIR)/hls.tcl -tclargs $(PRJ_NAME) "$(hls_code)" $(HLS_TB) $(BRD_PARTS) $(HLS_CLK) $(TOP_LVL_FN) $(HLS_DIR)/ $(HLS_OPTS) $(HLS_INCL); cd ../

hls_config: gen_hls_config
	mkdir -p $(CURR_BUILD_DIR)
	$(eval HLS_GEN_CODE_RUN_WITH_TB := $(shell echo $(HLS_CONFIG_DIR)/*pp ))
	$(eval HLS_GEN_CODE_RUN_WITH_TB +=  $(shell echo $(HLS_CONFIG_DIR)/*.h ))
	$(eval HLS_GEN_CODE_RUN := $(filter-out $(hls_tb_code_gen), $(HLS_GEN_CODE_RUN_WITH_TB)))
	cd $(CURR_BUILD_DIR); vivado_hls -f $(SCRIPT_DIR)/hls.tcl -tclargs $(PRJ_NAME) "$(HLS_GEN_CODE_RUN)" $(hls_curr_tb) $(BRD_PARTS) $(HLS_CLK) $(TOP_LVL_FN) $(HLS_CONFIG_DIR)/ $(HLS_OPTS) $(HLS_INCL); cd ../

gen_hls_prj:
	mkdir -p $(CURR_BUILD_DIR)
	cd $(CURR_BUILD_DIR); vivado_hls -f $(SCRIPT_DIR)/hls.tcl -tclargs $(PRJ_NAME) "$(hls_code)" $(HLS_TB) $(BRD_PARTS) $(HLS_CLK) $(TOP_LVL_FN) $(HLS_DIR)/ 0; cd ../

hw_gen: hls_config hw

hw: $(BITSTREAM)
	mkdir -p $(DEPLOY_DIR)
	cp $(BITSTREAM) $(DEPLOY_DIR)/${KERNEL}_wrapper.bit; cp $(PRJDIR)/${KERNEL}_wrapper.tcl $(DEPLOY_DIR);\
	cp $(PRJDIR)/$(VIVADO_PRJNAME).srcs/sources_1/bd/$(KERNEL)/hw_handoff/$(KERNEL).hwh $(DEPLOY_DIR)/$(KERNEL)_wrapper.hwh 
hw_pre:
	mkdir -p $(DEPLOY_DIR)
	cp $(BITSTREAM) $(DEPLOY_DIR)/${KERNEL}_wrapper.bit; cp $(PRJDIR)/${KERNEL}_wrapper.tcl $(DEPLOY_DIR);\
	cp $(PRJDIR)/$(VIVADO_PRJNAME).srcs/sources_1/bd/$(KERNEL)/hw_handoff/$(KERNEL).hwh $(DEPLOY_DIR)/$(KERNEL)_wrapper.hwh 

# hw en
 $(PRJDIR)/$(VIVADO_PRJNAME).xpr: $(IP_REPO)
	vivado -mode $(VIVADO_MODE) -source $(VVD_SCRIPT) -tclargs $(TOP) $(VIVADO_PRJNAME) $(PRJDIR) $(IP_REPO) $(FREQ_MHZ) $(CORE_NR)

gen_vivado_prj: $(IP_REPO)
	vivado -mode $(VIVADO_MODE) -source $(VVD_SCRIPT) -tclargs $(TOP) $(VIVADO_PRJNAME) $(PRJDIR) $(IP_REPO) $(FREQ_MHZ) $(CORE_NR)

bitfile:
	vivado -mode $(VIVADO_MODE) -source $(VVD_SYNTH_SCRIPT) -tclargs $(PRJDIR)/$(VIVADO_PRJNAME).xpr $(PRJDIR) $(VIVADO_PRJNAME) ${KERNEL}_wrapper

$(BITSTREAM): $(PRJDIR)/$(VIVADO_PRJNAME).xpr
	vivado -mode $(VIVADO_MODE) -source $(VVD_SYNTH_SCRIPT) -tclargs $(PRJDIR)/$(VIVADO_PRJNAME).xpr $(PRJDIR) $(VIVADO_PRJNAME) ${KERNEL}_wrapper

# launch Vivado in GUI mode with created project
launch_vivado_gui: $(PRJDIR)/$(VIVADO_PRJNAME).xpr
	vivado -mode gui $(PRJDIR)/$(VIVADO_PRJNAME).xpr


#python
sw:
	rm -rf $(DPLY_PY)
	mkdir -p $(DPLY_PY)
	cp $(PY_DIR)/$(PY_MI) $(DPLY_PY)/ 

prepdeploy:
	@echo "[INFO] placeholder REMEMBER!!!!"
########################
helplat: 
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "                      PynqZ2 Specific helper                     "
	@echo ""
	@echo "*****************************************************************"
	@echo ""
	@echo " [INFO] 'make hls TOP_LVL_FN=<top_function> ' builds hls project,"
	@echo "  HLS_OPTS= 1-sim pre, 2-synth, 3-cosim, 4-ip, 5-synth & ip"
	@echo "  HLS_OPTS= 6-export ip, P&R, 7-sim & synth  & cosim "
	@echo " [INFO] 'make hls_config' the same as hls but with configuration generation"
	@echo " [INFO] 'make gen_hls_prj' generate hls project"
	@echo ""
	@echo ""
	@echo " [INFO] 'make hw' create the bitstream, and copy it to be deployed"
	@echo " [INFO] 'make hw_gen' as before but from hls_config"
	@echo " [INFO] 'make bitfile' create the bitstream after project creation"
	@echo " [INFO] 'make gen_vivado_prj' creation of the vivado project with all the sources"
	@echo " [INFO] 'make launch_vivado_gui ' launch vivado in gui mode after creating the project"
	@echo ""
	@echo " [INFO] 'make sw' copy all the necessary stuffs on sw deployment side"
	@echo ""
	@echo ""
	@echo "*****************************************************************"
	@echo "" 
	@echo "               END of PynqZ2 Specific helper                     "
	@echo ""
	@echo "*****************************************************************"
########################