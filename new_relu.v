module acc_bias_relu(

    input i_add4_end,
    input clk,
    input rst_n,
    input layer1,
    output o_acc_end,
    
    
    input [15:0] i_acc_bias_fm_col,
    
    input i_add4_valid,
    input signed [22*32-1:0] i_add4_data,
    input signed [22*32-1:0] i_bias,
    input [15:0] i_bias_addr_base,
    
    output [15:0] o_sel_bias_addr,
    output [8*32-1:0] o_acc_data_out,
    output o_acc_data_out_valid
    );

reg signed [23*32-1:0] add4_bias_buf;
reg [8*32-1:0] data_out_buf ;
reg [15:0] sel_bias_addr_buf;
reg add4_valid_ff1;
reg add4_valid_ff2;

reg acc_end_ff1;
reg acc_end_ff2;
integer i;
integer j;

    always @(posedge clk ) begin
        if (!rst_n) begin
            add4_bias_buf <= 0;
            data_out_buf <= 0;
            add4_valid_ff1 <=0;
            add4_valid_ff2 <=0;
            sel_bias_addr_buf = i_bias_addr_base; 
            acc_end_ff1<=0;
            acc_end_ff2<=0;

        end else begin

            // add bias and add4_out  first clock
            if(i_add4_valid == 1) begin
                for(i=0;i<32;i=i+1) begin
                    add4_bias_buf[23*i+:23] <= i_bias[22*i+:22] + i_add4_data[22*i+:22];
                end
                add4_valid_ff1 <=1 ;               
            end else begin
                add4_valid_ff1 <=0 ;               
            end

            //relu for the second clock
            if (add4_valid_ff1) begin
                for(j=0;j<32;j=j+1)begin
                    data_out_buf[8*j+:8] <= (add4_bias_buf[23*j+:23]<0)? 0:  (add4_bias_buf[23*j+7 +: 8]>=127)?  8'b01111111:(   add4_bias_buf[23*i+6]?    (add4_bias_buf[23*j+7 +: 8]+1):add4_bias_buf[23*j+7 +: 8] ) ;
                end
                add4_valid_ff2 <= add4_valid_ff1;
            end else begin
                add4_valid_ff2 <= 0;
            end

            if (i_add4_end) begin
               sel_bias_addr_buf <= sel_bias_addr_buf+32;
               acc_end_ff1 <=1;
            end else begin
               acc_end_ff1 <=0;
            end 
            acc_end_ff2 <= acc_end_ff1;
        end
        
    end
    
       
 wire [8*32-1:0] fifo_out;

   
reg [15:0] wr_cnt;
reg [15:0] rd_cnt;
reg rd_en;
reg out_valid;

wire full;
wire empty;
always @(posedge clk ) begin
    if(!rst_n) begin
        wr_cnt <= 0;
        rd_cnt <= 0;
        rd_en <= 0;
        out_valid<=0;
    end 
    else begin
        if(add4_valid_ff2) begin
            wr_cnt <= wr_cnt+1;
        end
        if(wr_cnt>= 1 ) begin
            rd_en <= 1;
            rd_cnt<=rd_cnt+1;
        end
        if(rd_cnt == (i_acc_bias_fm_col) ) begin
            rd_en <=0;
            wr_cnt <=0;
            rd_cnt<=0;
        end
        out_valid <= rd_en;
        
    end

end

acc_syn_fifo acc_syn_fifo_ins (
      .clk(clk),      // input wire clk
//      .srst(rst_n),    // input wire srst
      .din(data_out_buf),      // input wire [7 : 0] din
      .wr_en(add4_valid_ff2),  // input wire wr_en
      .rd_en(rd_en),  // input wire rd_en
      .dout(fifo_out),    // output wire [7 : 0] dout
      .full(full),    // output wire full
      .empty(empty)  // output wire empty
    );
    
    
assign o_acc_data_out = layer1==1? fifo_out:fifo_out[8*16-1:0];
assign o_acc_data_out_valid = out_valid;
assign o_sel_bias_addr =  sel_bias_addr_buf;  
assign o_acc_end = acc_end_ff2;   
    
endmodule