# Script prepared by Wojciech M. Zabolotny (wzab<at>ise.pw.edu.pl) to
# create a Vivado project from the hierarchical list of files
# (extended project files).
# This files are published as PUBLIC DOMAIN
# 
# Source the project settings
source proj_def.tcl
# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Check the Vivado version
set viv_version [ version -short ]
set ver_cmp_res [ string compare $viv_version $eprj_vivado_version ]
if { $eprj_vivado_version_allow_upgrade } {
    if [ expr $ver_cmp_res < 0 ] {
	error "Wrong Vivado version. Expected: $eprj_vivado_version or higher, found $viv_version"
    }
} else {
    if [ expr $ver_cmp_res != 0 ] {
	error "Wrong Vivado version. Expected: $eprj_vivado_version , found $viv_version"
    }
}
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

# Create the global variable which will keep the list of the OOC synthesis runs
global vextproj_ooc_synth_runs
set vextproj_ooc_synth_runs [list ]

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

proc handle_xcix {ablock pdir line} {
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
    lassign $line lib fname
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
	set_property USED_IN {out_of_context synthesis implementation} $file_obj
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

# Handlers for VCS systems
proc handle_git_local {ablock pdir line} {
    upvar $ablock block
    lassign $line clone_dir commit_or_tag_id exported_dir strip_num
    set old_dir [ pwd ]
    cd $pdir
    file delete -force -- "ext_src"
    file mkdir "ext_src"
    #Prepare the git command
    set strip_cmd ""
    if { $strip_num ne ""} {
	append strip_cmd " --strip-components=$strip_num"
    }
    set git_cmd "( cd $clone_dir ; git archive --format tar $commit_or_tag_id $exported_dir ) | ( cd ext_src ; tar -xf - $strip_cmd )"
    exec bash -c "$git_cmd"
    cd $old_dir
}

proc handle_git_remote {ablock pdir line} {
    upvar $ablock block
    lassign $line repository_url tag_id exported_dir strip_num
    set old_dir [ pwd ]
    cd $pdir
    file delete -force -- "ext_src"
    file mkdir "ext_src"
    #Prepare the git command
    set strip_cmd ""
    if { $strip_num ne ""} {
	append strip_cmd " --strip-components=$strip_num"
    }
    set git_cmd "( git archive --format tar --remote $repository_url $tag_id $exported_dir ) | ( cd ext_src ; tar -xf - $strip_cmd )"
    exec bash -c "$git_cmd"
    cd $old_dir
}

proc handle_svn {ablock pdir line} {
    upvar $ablock block
    lassign $line repository_with_path revision
    set old_dir [ pwd ]
    cd $pdir
    file delete -force -- "ext_src"
    file mkdir "ext_src"
    #Prepare the SVN command
    set rev_cmd ""
    if { $revision ne ""} {
	append rev_cmd " -r $revision"
    }
    set svn_cmd "( cd ext_src ; svn export $rev_cmd $repository_with_path )"
    exec bash -c "$svn_cmd"
    cd $old_dir
}


#Line handling procedure
proc handle_line { ablock pdir line } {
    upvar $ablock block
    set rest [lassign $line type]
    switch [string tolower $type] {
	
	xci { handle_xci block $pdir $rest}
	xcix { handle_xcix block $pdir $rest}
	header { handle_verilog_header block $pdir $rest}
        global_header { handle_global_verilog_header block $pdir $rest}
	sys_verilog { handle_sys_verilog block $pdir $rest}
	verilog { handle_verilog block $pdir $rest}
	mif { handle_mif block $pdir $rest}
	bd { handle_bd block $pdir $rest}
	vhdl { handle_vhdl block $pdir $rest}

	xdc { handle_xdc block $pdir $rest}
	xdc_ooc { handle_xdc_ooc block $pdir $rest}
	exec { handle_exec block $pdir $rest}
	git_local {handle_git_local block $pdir $rest}
	git_remote {handle_git_remote block $pdir $rest}
	svn {handle_svn block $pdir $rest}
	default {
	    error "Unknown line of type: $type"
	}
    }    
}

proc handle_ooc { ablock pdir line } {
    global eprj_impl_strategy
    global eprj_impl_flow
    global eprj_synth_strategy
    global eprj_synth_flow
    global eprj_flow
    global eprj_part
    global vextproj_ooc_synth_runs

    upvar $ablock block
    lassign $line type stub fname blksetname
    #Create the new block of type OOC and continue parsing in it
    array set ooc_block {}
    eprj_create_block ooc_block "OOC" $blksetname
    if {[string match -nocase $stub "noauto"]} {
	set_property "use_blackbox_stub" "0" [get_filesets $blksetname]
    } elseif {![string match -nocase $stub "auto"]} {
	error "OOC stub creation mode must be either 'auto' or 'noauto' not: $stub"
    }
    read_prj ooc_block $pdir/$fname
    set_property TOP $blksetname [get_filesets $blksetname]
    update_compile_order -fileset $blksetname
    #Create synthesis run for the blockset (if not found)
    set ooc_synth_run_name ${blksetname}_synth_1
    if {[string equal [get_runs -quiet ${ooc_synth_run_name}] ""]} {
	create_run -name ${ooc_synth_run_name} -part $eprj_part -flow {$eprj_flow} -strategy $eprj_synth_strategy -constrset $blksetname
    } else {
	set_property strategy $eprj_synth_strategy [get_runs ${ooc_synth_run_name}]
	set_property flow $eprj_synth_flow [get_runs ${ooc_synth_run_name}]
    }
    lappend vextproj_ooc_synth_runs ${ooc_synth_run_name}
    set_property constrset $blksetname [get_runs ${ooc_synth_run_name}]
    set_property part $eprj_part [get_runs ${ooc_synth_run_name}]
    # Create implementation run for the blockset (if not found)
    set ooc_impl_run_name ${blksetname}_impl_1
    if {[string equal [get_runs -quiet ${ooc_impl_run_name}] ""]} {
	create_run -name impl_1 -part $eprj_part -flow {$eprj_flow} -strategy $eprj_impl_strategy -constrset $blksetname -parent_run ${ooc_synth_run_name}
    } else {
	set_property strategy $eprj_impl_strategy [get_runs ${ooc_impl_run_name}]
	set_property flow $eprj_impl_flow [get_runs ${ooc_impl_run_name}]
    }
    set_property constrset $blksetname [get_runs ${ooc_impl_run_name}]
    set_property part $eprj_part [get_runs ${ooc_impl_run_name}]
    set_property include_in_archive "0" [get_runs ${ooc_impl_run_name}]
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
		    handle_ooc block $prj_dir $line
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

# Write the list of the OOC synthesis runs to the file
set file_ooc_runs [open "ooc_synth_runs.txt" "w"]
puts $file_ooc_runs $vextproj_ooc_synth_runs
close $file_ooc_runs

puts "INFO: Project created:$eprj_proj_name"
#launch_runs synth_1
#wait_on_run synth_1
#launch_runs impl_1
#wait_on_run impl_1
#launch_runs impl_1 -to_step write_bitstream
#wait_on_run impl_1

