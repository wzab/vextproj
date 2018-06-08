# vextproj
This is repository for a project allowing to create Vivado projects with complex hierarchy of sources from simple, VCS friendly set of files. The project is published under the CC0 Creative Commons license as PUBLIC DOMAIN.

The approach is based on "extended project files" (eprj).
Each eprj file contains lines which describe single source file or a directory, which may contain other source files or directories.
For operation with VCS (especially GIT) it is important, that you can build a hierarchy of nested IP blocks, while 
having the flat structure of directories (one directory for each reusable component, all at the same level).
This allows to avoid using of submodules.
The VEXTPROJ environment is also described in my paper: [Version control friendly project management system for FPGA designs](http://doi.org/10.1117/12.2247944).

*Important remark:*

*Vextproj is intended to be used on Linux machines. I've successfully bult a simple demo (version\_2/demo\_wb/hdl) on a Windows machine, but the VCS related lines and "exec" line probably won't work on a Windows machine. I'm sorry, but I simply don't use Windows for serious FPGA development.*

# EPRJ file format
The description below describes the format used by the version 2 of the environment, which supports OOC compilation
of selected parts of the design.
This version is available in the "version_2" directory

The EPRJ file may contain the following lines:
* xci library file\_name

  This line adds the XCI file to the project
* xcix library file\_name

  This line adds the XCIX file to the project
* header file\_name

  This line adds the Verilog header file to the project
* global\_header file\_name

  This line adds the global Verilog header to the project
* sys\_verilog file\_name
 
  This line adds the System Verilog source to the project
*	verilog file\_name

  This line adds the Verilog source to the project
*	mif file\_name

  This line adds the MIF file to the project
  
* bd file\_name [ top ]
 
  This line adds the Block Design component to the project. Additional keyword "top" should be added
  if the component should be the top entity.
  
* ip directory\_name

  This line adds a directory with user IP repository to the list of IP repositories in the project

*	vhdl library file\_name

  This line adds the VHDL file to the specified library in the project

*	xdc file\_name

  This line adds the XDC constraints file to the project

*	xdc_ooc file\_name

  This line adds the XDC OOC constraints file to the project (only to the blocks selected for OOC synthesis)
  
*	prop property\_name property\_value

  This line sets the particular property of the last source or constraints file to the given value

*	propadd property\_name property\_value

  This line adds the given value to the list of values of the particular property of the last source or constraints file

  It is possible to use multiple "prop" or "propadd" lines in sequence below the source or constraints file

*	exec file\_name
	
  This line requests execution of the script. The script is executed in its directory. This line may be a security risk, but it is not more dangerous, than a simple Makefile...

Additionally there are two lines with special meaning:

* include directory\_path or eprj\_file\_path
 
 This line includes components, constraints and other items described by another EPRJ file. The paths may be absolute, but usually they are relative to the directory of the currently processed EPRJ file. If the directory\_path is specified, then the main.eprj is added at the end. Otherwise the full name of the included EPRJ file should be given.

* ooc stub file\_name blk\_top\_entity
 
  This line specifies that the block defined by the file\_name EPRJ file should be compiled Out-of-context (OOC). The stub field may be set to "auto" - informing that the stub should be generated automatically by the Vivado, or to "noauto" - informing, that the stub is provided in sources. The latter should be used if the OOC block uses ports with user defined types (e.g., the VHDL records). The blk\_top\_entity field should be the name of the top entity of the OOC-block. It will be also used as the name of the created fileset.

  Please note, that the stubs must be included in the appropriate EPRJ file. The important fact is, that the VHDL stubs must be put into the _xil\_defaultlib_ directory (at least for Vivado 2016.1). Otherwise Vivado does not recognize them as stubs.
  Below is an example of definition of two OOC blocks together with inclusion of their stubs:
  ```
  ooc noauto lfsr_test_a_ooc.eprj lfsr_test_a
  vhdl xil_defaultlib lfsr_test_a_stub.vhd
  ooc noauto lfsr_test_b_ooc.eprj lfsr_test_b
  vhdl xil_defaultlib lfsr_test_b_stub.vhd
  ```

The newest version supports also sources exported from Version Control System (VCS) repositories. There are three commands allowing to import sources from GIT or SVN repositories:

1. git\_remote repository\_url tag\_name [exported\_directory [stripped\_comp\_num]]

 That command downloads the whole tree or the subtree defined by the exported_directory (e.g., "rtl/module_1") from the remote repository.
 The version is defined by the tag_name (it should be "HEAD" for the newest version). The downloaded sources are located in the ext_src directory in the directory in which current EPRJ file is located.
 We may strip defined number of the exported path components using the stripped_comp_num (e.g., for "rtl/module_1" the value of 1 will strip "rtl", the value of 2 will strip "rtl/module_1") so that we can avoid having too complex paths.
 This command works only with git servers and protocols that support "git archive" command (e.g., free github doesn't support it while gitlab supports).

1. git\_local clone\_directory commit\_or\_tag\_name [exported\_directory [stripped\_comp\_num]]

 The second command may be used for local git repositories (e.g., clones of the repositories kept on servers that do not support "git archive", like github).
 It is also the only option if we want to use the version defined by the commit ID without any tag attached.
 Except of that it works similarly to the first command.

1. svn repository\_url\_with\_exported\_path [revision]
   
 The third version is dedicated for repositories located on the SVN servers. In their case the repository URL should include the exported directory.
 If the revision field is empty, then the newest version is exported.

 For example, to use sources of the OpenCores I2C controller, you should create a subdirectory in your GIT controlled project tree containing `.gitignore` file with `extsrc/` line, and the `main.eprj` file with contents given below:
 
 ```
 svn  http://opencores.org/ocsvn/i2c/i2c/trunk/rtl/vhdl 76
 vhdl work ext_src/vhdl/i2c_master_bit_ctrl.vhd 
 vhdl work ext_src/vhdl/i2c_master_byte_ctrl.vhd 
 vhdl work ext_src/vhdl/i2c_master_top.vhd
 ```
 
 Of course the above example requires that you have the OpenCores account allowing you to download the sources from OC SVN.

Of course one can easily extend this list, modifying the eprj_create.tcl script. 
The line type is detected in the handle\_line procedure, and separate handlers are provided for different lines.
The _include_ and _ooc_ lines are handled directly in the _read\_prj_ procedure.

The fact, that the file-paths are taken realtively to the directory, in which the current EPRJ file is created allows to easily reuse IP blocks, by including their top EPRJ file from different directories in different projects.

## How to use this solution

First you need to define settings for your project in the proj_def.tcl file. This file will be sourced by the next scripts.
Particularly you must define the eproj_def_root variable, which should be the relative path to the top EPRJ file of your project.

You should setup the environment for Vivado (by sourcing the appropriate setting64.sh or settings32.sh file).
Then you can create the Vivado project:

$ vivado -mode batch -source eprj_create.tcl

When the project is created, you can compile it

$ vivado -mode batch -source eprj_build.tcl

Both above commands return the status, so you can use them in the makfile. The provided build.sh script calls both above commands in order.

## Example project
I have prepared a very simple demo project, which runs on a [Z-Turn board](http://www.myirtech.com/list.asp?id=502).
The projects implements a few registers and memory connected to the [IPbus](https://svnweb.cern.ch/trac/cactus) bus, which in turn is connected via [AXI4-Lite to IPbus](https://svnweb.cern.ch/trac/cactus/ticket/1876) bridge to the bus of ARM processor in the Zynq FPGA. 

The demo subdirectory contains two subdirectories. The `hdl` subdirectory contains the eprj files and HDL sources of the design.
Please note, that some of the sources are taken from the IPbus repository (you can download all IPbus HDL sources via 
`svn co http://svn.cern.ch/guest/cactus/tags/ipbus_fw/ipbus_2_0_v1` as described in the [IPbus Firmware Wiki](https://svnweb.cern.ch/trac/cactus/wiki/IPbusFirmware)).
The `software` subdirectory contains everything what's needed to build the Linux system for Z-Turn board, including the simple driver for the AXIL4IPB bridge and simple test program written in Python.

To make use of the demo, you may run `build.sh` script in the `hdl`.
That creates the bitstream for the FPGA.
The bitstream will be placed in the `zturn_ipb_demo/zturn_ipb_demo.runs/impl_1/design_1_wrapper.bit` file.

To create the Linux kernel (with root filesystem included in intramfs), you should
run `build_soft.sh` script in the `software` directory.
The script downloads the Buildroot environment, configures it, adds additional
packages and compiles it. Finally in the `buildroot-2016.02/output/images` directory
you should find the `uImage` (kernel+rootfs) and `system.dtb` (device tree) that together
with the bitstream should be passed to the Z-Turn board (e.g. placed on the SD card, or
put on the TFTP server from where the Z-Turn board donwloads it).

After booting the Z-Turn board, please write `axil2ipb` in the console. The device driver will be loaded and the test program will be started. You should see the contents of four IPbus-accessible registers in the console, and the LED will change colour every half second. 

If you modify the HDL design or ARM configuration, you may need to modify the device-tree sources.
Unfortunately my scripts do not do that automatically (yet?).

*To do that you should "Export hardware" locally to the design, and then
"Launch SDK" (both from "File" menu in Vivado GUI).
In the SDK, in the "Xilinx Tools/Repositories" menu you should
create the new local repository pointing on the device-tree-xlnx
directory. (You can produce it by calling:
`git clone git://github.com/Xilinx/device-tree-xlnx.git` )
After adding the repository, you should select
"File/New/Board Support Package" of "device_tree" type
(select "device_tree" in the Board Support Package OS").
You can leave the default name device\_tree\_bsp\_0.
Then you can click "OK" or "Finish" in next dialog boxes
until you return to the main SDK window. Finally you should copy the `dts` and `dtsi` files
to the `software/dts` directory*

To make testing easier, I have put the DTS sources generated for the initial version of the design to this directory.

## References
The _vextproj_ was inspired by many publications. Below I provide the most important. (I'm sorry if I've forgotten some of them).
  1. http://xillybus.com/tutorials/vivado-version-control-packaging
  2. http://www.fpgadeveloper.com/2014/08/version-control-for-vivado-projects.html
  3. http://electronics.stackexchange.com/questions/59477/using-svn-with-xilinx-vivado
  4. http://opencores.org/websvn,filedetails?repname=w11&path=%2Fw11%2Ftrunk%2Fdoc%2FREADME_buildsystem_Vivado.txt

