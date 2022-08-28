#!/bin/bash
#/******************************************
#*MIT License
#*
#*Copyright (c) [2022] [Davide Conficconi, Eleonora D'Arnese, Emanuele Del Sozzo, Donatella Sciuto, Marco Domenico Santambrogio]
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


###############TOP configuration generation###################
#Pynq-Z2
make hw_gen CORE_NR=1 HT="fixed" PE=4  PE_ENTROP=4 FREQ_MHZ=200  TRGT_PLATFORM=pynqz2

#Ultra96-v2
make hw_gen CORE_NR=2 HT="float" PE=2 PE_ENTROP=1 FREQ_MHZ=200 TRGT_PLATFORM=ultra96_v2
make hw_gen CORE_NR=2 HT="fixed" PE=2 PE_ENTROP=4 FREQ_MHZ=200 TRGT_PLATFORM=ultra96_v2

#Zcu104
make hw_gen CORE_NR=2 HT="float" PE=2 PE_ENTROP=1 CACHING=true FREQ_MHZ=200 TRGT_PLATFORM=zcu104
make hw_gen CORE_NR=3 HT="fixed" PE=2 PE_ENTROP=8 FREQ_MHZ=200 CACHING=true URAM=true TRGT_PLATFORM=zcu104

#Alveo u200
make hw_gen PE=32 CORE_NR=1 HT="fixed" TARGET=hw OPT_LVL=3 CLK_FRQ=300 PE_ENTROP=8 TRGT_PLATFORM=alveo_u200