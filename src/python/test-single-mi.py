#!/usr/bin/env python
#ATTENTION IF PYTHON OR PYTHON 3
# coding: utf-8

# /******************************************
# *MIT License
# *
# *Copyright (c) [2022] [Davide Conficconi, Eleonora D'Arnese, Emanuele Del Sozzo, Donatella Sciuto, Marco Domenico Santambrogio]
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
# ******************************************/

import os
import cv2
import numpy as np
import math
import glob
import time
import pandas as pd
import multiprocessing
from pynq import Overlay
import pynq
from pynq import allocate
import struct
import statistics
import argparse


# function for specific multicore mapping on different platforms, memory banks and namings
def mi_accel_map(iron_pl, platform, caching, num_threads=1, i_ref_sz=512, config=None):
    mi_list = []
    if(caching):
        ref_size=i_ref_sz
        ref_dt="uint8"
        flt_size=1
        flt_dt=np.float32
        mi_size=1
        mi_dt="u4"
    else:
        ref_size=i_ref_sz
        ref_dt="uint8"
        flt_size=i_ref_sz
        flt_dt="uint8"
        mi_size=1
        mi_dt=np.float32

    if(num_threads>=1):
        if platform == 'Alveo':#pcie card based
            mi_acc_0=SingleAccelMI(iron_pl.mutual_information_master_1_1, platform, iron_pl.bank0,\
                caching, ref_size, ref_dt, flt_size, flt_dt, mi_size, mi_dt)
        else: #ZYNQ based
            mi_acc_0=SingleAccelMI(iron_pl.mutual_information_m_0, platform, None,\
                caching, ref_size, ref_dt, flt_size, flt_dt, mi_size, mi_dt, config)
        mi_list.append(mi_acc_0)
    if (num_threads >= 2):
        if platform == 'Alveo':#pcie card based
            mi_acc_1=SingleAccelMI(iron_pl.mutual_information_master_2_1,platform, iron_pl.bank1,\
                caching, ref_size, ref_dt, flt_size, flt_dt, mi_size, mi_dt)
        else: #ZYNQ based
            mi_acc_1=SingleAccelMI(iron_pl.mutual_information_m_1,platform,None,\
                caching, ref_size, ref_dt, flt_size, flt_dt, mi_size, mi_dt,config)
        mi_list.append(mi_acc_1)
    if(num_threads >= 3):
        if platform == 'Alveo':#pcie card based
            mi_acc_2=SingleAccelMI(iron_pl.mutual_information_master_3_1,platform, iron_pl.bank2,\
                caching, ref_size, ref_dt, flt_size, flt_dt, mi_size, mi_dt)
        else: #ZYNQ based
            mi_acc_2=SingleAccelMI(iron_pl.mutual_information_m_2,platform,None,\
                caching, ref_size, ref_dt, flt_size, flt_dt, mi_size, mi_dt, config)
        mi_list.append(mi_acc_2)
    if(num_threads >= 4):
        if platform == 'Alveo':#pcie card based
            mi_acc_3=SingleAccelMI(iron_pl.mutual_information_master_4_1,platform, iron_pl.bank3,\
                caching, ref_size, ref_dt, flt_size, flt_dt, mi_size, mi_dt)
        else: #ZYNQ based
            mi_acc_3=SingleAccelMI(iron_pl.mutual_information_m_3,platform,None,\
                caching, ref_size, ref_dt, flt_size, flt_dt, mi_size, mi_dt, config)
        mi_list.append(mi_acc_3)
    return mi_list




import pynq
from pynq import allocate
class SingleAccelMI :
    
    
###########################################################
# DEFAULTS of the INIT
###########################################################
#
# platform='Alveo'
#caching=False
#ref_size=512
# ref_dt="uint8"
# flt_size=512, then to the power of 2
#flt_dt="uint8"
# mi_size=1 then to the power of 2
# mi_dt=np.float32
#
###########################################################

    def __init__(self, accel_id,  platform='Alveo', mem_bank=None, caching=False, ref_size=512, ref_dt="uint8", flt_size=512, flt_dt="uint8", mi_size=1, mi_dt=np.float32, config=None):
            self.AP_CTRL = 0x00
            self.done_rdy = 0x6
            self.ap_start = 0x1
            self.REF_ADDR = 0x10
            self.FLT_ADDR_OR_MI = 0x18
            self.MI_ADDR_OR_FUNCT = 0x20
            self.STATUS_ADDR =0x28
            
            self.LOAD_IMG = 0
            self.COMPUTE = 1
            self.buff1_img = allocate(ref_size*ref_size, ref_dt, target=mem_bank)
            self.buff2_img_mi = allocate(flt_size*flt_size, flt_dt, target=mem_bank)
            self.buff3_mi_status = allocate(mi_size, mi_dt, target=mem_bank)

            self.buff1_img_addr = self.buff1_img.device_address
            self.buff2_img_mi_addr = self.buff2_img_mi.device_address
            self.buff3_mi_status_addr = self.buff3_mi_status.device_address
            
            self.accel = accel_id
            
            self.platform = platform
            self.caching = caching
            self.config = config
            # print(self.accel)
            # print(self.platform)
            # print(self.caching)

    def get_config(self):
        return self.config

    def init_accel(self, Ref_uint8, Flt_uint8):
        self.prepare_ref_buff(Ref_uint8)
        if not self.caching:
            self.prepare_flt_buff(Flt_uint8)
    
    def load_caching(self):
        if self.platform == 'Alveo':
            self.accel.call(self.buff1_img, self.buff2_img_mi, self.LOAD_IMG, self.buff3_mi_status) 
        else: #ZYNQ-based
            self.execute_zynq(self.LOAD_IMG)
    
    def read_status(self):
        return self.accel.mmio.read(self.STATUS_ADDR)

    def prepare_ref_buff(self, Ref_uint8):
        self.buff1_img[:] = Ref_uint8.flatten()
        self.buff1_img.flush()#sync_to_device
        if not self.caching:
            return
        else:
            if self.platform != 'Alveo':
                self.accel.write(self.STATUS_ADDR, self.buff3_mi_status_addr)
            self.load_caching()
            self.buff2_img_mi.invalidate()#sync_from_device
            self.buff3_mi_status.invalidate()#sync_from_device

    
    def prepare_flt_buff(self, Flt_uint8):
        if not self.caching:
            self.buff2_img_mi[:] = Flt_uint8.flatten()
            self.buff2_img_mi.flush() #sync_to_device
        else:
            self.buff1_img[:] = Flt_uint8.flatten()
            self.buff1_img.flush()#sync_to_device

    def execute_zynq(self, mi_addr_or_funct):
        self.accel.write(self.REF_ADDR, self.buff1_img.device_address)
        self.accel.write(self.FLT_ADDR_OR_MI, self.buff2_img_mi.device_address)
        self.accel.write(self.MI_ADDR_OR_FUNCT, mi_addr_or_funct)
        self.accel.write(self.AP_CTRL, self.ap_start)
        while(self.accel.mmio.read(0) & 0x4 != 0x4):
            pass
    
    def exec_and_wait(self):
        result = []
        if not self.caching:
            if self.platform == 'Alveo':
                self.accel.call(self.buff1_img, self.buff2_img_mi, self.buff3_mi_status)
            else:# ZYNQ based
                self.execute_zynq(self.buff3_mi_status.device_address)
            self.buff3_mi_status.invalidate()#sync_from_device
            result.append(self.buff3_mi_status)
        else:
            if self.platform == 'Alveo':
                self.accel.call(self.buff1_img, self.buff2_img_mi, self.COMPUTE, self.buff3_mi_status)
            else:# ZYNQ based
                self.execute_zynq(self.COMPUTE)
            self.buff2_img_mi.invalidate()#sync_from_device
            result.append(self.buff2_img_mi)
            self.buff3_mi_status.invalidate()#sync_from_device
            result.append(self.buff3_mi_status)
        
        return result

    
    def reset_cma_buff(self):
        del self.buff1_img 
        del self.buff2_img_mi
        del self.buff3_mi_status
    
    def mutual_info_sw(self, Ref_uint8, Flt_uint8, dim):
        j_h=np.histogram2d(Ref_uint8.ravel(),Flt_uint8.ravel(),bins=[256,256])[0]
        j_h=j_h/(dim*dim)
          
        j_h1=j_h[np.where(j_h>0.000000000000001)]
        entropy=(np.sum(j_h1*np.log2(j_h1)))*-1

        href=np.sum(j_h,axis=0)
        hflt=np.sum(j_h,axis=1)     

        href=href[np.where(href>0.000000000000001)]
        eref=(np.sum(href*(np.log2(href))))*-1

        hflt=hflt[np.where(hflt>0.000000000000001)]
        eflt=(sum(hflt*(np.log2(hflt))))*-1

        mutualinfo=eref+eflt-entropy

        return(mutualinfo)





def main():

    parser = argparse.ArgumentParser(description='Iron software for IR onto a python env')
    parser.add_argument("-ol", "--overlay", nargs='?', help='Path and filename of the target overlay', default='./iron_wrapper.bit')
    parser.add_argument("-clk", "--clock", nargs='?', help='Target clock frequency of the PL', default=100, type=int)
    parser.add_argument("-t", "--thread_number", nargs='?', help='Number of // threads', default=1, type=int)
    parser.add_argument("-p", "--platform", nargs='?', help='platform to target.\
     \'Alveo\' is used for PCIe/XRT based,\n while \'Ultra96\' will setup for a Zynq-based environment', default='Alveo')
    parser.add_argument("-mem", "--caching", action='store_true', help='if it use or not the caching')
    parser.add_argument("-im", "--image_dimension", nargs='?', help='Target images dimensions', default=512, type=int)
    parser.add_argument("-rp", "--res_path", nargs='?', help='Path of the Results', default='./')
    parser.add_argument("-c", "--config", nargs='?', help='hw config to print only', default='ok')

    hist_dim = 256
    dim = 512
    t=0
    args = parser.parse_args()
    accel_number=args.thread_number



    iron = Overlay(args.overlay)
    num_threads = accel_number
    if args.platform=='Zynq':
        from pynq.ps import Clocks;
        print("Previous Frequency "+str(Clocks.fclk0_mhz))
        Clocks.fclk0_mhz = args.clock; 
        print("New frequency "+str(Clocks.fclk0_mhz))
    
    ref = np.random.randint(low=0, high=255, size=(512,512), dtype='uint8')
    flt = np.random.randint(low=0, high=255, size=(512,512), dtype='uint8')
    accel_list=mi_accel_map(iron, args.platform, args.caching, num_threads, args.image_dimension, args.config)

    #time test single MI
    iterations=10
    t_tot = 0
    times=[]
    dim=args.image_dimension
    diffs=[]
    start_tot = time.time()
    for i in range(iterations):
        ref = np.random.randint(low=0, high=255, size=(dim,dim), dtype='uint8')
        flt = np.random.randint(low=0, high=255, size=(dim,dim), dtype='uint8')
        sw_mi=accel_list[0].mutual_info_sw(ref, flt, dim)
        accel_list[0].prepare_ref_buff(ref)
        accel_list[0].prepare_flt_buff(flt)
        start_single = time.time()
        out = accel_list[0].exec_and_wait()
        end_single = time.time()
        print("Hw res: "+str(out[0]))
        print("Sw res: "+str(sw_mi))
        t = end_single - start_single
        times.append(t)
        diff=sw_mi - out[0]
        diffs.append(diff)
        t_tot = t_tot +  t
    end_tot = time.time()

    accel_list[0].reset_cma_buff()
    print("Mean value of hw vs sw difference" +str(np.mean(diffs)))

    df = pd.DataFrame([\
        ["total_time_hw ",t_tot],\
        ["mean_time_hw",np.mean(times)],\
        ["std_time_hw",np.std(times)],\
        ["mean_diff",np.mean(diffs)],\
        ["std_diffs",np.std(diffs)]],\
                    columns=['Label','Test'+str(args.overlay)])
    df_path = os.path.join(args.res_path,'TimeMI_%02d.csv' % (args.clock))
    df.to_csv(df_path, index=False)
    data = {'time'+str(args.overlay):times,\
            'error'+str(args.overlay):diffs}

    df_breakdown = pd.DataFrame(data,\
            columns=['time'+str(args.overlay),'error'+str(args.overlay)])
    df_path_breakdown = os.path.join(args.res_path,'BreakdownMI_%02d.csv' % (args.clock))
    df_breakdown.to_csv(df_path_breakdown, index=False)
    
    if args.platform =='Alveo':
        iron.free()

    print("Test for Single MI values is at the end :)")



if __name__== "__main__":
    main()
