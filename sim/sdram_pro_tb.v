//----------------------------------------------------------------------------------------------------
//--SDRAM仿真文件
//----------------------------------------------------------------------------------------------------
`timescale  1ns/1ns		

/* 
module  sdram_pro_tb();
 
//------------<wire定义>----------------------------------------------------------------------------------	
//sdram_init					
wire    [3:0]   init_cmd        ;   					//初始化阶段指令
wire    [1:0]   init_bank       ;   					//初始化阶段L-Bank地址
wire    [11:0]  init_addr       ;   					//初始化阶段地址总线
wire            init_end        ;   					//初始化完成信号
//sdram_atref
wire            atref_req		;   //自动刷新请求
wire            atref_end		;   //自动刷新结束
wire    [3:0]   atref_cmd		;   //自动刷新阶段指令
wire    [1:0]   atref_bank		;   //自动刷新阶段L-Bank地址
wire    [11:0]  atref_addr		;   //自动刷新阶段地址总线
//sdram_write
wire    [12:0]  wr_sdram_addr	;   //数据写阶段地址总线
wire    [1:0]   wr_sdram_bank	;   //数据写阶段L-Bank地址
wire    [3:0]   wr_sdram_cmd	;   //数据写阶段指令
wire    [15:0]  wr_sdram_data   ;   //数据写阶段写入SDRAM数据
wire            wr_sdram_en     ;   //数据写阶段写数据有效使能信号
wire            wr_end          ;   //数据写阶段一次突发写结束
wire            sdram_wr_ack    ;   //数据写阶段写响应
//sdram_read
wire    [12:0]  rd_sdram_addr	;   //数据读阶段地址总线
wire    [1:0]   rd_sdram_bank	;   //数据读阶段L-Bank地址
wire    [3:0]   rd_sdram_cmd	;   //数据读阶段指令
wire    [15:0]  rd_sdram_data	;   //数据读阶段读取SDRAM数据
wire            rd_end          ;   //数据读阶段一次突发写结束
//sdram_plus
wire	[3:0]	sdram_cmd;
wire	[11:0]	sdram_addr;
wire	[1:0]	sdram_abnk;
wire	[15:0]	sdram_dq;

//------------<reg定义>----------------------------------------------------------------------------------		
reg             sys_clk         ;   					//系统时钟
reg             sys_rst_n       ;   					//复位信号
reg				atref_en		;
reg				wr_en;
reg		[15:0]	wr_data_in;
reg             rd_en           ;   //读使能

//------------<defparam定义>----------------------------------------------------------------------------------		
//重定义仿真模型中的相关参数
defparam sdram_model_plus_inst.addr_bits = 12;          //地址位宽
defparam sdram_model_plus_inst.data_bits = 16;          //数据位宽
defparam sdram_model_plus_inst.col_bits  = 9;           //列地址位宽
defparam sdram_model_plus_inst.mem_sizes = 2*1024*1024; //L-Bank容量
 
// parameter
parameter WR_BURST_LEN = 'd512;

//------------<设置初始测试条件>----------------------------------------
initial
  begin
    sys_clk     =   1'b1  ;
    sys_rst_n   <=  1'b0  ;
    #200
    sys_rst_n   <=  1'b1  ;
  end
//时钟信号
always  #10 sys_clk = ~sys_clk;

//atref_en:自动刷新使能
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        atref_en <=  1'b0;
    else    if((init_end == 1'b1) && (atref_req == 1'b1))
        atref_en <=  1'b1;
    else    if(atref_end == 1'b1)
        atref_en <=  1'b0;

//wr_en：写数据使能
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        wr_en   <=  1'b0;
    else    if(wr_end == 1'b1)
        wr_en   <=  1'b0;
    else    if(init_end == 1'b1)
        wr_en   <=  1'b1;
    else
        wr_en   <=  wr_en;
//wr_data_in:写数据
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        wr_data_in  <=  16'd0;
    else    if(wr_data_in == WR_BURST_LEN)
        wr_data_in  <=  16'd0;
    else    if(sdram_wr_ack == 1'b1)
        wr_data_in  <=  wr_data_in + 1'b1;
    else
        wr_data_in  <=  wr_data_in;


//rd_en:读数据使能
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rd_en   <=  1'b0;
    else    if(rd_end == 1'b1)
        rd_en   <=  1'b0;
    else    if(wr_en == 1'b0)
        rd_en   <=  1'b1;
    else
        rd_en   <=  rd_en;


//wr_sdram_data
assign  sdram_dq = (wr_sdram_en == 1'b1) ? wr_sdram_data : 16'hz;
 
 
//sdram_cmd,sdram_ba,sdram_addr
// assign  sdram_cmd  = (init_end == 1'b1) ? wr_sdram_cmd  : init_cmd;
// assign  sdram_bank = (init_end == 1'b1) ? wr_sdram_bank : init_bank;
// assign  sdram_addr = (init_end == 1'b1) ? wr_sdram_addr : init_addr;
assign  sdram_cmd  = (init_end == 1'b1) ? 
						(wr_end == 1'b1) ? rd_sdram_cmd  : wr_sdram_cmd 
						 : init_cmd;
assign  sdram_bank  = (init_end == 1'b1) ? 
						(wr_end == 1'b1) ? rd_sdram_bank  : wr_sdram_bank 
						 : init_bank;
assign  sdram_addr  = (init_end == 1'b1) ? 
						(wr_end == 1'b1) ? rd_sdram_addr  : wr_sdram_addr 
						 : init_addr;
// assign  sdram_cmd  = (wr_end == 1'b1) ? wr_sdram_cmd  : rd_sdram_cmd;
// assign  sdram_bank = (wr_end == 1'b1) ? wr_sdram_bank : rd_sdram_bank;
// assign  sdram_addr = (wr_end == 1'b1) ? wr_sdram_addr : rd_sdram_addr;


//------------<例化被测试模块>----------------------------------------
//sdram初始化模块
sdram_pro_init  U_sdram_pro_init(
    .sys_clk   (sys_clk   ),
    .sys_rst_n (sys_rst_n    ),
    .init_cmd   (init_cmd   ),
    .init_bank	(init_bank	),
    .init_addr  (init_addr  ),
    .init_end   (init_end   )
);

//sdram自动刷新模块
// sdram_pro_autorefresh U_sdram_pro_autorefresh(
    // .sys_clk		(sys_clk	),
    // .sys_rst_n	(sys_rst_n		),
    // .init_end		(init_end	),
    // //.atref_en		(atref_en   ),
    // .atref_en		(0   ),
    // .atref_req		(atref_req	),
    // .atref_addr		(atref_addr	),
    // .atref_cmd		(atref_cmd	),
    // .atref_bank		(atref_bank ),
    // .atref_end		(atref_end  )
// );

// sdram写数据模块
sdram_pro_write U_sdram_pro_write(
 
    .sys_clk        (sys_clk		),
    .sys_rst_n      (sys_rst_n      ),
    .init_end       (init_end       ),
    .wr_en          (wr_en          ),
 
    .wr_addr        (23'h0    ),
    .wr_data        (wr_data_in     ),
    .wr_burst_len   (WR_BURST_LEN   ),
 
    .wr_ack         (sdram_wr_ack   ),
    .wr_end         (wr_end         ),
    .wr_sdram_cmd	(wr_sdram_cmd	),
    .wr_sdram_bank	(wr_sdram_bank	),
    .wr_sdram_addr	(wr_sdram_addr	),
    .wr_sdram_en    (wr_sdram_en    ),
    .wr_sdram_data  (wr_sdram_data  )
 
);

//------------- sdram_read_inst -------------
sdram_pro_read  U_sdram_pro_read(
    .sys_clk       	(sys_clk        ),
    .sys_rst_n     	(sys_rst_n      ),
    .init_end       (init_end       ),
    .rd_en          (rd_en          ),
    .rd_addr        (23'h0    		),
    .rd_sdram_data  (sdram_dq       ),
    .rd_burst_len   (WR_BURST_LEN   ),
    .rd_ack         (               ),
    .rd_end         (rd_end         ),
    .rd_sdram_cmd	(rd_sdram_cmd	),
    .rd_sdram_bank	(rd_sdram_bank	),
    .rd_sdram_addr	(rd_sdram_addr	),
    .rd_data_out	(rd_sdram_data	)
);



//sdram模型模块
sdram_model_plus    sdram_model_plus_inst(
    .Dq     (sdram_dq        ),
    .Addr   (sdram_addr      ),
    .Ba     (sdram_addr		 ),
    .Clk    (sys_clk 		 ),
    .Cke    (1'b1            ),			//时钟使能信号一直拉高
    .Cs_n   (sdram_cmd[3]    ),
    .Ras_n  (sdram_cmd[2]    ),
    .Cas_n  (sdram_cmd[1]    ),
    .We_n   (sdram_cmd[0]    ),
    .Dqm    (4'b0            ),
    .Debug  (1'b1            )			//使能在MODLESIM窗口打印输出信息
 
);
//------------------------------------------------
//--状态机名称查看器
//------------------------------------------------
//reg [79:0]	name_state_cur;			//每字符8位宽，这里取最多10个字符80位宽
 
// always @(*) begin
    // case(sdram_pro_init_inst.cur_state)
        // 3'b000:		name_state_cur = "INIT_WAIT ";
        // 3'b001:		name_state_cur = "INIT_PRE  ";
        // 3'b011:		name_state_cur = "INIT_TRP  ";
        // 3'b010:		name_state_cur = "INIT_AR   "; 
		// 3'b110:		name_state_cur = "INIT_TRFC "; 
		// 3'b111:		name_state_cur = "INIT_MRS  "; 
		// 3'b101:		name_state_cur = "INIT_TMRD "; 
		// 3'b100:		name_state_cur = "INIT_END  "; 
        // default:	name_state_cur = "INIT_WAIT";
    // endcase
// end
 
//------------------------------------------------
 
endmodule
*/



// 总体仿真
`timescale  1ns/1ns
 
module  tb_sdram_pro_top();
 
//********************************************************************//
//****************** Internal Signal and Defparam ********************//
//********************************************************************//
 
//wire define
//sdram
wire            sdram_cke       ;   //SDRAM时钟使能信号
wire            sdram_cs_n      ;   //SDRAM片选信号
wire            sdram_ras_n     ;   //SDRAM行选通信号
wire            sdram_cas_n     ;   //SDRAM列选题信号
wire            sdram_we_n      ;   //SDRAM写使能信号
wire    [3:0]   sdram_cmd       ;   //
wire    [1:0]   sdram_bank		;   //SDRAM L-Bank地址
wire    [11:0]  sdram_addr      ;   //SDRAM地址总线
wire    [15:0]  sdram_dq        ;   //SDRAM数据总线
//sdram_ctrl
wire            init_end        ;   //初始化完成信号
wire            sdram_wr_ack    ;   //数据写阶段写响应
wire            sdram_rd_ack    ;   //数据读阶段响应
wire	[15:0]  wr_data_out		;   //读数据
//reg define
reg             sys_clk         ;   //系统时钟
reg             sys_rst_n       ;   //复位信号
reg             wr_en           ;   //写使能
reg     [15:0]  wr_data_in      ;   //写数据
reg             rd_en           ;   //读使能


//defparam
//重定义仿真模型中的相关参数
defparam sdram_model_plus_inst.addr_bits = 12;          //地址位宽
defparam sdram_model_plus_inst.data_bits = 16;          //数据位宽
defparam sdram_model_plus_inst.col_bits  = 9;           //列地址位宽
defparam sdram_model_plus_inst.mem_sizes = 2*1024*1024; //L-Bank容量
 
//重定义自动刷新模块自动刷新间隔时间计数最大值
//defparam sdram_ctrl_inst.sdram_atref_inst.CNT_REF_MAX = 39;
 
//********************************************************************//
//**************************** Clk And Rst ***************************//
//********************************************************************//
 
//时钟、复位信号
initial
  begin
    sys_clk     =   1'b1  ;
    sys_rst_n   <=  1'b0  ;
    #200
    sys_rst_n   <=  1'b1  ;
  end
always  #10 sys_clk = ~sys_clk;
//wr_en：写数据使能
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        wr_en   <=  1'b1;
    else    if(wr_data_in == 10'd10)
        wr_en   <=  1'b0;
    else
        wr_en   <=  wr_en;
//wr_data_in:写数据
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        wr_data_in  <=  16'd0;
    else    if(wr_data_in == 16'd10)
        wr_data_in  <=  16'd0;
    else    if(sdram_wr_ack == 1'b1)
        wr_data_in  <=  wr_data_in + 1'b1;
    else
        wr_data_in  <=  wr_data_in;
//rd_en:读数据使能
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rd_en   <=  1'b0;
    else    if(wr_en == 1'b0)
        rd_en   <=  1'b1;
    else
        rd_en   <=  rd_en;
//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//
//------------- sdram_ctrl_inst -------------
sdram_pro_top  U_sdram_pro_top(
    .sys_clk		(sys_clk        ),   //系统时钟
    .sys_rst_n		(sys_rst_n      ),   //复位信号，低电平有效
//SDRAM 控制器写端口
    .sdram_wr_req   (wr_en          ),   //写SDRAM请求信号
    .sdram_wr_addr  (23'h0		    ),   //SDRAM写操作的地址
    .WR_BURST_LEN   (10'd10         ),   //写sdram时数据突发长度
    .sdram_data_in  (wr_data_in     ),   //写入SDRAM的数据
    .sdram_wr_ack   (sdram_wr_ack   ),   //写SDRAM响应信号
//SDRAM 控制器读端口
    .sdram_rd_req   (rd_en          ),  //读SDRAM请求信号
    .sdram_rd_addr  (23'h0		    ),  //SDRAM写操作的地址
    .RD_BURST_LEN   (10'd10         ),  //读sdram时数据突发长度
    .sdram_data_out (sdram_data_out ),  //从SDRAM读出的数据
    //.init_end       (init_end       ),  //SDRAM 初始化完成标志
    .sdram_rd_ack   (			    ),  //读SDRAM响应信号
//FPGA与SDRAM硬件接口
    .sdram_cke      (sdram_cke      ),  // SDRAM 时钟有效信号
    .sdram_cmd      (sdram_cmd      ),  // SDRAM 片选信号
    .sdram_bank		(sdram_bank		),  // SDRAM L-Bank地址线
    .sdram_addr     (sdram_addr     ),  // SDRAM 地址总线
    .sdram_dq       (sdram_dq       )   // SDRAM 数据总线
);
//-------------sdram_model_plus_inst-------------
sdram_model_plus    sdram_model_plus_inst(
    .Dq     (sdram_dq       ),
    .Addr   (sdram_addr     ),
    .Ba     (sdram_bank		),
    .Clk    (sys_clk		),
    .Cke    (sdram_cke      ),
    .Cs_n   (sdram_cmd[3]   ),
    .Ras_n  (sdram_cmd[2]   ),
    .Cas_n  (sdram_cmd[1]   ),
    .We_n   (sdram_cmd[0]   ),
    .Dqm    (2'b0           ),
    .Debug  (1'b1           )
);
endmodule