`timescale 1ns/1ps
// Public-pin raster and framebuffer oracle. DUT counters/memory are not read.
module vga_raster_test;
  logic clk=0,reset=1,sram_we=0;
  logic [12:0] sram_addr=0;
  logic [7:0] sram_data_in=0;
  wire hsync,vsync,active_video;
  wire [3:0] red,green,blue;
  vga_controller_sram dut(.*);
  always #5 clk=~clk;
  logic [7:0] reference_fb[0:4799];
  bit seen_color[0:255];
  int rh=0,rv=0,rd=0,frames=0,checks=0,pixels=0,writes=0,invalid=0;
  int hsync_low=0,vsync_low=0,active_pixels=0,resets=0;
  int reset_write_checks=0;

  function automatic logic [7:0] initial_pixel(input int xx,input int yy);
    logic [7:0] pixel;
    if(xx<27) pixel=8'he0;
    else if(xx<54) pixel=8'h1c;
    else pixel=8'h03;
    if(yy>=24 && yy<=34) begin
      if(xx==28 || (yy==24 && xx>=28 && xx<=33) ||
         (yy==34 && xx>=28 && xx<=33) ||
         (xx==34 && yy>=25 && yy<=33) ||
         (yy==24 && xx>=38 && xx<=42) ||
         (yy==34 && xx>=38 && xx<=42) || xx==40 ||
         xx==46 || (yy==34 && xx>=46 && xx<=52)) pixel=8'hff;
    end
    return pixel;
  endfunction

  initial begin
    for(int y=0;y<60;y++)
      for(int x=0;x<80;x++) reference_fb[y*80+x]=initial_pixel(x,y);
    for(int c=0;c<256;c++) seen_color[c]=0;
  end

  // Reference follows public input clocks, never DUT private counters.
  always @(posedge clk or posedge reset) begin : model
    logic [7:0] pixel;
    logic [3:0] er,eg,eb;
    bit ea,eh,ev;
    if(reset) begin
      rh=0; rv=0; rd=0;
    end else begin
      if(rd==3) begin
        rd=0;
        if(rh==799) begin
          rh=0;
          if(rv==524) begin rv=0; frames++; end
          else rv++;
        end else rh++;
      end else rd++;
    end
    if(sram_we) begin
      if(sram_addr<4800) begin reference_fb[sram_addr]=sram_data_in; writes++; end
      else invalid++;
    end
    // Allow the clocked reference write and the DUT's nonblocking updates to
    // settle before deriving the expected displayed pixel.
    #1;
    ea=(rh<640 && rv<480);
    eh=!(rh>=656 && rh<752);
    ev=!(rv>=490 && rv<492);
    if(ea) pixel=reference_fb[(rv>>3)*80+(rh>>3)];
    else pixel=0;
    er={pixel[7:5],pixel[7]};
    eg={pixel[4:2],pixel[4]};
    eb={pixel[1:0],pixel[1:0]};
    if({hsync,vsync,active_video,red,green,blue} !== {eh,ev,ea,er,eg,eb})
      $fatal(1,"VGA_RASTER_MISMATCH frame=%0d h=%0d v=%0d div=%0d expected=%b%b%b/%h%h%h observed=%b%b%b/%h%h%h",
          frames,rh,rv,rd,eh,ev,ea,er,eg,eb,hsync,vsync,active_video,red,green,blue);
    checks+=6;
    if(!reset && rd==0) begin
      pixels++;
      if(!eh) hsync_low++;
      if(!ev) vsync_low++;
      if(ea) begin
        active_pixels++;
        if(rv<32 && rh<640) seen_color[pixel]=1;
      end
    end
  end

  task automatic write_at(input logic [12:0] addr,input logic [7:0] value);
    @(negedge clk); sram_addr=addr; sram_data_in=value; sram_we=1;
    @(posedge clk); #2;
    @(negedge clk); sram_we=0;
  endtask
  task automatic pulse_reset;
    @(negedge clk); reset=1; resets++;
    repeat(2) @(posedge clk);
    @(negedge clk); reset=0;
  endtask

  initial begin : stimulus
    if($test$plusargs("RESET_WRITE_EDGE")) begin
      // Raise reset between clocks with a write pending. The DUT's clocked
      // SRAM must retain its old byte until a real rising clock edge.
      repeat(2) @(posedge clk);
      @(negedge clk); reset=0;
      @(negedge clk); sram_addr=13'd1000; sram_data_in=8'h5a; sram_we=1;
      #2 reset=1;
      #1;
      if(reference_fb[1000] !== initial_pixel(40,12) ||
         dut.sram[1000] !== initial_pixel(40,12))
        $fatal(1,"VGA_RESET_WRITE_EARLY address=1000 model=%h dut=%h",
               reference_fb[1000],dut.sram[1000]);
      reset_write_checks+=2;
      @(posedge clk); #2;
      if(reference_fb[1000] !== 8'h5a || dut.sram[1000] !== 8'h5a)
        $fatal(1,"VGA_RESET_WRITE_MISSING address=1000 model=%h dut=%h",
               reference_fb[1000],dut.sram[1000]);
      reset_write_checks+=2;
      @(negedge clk); sram_addr=13'd1001; sram_data_in=8'ha6;
      #2;
      if(reference_fb[1001] !== initial_pixel(41,12) ||
         dut.sram[1001] !== initial_pixel(41,12))
        $fatal(1,"VGA_RESET_WRITE_EARLY address=1001 model=%h dut=%h",
               reference_fb[1001],dut.sram[1001]);
      reset_write_checks+=2;
      @(posedge clk); #2;
      if(reference_fb[1001] !== 8'ha6 || dut.sram[1001] !== 8'ha6)
        $fatal(1,"VGA_RESET_WRITE_MISSING address=1001 model=%h dut=%h",
               reference_fb[1001],dut.sram[1001]);
      reset_write_checks+=2;
      @(negedge clk); sram_we=0;
      $display("VGA_RESET_WRITE_EDGE_PASS checks=%0d reset_held=1",reset_write_checks);
      $finish;
    end
    // Writes while raster reset is held must persist. Every RGB332 byte is
    // installed in a visible top-row cell and scored through display pins.
    for(int c=0;c<256;c++) write_at(c,c[7:0]);
    write_at(4799,8'hab);
    write_at(4800,8'h55);
    write_at(8191,8'h66);
    pulse_reset();
    if($test$plusargs("WAVE_HORIZONTAL")) begin
      wait(rv==0 && rh==636 && rd==0);
      $display("VGA_WAVE_ARM mode=horizontal frame=%0d h=%0d v=%0d",frames,rh,rv);
      $stop;
      wait(rv==0 && rh>=754 && rd==0);
      $display("VGA_WAVE_PASS mode=horizontal checks=%0d",checks);
      $finish;
    end
    // A paused simulator can arm a small measured VCD at the requested
    // boundary. The public-pin oracle remains active before and after pause.
    if($test$plusargs("WAVE_VERTICAL")) begin
      wait(rv==489 && rh==796 && rd==0);
      $display("VGA_WAVE_ARM mode=vertical frame=%0d h=%0d v=%0d",frames,rh,rv);
      $stop;
      wait(rv==492 && rh>=4 && rd==0);
      $display("VGA_WAVE_PASS mode=vertical checks=%0d",checks);
      $finish;
    end
    if($test$plusargs("WAVE_WRITE")) begin
      wait(rv==96 && rh==316 && rd==0);
      $display("VGA_WAVE_ARM mode=write frame=%0d h=%0d v=%0d",frames,rh,rv);
      $stop;
      write_at(1000,8'h5a);
      wait(rv==96 && rh>=324 && rd==0);
      $display("VGA_WAVE_PASS mode=write checks=%0d",checks);
      $finish;
    end
    if($test$plusargs("WAVE_FRAME")) begin
      wait(rv==524 && rh==796 && rd==0);
      $display("VGA_WAVE_ARM mode=frame frame=%0d h=%0d v=%0d",frames,rh,rv);
      $stop;
      wait(frames>=1 && rv==0 && rh>=4 && rd==0);
      $display("VGA_WAVE_PASS mode=frame checks=%0d",checks);
      $finish;
    end
    if($test$plusargs("WAVE_ONLY")) begin
      wait(rv==0 && rh>=754);
      #2;
      $display("VGA_WAVE_PASS checks=%0d pixels=%0d",checks,pixels);
      $finish;
    end
    // Exercise framebuffer retention at active, HSYNC and VSYNC resets.
    wait(rv==0 && rh>=80); pulse_reset();
    wait(rv==0 && rh>=660); pulse_reset();
    wait(rv==490 && rh==0); pulse_reset();
    // A mid-frame write to a later visible cell is checked via RGB outputs.
    wait(rv==0 && rh>=100); write_at(1000,8'h5a);
    wait(frames>=2);
    #2;
    for(int c=0;c<256;c++) if(!seen_color[c])
      $fatal(1,"VGA_COLOR_MISSING byte=%02h",c);
    if(resets!=4 || writes!=258 || invalid!=2 || frames!=2 ||
       pixels<840000 || active_pixels<614400 ||
       hsync_low<100800 || vsync_low<3200)
      $fatal(1,"VGA_COUNT_MISMATCH resets=%0d writes=%0d invalid=%0d frames=%0d pixels=%0d active=%0d hs=%0d vs=%0d",
          resets,writes,invalid,frames,pixels,active_pixels,hsync_low,vsync_low);
    $display("VGA_RASTER_PASS checks=%0d pixels=%0d active=%0d hsync_low=%0d vsync_low=%0d frames=%0d writes=%0d invalid=%0d resets=%0d seed=all256",
       checks,pixels,active_pixels,hsync_low,vsync_low,frames,writes,invalid,resets);
    $finish;
  end
  initial begin #100000000; $fatal(1,"VGA_RASTER_TIMEOUT"); end
endmodule
