/******************************************
*MIT License
*
# *Copyright (c) [2022] [Davide Conficconi, Eleonora D'Arnese, Emanuele Del Sozzo, Donatella Sciuto, Marco Domenico Santambrogio]
*
*Permission is hereby granted, free of charge, to any person obtaining a copy
*of this software and associated documentation files (the "Software"), to deal
*in the Software without restriction, including without limitation the rights
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*copies of the Software, and to permit persons to whom the Software is
*furnished to do so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*SOFTWARE.
*/
/***************************************************************
*
* High-Level-Synthesis implementation file for Mutual Information computation
*
****************************************************************/
#include "histogram.h"
#include "entropy.h"
#include <stdio.h>
#include <string.h>
#include "assert.h"
#include "mutual_info.hpp"
#include "hls_math.h"
#include "utils.hpp"
#include "stdlib.h"

const unsigned int fifo_in_depth =  (MYROWS*MYCOLS)/(HIST_PE);
const unsigned int fifo_out_depth = 1;
const unsigned int pe_j_h_partition = HIST_PE;

typedef MinHistBits_t HIST_TYPE;
typedef MinHistPEBits_t HIST_PE_TYPE;


typedef enum FUNCTION_T {
	LOAD_IMG = 0,
	COMPUTE = 1
} FUNCTION;


void compute(INPUT_DATA_TYPE * input_img, INPUT_DATA_TYPE * input_ref,  data_t * mutual_info){

#ifndef CACHING
	#pragma HLS INLINE
#endif

#pragma HLS DATAFLOW

static	hls::stream<INPUT_DATA_TYPE> ref_stream("ref_stream");
#pragma HLS STREAM variable=ref_stream depth=2 dim=1
static	hls::stream<INPUT_DATA_TYPE> flt_stream("flt_stream");
#pragma HLS STREAM variable=flt_stream depth=2 dim=1

static  hls::stream<UNPACK_DATA_TYPE> ref_pe_stream[HIST_PE];
#pragma HLS STREAM variable=ref_pe_stream depth=2 dim=1
static  hls::stream<UNPACK_DATA_TYPE> flt_pe_stream[HIST_PE];
#pragma HLS STREAM variable=flt_pe_stream depth=2 dim=1

static	hls::stream<PACKED_HIST_PE_DATA_TYPE> j_h_pe_stream[HIST_PE];
#pragma HLS STREAM variable=j_h_pe_stream depth=2 dim=1

static	hls::stream<PACKED_HIST_DATA_TYPE> joint_j_h_stream("joint_j_h_stream");
#pragma HLS STREAM variable=joint_j_h_stream depth=2 dim=1
static	hls::stream<PACKED_HIST_DATA_TYPE> joint_j_h_stream_0("joint_j_h_stream_0");
#pragma HLS STREAM variable=joint_j_h_stream_0 depth=2 dim=1
static	hls::stream<PACKED_HIST_DATA_TYPE> joint_j_h_stream_1("joint_j_h_stream_1");
#pragma HLS STREAM variable=joint_j_h_stream_1 depth=2 dim=1
static	hls::stream<PACKED_HIST_DATA_TYPE> joint_j_h_stream_2("joint_j_h_stream_2");
#pragma HLS STREAM variable=joint_j_h_stream_2 depth=2 dim=1

static	hls::stream<PACKED_HIST_DATA_TYPE> row_hist_stream("row_hist_stream");
#pragma HLS STREAM variable=row_hist_stream depth=2 dim=1
static	hls::stream<PACKED_HIST_DATA_TYPE> col_hist_stream("col_hist_stream");
#pragma HLS STREAM variable=col_hist_stream depth=2 dim=1

static	hls::stream<OUT_ENTROPY_TYPE> full_entropy_stream("full_entropy_stream");
#pragma HLS STREAM variable=full_entropy_stream depth=2 dim=1
static	hls::stream<OUT_ENTROPY_TYPE> row_entropy_stream("row_entropy_stream");
#pragma HLS STREAM variable=row_entropy_stream depth=2 dim=1
static	hls::stream<OUT_ENTROPY_TYPE> col_entropy_stream("col_entropy_stream");
#pragma HLS STREAM variable=col_entropy_stream depth=2 dim=1

static	hls::stream<HIST_TYPE> full_hist_split_stream[ENTROPY_PE];
#pragma HLS STREAM variable=full_hist_split_stream depth=2 dim=1
static	hls::stream<HIST_TYPE> row_hist_split_stream[ENTROPY_PE];
#pragma HLS STREAM variable=row_hist_split_stream depth=2 dim=1
static	hls::stream<HIST_TYPE> col_hist_split_stream[ENTROPY_PE];
#pragma HLS STREAM variable=col_hist_split_stream depth=2 dim=1

static	hls::stream<OUT_ENTROPY_TYPE> full_entropy_split_stream[ENTROPY_PE];
#pragma HLS STREAM variable=full_entropy_split_stream depth=2 dim=1
static	hls::stream<OUT_ENTROPY_TYPE> row_entropy_split_stream[ENTROPY_PE];
#pragma HLS STREAM variable=row_entropy_split_stream depth=2 dim=1
static	hls::stream<OUT_ENTROPY_TYPE> col_entropy_split_stream[ENTROPY_PE];
#pragma HLS STREAM variable=col_entropy_split_stream depth=2 dim=1


static	hls::stream<data_t> mutual_information_stream("mutual_information_stream");
#pragma HLS STREAM variable=mutual_information_stream depth=2 dim=1


	// Step 1: read data from DDR and split them
	axi2stream<INPUT_DATA_TYPE, NUM_INPUT_DATA>(flt_stream, input_img);
#ifndef CACHING
	axi2stream<INPUT_DATA_TYPE, NUM_INPUT_DATA>(ref_stream, input_ref);
#else
	bram2stream<INPUT_DATA_TYPE, NUM_INPUT_DATA>(ref_stream, input_ref);
#endif

	split_stream<INPUT_DATA_TYPE, UNPACK_DATA_TYPE, UNPACK_DATA_BITWIDTH, NUM_INPUT_DATA, HIST_PE>(ref_stream, ref_pe_stream);
	split_stream<INPUT_DATA_TYPE, UNPACK_DATA_TYPE, UNPACK_DATA_BITWIDTH, NUM_INPUT_DATA, HIST_PE>(flt_stream, flt_pe_stream);
	// End Step 1


	// Step 2: Compute two histograms in parallel
	WRAPPER_HIST(HIST_PE)<UNPACK_DATA_TYPE, NUM_INPUT_DATA, HIST_PE_TYPE, PACKED_HIST_PE_DATA_TYPE, MIN_HIST_PE_BITS>(ref_pe_stream, flt_pe_stream, j_h_pe_stream);
	sum_joint_histogram<PACKED_HIST_PE_DATA_TYPE, J_HISTO_ROWS*J_HISTO_COLS/ENTROPY_PE, PACKED_HIST_DATA_TYPE, HIST_PE, HIST_PE_TYPE, MIN_HIST_PE_BITS, HIST_TYPE, MIN_HIST_BITS>(j_h_pe_stream, joint_j_h_stream);
	// End Step 2


	// Step 3: Compute histograms per row and column
	tri_stream<PACKED_HIST_DATA_TYPE, J_HISTO_ROWS*J_HISTO_COLS/ENTROPY_PE>(joint_j_h_stream, joint_j_h_stream_0, joint_j_h_stream_1, joint_j_h_stream_2);

	hist_row<PACKED_HIST_DATA_TYPE, J_HISTO_ROWS, J_HISTO_COLS/ENTROPY_PE, PACKED_HIST_DATA_TYPE, HIST_TYPE, MIN_HIST_BITS>(joint_j_h_stream_0, row_hist_stream);
	hist_col<PACKED_HIST_DATA_TYPE, J_HISTO_ROWS, J_HISTO_COLS/ENTROPY_PE>(joint_j_h_stream_1, col_hist_stream);
	// End Step 3


	// Step 4: Compute Entropies
	WRAPPER_ENTROPY(ENTROPY_PE)<PACKED_HIST_DATA_TYPE, HIST_TYPE, OUT_ENTROPY_TYPE, J_HISTO_ROWS*J_HISTO_COLS/ENTROPY_PE>(joint_j_h_stream_2, full_hist_split_stream, full_entropy_split_stream, full_entropy_stream);
	WRAPPER_ENTROPY(ENTROPY_PE)<PACKED_HIST_DATA_TYPE, HIST_TYPE, OUT_ENTROPY_TYPE, J_HISTO_ROWS/ENTROPY_PE>(row_hist_stream, row_hist_split_stream, row_entropy_split_stream, row_entropy_stream);
	WRAPPER_ENTROPY(ENTROPY_PE)<PACKED_HIST_DATA_TYPE, HIST_TYPE, OUT_ENTROPY_TYPE, J_HISTO_COLS/ENTROPY_PE>(col_hist_stream, col_hist_split_stream, col_entropy_split_stream, col_entropy_stream);
	// End Step 4


	// Step 6: Mutual information
	compute_mutual_information<OUT_ENTROPY_TYPE, data_t>(row_entropy_stream, col_entropy_stream, full_entropy_stream, mutual_information_stream);
	// End Step 6


	// Step 7: Write result back to DDR
	stream2axi<data_t, fifo_out_depth>(mutual_info, mutual_information_stream);

}


template<typename T, unsigned int size>
void copyData(T* in, T* out){
	for(int i = 0; i < size; i++){
#pragma HLS PIPELINE
		out[i] = in[i];
	}
}


#ifndef CACHING

#ifdef KERNEL_NAME
extern "C"{
	void KERNEL_NAME
#else
	void mutual_information_master
#endif //KERNEL_NAME
(INPUT_DATA_TYPE * input_img, INPUT_DATA_TYPE * input_ref, data_t * mutual_info){
#pragma HLS INTERFACE m_axi port=input_img depth=fifo_in_depth offset=slave bundle=gmem0
#pragma HLS INTERFACE m_axi port=input_ref depth=fifo_in_depth offset=slave bundle=gmem1
#pragma HLS INTERFACE m_axi port=mutual_info depth=1 offset=slave bundle=gmem2

#pragma HLS INTERFACE s_axilite port=input_img bundle=control
#pragma HLS INTERFACE s_axilite port=input_ref bundle=control
#pragma HLS INTERFACE s_axilite port=mutual_info register bundle=control
#pragma HLS INTERFACE s_axilite port=return bundle=control

	compute(input_img, input_ref, mutual_info);

}



#else // CACHING


#ifdef KERNEL_NAME
extern "C"{
	void KERNEL_NAME
#else
	void mutual_information_master
#endif //KERNEL_NAME
(INPUT_DATA_TYPE * input_img,  data_t * mutual_info, unsigned int functionality, int *status){
#pragma HLS INTERFACE m_axi port=input_img depth=fifo_in_depth offset=slave bundle=gmem0
#pragma HLS INTERFACE m_axi port=mutual_info depth=1 offset=slave bundle=gmem2
#pragma HLS INTERFACE m_axi port=status depth=1 offset=slave bundle=gmem1

#pragma HLS INTERFACE s_axilite port=input_img bundle=control
#pragma HLS INTERFACE s_axilite port=mutual_info register bundle=control
#pragma HLS INTERFACE s_axilite port=functionality register bundle=control
#pragma HLS INTERFACE s_axilite port=status register bundle=control
#pragma HLS INTERFACE s_axilite port=return bundle=control


	static INPUT_DATA_TYPE ref_img[NUM_INPUT_DATA] = {0};

#ifdef URAM 
#pragma HLS RESOURCE variable=ref_img core=RAM_1P_URAM
#endif //URAM

	switch(functionality){
	case LOAD_IMG:	copyData<INPUT_DATA_TYPE, NUM_INPUT_DATA>(input_img, ref_img);
					*status = 1;
					*mutual_info = 0.0;
					break;
	case COMPUTE:	compute(input_img, ref_img, mutual_info);
					*status = 1;
					break;
	default:		*status = -1;
					*mutual_info = 0.0;
					break;
	}


}

#endif //CACHING

#ifdef KERNEL_NAME

} // extern "C"

#endif //KERNEL_NAME
