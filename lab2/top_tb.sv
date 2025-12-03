`timescale 1ns/1ps
`include "apb_interface.sv"
`include "apb_master.sv"
`include "apb_slave.sv"

module tb_apb();
    logic clk, reset;
    apb_interface apb_if();

    initial begin
        clk = 0;
        reset = 0;
        #20 reset = 1;
        forever #5 clk = ~clk;
    end

    assign apb_if.PCLK = clk;
    assign apb_if.PRESETn = reset;

    apb_slave slave (apb_if.slave_mp);
    apb_master master (apb_if.master_mp);
    
    initial begin
        // Ждем сброса
        wait(reset === 1'b1);
        $display("Reset released, starting tests...");
        
        // Небольшая задержка после сброса
        repeat(2) @(posedge clk);

        $display("\n=====[TEST 1] Initial values after reset=====");
        master.read('h0); // addend
        master.read('h4); // control
        master.read('h8); // result

        $display("\n=====[TEST 2] Basic accumulation test=====");
        master.write('h0, 32'd10); // addend = 10
        master.write('h4, 32'd1);  // control = 1 (perform addition)
        repeat(2) @(posedge clk);
        master.read('h8); // Read result (should be 10)
        
        master.write('h0, 32'd5);  // addend = 5
        master.write('h4, 32'd1);  // control = 1 (perform addition)
        repeat(2) @(posedge clk);
        master.read('h8); // Read result (should be 15)

        $display("\n=====[TEST 3] Multiple accumulations=====");
        master.write('h0, 32'd20); // addend = 20
        master.write('h4, 32'd1);  // control = 1
        repeat(2) @(posedge clk);
        master.read('h8); // Read result (should be 35)
        
        master.write('h0, 32'd15); // addend = 15
        master.write('h4, 32'd1);  // control = 1
        repeat(2) @(posedge clk);
        master.read('h8); // Read result (should be 50)

        $display("\n=====[TEST 4] Reset result=====");
        master.write('h4, 32'd2); // control = 2 (reset result)
        repeat(2) @(posedge clk);
        master.read('h8); // Read result (should be 0)

        $display("\n=====[TEST 5] Accumulation after reset=====");
        master.write('h0, 32'd100); // addend = 100
        master.write('h4, 32'd1);   // control = 1
        repeat(2) @(posedge clk);
        master.read('h8); // Read result (should be 100)
        
        master.write('h0, 32'd50);  // addend = 50
        master.write('h4, 32'd1);   // control = 1
        repeat(2) @(posedge clk);
        master.read('h8); // Read result (should be 150)

        $display("\n=====[TEST 6] Large values test=====");
        master.write('h4, 32'd2);   // Reset result
        repeat(2) @(posedge clk);
        master.write('h0, 32'h7FFFFFFF); // addend = max positive 32-bit
        master.write('h4, 32'd1);
        repeat(2) @(posedge clk);
        master.read('h8);
        
        master.write('h0, 32'd1);
        master.write('h4, 32'd1);
        repeat(2) @(posedge clk);
        master.read('h8); // Should wrap around

        $display("\n=====[TEST 7] Zero addend test=====");
        master.write('h4, 32'd2);   // Reset result
        repeat(2) @(posedge clk);
        master.write('h0, 32'd0);   // addend = 0
        master.write('h4, 32'd1);   // control = 1
        repeat(2) @(posedge clk);
        master.read('h8); // Read result (should be 0)
        
        master.write('h0, 32'd25);  // addend = 25
        master.write('h4, 32'd1);   // control = 1
        repeat(2) @(posedge clk);
        master.read('h8); // Read result (should be 25)

        $display("\n=====[TEST 8] Control register operations=====");
        // Тестирование всех команд control_reg
        master.write('h4, 32'd0); // control = 0 (no operation)
        master.read('h4);
        master.write('h4, 32'd1); // control = 1 (add)
        master.read('h4);
        master.write('h4, 32'd2); // control = 2 (reset)
        master.read('h4);
        master.write('h4, 32'd999); // control = invalid value
        master.read('h4);

        $display("\n=====[TEST 9] Attempt to write read-only register=====");
        master.write('h8, 32'hDEAD_BEEF); // Try to write result register

        $display("\n=====[TEST 10] Invalid address check=====");
        master.write('hFFFFFFFF, 32'h12345678);
        master.read('h10000000);

        // Дополнительные неверные адреса
        master.write('h10, 32'h11111111);
        master.read('h14);

        $display("\n=====[TEST 11] Mixed read/write operations=====");
        // Чередование чтения и записи
        master.write('h0, 32'd7);
        master.read('h0);
        master.write('h4, 32'd1);
        master.read('h4);
        repeat(2) @(posedge clk);
        master.read('h8);
        
        master.write('h0, 32'd3);
        master.read('h0);
        master.write('h4, 32'd1);
        repeat(2) @(posedge clk);
        master.read('h8);

        $display("\n=====[TEST 12] Reset behavior after activity=====");
        reset = 0; #10; reset = 1;
        repeat(2) @(posedge clk);
        master.read('h0);
        master.read('h4);
        master.read('h8);

        $display("\n=====[TEST 13] Post-reset operations=====");
        // Операции после сброса
        master.write('h0, 32'd42);
        master.write('h4, 32'd1);
        repeat(2) @(posedge clk);
        master.read('h8);
        
        master.write('h0, 32'd8);
        master.write('h4, 32'd1);
        repeat(2) @(posedge clk);
        master.read('h8);

        $display("\n=====[TEST 14] Sequential accumulations=====");
        master.write('h4, 32'd2);   // Reset result
        repeat(2) @(posedge clk);
        
        // Последовательное накопление нескольких значений
        master.write('h0, 32'd1);
        master.write('h4, 32'd1);
        repeat(2) @(posedge clk);
        
        master.write('h0, 32'd2);
        master.write('h4, 32'd1);
        repeat(2) @(posedge clk);
        
        master.write('h0, 32'd3);
        master.write('h4, 32'd1);
        repeat(2) @(posedge clk);
        
        master.write('h0, 32'd4);
        master.write('h4, 32'd1);
        repeat(2) @(posedge clk);
        
        master.read('h8); // Should be 1+2+3+4 = 10

        $display("\n=====[TEST 15] Negative values test=====");
        master.write('h4, 32'd2);   // Reset result
        repeat(2) @(posedge clk);
        master.write('h0, 32'hFFFFFFFF); // addend = -1 (two's complement)
        master.write('h4, 32'd1);
        repeat(2) @(posedge clk);
        master.read('h8);
        
        master.write('h0, 32'd5);
        master.write('h4, 32'd1);
        repeat(2) @(posedge clk);
        master.read('h8);

        $display("\n====[ALL TESTS COMPLETED SUCCESSFULLY]====\n");
        #50;
        $finish;
    end

endmodule