library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lib.all;

-- MIPS pipelined processor implementation with hazard detection
-- clk and rst - Main processor
entity mips_pipeline is
	generic (
		WIDTH : positive := DATA_WIDTH
	);
	port (
		clk : in std_logic;
		rst : in std_logic
	);
end entity;

architecture arch of mips_pipeline is
	signal notclk : std_logic;
	
	-- Clear signals for the registers to flush the pipeline
	signal clear_IF_reg : std_logic := '0';
	signal clear_ID_reg : std_logic := '0';
	signal clear_EX_reg : std_logic := '0';
	signal clear_MEM_reg : std_logic := '0';
	
	-- Write enable signals for each stage to stall the pipeline
	signal write_PC_en : std_logic;
	signal write_IF_en : std_logic;
	signal write_ID_en : std_logic;
	signal write_EX_en : std_logic;
	signal write_MEM_en : std_logic := '1';
	
	-- Hazard control signals
	signal hazard_EXMEM_rt_to_IDEX_rs : std_logic;
	signal hazard_EXMEM_rt_to_IDEX_rt : std_logic;
	signal hazard_MEMWB_rt_to_IDEX_rs : std_logic;
	signal hazard_MEMWB_rt_to_IDEX_rt : std_logic;
	signal hazard_EXMEM_rd_to_IDEX_rs : std_logic;
	signal hazard_EXMEM_rd_to_IDEX_rt : std_logic;
	signal hazard_MEMWB_rd_to_IDEX_rs : std_logic;
	signal hazard_MEMWB_rd_to_IDEX_rt : std_logic;
	signal hazard_EXMEM_alu_to_IDEX_rs : std_logic;
	signal hazard_EXMEM_alu_to_IDEX_rt : std_logic;
	signal hazard_MEMWB_alu_to_IDEX_rs : std_logic;
	signal hazard_MEMWB_alu_to_IDEX_rt : std_logic;
	
	signal forward_IDEX_rs : std_logic_vector(WIDTH-1 downto 0);
	signal forward_IDEX_rt : std_logic_vector(WIDTH-1 downto 0);
	signal forward_PC_stall : std_logic;
	signal forward_IFID_stall : std_logic;
	signal forward_IDEX_stall : std_logic;
	signal forward_EXMEM_stall : std_logic;
	
	
	-- OLD SIGNALS
	signal forward_IDEX_reg_output_A_sel : std_logic_vector(1 downto 0);
	signal forward_IDEX_reg_output_B_sel : std_logic_vector(1 downto 0);
	signal forward_IDEX_reg_output_A : std_logic_vector(WIDTH-1 downto 0);
	signal forward_IDEX_reg_output_B : std_logic_vector(WIDTH-1 downto 0);
	signal forward_IDEX_ui_A_sel : std_logic_vector(1 downto 0);
	signal forward_IDEX_ui_B_sel : std_logic_vector(1 downto 0);
	signal forward_IDEX_ui_A : std_logic_vector(WIDTH-1 downto 0);
	signal forward_IDEX_ui_B : std_logic_vector(WIDTH-1 downto 0);
	signal IDEX_lui_A : std_logic_vector(WIDTH-1 downto 0);
	signal IDEX_lui_B : std_logic_vector(WIDTH-1 downto 0);
	signal EXMEM_lui_A : std_logic_vector(WIDTH-1 downto 0);
	signal EXMEM_lui_B : std_logic_vector(WIDTH-1 downto 0);
	
	-- OLD SIGNALS
	
	-- Stage 1/2 IF register signals
	signal IF_pc_in : std_logic_vector(WIDTH-1 downto 0);
	signal IF_instruction_in : std_logic_vector(WIDTH-1 downto 0);
	signal IF_pc_out : std_logic_vector(WIDTH-1 downto 0);
	signal IF_instruction_out : std_logic_vector(WIDTH-1 downto 0);
	
	-- Stage 2/3 ID register signals
	signal ID_reg_output_A_in : std_logic_vector(WIDTH-1 downto 0);
	signal ID_reg_output_B_in : std_logic_vector(WIDTH-1 downto 0);
	signal ID_rd_in : std_logic_vector(WIDTH-1 downto 0);
	signal ID_rs_in : std_logic_vector(WIDTH-1 downto 0);
	signal ID_rt_in : std_logic_vector(WIDTH-1 downto 0);
	signal ID_ctrl_next_pc_src_in : std_logic;
	signal ID_ctrl_beq_in : std_logic;
	signal ID_ctrl_bne_in : std_logic;
	signal ID_ctrl_jump_in : std_logic;
	signal ID_ctrl_jump_addr_src_in : std_logic;
	signal ID_ctrl_reg_dest_in : std_logic;
	signal ID_ctrl_reg_wr_in : std_logic;
	signal ID_ctrl_pc2reg31_in : std_logic;
	signal ID_ctrl_extender_in : std_logic;
	signal ID_ctrl_alu_src_in : std_logic;
	signal ID_ctrl_alu_op_in : std_logic_vector(ALU_OP_WIDTH-1 downto 0);
	signal ID_ctrl_lui_src_in : std_logic;
	signal ID_ctrl_byte_in : std_logic;
	signal ID_ctrl_half_in : std_logic;
	signal ID_ctrl_mem_rd_in : std_logic;
	signal ID_ctrl_mem_wr_in : std_logic;
	signal ID_ctrl_mem2reg_in : std_logic;
	signal ID_pc_out : std_logic_vector(WIDTH-1 downto 0);
	signal ID_instruction_out : std_logic_vector(WIDTH-1 downto 0);
	signal ID_reg_output_A_out : std_logic_vector(WIDTH-1 downto 0);
	signal ID_reg_output_B_out : std_logic_vector(WIDTH-1 downto 0);
	signal ID_rd_out : std_logic_vector(WIDTH-1 downto 0);
	signal ID_rs_out : std_logic_vector(WIDTH-1 downto 0);
	signal ID_rt_out : std_logic_vector(WIDTH-1 downto 0);
	signal ID_ctrl_next_pc_src_out : std_logic;
	signal ID_ctrl_beq_out : std_logic;
	signal ID_ctrl_bne_out : std_logic;
	signal ID_ctrl_jump_out : std_logic;
	signal ID_ctrl_jump_addr_src_out : std_logic;
	signal ID_ctrl_reg_dest_out : std_logic;
	signal ID_ctrl_reg_wr_out : std_logic;
	signal ID_ctrl_pc2reg31_out : std_logic;
	signal ID_ctrl_extender_out : std_logic;
	signal ID_ctrl_alu_src_out : std_logic;
	signal ID_ctrl_alu_op_out : std_logic_vector(ALU_OP_WIDTH-1 downto 0);
	signal ID_ctrl_lui_src_out : std_logic;
	signal ID_ctrl_byte_out : std_logic;
	signal ID_ctrl_half_out : std_logic;
	signal ID_ctrl_mem_rd_out : std_logic;
	signal ID_ctrl_mem_wr_out : std_logic;
	signal ID_ctrl_mem2reg_out : std_logic;
	
	-- Stage 3/4 EX register signals
	signal EX_branch_target : std_logic_vector(WIDTH-1 downto 0);
	signal EX_alu_output_in : std_logic_vector(WIDTH-1 downto 0);
	signal EX_rs_in : std_logic_vector(WIDTH-1 downto 0);
	signal EX_rt_in : std_logic_vector(WIDTH-1 downto 0);
	signal EX_alu_zero : std_logic;
	signal EX_pc_out : std_logic_vector(WIDTH-1 downto 0);
	signal EX_instruction_out : std_logic_vector(WIDTH-1 downto 0);
	signal EX_alu_output_out : std_logic_vector(WIDTH-1 downto 0);
	signal EX_branch_target_out : std_logic_vector(WIDTH-1 downto 0);
	signal EX_reg_output_B_out : std_logic_vector(WIDTH-1 downto 0);
	signal EX_rd_out : std_logic_vector(WIDTH-1 downto 0);
	signal EX_rs_out : std_logic_vector(WIDTH-1 downto 0);
	signal EX_rt_out : std_logic_vector(WIDTH-1 downto 0);
	signal EX_ctrl_lui_src_out : std_logic;
	signal EX_ctrl_reg_dest_out : std_logic;
	signal EX_ctrl_reg_wr_out : std_logic;
	signal EX_ctrl_pc2reg31_out : std_logic;
	signal EX_ctrl_byte_out : std_logic;
	signal EX_ctrl_half_out : std_logic;
	signal EX_ctrl_mem_rd_out : std_logic;
	signal EX_ctrl_mem_wr_out : std_logic;
	signal EX_ctrl_mem2reg_out : std_logic;
	
	-- Stage 4/5 MEM register signals
	signal MEM_alu_output_in : std_logic_vector(WIDTH-1 downto 0);
	signal MEM_mem_output_in : std_logic_vector(WIDTH-1 downto 0);
	signal MEM_rt_in : std_logic_vector(WIDTH-1 downto 0);
	signal MEM_pc_out : std_logic_vector(WIDTH-1 downto 0);
	signal MEM_instruction_out : std_logic_vector(WIDTH-1 downto 0);
	signal MEM_reg_output_B_out : std_logic_vector(WIDTH-1 downto 0);
	signal MEM_rd_out : std_logic_vector(WIDTH-1 downto 0);
	signal MEM_rs_out : std_logic_vector(WIDTH-1 downto 0);
	signal MEM_rt_out : std_logic_vector(WIDTH-1 downto 0);
	signal MEM_alu_output_out : std_logic_vector(WIDTH-1 downto 0);
	signal MEM_mem_output_out : std_logic_vector(WIDTH-1 downto 0);
	signal MEM_ctrl_lui_src_out : std_logic;
	signal MEM_ctrl_reg_dest_out : std_logic;
	signal MEM_ctrl_reg_wr_out : std_logic;
	signal MEM_ctrl_pc2reg31_out : std_logic;
	signal MEM_ctrl_mem2reg_out : std_logic;
	
	-- Stage 5/1 WB signals (no register)
	signal WB_reg_write_addr_out : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal WB_reg_write_data_out : std_logic_vector(WIDTH-1 downto 0);
	
begin
	
	-- IF, ID, EX, and MEM registers all latch on falling-edge clock
	notclk <= not clk;
	
	
	-- Hazard Detection Unit
	U_HAZARD : entity work.hazard_unit
		generic map (
			WIDTH => WIDTH
		)
		port map (
			IFID_instruction => IF_instruction_out,
			IDEX_instruction => ID_instruction_out,
			EXMEM_instruction => EX_instruction_out,
			MEMWB_instruction => MEM_instruction_out,
			EXMEM_reg_wr => EX_ctrl_reg_wr_out,
			MEMWB_reg_wr => MEM_ctrl_reg_wr_out,
			
			-- Control signals out
			EXMEM_rt_to_IDEX_rs => hazard_EXMEM_rt_to_IDEX_rs,
			EXMEM_rt_to_IDEX_rt => hazard_EXMEM_rt_to_IDEX_rt,
			MEMWB_rt_to_IDEX_rs => hazard_MEMWB_rt_to_IDEX_rs,
			MEMWB_rt_to_IDEX_rt => hazard_MEMWB_rt_to_IDEX_rt,
			EXMEM_rd_to_IDEX_rs => hazard_EXMEM_rd_to_IDEX_rs,
			EXMEM_rd_to_IDEX_rt => hazard_EXMEM_rd_to_IDEX_rt,
			MEMWB_rd_to_IDEX_rs => hazard_MEMWB_rd_to_IDEX_rs,
			MEMWB_rd_to_IDEX_rt => hazard_MEMWB_rd_to_IDEX_rt,
			EXMEM_alu_to_IDEX_rs => hazard_EXMEM_alu_to_IDEX_rs,
			EXMEM_alu_to_IDEX_rt => hazard_EXMEM_alu_to_IDEX_rt,
			MEMWB_alu_to_IDEX_rs => hazard_MEMWB_alu_to_IDEX_rs,
			MEMWB_alu_to_IDEX_rt => hazard_MEMWB_alu_to_IDEX_rt,
			PC_stall => forward_PC_stall,
			IFID_stall => forward_IFID_stall,
			IDEX_stall => forward_IDEX_stall,
			EXMEM_stall => forward_EXMEM_stall
			
			--alu_input_A_sel => forward_IDEX_reg_output_A_sel,
			--alu_input_B_sel => forward_IDEX_reg_output_B_sel,
			--IDEX_ui_A_sel => forward_IDEX_ui_A_sel,
			--IDEX_ui_B_sel => forward_IDEX_ui_B_sel,
		);
	U_FORWARDING : entity work.forwarding_unit
		generic map (
			WIDTH => WIDTH
		)
		port map (
			IDEX_rs_in => ID_rs_out,
			IDEX_rt_in => ID_rt_out,
			EXMEM_rd_in => EX_rd_out,
			EXMEM_rt_in => EX_rt_out,
			MEMWB_rd_in => MEM_rd_out,
			MEMWB_rt_in => MEM_rt_out,
			EXMEM_alu_in => EX_alu_output_out,
			MEMWB_alu_in => MEM_alu_output_out,
			
			-- Control signals in
			EXMEM_rt_to_IDEX_rs => hazard_EXMEM_rt_to_IDEX_rs,
			EXMEM_rt_to_IDEX_rt => hazard_EXMEM_rt_to_IDEX_rt,
			MEMWB_rt_to_IDEX_rs => hazard_MEMWB_rt_to_IDEX_rs,
			MEMWB_rt_to_IDEX_rt => hazard_MEMWB_rt_to_IDEX_rt,
			EXMEM_rd_to_IDEX_rs => hazard_EXMEM_rd_to_IDEX_rs,
			EXMEM_rd_to_IDEX_rt => hazard_EXMEM_rd_to_IDEX_rt,
			MEMWB_rd_to_IDEX_rs => hazard_MEMWB_rd_to_IDEX_rs,
			MEMWB_rd_to_IDEX_rt => hazard_MEMWB_rd_to_IDEX_rt,
			EXMEM_alu_to_IDEX_rs => hazard_EXMEM_alu_to_IDEX_rs,
			EXMEM_alu_to_IDEX_rt => hazard_EXMEM_alu_to_IDEX_rt,
			MEMWB_alu_to_IDEX_rs => hazard_MEMWB_alu_to_IDEX_rs,
			MEMWB_alu_to_IDEX_rt => hazard_MEMWB_alu_to_IDEX_rt,
			
			IDEX_rs_out => forward_IDEX_rs,
			IDEX_rt_out => forward_IDEX_rt
		);
	
	
	-- Stage 1: Instruction Fetch
	write_PC_en <= not forward_PC_stall;
	U_STAGE1_IF : entity work.stage1_IF
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => clk,
			rst => rst,
			wr_en => write_PC_en,
			branch_target => EX_branch_target,
			beq => ID_ctrl_beq_out,
			bne => ID_ctrl_bne_out,
			jump => ID_ctrl_jump_out,
			zero => EX_alu_zero,
			pc => IF_pc_in,
			instruction => IF_instruction_in
		);
	
	write_IF_en <= not forward_IFID_stall;
	U_IF_REG : entity work.stage1_IF_reg
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => notclk,
			rst => rst,
			wr_en => write_IF_en,
			clr => clear_IF_reg,
			pc => IF_pc_in,
			instruction => IF_instruction_in,
			pc_out => IF_pc_out,
			instruction_out => IF_instruction_out
		);
	
	-- Stage 2: Instruction Decode
	U_STAGE2_ID : entity work.stage2_ID
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => clk,
			rst => rst,
			instruction => IF_instruction_out,
			reg_wr => MEM_ctrl_reg_wr_out,
			reg_write_addr => WB_reg_write_addr_out,
			reg_write_data => WB_reg_write_data_out,
			reg_output_A => ID_reg_output_A_in,
			reg_output_B => ID_reg_output_B_in,
			rd => ID_rd_in,
			rs => ID_rs_in,
			rt => ID_rt_in,
			ctrl_beq => ID_ctrl_beq_in,
			ctrl_bne => ID_ctrl_bne_in,
			ctrl_jump => ID_ctrl_jump_in,
			ctrl_jump_addr_src => ID_ctrl_jump_addr_src_in,
			ctrl_reg_dest => ID_ctrl_reg_dest_in,
			ctrl_reg_wr => ID_ctrl_reg_wr_in,
			ctrl_pc2reg31 => ID_ctrl_pc2reg31_in,
			ctrl_extender => ID_ctrl_extender_in,
			ctrl_alu_src => ID_ctrl_alu_src_in,
			ctrl_alu_op => ID_ctrl_alu_op_in,
			ctrl_lui_src => ID_ctrl_lui_src_in,
			ctrl_byte => ID_ctrl_byte_in,
			ctrl_half => ID_ctrl_half_in,
			ctrl_mem_rd => ID_ctrl_mem_rd_in,
			ctrl_mem_wr => ID_ctrl_mem_wr_in,
			ctrl_mem2reg => ID_ctrl_mem2reg_in
		);
	
	write_ID_en <= not forward_IDEX_stall;
	U_ID_REG : entity work.stage2_ID_reg
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => notclk,
			rst => rst,
			wr_en => write_ID_en,
			clr => clear_ID_reg,
			pc => IF_pc_out,
			instruction => IF_instruction_out,
			reg_output_A => ID_reg_output_A_in,
			reg_output_B => ID_reg_output_B_in,
			rd => ID_rd_in,
			rs => ID_rs_in,
			rt => ID_rt_in,
			ctrl_beq => ID_ctrl_beq_in,
			ctrl_bne => ID_ctrl_bne_in,
			ctrl_jump => ID_ctrl_jump_in,
			ctrl_jump_addr_src => ID_ctrl_jump_addr_src_in,
			ctrl_reg_dest => ID_ctrl_reg_dest_in,
			ctrl_reg_wr => ID_ctrl_reg_wr_in,
			ctrl_pc2reg31 => ID_ctrl_pc2reg31_in,
			ctrl_extender => ID_ctrl_extender_in,
			ctrl_alu_src => ID_ctrl_alu_src_in,
			ctrl_alu_op => ID_ctrl_alu_op_in,
			ctrl_lui_src => ID_ctrl_lui_src_in,
			ctrl_byte => ID_ctrl_byte_in,
			ctrl_half => ID_ctrl_half_in,
			ctrl_mem_rd => ID_ctrl_mem_rd_in,
			ctrl_mem_wr => ID_ctrl_mem_wr_in,
			ctrl_mem2reg => ID_ctrl_mem2reg_in,
			
			pc_out => ID_pc_out,
			instruction_out => ID_instruction_out,
			reg_output_A_out => ID_reg_output_A_out,
			reg_output_B_out => ID_reg_output_B_out,
			rd_out => ID_rd_out,
			rs_out => ID_rs_out,
			rt_out => ID_rt_out,
			ctrl_beq_out => ID_ctrl_beq_out,
			ctrl_bne_out => ID_ctrl_bne_out,
			ctrl_jump_out => ID_ctrl_jump_out,
			ctrl_jump_addr_src_out => ID_ctrl_jump_addr_src_out,
			ctrl_reg_dest_out => ID_ctrl_reg_dest_out,
			ctrl_reg_wr_out => ID_ctrl_reg_wr_out,
			ctrl_pc2reg31_out => ID_ctrl_pc2reg31_out,
			ctrl_extender_out => ID_ctrl_extender_out,
			ctrl_alu_src_out => ID_ctrl_alu_src_out,
			ctrl_alu_op_out => ID_ctrl_alu_op_out,
			ctrl_lui_src_out => ID_ctrl_lui_src_out,
			ctrl_byte_out => ID_ctrl_byte_out,
			ctrl_half_out => ID_ctrl_half_out,
			ctrl_mem_rd_out => ID_ctrl_mem_rd_out,
			ctrl_mem_wr_out => ID_ctrl_mem_wr_out,
			ctrl_mem2reg_out => ID_ctrl_mem2reg_out
		);
	
	-- Stage 3: Execute
	U_STAGE3_EX : entity work.stage3_EX
		generic map (
			WIDTH => WIDTH
		)
		port map (
			pc => ID_pc_out,
			instruction => ID_instruction_out,
			reg_output_A => forward_IDEX_rs,
			reg_output_B => forward_IDEX_rt,
			immediate => ID_instruction_out(ITYPE_IMMEDIATE_RANGE),
			ctrl_extender => ID_ctrl_extender_out,
			ctrl_alu_src => ID_ctrl_alu_src_out,
			ctrl_alu_op => ID_ctrl_alu_op_out,
			ctrl_beq => ID_ctrl_beq_out,
			ctrl_bne => ID_ctrl_bne_out,
			ctrl_jump => ID_ctrl_jump_out,
			ctrl_jump_addr_src => ID_ctrl_jump_addr_src_out,
			
			rs => EX_rs_in,
			rt => EX_rt_in,
			branch_target => EX_branch_target,
			alu_output => EX_alu_output_in,
			alu_zero => EX_alu_zero
			-- Unused
			--alu_carry =>
			--alu_sign =>
			--alu_overflow => 
		);
	
	write_EX_en <= not forward_EXMEM_stall;
	U_EX_REG : entity work.stage3_EX_reg
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => notclk,
			rst => rst,
			wr_en => write_EX_en,
			clr => clear_EX_reg,
			pc => ID_pc_out,
			instruction => ID_instruction_out,
			reg_output_B => forward_IDEX_rt,
			rd => ID_rd_out,
			rs => EX_rs_in,
			rt => EX_rt_in,
			alu_output => EX_alu_output_in,
			ctrl_lui_src => ID_ctrl_lui_src_out,
			ctrl_reg_dest => ID_ctrl_reg_dest_out,
			ctrl_reg_wr => ID_ctrl_reg_wr_out,
			ctrl_pc2reg31 => ID_ctrl_pc2reg31_out,
			ctrl_byte => ID_ctrl_byte_out,
			ctrl_half => ID_ctrl_half_out,
			ctrl_mem_rd => ID_ctrl_mem_rd_out,
			ctrl_mem_wr => ID_ctrl_mem_wr_out,
			ctrl_mem2reg => ID_ctrl_mem2reg_out,
			
			pc_out => EX_pc_out,
			instruction_out => EX_instruction_out,
			reg_output_B_out => EX_reg_output_B_out,
			rd_out => EX_rd_out,
			rs_out => EX_rs_out,
			rt_out => EX_rt_out,
			alu_output_out => EX_alu_output_out,
			ctrl_lui_src_out => EX_ctrl_lui_src_out,
			ctrl_reg_dest_out => EX_ctrl_reg_dest_out,
			ctrl_reg_wr_out => EX_ctrl_reg_wr_out,
			ctrl_pc2reg31_out => EX_ctrl_pc2reg31_out,
			ctrl_byte_out => EX_ctrl_byte_out,
			ctrl_half_out => EX_ctrl_half_out,
			ctrl_mem_rd_out => EX_ctrl_mem_rd_out,
			ctrl_mem_wr_out => EX_ctrl_mem_wr_out,
			ctrl_mem2reg_out => EX_ctrl_mem2reg_out
		);
	
	
	U_STAGE4_MEM : entity work.stage4_MEM
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => clk,
			rst => rst,
			instruction => EX_instruction_out,
			alu_output => EX_alu_output_out,
			reg_output_B => EX_reg_output_B_out,
			ctrl_mem_rd => EX_ctrl_mem_rd_out,
			ctrl_mem_wr => EX_ctrl_mem_wr_out,
			ctrl_byte => EX_ctrl_byte_out,
			ctrl_half => EX_ctrl_half_out,
			rt => MEM_rt_in,
			mem_output => MEM_mem_output_in
		);
	
	U_MEM_REG : entity work.stage4_MEM_reg
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => notclk,
			rst => rst,
			wr_en => write_MEM_en,
			clr => clear_MEM_reg,
			pc => EX_pc_out,
			instruction => EX_instruction_out,
			reg_output_B => EX_reg_output_B_out,
			alu_output => EX_alu_output_out,
			mem_output => MEM_mem_output_in,
			rd => EX_rd_out,
			rs => EX_rs_out,
			rt => MEM_rt_in,
			ctrl_lui_src => EX_ctrl_lui_src_out,
			ctrl_reg_dest => EX_ctrl_reg_dest_out,
			ctrl_reg_wr => EX_ctrl_reg_wr_out,
			ctrl_pc2reg31 => EX_ctrl_pc2reg31_out,
			ctrl_mem2reg => EX_ctrl_mem2reg_out,
			
			pc_out => MEM_pc_out,
			instruction_out => MEM_instruction_out,
			reg_output_B_out => MEM_reg_output_B_out,
			alu_output_out => MEM_alu_output_out,
			mem_output_out => MEM_mem_output_out,
			rd_out => MEM_rd_out,
			rs_out => MEM_rs_out,
			rt_out => MEM_rt_out,
			ctrl_lui_src_out => MEM_ctrl_lui_src_out,
			ctrl_reg_dest_out => MEM_ctrl_reg_dest_out,
			ctrl_reg_wr_out => MEM_ctrl_reg_wr_out,
			ctrl_pc2reg31_out => MEM_ctrl_pc2reg31_out,
			ctrl_mem2reg_out => MEM_ctrl_mem2reg_out
		);
	
	U_STAGE5_WB : entity work.stage5_WB
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => clk,
			rst => rst,
			pc => MEM_pc_out,
			instruction => MEM_instruction_out,
			reg_output_B => MEM_reg_output_B_out,
			alu_output => MEM_alu_output_out,
			mem_output => MEM_mem_output_out,
			ctrl_lui_src => MEM_ctrl_lui_src_out,
			ctrl_reg_dest => MEM_ctrl_reg_dest_out,
			ctrl_pc2reg31 => MEM_ctrl_pc2reg31_out,
			ctrl_mem2reg => MEM_ctrl_mem2reg_out,
			reg_write_addr => WB_reg_write_addr_out,
			reg_write_data => WB_reg_write_data_out
		);
	
end arch;