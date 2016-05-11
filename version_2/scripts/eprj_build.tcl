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
reset_run lfsr_test_a_synth_1
reset_run lfsr_test_b_synth_1
launch_runs lfsr_test_b_synth_1 lfsr_test_a_synth_1 -jobs 4
launch_runs synth_1 -scripts_only
set_property NEEDS_REFRESH 0 [get_runs lfsr_test_b_synth_1]
set_property NEEDS_REFRESH 0 [get_runs lfsr_test_a_synth_1]
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
