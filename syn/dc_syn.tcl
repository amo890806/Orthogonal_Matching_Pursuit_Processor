#Read All Files
read_file -format verilog ../src/OMP.v
current_design OMP
link

#Setting Clock Constraints
source -echo -verbose OMP.sdc
check_design
uniquify
set_fix_multiple_port_nets  -all -buffer_constants

compile -map_effort high -area_effort high

write -format ddc     -hierarchy -output "OMP_syn.ddc"
write_sdf -version 1.0  OMP_syn.sdf
write -format verilog -hierarchy -output OMP_syn.v
report_area -hierarchy > area.log
report_timing > timing.log
report_cell [get_cells -hier *] > cell.log
report_power -analysis_effort high -verbose > power.log
report_qor   >  OMP_syn.qor
