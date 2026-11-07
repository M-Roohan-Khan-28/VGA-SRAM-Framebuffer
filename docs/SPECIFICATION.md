# Bounded raster and framebuffer contract

The existing `vga_controller_sram` is an 80×60 internal RGB332 framebuffer
displayed as 640×480 active pixels by 8×8 replication. It advances one
pixel after four input clocks, counts horizontal positions 0–799 and lines
0–524, and then wraps the frame. `active_video` is high for h<640 and v<480.
HSYNC is low at h=656–751, and VSYNC is low at v=490–491. Outside active
video, RGB is zero. Active RGB332 bytes expand as red `{p[7:5],p[7]}`,
green `{p[4:2],p[4]}`, and blue `{p[1:0],p[1:0]}`.

The internal framebuffer initializes to the source-defined three-color
background and DIL signature for simulation. The 13-bit CPU-style write port
accepts indices 0–4799. The corrected RTL ignores writes at 4800–8191;
there is no wraparound or error output. Framebuffer writes remain allowed
during raster reset, and valid contents persist through raster resets.
The output reflects a write after the active clock edge and NBA settlement.

This is a simulation contract for an internal framebuffer. It is not an
external SRAM bus, FPGA initialization guarantee, timing closure or hardware
evidence. Original source history, notices and historical reports remain.
