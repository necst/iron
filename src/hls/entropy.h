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
* High-Level-Synthesis header file for Mutual Information computation
*
****************************************************************/
#ifndef ENTROPY_H
#define ENTROPY_H

#include "mutual_info.hpp"
#include "hls_stream.h"
#include "hls_math.h"
#include "utils.hpp"
#include "ap_fixed.h"

#define THRESHOLD 1


const ENTROPY_TYPE inverseLnOf2 = 1.4426950408889634f;
const ENTROPY_TYPE lnOf2 = 0.69314718055994529f;


template<typename Tin, typename Tout, unsigned int dim>
void compute_entropy(hls::stream<Tin> &in_stream, hls::stream<Tout> &out_stream){

#ifndef FIXED
	Tout entropy = 0;
	ENTROPY_TYPE tmp_entropy[ACC_SIZE] = {0};
#else
	ENTROPY_TYPE entropy = 0;
#endif

	for(int i = 0; i < dim; i++){
#pragma HLS PIPELINE
		Tin tmp = in_stream.read();
		if (tmp > THRESHOLD){
			ENTROPY_TYPE tmpf = tmp;
#ifndef FIXED
			ENTROPY_TYPE log2Value = hls::log(tmpf)/lnOf2;
			ENTROPY_TYPE prod = tmp*log2Value;
			tmp_entropy[i%ACC_SIZE] += prod;
#else
			ENTROPY_TYPE log2Value = hls::log2(tmpf);
			ENTROPY_TYPE prod = tmp*log2Value;
			entropy += prod;
#endif
		}
	}

#ifndef FIXED
	for(int i = 0; i < ACC_SIZE; i++){
#pragma HLS UNROLL
		entropy += tmp_entropy[i];
	}
#endif

	Tout out_entropy = entropy;

	out_stream.write(out_entropy);

}


template<typename T, unsigned int dim0, unsigned int dim1, typename Tout, typename Ttmp, unsigned int bitsTtmp>
void hist_row(hls::stream<T> &in_stream, hls::stream<T> &out_stream){

	static Ttmp acc_array[dim0];
#pragma HLS ARRAY_PARTITION variable=acc_array cyclic factor=ENTROPY_PE_CONST dim=1
	Ttmp acc_val = 0;

	for(int i = 0; i < dim0; i++){
		for(int j = 0; j < dim1; j++){
#pragma HLS PIPELINE
			T in = in_stream.read();
			Ttmp tmp = 0;
			for(int k = 0; k < ENTROPY_PE; k++){
				Ttmp unpacked = in.range((k+1)*bitsTtmp-1, k*bitsTtmp);
				tmp += unpacked;
			}
			if(j == 0){
				acc_val = tmp;
			} else if (j < dim1 - 1) {
				acc_val += tmp;
			} else {
				acc_array[i] = acc_val + tmp;
			}
		}
	}

	for(int i = 0; i < dim0; i+=ENTROPY_PE){
#pragma HLS PIPELINE
		Tout out = 0;
		for(int k = 0; k < ENTROPY_PE; k++){
			Ttmp tmp = acc_array[i+k];
			out.range((k+1)*bitsTtmp-1, k*bitsTtmp) = tmp;
		}
		out_stream.write(out);
	}

}


template<typename T, unsigned int dim0, unsigned int dim1>
void hist_col(hls::stream<T> &in_stream, hls::stream<T> &out_stream){

	static T acc_array[dim1];

	for(int i = 0; i < dim0; i++){
		for(int j = 0; j < dim1; j++){
#pragma HLS PIPELINE
			T in = in_stream.read();
			if(i == 0){
				acc_array[j] = in;
			} else {
				acc_array[j] += in;
			}
		}
	}

	for(int i = 0; i < dim1; i++){
#pragma HLS PIPELINE
		T out = acc_array[i];
		out_stream.write(out);
	}

}


template<typename Tin, typename Tout>
void compute_mutual_information(hls::stream<Tin>& in0, hls::stream<Tin>& in1, hls::stream<Tin>& in2, hls::stream<Tout>& out){

	Tin tmp0 = in0.read();
	Tin tmp1 = in1.read();
	Tin tmp2 = in2.read();

#ifndef FIXED
	Tin tmp3 = tmp0 + tmp1 - tmp2;
#else
	int tmp3 = tmp0 + tmp1 - tmp2;
#endif
	Tout tmp4 = -tmp3*scale_factor + MIN_HIST_BITS_NO_OVERFLOW;

	out.write(tmp4);

}

template<typename T, unsigned int dim>
void sum_streams(hls::stream<T> in[dim], hls::stream<T>& out){

	T out_val = 0;
	for(int i = 0; i < dim; i++){
#pragma HLS UNROLL
		T tmp = in[i].read();
		out_val += tmp;
	}

	out.write(out_val);

}

template<typename Tin, typename Tunpack, typename Tout, unsigned int dim>
void wrapper_entropy_1(hls::stream<Tin>& hist_stream, hls::stream<Tunpack> hist_split_stream[1], hls::stream<Tout> entropy_split_stream[1], hls::stream<Tout> &entropy_stream){
#pragma HLS INLINE

	compute_entropy<Tin, Tout, dim>(hist_stream, entropy_stream);

}

template<typename Tin, typename Tunpack, typename Tout, unsigned int dim>
void wrapper_entropy_2(hls::stream<Tin>& hist_stream, hls::stream<Tunpack> hist_split_stream[2], hls::stream<Tout> entropy_split_stream[2], hls::stream<Tout> &entropy_stream){
#pragma HLS INLINE

	split_stream<Tin, Tunpack, MIN_HIST_BITS, dim, 2>(hist_stream, hist_split_stream);

	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[0], entropy_split_stream[0]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[1], entropy_split_stream[1]);

	sum_streams<Tout, 2>(entropy_split_stream, entropy_stream);

}


template<typename Tin, typename Tunpack, typename Tout, unsigned int dim>
void wrapper_entropy_4(hls::stream<Tin>& hist_stream, hls::stream<Tunpack> hist_split_stream[4], hls::stream<Tout> entropy_split_stream[4], hls::stream<Tout> &entropy_stream){
#pragma HLS INLINE

	split_stream<Tin, Tunpack, MIN_HIST_BITS, dim, 4>(hist_stream, hist_split_stream);

	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[0], entropy_split_stream[0]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[1], entropy_split_stream[1]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[2], entropy_split_stream[2]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[3], entropy_split_stream[3]);

	sum_streams<Tout, 4>(entropy_split_stream, entropy_stream);

}


template<typename Tin, typename Tunpack, typename Tout, unsigned int dim>
void wrapper_entropy_8(hls::stream<Tin>& hist_stream, hls::stream<Tunpack> hist_split_stream[8], hls::stream<Tout> entropy_split_stream[8], hls::stream<Tout> &entropy_stream){
#pragma HLS INLINE

	split_stream<Tin, Tunpack, MIN_HIST_BITS, dim, 8>(hist_stream, hist_split_stream);

	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[0], entropy_split_stream[0]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[1], entropy_split_stream[1]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[2], entropy_split_stream[2]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[3], entropy_split_stream[3]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[4], entropy_split_stream[4]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[5], entropy_split_stream[5]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[6], entropy_split_stream[6]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[7], entropy_split_stream[7]);

	sum_streams<Tout, 8>(entropy_split_stream, entropy_stream);

}


template<typename Tin, typename Tunpack, typename Tout, unsigned int dim>
void wrapper_entropy_16(hls::stream<Tin>& hist_stream, hls::stream<Tunpack> hist_split_stream[16], hls::stream<Tout> entropy_split_stream[16], hls::stream<Tout> &entropy_stream){
#pragma HLS INLINE

	split_stream<Tin, Tunpack, MIN_HIST_BITS, dim, 16>(hist_stream, hist_split_stream);

	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[0], entropy_split_stream[0]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[1], entropy_split_stream[1]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[2], entropy_split_stream[2]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[3], entropy_split_stream[3]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[4], entropy_split_stream[4]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[5], entropy_split_stream[5]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[6], entropy_split_stream[6]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[7], entropy_split_stream[7]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[8], entropy_split_stream[8]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[9], entropy_split_stream[9]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[10], entropy_split_stream[10]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[11], entropy_split_stream[11]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[12], entropy_split_stream[12]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[13], entropy_split_stream[13]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[14], entropy_split_stream[14]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[15], entropy_split_stream[15]);

	sum_streams<Tout, 16>(entropy_split_stream, entropy_stream);

}


template<typename Tin, typename Tunpack, typename Tout, unsigned int dim>
void wrapper_entropy_32(hls::stream<Tin>& hist_stream, hls::stream<Tunpack> hist_split_stream[32], hls::stream<Tout> entropy_split_stream[32], hls::stream<Tout> &entropy_stream){
#pragma HLS INLINE

	split_stream<Tin, Tunpack, MIN_HIST_BITS, dim, 32>(hist_stream, hist_split_stream);

	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[0], entropy_split_stream[0]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[1], entropy_split_stream[1]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[2], entropy_split_stream[2]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[3], entropy_split_stream[3]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[4], entropy_split_stream[4]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[5], entropy_split_stream[5]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[6], entropy_split_stream[6]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[7], entropy_split_stream[7]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[8], entropy_split_stream[8]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[9], entropy_split_stream[9]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[10], entropy_split_stream[10]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[11], entropy_split_stream[11]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[12], entropy_split_stream[12]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[13], entropy_split_stream[13]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[14], entropy_split_stream[14]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[15], entropy_split_stream[15]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[16], entropy_split_stream[16]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[17], entropy_split_stream[17]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[18], entropy_split_stream[18]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[19], entropy_split_stream[19]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[20], entropy_split_stream[20]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[21], entropy_split_stream[21]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[22], entropy_split_stream[22]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[23], entropy_split_stream[23]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[24], entropy_split_stream[24]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[25], entropy_split_stream[25]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[26], entropy_split_stream[26]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[27], entropy_split_stream[27]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[28], entropy_split_stream[28]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[29], entropy_split_stream[29]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[30], entropy_split_stream[30]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[31], entropy_split_stream[31]);

	sum_streams<Tout, 32>(entropy_split_stream, entropy_stream);

}

template<typename Tin, typename Tunpack, typename Tout, unsigned int dim>
void wrapper_entropy_64(hls::stream<Tin>& hist_stream, hls::stream<Tunpack> hist_split_stream[64], hls::stream<Tout> entropy_split_stream[64], hls::stream<Tout> &entropy_stream){
#pragma HLS INLINE

	split_stream<Tin, Tunpack, MIN_HIST_BITS, dim, 64>(hist_stream, hist_split_stream);

	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[0], entropy_split_stream[0]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[1], entropy_split_stream[1]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[2], entropy_split_stream[2]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[3], entropy_split_stream[3]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[4], entropy_split_stream[4]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[5], entropy_split_stream[5]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[6], entropy_split_stream[6]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[7], entropy_split_stream[7]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[8], entropy_split_stream[8]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[9], entropy_split_stream[9]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[10], entropy_split_stream[10]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[11], entropy_split_stream[11]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[12], entropy_split_stream[12]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[13], entropy_split_stream[13]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[14], entropy_split_stream[14]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[15], entropy_split_stream[15]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[16], entropy_split_stream[16]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[17], entropy_split_stream[17]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[18], entropy_split_stream[18]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[19], entropy_split_stream[19]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[20], entropy_split_stream[20]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[21], entropy_split_stream[21]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[22], entropy_split_stream[22]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[23], entropy_split_stream[23]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[24], entropy_split_stream[24]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[25], entropy_split_stream[25]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[26], entropy_split_stream[26]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[27], entropy_split_stream[27]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[28], entropy_split_stream[28]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[29], entropy_split_stream[29]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[30], entropy_split_stream[30]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[31], entropy_split_stream[31]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[32], entropy_split_stream[32]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[33], entropy_split_stream[33]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[34], entropy_split_stream[34]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[35], entropy_split_stream[35]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[36], entropy_split_stream[36]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[37], entropy_split_stream[37]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[38], entropy_split_stream[38]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[39], entropy_split_stream[39]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[40], entropy_split_stream[40]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[41], entropy_split_stream[41]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[42], entropy_split_stream[42]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[43], entropy_split_stream[43]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[44], entropy_split_stream[44]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[45], entropy_split_stream[45]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[46], entropy_split_stream[46]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[47], entropy_split_stream[47]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[48], entropy_split_stream[48]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[49], entropy_split_stream[49]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[50], entropy_split_stream[50]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[51], entropy_split_stream[51]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[52], entropy_split_stream[52]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[53], entropy_split_stream[53]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[54], entropy_split_stream[54]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[55], entropy_split_stream[55]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[56], entropy_split_stream[56]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[57], entropy_split_stream[57]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[58], entropy_split_stream[58]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[59], entropy_split_stream[59]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[60], entropy_split_stream[60]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[61], entropy_split_stream[61]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[62], entropy_split_stream[62]);
	compute_entropy<Tunpack, Tout, dim>(hist_split_stream[63], entropy_split_stream[63]);

	sum_streams<Tout, 64>(entropy_split_stream, entropy_stream);

}


#endif // ENTROPY_H
