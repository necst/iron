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


set proj_name      [lindex $argv 2]
set src_dir          [lindex $argv 3]
set tb_file [lindex $argv 4]
set proj_part      [lindex $argv 5]
set clk      [lindex $argv 6]
set toplevel    [lindex $argv 7]
set incldirs       [lindex $argv 8]
set steps [lindex $argv 9]
set hlsinclude [lindex $argv 10]

if {$steps == 0} {
    set opts "PRJ"
}
if {$steps == 1} {
    set opts "SIM"
}
if {$steps == 2} {
    set opts "SYNTH"
}
if {$steps == 3} {
    set opts "COSIM"
}
if {$steps == 4} {
    set opts "IP EXPORT"
}
if {$steps == 5} {
    set opts "SYNTH and IP"
}
if {$steps == 6} {
    set opts "IP EXPORT and place and route"
}

if {$steps == 7} {
    set opts "SIM SYNTH COSIM"
}

set sdx 0
puts ""
puts ""
puts ""
puts "***************************************************************"
puts ""
puts "    \[INFO\] HLS project: $proj_name"
puts "    \[INFO\] HLS sources files: $src_dir"
puts "    \[INFO\] Target platform: $proj_part"
puts "    \[INFO\] Clock period: $clk ns"
puts "    \[INFO\] Top level function: $toplevel"
puts "    \[INFO\] Include directories: $incldirs"
puts "    \[INFO\] HLS options: $steps, $opts"
puts "    \[INFO\] HLS includes locations $hlsinclude"
puts ""
puts "***************************************************************"
puts ""
puts ""
puts ""
puts ""
open_project $proj_name
set_top $toplevel
add_files $src_dir 
#-cflags "-std=c++11 -I$incldirs -I$hlsinclude"
puts "add_files $src_dir -cflags \"-std=c++11 -I$incldirs -I$hlsinclude\""
add_files -tb $tb_file
open_solution "solution1"
set_part $proj_part
create_clock -period $clk -name default

if {$sdx == 1} {
    config_sdx -optimization_level none -target xocc
}
if {$steps == 1} {
    csim_design -clean
}
if {$steps == 2} {
    csynth_design
}
if {$steps == 3} {
    cosim_design
}
if {$steps == 4} {
    export_design -rtl verilog -format ip_catalog
}
if {$steps == 5} {
    csynth_design
    export_design -rtl verilog -format ip_catalog
}
if {$steps == 6} {
    export_design -flow impl -rtl verilog -format ip_catalog
}
if {$steps == 7} {
    csim_design -clean
    csynth_design
    cosim_design
}
close_project
exit 0
