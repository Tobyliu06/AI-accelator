module cpu5_stage (
    input  wire clk,
    input  wire rst_n,
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_reg_t0,
    output wire [31:0] dbg_reg_t1
);

    // -----------------------------
    // Memories and register file
    // -----------------------------
    reg [31:0] imem [0:255];
    reg [31:0] dmem [0:255];
    reg [31:0] regs [0:31];

    // -----------------------------
    // Program counter
    // -----------------------------
    reg [31:0] pc;

    // -----------------------------
    // Pipeline registers
    // -----------------------------
    reg [31:0] if_id_pc;
    reg [31:0] if_id_instr;

    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_rs_val;
    reg [31:0] id_ex_rt_val;
    reg [31:0] id_ex_imm;
    reg [4:0]  id_ex_rs;
    reg [4:0]  id_ex_rt;
    reg [4:0]  id_ex_rd;

    reg        id_ex_reg_write;
    reg        id_ex_mem_read;
    reg        id_ex_mem_write;
    reg        id_ex_mem_to_reg;
    reg        id_ex_alu_src;
    reg [2:0]  id_ex_alu_op;
    reg        id_ex_branch;
    reg        id_ex_jump;

    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_rt_val;
    reg [4:0]  ex_mem_write_reg;
    reg        ex_mem_reg_write;
    reg        ex_mem_mem_read;
    reg        ex_mem_mem_write;
    reg        ex_mem_mem_to_reg;
    reg        ex_mem_take_branch;
    reg [31:0] ex_mem_branch_target;
    reg        ex_mem_take_jump;
    reg [31:0] ex_mem_jump_target;

    reg [31:0] mem_wb_mem_data;
    reg [31:0] mem_wb_alu_result;
    reg [4:0]  mem_wb_write_reg;
    reg        mem_wb_reg_write;
    reg        mem_wb_mem_to_reg;

    // -----------------------------
    // IF stage
    // -----------------------------
    wire [31:0] if_instr = imem[pc[9:2]];

    // -----------------------------
    // ID stage decode
    // -----------------------------
    wire [5:0] id_opcode = if_id_instr[31:26];
    wire [4:0] id_rs     = if_id_instr[25:21];
    wire [4:0] id_rt     = if_id_instr[20:16];
    wire [4:0] id_rd     = if_id_instr[15:11];
    wire [5:0] id_funct  = if_id_instr[5:0];
    wire [15:0] id_imm16 = if_id_instr[15:0];
    wire [25:0] id_jidx  = if_id_instr[25:0];

    wire [31:0] id_rs_val = regs[id_rs];
    wire [31:0] id_rt_val = regs[id_rt];
    wire [31:0] id_imm_sext = {{16{id_imm16[15]}}, id_imm16};

    reg        id_reg_write;
    reg        id_mem_read;
    reg        id_mem_write;
    reg        id_mem_to_reg;
    reg        id_alu_src;
    reg [2:0]  id_alu_op;
    reg        id_branch;
    reg        id_jump;

    // ALU op encoding
    // 000:add, 001:sub, 010:and, 011:or, 100:xor
    always @(*) begin
        id_reg_write = 1'b0;
        id_mem_read  = 1'b0;
        id_mem_write = 1'b0;
        id_mem_to_reg= 1'b0;
        id_alu_src   = 1'b0;
        id_alu_op    = 3'b000;
        id_branch    = 1'b0;
        id_jump      = 1'b0;

        case (id_opcode)
            6'b000000: begin // R-type
                id_reg_write = 1'b1;
                case (id_funct)
                    6'h20: id_alu_op = 3'b000; // add
                    6'h22: id_alu_op = 3'b001; // sub
                    6'h24: id_alu_op = 3'b010; // and
                    6'h25: id_alu_op = 3'b011; // or
                    6'h26: id_alu_op = 3'b100; // xor
                    default: id_reg_write = 1'b0; // treat unknown as nop
                endcase
            end
            6'h08: begin // addi
                id_reg_write = 1'b1;
                id_alu_src   = 1'b1;
                id_alu_op    = 3'b000;
            end
            6'h23: begin // lw
                id_reg_write = 1'b1;
                id_mem_read  = 1'b1;
                id_mem_to_reg= 1'b1;
                id_alu_src   = 1'b1;
                id_alu_op    = 3'b000;
            end
            6'h2b: begin // sw
                id_mem_write = 1'b1;
                id_alu_src   = 1'b1;
                id_alu_op    = 3'b000;
            end
            6'h04: begin // beq
                id_branch = 1'b1;
                id_alu_op = 3'b001;
            end
            6'h02: begin // j
                id_jump = 1'b1;
            end
            default: begin
                // nop
            end
        endcase
    end

    // -----------------------------
    // EX stage
    // -----------------------------
    wire [31:0] ex_src_b = id_ex_alu_src ? id_ex_imm : id_ex_rt_val;
    reg  [31:0] ex_alu_result;
    wire ex_zero = (id_ex_rs_val == id_ex_rt_val);
    wire [31:0] ex_branch_target = id_ex_pc + 32'd4 + (id_ex_imm << 2);
    wire [31:0] ex_jump_target   = {id_ex_pc[31:28], if_id_instr[25:0], 2'b00};

    always @(*) begin
        case (id_ex_alu_op)
            3'b000: ex_alu_result = id_ex_rs_val + ex_src_b;
            3'b001: ex_alu_result = id_ex_rs_val - ex_src_b;
            3'b010: ex_alu_result = id_ex_rs_val & ex_src_b;
            3'b011: ex_alu_result = id_ex_rs_val | ex_src_b;
            3'b100: ex_alu_result = id_ex_rs_val ^ ex_src_b;
            default: ex_alu_result = 32'd0;
        endcase
    end

    wire [4:0] ex_dst_reg = (id_ex_alu_src || id_ex_mem_read) ? id_ex_rt : id_ex_rd;

    // -----------------------------
    // WB mux
    // -----------------------------
    wire [31:0] wb_data = mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'd0;
            if_id_pc <= 32'd0;
            if_id_instr <= 32'd0;
            id_ex_pc <= 32'd0;
            id_ex_rs_val <= 32'd0;
            id_ex_rt_val <= 32'd0;
            id_ex_imm <= 32'd0;
            id_ex_rs <= 5'd0;
            id_ex_rt <= 5'd0;
            id_ex_rd <= 5'd0;
            id_ex_reg_write <= 1'b0;
            id_ex_mem_read <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_alu_src <= 1'b0;
            id_ex_alu_op <= 3'b000;
            id_ex_branch <= 1'b0;
            id_ex_jump <= 1'b0;
            ex_mem_alu_result <= 32'd0;
            ex_mem_rt_val <= 32'd0;
            ex_mem_write_reg <= 5'd0;
            ex_mem_reg_write <= 1'b0;
            ex_mem_mem_read <= 1'b0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_mem_to_reg <= 1'b0;
            ex_mem_take_branch <= 1'b0;
            ex_mem_branch_target <= 32'd0;
            ex_mem_take_jump <= 1'b0;
            ex_mem_jump_target <= 32'd0;
            mem_wb_mem_data <= 32'd0;
            mem_wb_alu_result <= 32'd0;
            mem_wb_write_reg <= 5'd0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;

            for (i = 0; i < 32; i = i + 1) regs[i] <= 32'd0;
            for (i = 0; i < 256; i = i + 1) dmem[i] <= 32'd0;
        end else begin
            // WB
            if (mem_wb_reg_write && (mem_wb_write_reg != 5'd0)) begin
                regs[mem_wb_write_reg] <= wb_data;
            end

            // MEM
            if (ex_mem_mem_write) begin
                dmem[ex_mem_alu_result[9:2]] <= ex_mem_rt_val;
            end
            mem_wb_mem_data <= ex_mem_mem_read ? dmem[ex_mem_alu_result[9:2]] : 32'd0;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_write_reg <= ex_mem_write_reg;
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;

            // EX -> MEM
            ex_mem_alu_result <= ex_alu_result;
            ex_mem_rt_val <= id_ex_rt_val;
            ex_mem_write_reg <= ex_dst_reg;
            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_take_branch <= id_ex_branch && ex_zero;
            ex_mem_branch_target <= ex_branch_target;
            ex_mem_take_jump <= id_ex_jump;
            ex_mem_jump_target <= ex_jump_target;

            // ID -> EX
            id_ex_pc <= if_id_pc;
            id_ex_rs_val <= id_rs_val;
            id_ex_rt_val <= id_rt_val;
            id_ex_imm <= id_imm_sext;
            id_ex_rs <= id_rs;
            id_ex_rt <= id_rt;
            id_ex_rd <= id_rd;
            id_ex_reg_write <= id_reg_write;
            id_ex_mem_read <= id_mem_read;
            id_ex_mem_write <= id_mem_write;
            id_ex_mem_to_reg <= id_mem_to_reg;
            id_ex_alu_src <= id_alu_src;
            id_ex_alu_op <= id_alu_op;
            id_ex_branch <= id_branch;
            id_ex_jump <= id_jump;

            // IF/PC update with simple control hazard handling
            if (ex_mem_take_jump) begin
                pc <= ex_mem_jump_target;
                if_id_instr <= 32'd0;
                if_id_pc <= 32'd0;
            end else if (ex_mem_take_branch) begin
                pc <= ex_mem_branch_target;
                if_id_instr <= 32'd0;
                if_id_pc <= 32'd0;
            end else begin
                if_id_pc <= pc;
                if_id_instr <= if_instr;
                pc <= pc + 32'd4;
            end

            regs[0] <= 32'd0;
        end
    end

    assign dbg_pc = pc;
    assign dbg_reg_t0 = regs[8];
    assign dbg_reg_t1 = regs[9];

endmodule
