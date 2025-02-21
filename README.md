
#  Single-Cycle RISC-V - Design and verification  

This project features both digital design and formal verification of a single-cycle RISC-V processor. Processor supports 7 instruction types (R, I, S, J, B, L, U).
As this is an introduction to a RISC-V architecture, it is decided, that we develop a single-cycle version, due to it being simpler, which turned out to be a challenge during verification, since we are using both positive and negative edge of a clock. Also, next to a RISC-V core that is duplicated (Dual-core), system contains L1,L2  and main data memory in case of misses in pre-mentioned cache memories. 
## Features

- Single-cycle
- Both digital design and formal verification are covered
- 7 instruction types
- Cache memory subsystem included with MESI protocol
- MESI protocol
- Direct-mapped L1 cache memory
- Set-asociative L2 cache memory
- Snoop protocol


## Screenshots
Block scheme of a system looks like this: 

![top_module](https://github.com/user-attachments/assets/797874b8-bdf8-472e-bbbd-0521b15bd7ab)


## Running Tests

To run tests, consult the provided documentation. Tcl scripts are also provided. In this repo in folder *instruction_tests* there are several machine codes that test certain functionalities of a design on a basic level (you can consider these as unit-level tests). However, real verification is done with JasperGold tool by Cadence, visit *scripts* and *verif* folders.

```bash
  jg do_ref_model.tcl
```


## Appendix

Here is a quick descripition of folders in this repo:

- *docs* : Documentation of the entire project
- *hdl* : SystemVerilog design files(*names should be quite descriptive*) and *code.mem* files for a machine code to run in Vivado Suite.
- *img_help* : Some assisting pictures and screenshots
- *instruction_tests* : Set of mentioned unit-level tests and machine codes to use in Vivado
- *scripts*: Tcl scripts and .f files that help in building a project
- *tb*: Assisting testbench files and waveforms
- *verif*: All files relevant to formal verification. For complete verification use *reference_model* and *reference_model_top* folders, other are just assisting.
- others: Refreences for SystemVerilog and RISC-V

