module apb_slave(apb_interface apb_if);

    logic [31:0] addend_reg;       // Добавляемое значение
    logic [31:0] control_reg;      // Контрольный регистр
    logic [31:0] result_reg;      // Текущий результат (накопленная сумма)
    
    logic trans_done;
    logic ready_set;

    // APB логика
    always_ff @(posedge apb_if.PCLK or negedge apb_if.PRESETn) begin
        if (!apb_if.PRESETn) begin
            apb_if.PREADY  <= 1'b0;
            apb_if.PSLVERR <= 1'b0;
            addend_reg     <= 32'b0;
            control_reg    <= 32'b0;
            result_reg     <= 32'b0;
            apb_if.PRDATA  <= 32'b0;
            trans_done     <= 1'b0;
            ready_set      <= 1'b0;
        end else begin
            // Сброс сигналов ошибки и готовности только когда транзакция завершена
            if (apb_if.PREADY && apb_if.PSEL && apb_if.PENABLE) begin
                apb_if.PREADY <= 1'b0;
                apb_if.PSLVERR <= 1'b0;
                ready_set <= 1'b0;
            end

            // WRITE операция
            if (apb_if.PSEL && apb_if.PENABLE && apb_if.PWRITE && !ready_set) begin
                case (apb_if.PADDR)
                    32'h0: begin // Запись добавляемого значения
                        addend_reg <= apb_if.PWDATA;
                        $display("[APB_SLAVE] Write addend: %0d (0x%08h)", apb_if.PWDATA, apb_if.PWDATA);
                        apb_if.PREADY <= 1'b1;
                        ready_set <= 1'b1;
                    end
                    32'h4: begin // Запись контрольного регистра
                        control_reg <= apb_if.PWDATA;
                        $display("[APB_SLAVE] Write control: 0x%08h", apb_if.PWDATA);
                        
                        // Выполнение операции на основе control_reg
                        case (apb_if.PWDATA)
                            32'd1: begin // Выполнить сложение с накоплением
                                result_reg <= result_reg + addend_reg;
                                $display("[APB_SLAVE] Accumulation: result = %0d + %0d = %0d", 
                                         result_reg, addend_reg, result_reg + addend_reg);
                            end
                            32'd2: begin // Сброс результата
                                result_reg <= 32'b0;
                                $display("[APB_SLAVE] Result reset to 0");
                            end
                            default: begin // Другие значения - ничего не делать
                                $display("[APB_SLAVE] No operation (control = 0x%08h)", apb_if.PWDATA);
                            end
                        endcase
                        apb_if.PREADY <= 1'b1;
                        ready_set <= 1'b1;
                    end
                    32'h8: begin // Ошибка: попытка записи в регистр результата (только для чтения)
                        $display("[APB_SLAVE] ERROR: WRITE to read-only result register (0x%08h)", apb_if.PADDR);
                        apb_if.PSLVERR <= 1'b1;
                        apb_if.PREADY  <= 1'b1;
                        ready_set <= 1'b1;
                    end 
                    default: begin // Неверный адрес
                        $display("[APB_SLAVE] ERROR: addr isn't in range (0x%08h)", apb_if.PADDR);
                        apb_if.PSLVERR <= 1'b1;
                        apb_if.PREADY  <= 1'b1;
                        ready_set <= 1'b1;
                    end
                endcase
                trans_done <= 1'b1;
            end 
            // READ операция
            else if (apb_if.PSEL && apb_if.PENABLE && !apb_if.PWRITE && !ready_set) begin
                case (apb_if.PADDR)
                    32'h0: begin // Чтение добавляемого значения
                        apb_if.PRDATA <= addend_reg;
                        $display("[APB_SLAVE] Read addend: %0d (0x%08h)", addend_reg, addend_reg);
                    end
                    32'h4: begin // Чтение контрольного регистра
                        apb_if.PRDATA <= control_reg;
                        $display("[APB_SLAVE] Read control: 0x%08h", control_reg);
                    end
                    32'h8: begin // Чтение текущего результата
                        apb_if.PRDATA <= result_reg;
                        $display("[APB_SLAVE] Read result: %0d (0x%08h)", result_reg, result_reg);
                    end
                    default: begin // Неверный адрес
                        $display("[APB_SLAVE] ERROR: addr isn't in range (0x%08h)", apb_if.PADDR);
                        apb_if.PSLVERR <= 1'b1;
                        apb_if.PRDATA  <= 32'hDEAD_BEEF;
                    end
                endcase
                apb_if.PREADY <= 1'b1;
                ready_set <= 1'b1;
                trans_done <= 1'b1;
            end

        end // else not reset
    end // always_ff

endmodule