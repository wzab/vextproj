# Script prepared by Wojciech M. Zabolotny (wzab<at>ise.pw.edu.pl) to
# create a Vivado project from the hierarchical list of files
# (extended project files).
# This files are published as PUBLIC DOMAIN
# 
# Source the project settings
source proj_def.tcl
# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Create project
create_project $eprj_proj_name ./$eprj_proj_name

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects $eprj_proj_name]
set_property "board_part" $eprj_board_part $obj
set_property "part" $eprj_part $obj
set_property "default_lib" $eprj_default_lib $obj
set_property "simulator_language" $eprj_simulator_language $obj
set_property "target_language" $eprj_target_language $obj

# Procedure below reads the source files from PRJ files, extended with
# the "include file" statement

#Important thing - path to the source files should be given relatively
#to the location of the PRJ file.
proc read_prj { prj } {
    #initialize results to an empty list
    set res []
    #allow to use just the directory names. In this case add
    #the "/main.eprj" to it
    if {[file isdirectory $prj]} {
       append prj "/main.eprj"
       puts "Added default main.eprj to the directory name: $prj"
    }
    if {[file exists $prj]} {
	puts "\tReading PRJ file: $prj"
	set source [open $prj r]
	set source_data [read $source]
	close $source
	#Extract the directory of the PRJ file, as all paths to the
	#source files must be given relatively to that directory
	set prj_dir [ file dirname $prj ]
	regsub -all {\"} $source_data {} source_data
	set prj_lines [split $source_data "\n" ]
	set line_count 0
	foreach line $prj_lines {
	    incr line_count
	    #Ignore empty and commented lines
	    if {[llength $line] > 0 && ![string match -nocase "#*" $line]} {
		#Detect the inlude line
		lassign $line type fname
		if {[string match -nocase $type "include"]} {
                    puts "\tIncluding PRJ file: $prj_dir/$fname"
		    set inc [ read_prj $prj_dir/$fname ]
		    foreach l $inc {
			lappend res $l
		    }
		} else {
		    lappend res [linsert $line 0 $prj_dir] 
		}
	    }
	}
    } else {
      error "Requested file $prj is not available!"
    }
    return $res
}


# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
set sobj [get_filesets sources_1]

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set cobj [get_filesets constrs_1]
# Read project definitions
set prj_lines [ read_prj $eprj_def_root ]
foreach line $prj_lines {
    # Just read the type
    puts $line
    lassign $line pdir type lib fname
    # Handle the source files
    if { \
	     [string match -nocase $type "xci"]  || \
	     [string match -nocase $type "xcix"]  || \
	     [string match -nocase $type "header"]  || \
	     [string match -nocase $type "global_header"]  || \
	     [string match -nocase $type "sys_verilog"]  || \
	     [string match -nocase $type "verilog"] || \
	     [string match -nocase $type "mif"] || \
	     [string match -nocase $type "bd"] || \
	     [string match -nocase $type "vhdl"]} {
	    
	set nfile [file normalize "$pdir/$fname"]
        if {! [file exists $nfile]} {
           error "Requested file $nfile is not available!"
        }
	add_files -norecurse -fileset $sobj $nfile
	set file_obj [get_files -of_objects $sobj $nfile]
	#Handle VHDL file
	if {[string match -nocase $type "vhdl"]} {
	    set_property "file_type" "VHDL" $file_obj
	    set_property "library" $lib $file_obj
	}
	#Handle Verilog file
	if {[string match -nocase $type "verilog"]} {
	    set_property "file_type" "Verilog" $file_obj
	    set_property "library" $lib $file_obj
	}
	#Handle SystemVerilog file
	if {[string match -nocase $type "sys_verilog"]} {
	    set_property "file_type" "SystemVerilog" $file_obj
	}
	#Handle Verilog header file
	if {[string match -nocase $type "header"]} {
	    set_property "file_type" "Verilog Header" $file_obj
	}
	#Handle global Verilog header file
	if {[string match -nocase $type "global_header"]} {
	    set_property "file_type" "Verilog Header" $file_obj
	    set_property is_global_include true $file_obj
	}
	#Handle XCI file
	if {[string match -nocase $type "xci"]} {
	    #set_property "synth_checkpoint_mode" "Singular" $file_obj
	    set_property "library" $lib $file_obj
	}
	#Handle XCIX file
	if {[string match -nocase $type "xcix"]} {
	    #set_property "synth_checkpoint_mode" "Singular" $file_obj
	    set_property "library" $lib $file_obj
            export_ip_user_files -of_objects  $file_obj -force -quiet
	}
	#Handle BD file
	if {[string match -nocase $type "bd"]} {
	   if { ![get_property "is_locked" $file_obj] } {
	      set_property "generate_synth_checkpoint" "0" $file_obj
	    }
	}
	#Handle MIF file
	if {[string match -nocase $type "mif"]} {
            set_property "file_type" "Memory Initialization Files" $file_obj
	    set_property "library" $lib $file_obj
	    #set_property "synth_checkpoint_mode" "Singular" $file_obj
	}
    }
    if { [string match -nocase $type "xdc"]} {
	set nfile [file normalize "$pdir/$fname"]
        if {![file exists $nfile]} {
           error "Requested file $nfile is not available!"
        }
	add_files -norecurse -fileset $cobj $nfile
	set file_obj [get_files -of_objects $cobj $nfile]
	set_property "file_type" "XDC" $file_obj
    }	
    if { [string match -nocase $type "exec"]} {
	set nfile [file normalize "$pdir/$fname"]
        if {![file exists $nfile]} {
           error "Requested file $nfile is not available!"
        }
        #Execute the program in its directory
        set old_dir [ pwd ]
        cd $pdir
	exec "./$fname"
        cd $old_dir
    }	
}
set_property "top" $eprj_top_entity $sobj
update_compile_order -fileset sources_1
# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part $eprj_part -flow {$eprj_flow} -strategy $eprj_synth_strategy -constrset constrs_1
} else {
  set_property strategy $eprj_synth_strategy [get_runs synth_1]
  set_property flow $eprj_synth_flow [get_runs synth_1]
}
set obj [get_runs synth_1]

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part $eprj_part -flow {$eprj_flow} -strategy $eprj_impl_strategy -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy $eprj_impl_strategy [get_runs impl_1]
  set_property flow $eprj_impl_flow [get_runs impl_1]
}
set obj [get_runs impl_1]

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:$eprj_proj_name"
#launch_runs synth_1
#wait_on_run synth_1
#launch_runs impl_1
#wait_on_run impl_1
#launch_runs impl_1 -to_step write_bitstream
#wait_on_run impl_1

