# vextproj
This is repository for a project allowing to create Vivado projects with complex hierarchy of sources from simple, VCS friendly set of files. The project is published under the CC0 Creative Commons license as PUBLIC DOMAIN.

The approach is based on "extended project files" (eprj).
Each eprj file contains lines which describe single source file or a directory, which may contain other source files or directories.
For operation with VCS (especially GIT) it is important, that you can build a hierarchy of nested IP blocks, while 
having the flat structure of directories (one directory for each reusable component, all at the same level).
This allows to avoid using of submodules.

The source definition line in the EPRJ file has the following syntax:

type  library filepath

The following types are recognized:
* xci   - For IP cores
* xcix  - For IP cores containers
* header - for Verilog headers
* global_header - for global Verilog headers
* sys_verilog - for System Verilog files
* verilog - for Verilog sources
* mif - for Memory Initialization Files
* vhdl - for VHDL sources
* bd - for Block Designer sources
* xdc - for design constrains (in that case the "library" argument is not used, you can set it to "none").
* exec - for scripts which should be executed in their directories. Watch out! This may execute arbitrary
  commands on your account!

Of course one can easily extend this list, modifying the eprj_create.tcl script.
All filepaths are taken realtively to the directory, in which the current EPRJ file is created. This allows to easile reuse IP blocks, by including their top EPRJ file from different directories in different projects.

The include line has a very simple syntax:

include directory_or_filepath

If the second word is the directory, then the default "main.eprj" file is searched for in that directory.
You may include another file by specifying its path including the file name (it may be useful, if the particular IP block may be reused in different ways, including only certain subset of sources).

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

