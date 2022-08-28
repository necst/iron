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
* Utilities for the code to be synthesized
*
****************************************************************/
#ifndef UTILS_HPP
#define UTILS_HPP

#include "hls_stream.h"


template<typename T, unsigned int size>
void axi2stream(hls::stream<T> &out,const T* in){
    for(int i = 0; i <size; i++){
        #pragma HLS PIPELINE
        T tmp = in[i];
        out.write(tmp);
    }
}

template<typename T, unsigned int size>
void bram2stream(hls::stream<T> &out, const T* in){
    for(int i = 0; i <size; i++){
        #pragma HLS PIPELINE
        T tmp = in[i];
        out.write(tmp);
    }
}

template<typename T, unsigned int size>
void axi2stream_split(hls::stream<T> &out0, hls::stream<T> &out1, const T* in){
    for(int i = 0; i <size; i++){
#pragma HLS PIPELINE
        T tmp = in[i];
        if(!(i%2)){
			out0.write(tmp);
		} else {
			out1.write(tmp);
		}
    }
}


template<typename Tin, typename Tout, unsigned int out_bitwidth, unsigned int size, unsigned int STREAM>
void split_stream(hls::stream<Tin> &in, hls::stream<Tout> out[STREAM]){
    for(int i = 0; i <size; i++){
        #pragma HLS PIPELINE
        Tin tmp = in.read();
        for(int j = 0; j < STREAM; j++){
        	ap_uint<out_bitwidth> unpacked = tmp.range((j+1)*out_bitwidth - 1, j*out_bitwidth);
        	Tout elem = *((Tout *)&unpacked);
        	out[j].write(elem);
        }
    }
}


template<typename Tin, typename Tout, unsigned int out_bitwidth, unsigned int size>
void convert_stream(hls::stream<Tin> &in, hls::stream<Tout> &out){
    for(int i = 0; i <size; i++){
        #pragma HLS PIPELINE
        Tin in_val = in.read();
        unsigned int tmp = in_val;
        Tout elem = *((Tout *)&tmp);
        out.write(elem);
    }
}


template<typename T, unsigned int size>
void tri_stream(hls::stream<T> &in, hls::stream<T> &out0, hls::stream<T> &out1, hls::stream<T> &out2){
    for(int i = 0; i <size; i++){
        #pragma HLS PIPELINE
        T tmp = in.read();
        out0.write(tmp);
		out1.write(tmp);
		out2.write(tmp);
    }
}


template<typename T, unsigned int size>
void stream2axi(T* out, hls::stream<T> &in){
    for(int i = 0; i <size; i++){
        #pragma HLS PIPELINE
        T tmp = in.read();
        out[i] = tmp;
    }
}


template<typename T, unsigned int size>
void join_and_sum(hls::stream<T> &in0, hls::stream<T> &in1, hls::stream<T> &out){
    for(int i = 0; i < size; i++){
        #pragma HLS PIPELINE
        T tmp0 = in0.read();
        T tmp1 = in1.read();
        T tmp2 = tmp0 + tmp1;
        out.write(tmp2);
    }
}



#endif // UTILS_HPP
