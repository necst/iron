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

if {$argc != 4} {
  puts "Expected: <project_to_synthesize> <prj_dir> <prj_name> <top>"
  exit
}

set prj_dir [lindex $argv 1]
set prj_name [lindex $argv 2]
set top [lindex $argv 3]


open_project [lindex $argv 0]
launch_runs synth_1 -jobs 2
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1


set vvd_version [version -short]
set vvd_version_split [split $vvd_version "."]
set vvd_vers_year [lindex $vvd_version_split 0]
if {$vvd_vers_year < 2019} {
	file copy -force $prj_dir/$prj_name.runs/impl_1/$top.sysdef $prj_dir/$top.hdf
} else {
	write_hw_platform -fixed -force  -include_bit -file $prj_dir/$top.xsa
}

