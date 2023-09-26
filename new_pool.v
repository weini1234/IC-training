`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/02 16:22:42
// Design Name: 
// Module Name: pool_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pool_module(
	input clk,
	input rst_n,
	input pool_en,
	input layer1,
	input valid_in,
	input signed [8*32-1:0] data_in,
	
	input [15:0] col,
	
	output signed [8*16-1:0] data_out,
	//output [15:0] addr_out_row,
	//output [15:0] addr_out_col,
	output valid_out,
	output pool_end
    );
//generate start;
reg valid_in_ff1;
reg signed [8*32-1:0] data_in_ff1;
reg valid_in_ff2;
reg signed [8*32-1:0] data_in_ff2;
reg start;
reg nopool_end;
always@(posedge clk)
begin
	if(!rst_n)
		begin
			valid_in_ff1<=0;
			data_in_ff1<=0;
			valid_in_ff2<=0;
			data_in_ff2<=0;
			start<=0;
			nopool_end<=0;
		end
	else	
		begin
			data_in_ff1<=data_in;
			data_in_ff2<=data_in_ff1;
			valid_in_ff1<=valid_in;
			valid_in_ff2<=valid_in_ff1;
			nopool_end<=(!valid_in)&valid_in_ff1;
			start<=(!valid_in_ff1)&valid_in;
		end
end
//////start module
reg start_reg;
reg pool_over;
reg pool_over_ff1;
always@(posedge clk)
begin
	if(!rst_n)
		begin
			start_reg<=0;
		end
	else
		begin
			if(start)
				begin
					start_reg<=1;
				end
			else
				begin
					if(pool_over)
						begin
							start_reg<=0;
						end
					else
						begin
							start_reg<=start_reg;
						end
				end
			
		end
end



reg [15:0] col_num;
reg pool_valid;
reg signed [7:0] pool_temp[0:31];
integer i;
integer j;
integer k;
integer m;
integer n;
integer a;
always@(posedge clk)
begin
	if(!rst_n)
		begin
			col_num<=0;
            for(i=0;i<32;i=i+1)begin
            pool_temp[i]<=0;
            end
			pool_valid<=0;
			pool_over<=0;
			pool_over_ff1<=0;
		end
	else
		begin
			if(start_reg)
				begin
                if(col_num<=col-1)
                begin
                    for(j=0;j<32;j=j+1)
                    begin
                     pool_temp[j]<=data_in_ff2[8*(j+1)-1:8*j];
                    end
                    if(col_num<col-1)
                    begin
                        if(col_num%2==1)
                        begin
                        pool_valid<=1;
                        end
                        else
                        begin
                        pool_valid<=0;
                        end
                        col_num<=col_num+1;
                        pool_over<=0;
                    end
                    else
                    begin
                        pool_valid<=1;
                        col_num<=0;
                        pool_over<=1;
                    end

                end
                else begin
                    col_num<=0;
                    pool_valid<=pool_valid;
                    pool_over<=pool_over;
                end
				pool_over_ff1<=pool_over;
				end
					
			else
				begin
					
					col_num<=0;
					pool_valid<=0;
					for(k=0;k<32;k=k+1)begin
                        pool_temp[k]=0;
                    end
					
					pool_over<=0;
					pool_over_ff1<=0;
				end
		end
end
	

		
		
	







reg signed [7:0] pool1[0:15];
reg signed [7:0] pool2[0:15];
reg signed [8*32-1:0] pool_result;

reg pool_result_valid;
reg pool_ff1;
reg start_regff1;
reg pool_overff2;
reg pool_overff3;
always@(posedge clk)
begin
	if(!rst_n)
		begin
			//addr_row<=0;
			//addr_col<=0;
			pool1<=0;
			pool2<=0;
			pool_result<=0;
			pool_result_valid<=0;
			pool_ff1<=0;
			start_regff1<=0;
			pool_overff2<=0;
			pool_overff3<=0;
		end
	else
		begin
			start_regff1<=start_reg;
			pool_overff2<=pool_over_ff1;
			pool_overff3<=pool_overff2;
			if(start_regff1)
				begin
                    for (m=0;m<16;m=m+1)begin
					    if(pool_temp[2*m]<pool_temp[2*m+1])
						begin
							pool1[m]<=pool_temp[2*m+1];
						end
					    else
						begin
							pool1[m]<=pool_temp[2*m];
						end
                    end
                    for (n=0;n<16;n=n+1)begin
                        pool2[n]=pool1[n];
                    end
                    for (a=0;a<16;a=a+1)begin
                        if(pool1[a]<pool2[a])
                        begin
                            pool_result[8*(a+1)-1:8*a]=pool2[a];
                        end
                        else 
                        begin
                            pool_result[8*(a+1)-1:8*a]=pool1[a];
                        end
                    end
					
					pool_ff1<=pool_valid;
					
					pool_result_valid<=pool_ff1;
					
					//if(pool_result_valid)
					//	begin
					//		addr_col<=addr_col+1;
					//		if(addr_col==col-1)
					//			begin
					//				addr_col<=0;
					//				if(addr_row==row-1)
					//					begin
					//						addr_row<=0;
					//					end
					//				else
					//					begin
					//						addr_row<=addr_row+1;
					//					end
					//		end
					//		else
					//		begin
					//			addr_row<=addr_row;
					//		end
					//	end
					//else
					//	begin
					//		addr_col<=addr_col;
					//	end
				end
			else
				begin
					//addr_row<=0;
					//addr_col<=0;
					pool1<=0;
					pool2<=0;
					pool_result<=0;
					pool_result_valid<=0;
					pool_ff1<=0;
					pool_overff2<=0;
				end
		end
end	
assign pool_end=pool_en ? pool_overff3 : nopool_end;
//assign data_out=pool_result;
//assign valid_out=pool_result_valid;

assign data_out=pool_en ?(layer1? pool_result: pool_result[16*8-1:0]):data_in;
assign valid_out=pool_en ? pool_result_valid:valid_in;
//assign addr_out_col=addr_col;
//assign addr_out_row=addr_row;
endmodule


























