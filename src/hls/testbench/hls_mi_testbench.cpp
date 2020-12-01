/******************************************
*MIT License
*
# *Copyright (c) [2020] [Davide Conficconi, Eleonora D'Arnese, Emanuele Del Sozzo, Donatella Sciuto, Marco Domenico Santambrogio]
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
* High-Level-Synthesis testbench file for Mutual Information computation
*
****************************************************************/
#include <iostream>
#include <cmath>
#include <random>
#include <stdio.h>
#include "mutual_info.hpp"


int main(){

   MY_PIXEL ref[DIMENSION * DIMENSION];
   MY_PIXEL flt[DIMENSION * DIMENSION];

   int myseed = 1234;

   std::default_random_engine rng(myseed);
   std::uniform_int_distribution<int> rng_dist(0, MAX_RANGE);

   data_t mihls_0, mihls_1, mihls_2;

   for(int i=0;i<DIMENSION;i++){
      for(int j=0;j<DIMENSION;j++){
         ref[i *DIMENSION + j]=static_cast<unsigned char>(rng_dist(rng));
      }
   }

#ifdef CACHING
   int status = 0;
   printf("Loading image...\n");
   mutual_information_master((INPUT_DATA_TYPE*)ref, &mihls_0, 0, &status);
   printf("Status %d\n", status);
#endif

   for(int i=0;i<DIMENSION;i++){
      for(int j=0;j<DIMENSION;j++){
         flt[i *DIMENSION + j]=static_cast<unsigned char>(rng_dist(rng));
      }
   }


   double j_h[J_HISTO_ROWS][J_HISTO_COLS];
   for(int i=0;i<J_HISTO_ROWS;i++){
      for(int j=0;j<J_HISTO_COLS;j++){
         j_h[i][j]=0.0;
      }
   }


   for(int i=0;i<DIMENSION;i++){
      for(int j=0;j<DIMENSION;j++){
         unsigned int a=ref[i *DIMENSION + j];
         unsigned int b=flt[i *DIMENSION + j];
         j_h[a][b]= (j_h[a][b])+1;
      }
   }

   for (int i=0; i<J_HISTO_ROWS; i++) {
      for (int j=0; j<J_HISTO_COLS; j++) {
         j_h[i][j] = j_h[i][j]/(1.0*DIMENSION*DIMENSION);
      }
   }

   float entropy = 0.0;
   for (int i=0; i<J_HISTO_ROWS; i++) {
      for (int j=0; j<J_HISTO_COLS; j++) {
         float v = j_h[j][i];
         if (v > 0.000000000000001) {
            entropy += v*log2(v);///log(2);
         }
      }
   }
   entropy *= -1;

   double href[ANOTHER_DIMENSION];
   for(int i=0;i<ANOTHER_DIMENSION;i++){
      href[i]=0.0;
   }

   for (int i=0; i<ANOTHER_DIMENSION; i++) {
      for (int j=0; j<ANOTHER_DIMENSION; j++) {
         href[i] += j_h[i][j];
      }
   }

   double hflt[ANOTHER_DIMENSION];
   for(int i=0;i<ANOTHER_DIMENSION;i++){
      hflt[i]=0.0;
   }

   for (int i=0; i<J_HISTO_ROWS; i++) {
      for (int j=0; j<J_HISTO_COLS; j++) {
         hflt[i] += j_h[j][i];
      }
   }


   double eref = 0.0;
   for (int i=0; i<ANOTHER_DIMENSION; i++) {
      if (href[i] > 0.000000000001) {
         eref += href[i] * log2(href[i]);///log(2);
      }
   }
   eref *= -1;


   double eflt = 0.0;
   for (int i=0; i<ANOTHER_DIMENSION; i++) {
      if (hflt[i] > 0.000000000001) {
         eflt += hflt[i] * log2(hflt[i]);///log(2);
      }
   }
   eflt =  eflt * (-1);

   double mutualinfo = eref + eflt - entropy;
   printf("Software MI %lf\n",mutualinfo);

#ifndef CACHING
   mutual_information_master((INPUT_DATA_TYPE*)flt, (INPUT_DATA_TYPE*)ref, &mihls_0);

  printf("First Hardware MI %f\n", mihls_0);

  mutual_information_master((INPUT_DATA_TYPE*)flt, (INPUT_DATA_TYPE*)ref, &mihls_1);
  printf("Second Hardware MI %f\n", mihls_1);
#else
   mutual_information_master((INPUT_DATA_TYPE*)flt, &mihls_0, 1, &status);

   printf("First Hardware MI %f\n", mihls_0);
   printf("Status %d\n", status);

   mutual_information_master((INPUT_DATA_TYPE*)flt, &mihls_1, 1, &status);
   printf("Second Hardware MI %f\n", mihls_1);
   printf("Status %d\n", status);

   mutual_information_master((INPUT_DATA_TYPE*)flt, &mihls_2, 2, &status);
   printf("Status %d\n", status);
#endif

   if(((data_t)mutualinfo - mihls_0 > 0.01) || ((data_t)mutualinfo - mihls_1 > 0.01)){
       return 1;
   }

   return 0;
}


