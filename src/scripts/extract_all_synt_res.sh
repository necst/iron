#!/bin/bash

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
print_log(){
    MSG=$1
    SCRIPTS_DEBUG=$2
    if [ "$SCRIPTS_DEBUG" == true ];
    then
        echo $MSG
    fi
}

TRGT_PLATFORM=$1
VITIS=$2
PREPARE_BITSTREAMS=$3
FREQ_MHZ=$4

SCRIPTS_DEBUG=
#define this to enable debug prints
echo "Starting to extract all synthesis results and bitstreams"
cp src/scripts/extra_synt_res.sh build/$TRGT_PLATFORM/
cd build/$TRGT_PLATFORM 
all_builds=$(ls)

minus_one_build=();
for i in $all_builds;
do minus_one_build+=("$i");
done;

print_log ${minus_one_build[0]} $SCRIPTS_DEBUG


./extra_synt_res.sh --config_fldr=${minus_one_build[0]} -pb=$PREPARE_BITSTREAMS -v=$VITIS -tp=$TRGT_PLATFORM -fe=true -fm=$FREQ_MHZ
print_log "first done" $SCRIPTS_DEBUG

for j in ${minus_one_build[@]:1};
do
	print_log $j  $SCRIPTS_DEBUG
	./extra_synt_res.sh --config_fldr=$j -pb=$PREPARE_BITSTREAMS -v=$VITIS -tp=$TRGT_PLATFORM -fe=false -fm=$FREQ_MHZ

done
echo "done"
cd -


