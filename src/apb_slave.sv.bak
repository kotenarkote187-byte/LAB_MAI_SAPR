`timescale 1ns/1ps

module apb_slave (
    // APB интерфейс
    input  logic        PCLK,
    input  logic        PRESETn,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR
);

    // Внутренние регистры
    logic [31:0] registers [0:15];
    
    // Всегда готовы
    assign PREADY = 1'b1;
    assign PSLVERR = 1'b0;

    // Логика записи
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            // Сброс регистров
            foreach(registers[i]) begin
                registers[i] <= 32'd0;
            end
            $display("");
            $display("================================================");
            $display("APB SLAVE: RESET COMPLETED");
            $display("All registers initialized to 0x00000000");
            $display("================================================");
            $display("");
        end else if (PSEL && PENABLE && PWRITE) begin
            // Запись в регистр
            if (PADDR[31:4] == 28'h0) begin
                registers[PADDR[3:0]] <= PWDATA;
                $display("");
                $display("------------------------------------------------");
                $display("APB SLAVE: WRITE OPERATION");
                $display("------------------------------------------------");
                $display("Register[0x%01h] = 0x%08h", PADDR[3:0], PWDATA);
                $display("Previous value: 0x%08h", registers[PADDR[3:0]]);
                $display("Write successful");
                $display("------------------------------------------------");
                $display("");
            end else begin
                $display("APB SLAVE: Invalid write address 0x%08h", PADDR);
            end
        end
    end

    // Логика чтения - комбинационная логика для немедленного ответа
    always_comb begin
        PRDATA = 32'd0;
        if (PSEL && !PWRITE) begin
            if (PADDR[31:4] == 28'h0) begin
                PRDATA = registers[PADDR[3:0]];
                $display("");
                $display("------------------------------------------------");
                $display("APB SLAVE: READ OPERATION - COMBINATIONAL");
                $display("------------------------------------------------");
                $display("Reading Register[0x%01h]", PADDR[3:0]);
                $display("Data to read: 0x%08h", registers[PADDR[3:0]]);
                $display("PRDATA driven: 0x%08h", PRDATA);
                $display("Read data ready IMMEDIATELY");
                $display("------------------------------------------------");
                $display("");
            end else begin
                PRDATA = 32'hDEADBEEF;
                $display("APB SLAVE: Invalid read address 0x%08h, returning 0xDEADBEEF", PADDR);
            end
        end
    end

    // Функция для отладки - печать всех регистров
    function void print_all_registers();
        begin
            $display("");
            $display("================================================");
            $display("APB SLAVE: REGISTER DUMP");
            $display("================================================");
            for (int i = 0; i < 16; i++) begin
                $display("Register[0x%01h] = 0x%08h", i, registers[i]);
            end
            $display("================================================");
            $display("");
        end
    endfunction

endmodule