# FPGA optical flow for event-based sensors #

This repository contains code supporting an ISCAS 2018 paper (to be linked once published).

An example of the code in action can be found at
* Input data used by this repo: [Rotating Bar Video](https://youtu.be/uI0BoMI96kI)
* [Resulting direction](https://youtu.be/sE-xBcOgiY4)
* [Resulting speed](https://youtu.be/kVjdE0-t4u0)
* [Live screengrab of FPGA results from handheld sensor](https://www.youtube.com/edit?o=U&video_id=86VnBYzJHFQ)

### Folders ###
* Under the VHDL folder you will find code for the module (implementation) and code for simulating each module (simulation)
* The Matlab folder contains three main scripts
1. "full_precision_plane_fit" implements the plane fitting algorithm at full precision without considering the restrictions of FPGA implementation.
2. "vhdl_plane_fit" contains Matlab code for processing data exactly as the VHDL module would.
3. "verify_vhdl_simulations" verifies that the Matlab VHDL simulations produce the exact same results as the actual VHDL simulations.

### Simulation and Verification ###
* The code allows full precision simulations to be compared to VHDL simulations to investigate any loss of accuracy.
* To verify the VHDL simulations, they need to be run one at a time. Each simulation module uses the output of the previous simulation module as input.

### Known Issues ###
* The divider in the format_output.vhd module does not simulate correctly on our CentOS 7 machine. No errors are thrown, but the outputs are incorrect. The simulation works correctly on our Windows 7 machines.

### Who do I talk to? ###

* Garrick Orchard (garrickorchard@gmail.com)

