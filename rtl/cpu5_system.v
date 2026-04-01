module cpu5_system (
    input  wire clk,
    input  wire rst_n,
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_r8,
    output wire [31:0] dbg_r9,
    output wire [31:0] dbg_r10
);
    // ------------------ memories ------------------
    reg [31:0] imem [0:255];
    reg [31:0] dmem [0:255];

    // ------------------ PC + IF ------------------
    reg [31:0] pc;
    wire [31:0] instr_if = imem[pc[9:2]];

    // IF/ID
    reg [31:0] if_id_pc;
    reg [31:0] if_id_instr;

    // ID decode wires
    wire [5:0] id_opcode = if_id_instr[31:26];
    wire [4:0] id_rs     = if_id_instr[25:21];
    wire [4:0] id_rt     = if_id_instr[20:16];
    wire [4:0] id_rd     = if_id_instr[15:11];
    wire [5:0] id_funct  = if_id_instr[5:0];
    wire [15:0] id_imm16 = if_id_instr[15:0];
    wire [25:0] id_jidx  = if_id_instr[25:0];
    wire [31:0] id_imm_sext = {{16{id_imm16[15]}}, id_imm16};
    wire [31:0] id_imm_zext = {16'd0, id_imm16};

    wire id_reg_write, id_mem_read, id_mem_write, id_mem_to_reg, id_alu_src;
    wire id_branch_eq, id_branch_ne, id_jump, id_valid_inst;
    wire [3:0] id_alu_ctrl;

    control_unit u_ctrl (
        .opcode(id_opcode), .funct(id_funct),
        .reg_write(id_reg_write), .mem_read(id_mem_read), .mem_write(id_mem_write),
        .mem_to_reg(id_mem_to_reg), .alu_src(id_alu_src), .alu_ctrl(id_alu_ctrl),
        .branch_eq(id_branch_eq), .branch_ne(id_branch_ne), .jump(id_jump), .valid_inst(id_valid_inst)
    );

    wire [31:0] rf_rdata1, rf_rdata2;
    wire [31:0] wb_data;
    regfile32 u_rf (
        .clk(clk),
        .we(mem_wb_reg_write),
        .waddr(mem_wb_rd),
        .wdata(wb_data),
        .raddr1(id_rs),
        .raddr2(id_rt),
        .rdata1(rf_rdata1),
        .rdata2(rf_rdata2)
    );

    // ID/EX
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_rs_val;
    reg [31:0] id_ex_rt_val;
    reg [31:0] id_ex_imm;
    reg [4:0]  id_ex_rs;
    reg [4:0]  id_ex_rt;
    reg [4:0]  id_ex_rd;
    reg [25:0] id_ex_jidx;

    reg        id_ex_reg_write;
    reg        id_ex_mem_read;
    reg        id_ex_mem_write;
    reg        id_ex_mem_to_reg;
    reg        id_ex_alu_src;
    reg [3:0]  id_ex_alu_ctrl;
    reg        id_ex_branch_eq;
    reg        id_ex_branch_ne;
    reg        id_ex_jump;

    wire hazard_stall;
    hazard_unit u_hazard (
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rt(id_ex_rt),
        .if_id_rs(id_rs),
        .if_id_rt(id_rt),
        .stall(hazard_stall)
    );

    // EX stage + forwarding
    wire [1:0] fwd_a, fwd_b;
    forward_unit u_fwd (
        .id_ex_rs(id_ex_rs), .id_ex_rt(id_ex_rt),
        .ex_mem_reg_write(ex_mem_reg_write), .ex_mem_rd(ex_mem_rd),
        .mem_wb_reg_write(mem_wb_reg_write), .mem_wb_rd(mem_wb_rd),
        .fwd_a(fwd_a), .fwd_b(fwd_b)
    );

    reg [31:0] ex_src_a, ex_src_b_base;
    always @(*) begin
        case (fwd_a)
            2'b10: ex_src_a = ex_mem_alu_y;
            2'b01: ex_src_a = wb_data;
            default: ex_src_a = id_ex_rs_val;
        endcase

        case (fwd_b)
            2'b10: ex_src_b_base = ex_mem_alu_y;
            2'b01: ex_src_b_base = wb_data;
            default: ex_src_b_base = id_ex_rt_val;
        endcase
    end

    wire [31:0] ex_src_b = id_ex_alu_src ? id_ex_imm : ex_src_b_base;
    wire [31:0] ex_alu_y;
    wire ex_zero;

    alu32 u_alu (
        .a(ex_src_a),
        .b(ex_src_b),
        .alu_ctrl(id_ex_alu_ctrl),
        .y(ex_alu_y),
        .zero(ex_zero)
    );

    wire [31:0] ex_branch_target = id_ex_pc + 32'd4 + (id_ex_imm << 2);
    wire [31:0] ex_jump_target   = {id_ex_pc[31:28], id_ex_jidx, 2'b00};
    wire ex_take_branch = (id_ex_branch_eq && ex_zero) || (id_ex_branch_ne && !ex_zero);

    wire [4:0] ex_dst = id_ex_alu_src ? id_ex_rt : id_ex_rd;

    // EX/MEM
    reg [31:0] ex_mem_alu_y;
    reg [31:0] ex_mem_store_data;
    reg [4:0]  ex_mem_rd;
    reg        ex_mem_reg_write;
    reg        ex_mem_mem_read;
    reg        ex_mem_mem_write;
    reg        ex_mem_mem_to_reg;
    reg        ex_mem_take_branch;
    reg [31:0] ex_mem_branch_target;
    reg        ex_mem_take_jump;
    reg [31:0] ex_mem_jump_target;

    // MEM/WB
    reg [31:0] mem_wb_mem_rdata;
    reg [31:0] mem_wb_alu_y;
    reg [4:0]  mem_wb_rd;
    reg        mem_wb_reg_write;
    reg        mem_wb_mem_to_reg;

    assign wb_data = mem_wb_mem_to_reg ? mem_wb_mem_rdata : mem_wb_alu_y;

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
            id_ex_jidx <= 26'd0;
            id_ex_reg_write <= 1'b0;
            id_ex_mem_read <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_alu_src <= 1'b0;
            id_ex_alu_ctrl <= 4'd0;
            id_ex_branch_eq <= 1'b0;
            id_ex_branch_ne <= 1'b0;
            id_ex_jump <= 1'b0;

            ex_mem_alu_y <= 32'd0;
            ex_mem_store_data <= 32'd0;
            ex_mem_rd <= 5'd0;
            ex_mem_reg_write <= 1'b0;
            ex_mem_mem_read <= 1'b0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_mem_to_reg <= 1'b0;
            ex_mem_take_branch <= 1'b0;
            ex_mem_branch_target <= 32'd0;
            ex_mem_take_jump <= 1'b0;
            ex_mem_jump_target <= 32'd0;

            mem_wb_mem_rdata <= 32'd0;
            mem_wb_alu_y <= 32'd0;
            mem_wb_rd <= 5'd0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;

            for (i = 0; i < 256; i = i + 1) dmem[i] <= 32'd0;
        end else begin
            // MEM stage
            if (ex_mem_mem_write) begin
                dmem[ex_mem_alu_y[9:2]] <= ex_mem_store_data;
            end
            mem_wb_mem_rdata <= ex_mem_mem_read ? dmem[ex_mem_alu_y[9:2]] : 32'd0;
            mem_wb_alu_y <= ex_mem_alu_y;
            mem_wb_rd <= ex_mem_rd;
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;

            // EX->MEM
            ex_mem_alu_y <= ex_alu_y;
            ex_mem_store_data <= ex_src_b_base;
            ex_mem_rd <= ex_dst;
            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_take_branch <= ex_take_branch;
            ex_mem_branch_target <= ex_branch_target;
            ex_mem_take_jump <= id_ex_jump;
            ex_mem_jump_target <= ex_jump_target;

            // IF + ID handling
            if (ex_mem_take_jump) begin
                pc <= ex_mem_jump_target;
                if_id_pc <= 32'd0;
                if_id_instr <= 32'd0;

                // bubble ID/EX
                id_ex_reg_write <= 1'b0;
                id_ex_mem_read <= 1'b0;
                id_ex_mem_write <= 1'b0;
                id_ex_mem_to_reg <= 1'b0;
                id_ex_alu_src <= 1'b0;
                id_ex_alu_ctrl <= 4'd0;
                id_ex_branch_eq <= 1'b0;
                id_ex_branch_ne <= 1'b0;
                id_ex_jump <= 1'b0;
            end else if (ex_mem_take_branch) begin
                pc <= ex_mem_branch_target;
                if_id_pc <= 32'd0;
                if_id_instr <= 32'd0;

                // bubble ID/EX
                id_ex_reg_write <= 1'b0;
                id_ex_mem_read <= 1'b0;
                id_ex_mem_write <= 1'b0;
                id_ex_mem_to_reg <= 1'b0;
                id_ex_alu_src <= 1'b0;
                id_ex_alu_ctrl <= 4'd0;
                id_ex_branch_eq <= 1'b0;
                id_ex_branch_ne <= 1'b0;
                id_ex_jump <= 1'b0;
            end else if (hazard_stall) begin
                // Stall IF/ID and PC, insert bubble into ID/EX
                pc <= pc;
                if_id_pc <= if_id_pc;
                if_id_instr <= if_id_instr;

                id_ex_reg_write <= 1'b0;
                id_ex_mem_read <= 1'b0;
                id_ex_mem_write <= 1'b0;
                id_ex_mem_to_reg <= 1'b0;
                id_ex_alu_src <= 1'b0;
                id_ex_alu_ctrl <= 4'd0;
                id_ex_branch_eq <= 1'b0;
                id_ex_branch_ne <= 1'b0;
                id_ex_jump <= 1'b0;
            end else begin
                // Normal IF
                if_id_pc <= pc;
                if_id_instr <= instr_if;
                pc <= pc + 32'd4;

                // Normal ID->EX
                id_ex_pc <= if_id_pc;
                id_ex_rs_val <= rf_rdata1;
                id_ex_rt_val <= rf_rdata2;
                id_ex_imm <= (id_opcode == 6'h0c || id_opcode == 6'h0d) ? id_imm_zext : id_imm_sext;
                id_ex_rs <= id_rs;
                id_ex_rt <= id_rt;
                id_ex_rd <= id_rd;
                id_ex_jidx <= id_jidx;
                id_ex_reg_write <= id_reg_write && id_valid_inst;
                id_ex_mem_read <= id_mem_read;
                id_ex_mem_write <= id_mem_write;
                id_ex_mem_to_reg <= id_mem_to_reg;
                id_ex_alu_src <= id_alu_src;
                id_ex_alu_ctrl <= id_alu_ctrl;
                id_ex_branch_eq <= id_branch_eq;
                id_ex_branch_ne <= id_branch_ne;
                id_ex_jump <= id_jump;
            end
        end
    end

    assign dbg_pc = pc;
    assign dbg_r8 = u_rf.regs[8];
    assign dbg_r9 = u_rf.regs[9];
    assign dbg_r10 = u_rf.regs[10];
endmodule
