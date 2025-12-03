module apb_master(apb_interface apb_if);

    // Сброс не нужен для выходов интерфейса - они управляются только задачами
    // always_ff @(posedge apb_if.PCLK or negedge apb_if.PRESETn) begin
    //     if (!apb_if.PRESETn) begin
    //         apb_if.PSEL    <= 1'b0;
    //         apb_if.PENABLE <= 1'b0;
    //         apb_if.PWRITE  <= 1'b0;
    //         apb_if.PADDR   <= 32'b0;
    //         apb_if.PWDATA  <= 32'b0;
    //     end
    // end

    task write(input logic [31:0] waddr, input logic [31:0] wdata); 
        $display("[APB_MASTER] Write request: addr=0x%08h, data=%0d", waddr, wdata);

        // Инициализация транзакции
        @(posedge apb_if.PCLK);
        apb_if.PSEL    <= 1'b1;   
        apb_if.PENABLE <= 1'b0;  
        apb_if.PWRITE  <= 1'b1;   
        apb_if.PADDR   <= waddr; 
        apb_if.PWDATA  <= wdata; 

        // Фаза включения
        @(posedge apb_if.PCLK);
        apb_if.PENABLE <= 1'b1;     

        // Ожидание готовности
        wait(apb_if.PREADY);
        @(posedge apb_if.PCLK);
        
        // Завершение транзакции
        apb_if.PSEL    <= 1'b0;   
        apb_if.PENABLE <= 1'b0;
        
        if (apb_if.PSLVERR) 
            $display("[APB_MASTER] ERROR WRITE");
        else 
            $display("[APB_MASTER] Write completed.\n"); 
            
        // Дополнительный такт для стабилизации
        @(posedge apb_if.PCLK);
    endtask

    task read(input logic [31:0] raddr);
        logic [31:0] rdata;
        
        $display("[APB_MASTER] READ from addr: %2h", raddr);

        // Инициализация транзакции
        @(posedge apb_if.PCLK);
        apb_if.PSEL    <= 1'b1;    
        apb_if.PENABLE <= 1'b0;    
        apb_if.PWRITE  <= 1'b0;  
        apb_if.PADDR   <= raddr;

        // Фаза включения
        @(posedge apb_if.PCLK); 
        apb_if.PENABLE <= 1'b1;

        // Ожидание готовности
        wait(apb_if.PREADY);
        @(posedge apb_if.PCLK);
        
        if (apb_if.PSLVERR) begin
            $display("[APB_MASTER] ERROR READ\n");
        end else begin
            rdata = apb_if.PRDATA; 
            $display("[APB_MASTER] Read completed.");
            $display("[APB_MASTER] READ: rdata = %0d (0x%08h)\n", rdata[31:0], rdata[31:0]);
        end

        // Завершение транзакции
        apb_if.PSEL    <= 1'b0;   
        apb_if.PENABLE <= 1'b0;
        
        // Дополнительный такт для стабилизации
        @(posedge apb_if.PCLK);
    endtask 
   
endmodule