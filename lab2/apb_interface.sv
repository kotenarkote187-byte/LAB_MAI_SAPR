interface apb_interface;
    
    logic PCLK;   
    logic PRESETn; 
    logic PSEL;    
    logic PENABLE; 
    logic PWRITE;   
    logic [31:0] PADDR;  
    logic [31:0] PWDATA; 
    logic [31:0] PRDATA;
    logic PSLVERR;  
    logic PREADY;   
    
   
    modport master_mp (
        output PRESETn, 
        output PSEL,    
        output PENABLE, 
        output PWRITE,  
        output PADDR,  
        output PWDATA, 
        input  PRDATA, 
        input  PSLVERR, 
        input  PREADY,  
        input  PCLK    
    );
    
    
    modport slave_mp (
        input  PCLK,  
        input  PRESETn, 
        input  PSEL,    
        input  PENABLE, 
        input  PWRITE,  
        input  PADDR,  
        input  PWDATA,   
        output PRDATA, 
        output PSLVERR, 
        output PREADY 
    );
endinterface