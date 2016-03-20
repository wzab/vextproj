source proj_def.tcl
open_project $eprj_proj_name/$eprj_proj_name.xpr
# set the current synth run
current_run -synthesis [get_runs synth_1]
# set the current impl run
current_run -implementation [get_runs impl_1]
puts "INFO: Project loaded:$eprj_proj_name"
reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
reset_run impl_1
launch_runs impl_1
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
puts "INFO: Project compiled:$eprj_proj_name"
