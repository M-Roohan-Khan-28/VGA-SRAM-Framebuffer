`timescale 1ns/1ps

module tb_vga_controller_sram;

logic clk;
logic reset;
logic sram_we;
logic [12:0] sram_addr;
logic [7:0] sram_data_in;
logic hsync;
logic vsync;
logic active_video;
logic [3:0] red;
logic [3:0] green;
logic [3:0] blue;

integer pass_count;
integer fail_count;

vga_controller_sram dut(

    .clk          (clk),
    .reset        (reset),
    .sram_we      (sram_we),
    .sram_addr    (sram_addr),
    .sram_data_in (sram_data_in),
    .hsync        (hsync),
    .vsync        (vsync),
    .active_video (active_video),
    .red          (red),
    .green        (green),
    .blue         (blue)

);

always #5 clk = ~clk;

task automatic check_result(input logic condition, input string message);
begin

    if(condition)
    begin
        $display("PASS: %s", message);
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("FAIL: %s", message);
        fail_count = fail_count + 1;
    end

end
endtask

initial
begin

    $dumpfile("vga_controller_sram.vcd");
    $dumpvars(0, tb_vga_controller_sram);

    clk          = 1'b0;
    reset        = 1'b1;
    sram_we      = 1'b0;
    sram_addr    = 13'd0;
    sram_data_in = 8'h00;
    pass_count   = 0;
    fail_count   = 0;

    #30;
    reset = 1'b0;

    wait(dut.v_count == 10'd0 && dut.h_count == 10'd656);
    #1;
    check_result(hsync == 1'b0, "HSYNC becomes active-low at pixel 656");

    wait(dut.v_count == 10'd0 && dut.h_count == 10'd752);
    #1;
    check_result(hsync == 1'b1, "HSYNC returns high at pixel 752");

    wait(dut.v_count == 10'd8 && dut.h_count == 10'd8);
    #1;
    check_result(active_video == 1'b1 && red == 4'hF,
                 "Visible SRAM background pixel is displayed");

    wait(dut.v_count == 10'd192 && dut.h_count == 10'd224);
    #1;
    check_result(red == 4'hF && green == 4'hF && blue == 4'hF,
                 "Unique DIL signature pixel is read from SRAM");

    @(negedge clk);
    sram_addr    = 13'd0;
    sram_data_in = 8'b111_111_00;
    sram_we      = 1'b1;

    @(posedge clk);
    #1;

    @(negedge clk);
    sram_we = 1'b0;

    check_result(dut.sram[0] == 8'b111_111_00,
                 "SRAM write port updates a framebuffer location");

    wait(dut.v_count == 10'd490 && dut.h_count == 10'd0);
    #1;
    check_result(vsync == 1'b0, "VSYNC becomes active-low at line 490");

    wait(dut.v_count == 10'd492 && dut.h_count == 10'd0);
    #1;
    check_result(vsync == 1'b1, "VSYNC returns high at line 492");

    $display("------------------------------------------");
    $display("TOTAL PASSED = %0d", pass_count);
    $display("TOTAL FAILED = %0d", fail_count);
    $display("------------------------------------------");

    if(fail_count == 0)
        $display("ALL VGA TESTS PASSED");
    else
        $fatal(1, "VGA TESTBENCH FAILED");

    #20;
    $finish;

end

endmodule
