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

# The project reading procedure operates on objects storing the files
proc eprj_create_block {ablock mode setname } {
    upvar $ablock block    
    #Set the mode of the block
    #may be either IC - in context or OOC - out of context
    set block(mode) $mode
    if [string match -nocase $mode "IC"] {
	# Create 'sources_1' fileset (if not found)
	if {[string equal [get_filesets -quiet sources_1] ""]} {
	    create_fileset -srcset sources_1
	}
	set block(srcset) [get_filesets sources_1]
	# Create 'constrs_1' fileset (if not found)
	if {[string equal [get_filesets -quiet constrs_1] ""]} {
	    create_fileset -constrset constrs_1
	}
	set block(cnstrset) [get_filesets constrs_1]
    } elseif [string match -nocase $mode "OOC"] {
	# We create only a single blkset
	# Create 'setname' fileset (if not found)
	if {[string equal [get_filesets -quiet $setname] ""]} {
	    create_fileset -blockset $setname
	}
	# Both constraints and XDC should be added to the same set
	set block(srcset) [get_filesets $setname]
	set block(cnstrset) [get_filesets $setname]	
    } else {
	error "The block mode must be either IC - in context, or OOC - out of context. The $mode value is unacceptable"
    }
}

#Add file to the sources fileset
proc add_file_sources {ablock pdir fname} {
    upvar $ablock block
    set nfile [file normalize "$pdir/$fname"]
    if {! [file exists $nfile]} {
	error "Requested file $nfile is not available!"
    }
    add_files -norecurse -fileset $block(srcset) $nfile
    set file_obj [get_files -of_objects $block(srcset) $nfile]
    return $file_obj
}

proc handle_xci {ablock pdir line} {
    upvar $ablock block
    #Handle XCI file
    lassign $line lib fname
    set file_obj [add_file_sources block $pdir $fname]
    #set_property "synth_checkpoint_mode" "Singular" $file_obj
    set_property "library" $lib $file_obj
}

proc handle_xci {ablock pdir line} {
    upvar $ablock block
    #Handle XCIX file
    lassign $line lib fname
    set file_obj [add_file_sources block $pdir $fname]
    #set_property "synth_checkpoint_mode" "Singular" $file_obj
    set_property "library" $lib $file_obj
    export_ip_user_files -of_objects  $file_obj -force -quiet
}

proc handle_vhdl {ablock pdir line} {
    upvar $ablock block
    #Handle VHDL file
    lassign $line lib fname
    set file_obj [add_file_sources block $pdir $fname]
    set_property "file_type" "VHDL" $file_obj
    set_property "library" $lib $file_obj
}

proc handle_verilog {ablock pdir line} {
    upvar $ablock block
    #Handle Verilog file
    lassign $line fname
    set file_obj [add_file_sources block $pdir $fname]
    set_property "file_type" "Verilog" $file_obj
}

proc handle_sys_verilog {ablock pdir line} {
    upvar $ablock block
    #Handle SystemVerilog file
    lassign $line fname
    set file_obj [add_file_sources block $pdir $fname]
    set_property "file_type" "SystemVerilog" $file_obj
}

proc handle_verilog_header {ablock pdir line} {
    upvar $ablock block
    #Handle SystemVerilog file
    lassign $line fname
    set file_obj [add_file_sources block $pdir $fname]
    set_property "file_type" "Verilog Header" $file_obj
}

proc handle_global_verilog_header {ablock pdir line} {
    upvar $ablock block
    #Handle Global Verilog Header file
    lassign $line fname
    set file_obj [add_file_sources block $pdir $fname]
    set_property "file_type" "Verilog Header" $file_obj
    set_property is_global_include true $file_obj
}

proc handle_bd {ablock pdir line} {
    upvar $ablock block
    #Handle BD file
    lassign $line fname
    set file_obj [add_file_sources block $pdir $fname]
    if { ![get_property "is_locked" $file_obj] } {
	set_property "generate_synth_checkpoint" "0" $file_obj
    }
}

proc handle_mif {ablock pdir line} {
    upvar $ablock block
    #Handle MIF file
    lassign $line fname
    set file_obj [add_file_sources block $pdir $fname]
    set_property "file_type" "Memory Initialization Files" $file_obj
    set_property "library" $lib $file_obj
    #set_property "synth_checkpoint_mode" "Singular" $file_obj
}

proc handle_xdc {ablock pdir line} {
    upvar $ablock block
    #Handle XDC file
    lassign $line fname
    set nfile [file normalize "$pdir/$fname"]
    if {![file exists $nfile]} {
	error "Requested file $nfile is not available!"
    }
    add_files -norecurse -fileset $block(cnstrset) $nfile
    set file_obj [get_files -of_objects $block(cnstrset) $nfile]
    set_property "file_type" "XDC" $file_obj
}	

proc handle_xdc_ooc {ablock pdir line} {
    upvar $ablock block
    #Handle XDC_OOC file
    lassign $line fname
    set nfile [file normalize "$pdir/$fname"]
    if {![file exists $nfile]} {
	error "Requested file $nfile is not available!"
    }
    if {![string match -nocase $block(mode) "OOC"]} {
	puts "Ignored file $nfile in IC mode"
    } else {
	add_files -norecurse -fileset $block(cnstrset) $nfile
	set file_obj [get_files -of_objects $block(cnstrset) $nfile]
	set_property "file_type" "XDC" $file_obj
    }	
}

proc handle_exec {ablock pdir line} {
    upvar $ablock block
    #Handle EXEC line
    lassign $line fname
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

#Line handling procedure
proc handle_line { ablock pdir line } {
    upvar $ablock block
    set rest [lassign $line type]
    switch [string tolower $type] {
	
	xci { handle_xci block $pdir $rest}
	xcix { handle_xcix block $pdir $rest}
	header { handle_header block $pdir $rest}
        global_header { handle_global_header block $pdir $rest}
	sys_verilog { handle_sys_verilog block $pdir $rest}
	verilog { handle_verilog block $pdir $rest}
	mif { handle_mif block $pdir $rest}
	bd { handle_bd block $pdir $rest}
	vhdl { handle_vhdl block $pdir $rest}

	xdc { handle_xdc block $pdir $rest}
	xdc_ooc { handle_xdc_ooc block $pdir $rest}
	exec { handle_exec block $pdir $rest}
	default {
	    error "Unknown line of type: $type"
	}
    }    
}

# Prepare the main block
array set main_block {}
eprj_create_block main_block "IC" ""

# Procedure below reads the source files from PRJ files, extended with
# the "include file" statement
#Important thing - path to the source files should be given relatively
#to the location of the PRJ file.
proc read_prj { ablock prj } {
    upvar $ablock block
    parray block
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
		#Detect the inlude line and ooc line
		lassign $line type fname
		if {[string match -nocase $type "include"]} {
                    puts "\tIncluding PRJ file: $prj_dir/$fname"
		    read_prj block $prj_dir/$fname 
		} elseif {[string match -nocase $type "ooc"]} {
		    lassign $line type fname blksetname
		    #Create the new block of type OOC and continue parsing in it
		    array set ooc_block {}
		    eprj_create_block ooc_block "OOC" $blksetname
		    read_prj $ooc_block $prj_dir/$fname
		    set_property TOP $blksetname [get_filesets $blksetname]
		    update_compile_order -fileset $blksetname
		} else {
		    handle_line block $prj_dir $line
		}
	    }
	}
    } else {
      error "Requested file $prj is not available!"
    }
}


# Read project definitions
read_prj main_block $eprj_def_root 
set_property "top" $eprj_top_entity  $main_block(srcset)
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
