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


SCRIPTS_DEBUG=
#define this to enable debug prints

print_log "$@" $SCRIPTS_DEBUG
for i in "$@"
do
case $i in
    -cf=*|--config_fldr=*)
    config_fldr="${i#*=}"
    shift
    ;;
    -pb=*|--prep_bitstream=*)
    prep_bitstream="${i#*=}"
    shift
    ;;
    -v=*|--vitis=*)
    vitis="${i#*=}"
    shift
    ;;
    -tp=*|--trgt_platform=*)
    trgt_platform="${i#*=}"
    shift
    ;;
    -fe=*|--first_exe=*)
    first_exe="${i#*=}"
    shift
    ;;
    -fm=*|--freq_mhz=*)
    FREQ_MHZ="${i#*=}"
    shift
    ;;
    --default)
    DEFAULT=YES
    shift
    ;;
    *)
          # unknown option
    ;;
esac
done

if [ -z "$FREQ_MHZ" ]
then
    trgt_period=10
    print_log "Not setted FREQ_MHZ" $SCRIPTS_DEBUG
else
    trgt_period=$(python3 -c "print((1 / $FREQ_MHZ)*1000)")
    print_log "Setting Frequency to $FREQ_MHZ" $SCRIPTS_DEBUG
fi
prj_fldr="iron-vivado"
prj_name="iron-vivado"
dseign_name="iron_wrapper"


print_log "current params are: $1 $2 $3 $4 $5 $6" $SCRIPTS_DEBUG
print_log "config folder $config_fldr" $SCRIPTS_DEBUG
print_log "prep bits $prep_bitstream" $SCRIPTS_DEBUG
print_log "vitis $vitis" $SCRIPTS_DEBUG
print_log "trgt $trgt_platform" $SCRIPTS_DEBUG
platform=$trgt_platform
print_log "first exe $first_exe" $SCRIPTS_DEBUG
print_log "freq mhz $FREQ_MHZ" $SCRIPTS_DEBUG


bitfilefldr=""
arrconfig=(${config_fldr//_/,}); 
config_separation=(${config_fldr//_/}); 

config=$arrconfig
cfile_name="config_res_"
config_as_fldr=$config_fldr
config_fldr_regex="[0-9]-512-8-((float)|(fixed))-[0-9]+-[0-9]+-((true|false))-((true|false))"
print_log "$config_as_fldr and $config_fldr_regex" $SCRIPTS_DEBUG

if [ -d $config_fldr ]; 
    then 
        if [[ $config_as_fldr =~ $config_fldr_regex ]] ; 
        then 
            print_log $i $SCRIPTS_DEBUG;
            #conf_asfldr_array=(${config_as_fldr//_/ });
            conf_asfldr_array=(${config_as_fldr//-/ });
            cachings="";
            urams="";
            hpe="${conf_asfldr_array[4]}";
            epe="${conf_asfldr_array[5]}";
            datatype="FLT";
            #3 flt o fx
            if [ ${conf_asfldr_array[3]} == "fixed" ];
            then
                datatype="FX";
            fi;
            #4 hpe
            #5 epe
            if [ ${conf_asfldr_array[8]} == "true" ];
            then
                cachings="C";
                if [ ${conf_asfldr_array[9]} == "true" ];
                then
                    urams="U";
                fi;
            fi;
            #8 caching
            #9 uram

            config_paper="${conf_asfldr_array[0]}$cachings$urams$datatype-$hpe-$epe-${conf_asfldr_array[7]}"
            print_log $config_paper $SCRIPTS_DEBUG
        else 
            echo "$config_fldr not a config fldr"; 
            exit
        fi;  
    else 
        echo "$config_fldr not a folder";
        exit
fi;


if [ "$vitis" == true ]
then
    print_log "yeah Vitis" $SCRIPTS_DEBUG
    platform="xilinx_u200_xdma_201830_2"
    kernel_name="mutual_information_master"
    clock_file=./${config_fldr}/hw/${platform}/link/v++_link_${kernel_name}_guidance.html
    res_file=./${config_fldr}/hw/${platform}/link/imp/kernel_util_placed.rpt

bitfilefldr="xclbin_alveo_"

    if [ -f "$clock_file" ]
    then
          print_log "$config_as_fldr has a timing file :D" $SCRIPTS_DEBUG
    else
        echo "$config_as_fldr does not have a timing file" 
        exit
    fi
    if [ -f "$res_file" ]
    then
          print_log "$config_as_fldr has a placed and routed design" $SCRIPTS_DEBUG
    else
        echo "$config_as_fldr does not have a placed and routed design"
        exit
    fi
    clk_freq_mhz=$(cat $clock_file | grep MHz | grep "clkwiz_kernel_clk_out1 =" | sed "s/.*= //" | sed "s/ MHz//")
    resources=$(cat $res_file | grep "Used Resources" | sed "s/|\s*Used Resources\s*|\s*//" | sed -e "s/[][]//g" | sed "s/%\s|//g" | sed "s/\s\{1,5\}/,/g")

    if [ "$first_exe" == true ] || [ ! -f "${cfile_name}${trgt_platform}.csv" ]
    then
        echo -en "Config,FMHz,LUT,LUT%,LUTAsMem,LUTAsMem%,REG,REG%,BRAM,BRAM%,URAM,URAM%,DSP,DSP%\n" > ${cfile_name}${trgt_platform}.csv

    fi 
    echo -en "$config_paper,$clk_freq_mhz,$resources\n" >> ${cfile_name}${trgt_platform}.csv
    config_array=(${config_fldr//_/ });

#end vitis
else


bitfilefldr="bitstream_"

    print_log "is more a zynq :D" $SCRIPTS_DEBUG

    timing_file=./${config_fldr}/${prj_fldr}/${prj_name}.runs/impl_1/${dseign_name}_timing_summary_postroute_physopted.rpt
    util_file=./${config_fldr}/${prj_fldr}/${prj_name}.runs/impl_1/${dseign_name}_utilization_placed.rpt


    if [ -f "$timing_file" ]
    then
          print_log "$config is here :D" $SCRIPTS_DEBUG
    else
        echo "No timing postroute file"
        exit
    fi
    prova=($(cat ${timing_file} | grep "Slack" | cut -d":" -f 2 | sed "s/\(\ \)*//"))

    slack_ns=${prova[5]/ns,/ }
    slack_ns_dot=${slack_ns/./,}

    final_period=$(python3 -c "print($trgt_period - $slack_ns)")

    clk_freq_mhz=$(python3 -c "print((1 / $final_period)*1000)")
    CLB=$(cat $util_file | grep "Slice LUTs" | sed "s/ *$//" | sed "s/|\s* Slice LUTs\s*|\s*//" | sed "s/|\s*0 |\s* [0-9]*\s*|\s*//" | sed "s/ |//"| sed "s/\s/,/")

    #if zynq MPSoC
    if [ -z "$CLB" ]
    then

    CLB=$(cat $util_file | grep "CLB LUTs" | sed "s/ *$//" | sed "s/|\s* CLB LUTs\s*|\s*//" | sed "s/|\s*0 |\s* [0-9]*\s*|\s*//" | sed "s/ |//"| sed "s/\s/,/")

    fi

    FF=$(cat $util_file | grep "Slice Registers" | head -1 | sed "s/ *$//" | sed "s/| \s*Slice Registers \s*|\s*//" | sed "s/|\s*0 |\s* [0-9]*\s*|\s*//" | sed "s/ |//" | sed "s/\s/,/")

    #if zynq MPSoC
    if [ -z "$FF" ]
    then

    FF=$(cat $util_file | grep "CLB Registers" | head -1 | sed "s/ *$//" | sed "s/| \s*CLB Registers \s*|\s*//" | sed "s/|\s*0 |\s* [0-9]*\s*|\s*//" | sed "s/ |//" | sed "s/\s/,/")

    fi

    BRAM=$(cat $util_file | grep "Block RAM Tile" | head -1 | sed "s/ *$//" | sed "s/| Block RAM Tile\s*|\s*//" | sed "s/|\s*0 |\s* [0-9]*\s*|\s*//" | sed "s/ |//" | sed "s/\s/,/")


    DSP=$(cat $util_file | grep "DSPs" | head -1 | sed "s/ *$//" | sed "s/| DSPs\s*|\s*//" | sed "s/|\s*0 |\s* [0-9]*\s*|\s*//" | sed "s/ |//" | sed "s/\s/,/")


    URAM=$(cat $util_file | grep "URAM" | head -1 | sed "s/ *$//" | sed "s/| URAM\s*|\s*//" | sed "s/|\s*0 |\s* [0-9]*\s*|\s*//" | sed "s/ |//" | sed "s/\s/,/")

    if [ "$first_exe" == true ] || [ ! -f "${cfile_name}${trgt_platform}.csv" ]
    then 
        echo -en "Configuration,Freq_mhz,CLB,CLB%,FF,FF%,BRAM,BRAM%,DSP,DSP%,URAM,URAM%\n" > ${cfile_name}${trgt_platform}.csv
    fi
    echo -en "$config_paper,$clk_freq_mhz,$CLB,$FF,$BRAM,$DSP,$URAM\n" >> ${cfile_name}${trgt_platform}.csv



fi
#end if vitis

print_log "check if need to prepare" $SCRIPTS_DEBUG


conf_list=(CORE_NR D IB HT PE PE_ENTROP BV ACC_SZ CACHING URAM CODE_VERS)

if [ "$prep_bitstream" == true ]
then
if [ "$vitis" == true ] 
then

xclbin_file=./${config_fldr}/hw/${platform}/${kernel_name}.xclbin


if [ -f "$xclbin_file" ]
then
      print_log "there is an xclbin!" $SCRIPTS_DEBUG
else
    echo "there is NO xclbin :("
    exit
fi
mkdir -p ../${bitfilefldr}${trgt_platform}/${config_fldr}
cp -R $xclbin_file  ../${bitfilefldr}${trgt_platform}/${config_fldr}/

else #vitis

    bitstream_file=./${config_fldr}/${prj_fldr}/${prj_name}.runs/impl_1/${dseign_name}.bit
    deploy_dir=./${config_fldr}/deploy

    config_array=(${config_fldr//_/ });

    if [ -d "$deploy_dir" ]
    then
          print_log "there is already a deploy dir is here :D" $SCRIPTS_DEBUG
    else
        conf_mk=(); 
        k=0; 
        for j in ${config_array[@]}; 
        do 
            tmp1="${conf_list[$k]}=$j"; 
            print_log $tmp1 $SCRIPTS_DEBUG;
            conf_mk+=($tmp1); 
            ((k=k+1));
        done; 
        print_log "reading the conf_mk" $SCRIPTS_DEBUG;  
        print_log ${conf_mk[@]} $SCRIPTS_DEBUG;
        print_log ${config_array} $SCRIPTS_DEBUG; 
        cd ../../; make hw_pre ${conf_mk[@]} TRGT_PLATFORM=$platform; cd -
    fi
    mkdir -p ../${bitfilefldr}${platform}/${config_fldr}
    cp -R $deploy_dir/  ../${bitfilefldr}${platform}/${config_fldr}/
fi #vitis
fi #prep_bitstream
