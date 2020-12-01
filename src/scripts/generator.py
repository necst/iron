# /******************************************
# *MIT License
# *
# *Copyright (c) [2020] [Davide Conficconi, Eleonora D'Arnese, Emanuele Del Sozzo, Donatella Sciuto, Marco Domenico Santambrogio]
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


import argparse
import os
import numpy
import math
###################################################################################################################################

def print_mi_config(num_pe, inp_img_bits, inp_img_dim,  derived , pe_entropy, fixed, caching, uram, vitis, out_path):
    if fixed:
        fixerd_or_not=""
    else:
        fixerd_or_not="//"
    if vitis:
        vitis_externC="\"C\""
    else:
        vitis_externC=""

    mi_header = open(out_path+"mutual_info.hpp","w+")
    mi_header.write("/******************************************\n \
*MIT License\n \
*\n \
*Copyright (c) [2020] [Davide Conficconi, Eleonora D'Arnese, Emanuele Del Sozzo, Marco Domenico Santambrogio]\n \
*\n \
*Permission is hereby granted, free of charge, to any person obtaining a copy\n \
*of this software and associated documentation files (the \"Software\"), to deal\n \
*in the Software without restriction, including without limitation the rights\n \
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n \
*copies of the Software, and to permit persons to whom the Software is\n \
*furnished to do so, subject to the following conditions:\n \
*\n \
*The above copyright notice and this permission notice shall be included in all\n \
*copies or substantial portions of the Software.\n \
*\n \
*THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n \
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n \
*FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n \
*AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n \
*LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n \
*OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n \
*SOFTWARE.\n \
*/\n \
/***************************************************************\n \
*\n \
* High-Level-Synthesis header file for Mutual Information computation\n \
*\n \
****************************************************************/\n \
#ifndef MUTUAL_INF_H\n \
#define MUTUAL_INF_H\n \
#include \"ap_int.h\"\n \
\n \
typedef float data_t;\n \
#define DATA_T_BITWIDTH 32\n \
typedef ap_uint<{0}> MY_PIXEL; \n \
//0\n \
\n \
#define TWO_FLOAT 2.0f\n \
#define OUT_BUFF_SIZE 1\n \
\n \
#define ENTROPY_THRESH 0.000000000000001\n \
#define ENTROPY_FLT_THRESH 0.000000000001\n \
#define ENTROPY_REF_THRESH 0.000000000001\n \
\n \
/************/\n \
\n \
/*********** SIM used values **********/\n \
#define DIMENSION {1}\n \
//1\n \
/*********** End **********/\n \
\n \
#define MYROWS DIMENSION // Y\n \
#define MYCOLS DIMENSION\n \
\n \
/*********** SIM used values **********/\n \
#define MAX_RANGE (int)(MAX_FREQUENCY - 1)\n \
/*********** End **********/\n \
\n \
/*\n \
 Joint Histogram computations\n \
*/\n \
\n \
#define HIST_PE {2}\n \
//2\n \
#define UNPACK_DATA_BITWIDTH {0}\n \
//0\n \
#define UNPACK_DATA_TYPE ap_uint<UNPACK_DATA_BITWIDTH>\n \
\n \
#define INPUT_DATA_BITWIDTH (HIST_PE*UNPACK_DATA_BITWIDTH)\n \
#define INPUT_DATA_TYPE ap_uint<INPUT_DATA_BITWIDTH>\n \
\n \
#define NUM_INPUT_DATA (DIMENSION*DIMENSION/(HIST_PE))\n \
\n \
#define WRAPPER_HIST2(num) wrapper_joint_histogram_##num\n \
#define WRAPPER_HIST(num) WRAPPER_HIST2(num)\n \
\n \
#define WRAPPER_ENTROPY2(num) wrapper_entropy_##num\n \
#define WRAPPER_ENTROPY(num) WRAPPER_ENTROPY2(num)\n \
\n \
#define J_HISTO_ROWS {3}\n \
//3\n \
#define J_HISTO_COLS J_HISTO_ROWS\n \
#define MIN_HIST_BITS {4}\n \
//4\n \
//#define MIN_J_HISTO_BITS (int)(std::ceil(std::log2(MYROWS*MYCOLS)))\n \
// TODO overflow non contemplato :D, sarebbe + 1\n \
#define MIN_HIST_PE_BITS (MIN_HIST_BITS - {5})\n \
//5\n \
//#define MIN_HISTO_PE_BITS (int)(std::ceil(std::log2(ROW_PE_KRNL*COLS_PE_KRNL)))\n \
//MIN_HIST_BITS - log2(HIST_PE)\n \
\n \
\n \
typedef ap_uint<MIN_HIST_BITS> MinHistBits_t;\n \
typedef ap_uint<MIN_HIST_PE_BITS> MinHistPEBits_t;\n \
\n \
\n \
#define ENTROPY_PE {6}\n \
//6\n \
const unsigned int ENTROPY_PE_CONST = ENTROPY_PE;\n \
\n \
#define PACKED_HIST_PE_DATA_BITWIDTH (MIN_HIST_PE_BITS*ENTROPY_PE)\n \
#define PACKED_HIST_PE_DATA_TYPE ap_uint<PACKED_HIST_PE_DATA_BITWIDTH>\n \
\n \
#define PACKED_HIST_DATA_BITWIDTH (MIN_HIST_BITS*ENTROPY_PE)\n \
#define PACKED_HIST_DATA_TYPE ap_uint<PACKED_HIST_DATA_BITWIDTH>\n \
\n \
//#define PACKED_DATA_T_DATA_BITWIDTH (INNER_ENTROPY_TYPE_BITWIDTH*ENTROPY_PE)\n \
//#define PACKED_DATA_T_DATA_TYPE ap_uint<PACKED_DATA_T_DATA_BITWIDTH>\n \
\n \
#define UINT_OUT_ENTROPY_TYPE_BITWIDTH {7}\n \
//7\n \
// MAX std::ceil(std::log2( log2(MYROWS*MYCOLS) * (MYROWS*MYCOLS) )) + 1\n \
#define UINT_OUT_ENTROPY_TYPE ap_uint<UINT_OUT_ENTROPY_TYPE_BITWIDTH>\n \
\n \
#define FIXED_BITWIDTH 42\n \
#define FIXED_INT_BITWIDTH UINT_OUT_ENTROPY_TYPE_BITWIDTH\n \
{8}#define FIXED ap_ufixed<42, {7}>\n \
//8\n \
#ifndef FIXED\n \
    #define ENTROPY_TYPE data_t\n \
    #define OUT_ENTROPY_TYPE data_t\n \
#else\n \
    #define ENTROPY_TYPE FIXED\n \
    #define OUT_ENTROPY_TYPE UINT_OUT_ENTROPY_TYPE\n \
#endif\n \
\n \
\n \
#define ANOTHER_DIMENSION J_HISTO_ROWS // should be equal to j_histo_rows\n \
\n \
\n \
//UNIFORM QUANTIZATION\n \
#define INTERVAL_NUMBER {9} // L, amount of levels we want for the binning process, thus at the output\n \
//9\n \
#define MAX_FREQUENCY {10} // or 255? the maximum number of levels at the input stage\n \
//10\n\
#define MINIMUM_FREQUENCY 0\n \
#define INTERVAL_LENGTH ( (MAX_FREQUENCY - MINIMUM_FREQUENCY) / INTERVAL_NUMBER ) // Q = (fmax - fmin )/L\n \
#define INDEX_QUANTIZED(i) (i/INTERVAL_LENGTH) // Qy(i) =  f - fmin / Q\n \
\n \
/*****************/\n \
const ENTROPY_TYPE scale_factor = {11}f;\n\
//11 \n \
//constexpr float scale_factor = 1.0f /(DIMENSION*DIMENSION);\n\
\n \
#ifndef CACHING\n \
    extern {12} void mutual_information_master(INPUT_DATA_TYPE * input_img, INPUT_DATA_TYPE * input_ref, data_t * mutual_info);\n \
#else\n \
    extern {12} void mutual_information_master(INPUT_DATA_TYPE * input_img,  data_t * mutual_info, unsigned int functionality, int* status);\n \
#endif\n \
\n \
//12 \n \
#define ACC_SIZE {13}\n \
// 13\n \
\n".format(inp_img_bits, \
    inp_img_dim, \
    num_pe, \
    derived.hist_dim, \
    derived.histos_bits, \
    derived.pe_bits, \
    pe_entropy, \
    derived.uint_fixed_bitwidth , \
    fixerd_or_not,\
    derived.quant_levels, derived.maximum_freq,\
    derived.scale_factor,\
    vitis_externC,\
    derived.entr_acc_size) )
    if caching:
        mi_header.write(" \n \
#define CACHING\n\
//14")
    if uram:
        mi_header.write(" \n \
#define URAM\n \
//15")
    mi_header.write("\n#endif")


######################################################
######################################################
######################################################
######################################################

class ParametersDerived:

    def __init__(self):
        self.histos_bits = 0
        self.quant_levels = 0
        self.reduced_lvls = 0 
        self.hist_dim = 0
        self.j_idx_bits = 0
        self.idx_bits = 0
        self.reduced_histos_bits = 0
        self.maximum_freq = 0
        self.in_dim = 0
        self.in_bits = 0
        self.bin_val = 0
        self.pe_number = 0
        self.entr_acc_size = 0
        self.bit_entropy = 0
        self.scale_factor = 0
        self.pe_bits = 0
        self.uint_fixed_bitwidth=0

    def derive_bitwidth(self,data_container):
        return 32


    def derive(self, in_dim, in_bits, bin_val, pe_number, entr_acc_size, histotype):
        self.in_dim = in_dim
        self.in_bits = in_bits
        self.bin_val = bin_val
        self.pe_number = pe_number
        self.entr_acc_size = entr_acc_size
        self.histos_bits = math.ceil(numpy.log2(in_dim*in_dim))
        self.reduced_lvls = math.ceil(in_bits - bin_val)
        self.quant_levels = math.ceil(2**self.reduced_lvls)
        self.hist_dim = math.ceil(2**self.reduced_lvls)
        self.j_idx_bits = math.ceil(numpy.log2(self.hist_dim*self.hist_dim))
        self.idx_bits = math.ceil(numpy.log2(self.hist_dim))
        self.reduced_histos_bits = math.ceil(numpy.log2(in_dim*in_dim / pe_number))
        self.maximum_freq = math.ceil(2**in_bits)
        self.bit_entropy = self.derive_bitwidth(histotype)
        self.scale_factor = 1 / (in_dim*in_dim)
        self.pe_bits = math.ceil(numpy.log2(pe_number))
        self.uint_fixed_bitwidth=math.ceil(math.log2(math.log2(in_dim*in_dim)*in_dim*in_dim))

    
    def printDerived(self):
        print("Starting params:\n in_dim {0}\n in_bits {1}\n bin_val {2}\n pe_number {3}\n entr_acc_size {4}\n"\
            .format(self.in_dim,\
            self.in_bits, self.bin_val, self.pe_number, self.entr_acc_size))
        print("Derived Configuration: \nhisto bits "+ str(self.histos_bits))
        print("quant_levels "+ str(self.quant_levels))
        print("hist_dim "+ str(self.hist_dim))
        print("j_idx_bits "+ str(self.j_idx_bits))
        print("idx_bits "+ str(self.idx_bits))
        print("reduced_histos_bits "+ str(self.reduced_histos_bits))
        print("maximum_freq "+ str(self.maximum_freq))
        print("entropies bitwdith "+str(self.bit_entropy))
###################################################################################################################################
###################################################################################################################################
###################################################################################################################################
###################################################################################################################################
###################################################################################################################################
###################################################################################################################################
###################################################################################################################################
###################################################################################################################################

def main():
    parser = argparse.ArgumentParser(description='Configuration Generation for the MI and histogram accelerator,\n\
        Default configuration is to use \'float\' datatypes with a 512x512 8 bits input matrix and a histogram of 256 levels with one PE')
    parser.add_argument("-op","--out_path", nargs='?', help='output path for the out files, default ./', default='./')
    parser.add_argument("-c", "--clean", help='clean previously created files befor starting', action='store_true')
    
    parser.add_argument("-ht", "--histotype", nargs='?', help='data type for the floating point computation, default float', default='float')
    parser.add_argument("-pe", "--pe_number", nargs='?', help='number of PEs assigned to the joint histogram computation, default 1', default='1', type=int)
    parser.add_argument("-ib", "--in_bits", nargs='?', help='number of bits for the target input image, default 8', default='8', type=int)
    parser.add_argument("-id", "--in_dim", nargs='?', help='maximum dimension of the target input image, default 512', default='512', type=int)
    parser.add_argument("-bv", "--bin_val", nargs='?', help='reduction factor of in the binning process of the histogram \n\
                        (i.e. a factor of 2 means 2** (in bits - bin_val) bin levels) , default 0', default='0', type=int)
    parser.add_argument("-es", "--entr_acc_size", nargs='?', help=' accumulator size for the entropies computation', default='8', type=int)
    parser.add_argument("-pen", "--pe_entropy", nargs='?', help='number of PEs assigned to the entropy computation, default 1', default='1', type=int)
    
    parser.add_argument("-vts", "--vitis", help='generate vitis version?', action='store_true')
    parser.add_argument("-mem", "--cache_mem", help='use the caching version or not', action='store_true')
    parser.add_argument("-uram", "--use_uram", help="using a caching version with urams, no sens to use without caching", action='store_true')
    args = parser.parse_args()
    derived = ParametersDerived()
    derived.derive(args.in_dim, args.in_bits, args.bin_val, args.pe_number, args.entr_acc_size, args.histotype)
    #derived.printDerived()
    #print(args)
    #print(args.clean)
    fixed=(args.histotype == "fixed")
    if args.clean:
        os.remove(args.out_path+"mutual_info.hpp")

    print_mi_config(args.pe_number, args.in_bits ,\
        args.in_dim,  derived, args.pe_entropy, \
        fixed , args.cache_mem, args.use_uram, args.vitis, args.out_path)

if __name__== "__main__":
    main()
