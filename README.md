# vextproj
This is repository for a project allowing to create Vivado projects with complex hierarchy of sources from simple, VCS friendly set of files. The project is published under the CCO Creative Commons license as PUBLIC DOMAIN.

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
* xdc - for design constrains (in that case the "library" argument is not used, you can set it to "none").

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
At the moment I can't provide the demo project (the one for which I have developed this solution can't be freely published).
I hope to add a simple demonstration soon.
