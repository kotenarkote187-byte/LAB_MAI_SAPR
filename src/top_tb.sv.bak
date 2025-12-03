`timescale 1ns/1ps

module Testbench;

    // Тактовый сигнал и сброс
    logic clk;
    logic rst_n;
    
    // APB сигналы
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;
    
    // Генерация тактового сигнала
    initial begin
        clk = 0;
        $display("Starting clock generation...");
        forever #5 clk = ~clk;
    end
    
    // Генерация сброса
    initial begin
        rst_n = 0;
        $display("Reset asserted");
        #20 rst_n = 1;
        $display("Reset deasserted at time %0t", $time);
    end
    
    // Инстанциирование мастера
    apb_master master_inst (
        .PCLK(clk),
        .PRESETn(rst_n),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );
    
    // Инстанциирование slave
    apb_slave slave_inst (
        .PCLK(clk),
        .PRESETn(rst_n),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );
    
    // Основной тест
    initial begin
        logic [31:0] read_data;
        
        // Инициализация
        #30;
        $display("");
        $display("************************************************");
        $display("APB SYSTEM TEST STARTED");
        $display("************************************************");
        $display("");
        
        // 1. Запись по адресу 0x0 значения 2
        $display("TEST 1: Writing value 2 to address 0x0");
        master_inst.apb_write(32'h00000000, 32'h00000002);
        #50;
        
        // 2. Запись по адресу 0x4 значения дата
        $display("TEST 2: Writing date to address 0x4");
        master_inst.apb_write(32'h00000004, 32'h15122024);
        #50;
        
        // 3. Запись по адресу 0x8 значения фамилия
        $display("TEST 3: Writing surname to address 0x8");
        master_inst.apb_write(32'h00000008, 32'h424F4E44); // BOND
        #50;
        
        // 4. Запись по адресу 0xC значения имя
        $display("TEST 4: Writing name to address 0xC");
        master_inst.apb_write(32'h0000000C, 32'h45564745); // EVGE
        #50;
        
        // Печать всех регистров slave для проверки
        slave_inst.print_all_registers();
        
        // Чтение для проверки
        $display("");
        $display("************************************************");
        $display("VERIFICATION PHASE: Reading back all values");
        $display("************************************************");
        $display("");
        
        // Чтение адреса 0x0
        $display("READING ADDRESS 0x0");
        master_inst.apb_read(32'h00000000, read_data);
        $display("VERIFICATION: Read addr 0x0 = 0x%08h (Expected: 0x00000002)", read_data);
        if (read_data == 32'h00000002) 
            $display("PASS: Data matches expected value!");
        else 
            $display("FAIL: Data mismatch!");
        #20;
        
        // Чтение адреса 0x4
        $display("READING ADDRESS 0x4");
        master_inst.apb_read(32'h00000004, read_data);
        $display("VERIFICATION: Read addr 0x4 = 0x%08h (Expected: 0x15122024)", read_data);
        if (read_data == 32'h15122024) 
            $display("PASS: Data matches expected value!");
        else 
            $display("FAIL: Data mismatch!");
        #20;
        
        // Чтение адреса 0x8
        $display("READING ADDRESS 0x8");
        master_inst.apb_read(32'h00000008, read_data);
        $display("VERIFICATION: Read addr 0x8 = 0x%08h (Expected: 0x424F4E44)", read_data);
        if (read_data == 32'h424F4E44) 
            $display("PASS: Data matches expected value!");
        else 
            $display("FAIL: Data mismatch!");
        #20;
        
        // Чтение адреса 0xC
        $display("READING ADDRESS 0xC");
        master_inst.apb_read(32'h0000000C, read_data);
        $display("VERIFICATION: Read addr 0xC = 0x%08h (Expected: 0x45564745)", read_data);
        if (read_data == 32'h45564745) 
            $display("PASS: Data matches expected value!");
        else 
            $display("FAIL: Data mismatch!");
        #20;
        
        // Финальный отчет
        $display("");
        $display("************************************************");
        $display("APB SYSTEM TEST COMPLETED");
        $display("************************************************");
        $display("Summary: All operations finished");
        $display("Simulation time: %0t ns", $time);
        $display("************************************************");
        $display("");
        
        #50;
        $finish;
    end
    
    // Мониторинг APB шины
    initial begin
        $monitor("Time: %0t | APB_BUS: PSEL=%b PENABLE=%b PWRITE=%b PADDR=0x%08h PWDATA=0x%08h PRDATA=0x%08h PREADY=%b", 
                 $time, PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY);
    end

    // Тайм-аут для безопасности
    initial begin
        #2000; // 2000 нс тайм-аут
        $display("");
        $display("TIMEOUT: Simulation took too long, forcing finish");
        $display("");
        $finish;
    end

endmodule