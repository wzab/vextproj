source proj_def.tcl
open_project $eprj_proj_name/$eprj_proj_name.xpr
# set the current synth run
current_run -synthesis [get_runs synth_1]
# set the current impl run
current_run -implementation [get_runs impl_1]
puts "INFO: Project loaded:$eprj_proj_name"
reset_run synth_1
# Two lines below are the workaround for the problem reported here:
# https://forums.xilinx.com/t5/Synthesis/Vivado-incorrect-automatic-compilation-order-in-OOC-synthesis/td-p/698067
# In fact there should be the list of the OOC runs created by the eprj_create.tcl
# script. At the moment this list is created manually...
#set ooc_runs { lfsr_test_a_synth_1 lfsr_test_b_synth_1 }
#foreach { run } $ooc_runs {
#   reset_run $run
#}
#launch_runs $ooc_runs -jobs 4
#launch_runs synth_1 -scripts_only
#foreach { run } $ooc_runs {
#   set_property NEEDS_REFRESH 0 [get_runs $run]
#}
reset_run synth_1
# End of workaround
launch_runs synth_1 -jobs 4
wait_on_run synth_1
reset_run impl_1
launch_runs impl_1 -jobs 4
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
puts "INFO: Project compiled:$eprj_proj_name"