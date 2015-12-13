library ieee;
use ieee.std_logic_1164.all;
use work.lib.all;

-- MIPS Control for the datapath
-- Now a state machine for multi-cycle processsor
-- States:
--   1: Instruction Fetch
--   2: Instruction Decode
--   3: Execute
--   4: Memory Access
--   5: Write Back
--
-- reg_dest: selects the write address (RD or RT)
-- extender: controls signed or zero extension ('1' and '0' respectively)
-- alu_src: selects register output B or extender output for ALU input B
-- alu_op: selects the ALU operation performed
-- mem2reg: determines if the data memory output will be written to registers
entity control is
	port (
		rst : in std_logic;
		opcode : in std_logic_vector(OPCODE_RANGE);
		func : in std_logic_vector(RTYPE_FUNC_WIDTH-1 downto 0);
		beq : out std_logic;
		bne : out std_logic;
		jump : out std_logic;
		jump_addr_src : out std_logic;
		pc2reg31 : out std_logic;
		reg_dest : out std_logic;
		reg_wr : out std_logic;
		extender : out std_logic;
		alu_src : out std_logic;
		alu_op : out std_logic_vector(ALU_OP_WIDTH-1 downto 0);
		lui_src : out std_logic;
		byte : out std_logic;
		half : out std_logic;
		mem_rd : out std_logic;
		mem_wr : out std_logic;
		mem2reg : out std_logic
	);
end entity;

architecture arch of control is
begin
	
	process(rst, opcode, func)
	begin
		beq <= '0';
		bne <= '0';
		jump <= '0';
		jump_addr_src <= '0';
		pc2reg31 <= '0';
		reg_dest <= '0';
		reg_wr <= '0';
		extender <= '1'; -- Sign extend is default
		alu_src <= '0';
		alu_op <= (others => '0');
		lui_src <= '0';
		byte <= '0';
		half <= '0';
		mem_rd <= '0';
		mem_wr <= '0';
		mem2reg <= '0';
		
		if(rst = '0') then
			
			case opcode is
				when OPCODE_RTYPE =>
					if(func = RTYPE_FUNC_JR) then
						jump <= '1';
						jump_addr_src <= '1';
					else
						reg_dest <= '1';
						reg_wr <= '1';
						alu_op <= ALU_OP_FUNC;
					end if;
				
				when OPCODE_LUI =>
					reg_wr <= '1';
					alu_src <= '1';
					alu_op <= ALU_OP_ADD;
					lui_src <= '1';
				
				when OPCODE_ADDI =>
					reg_wr <= '1';
					alu_src <= '1';
					alu_op <= ALU_OP_ADD;
				
				when OPCODE_ADDIU =>
					reg_wr <= '1';
					alu_src <= '1';
					alu_op <= ALU_OP_ADDU;
				
				when OPCODE_ANDI =>
					reg_wr <= '1';
					extender <= '0';
					alu_src <= '1';
					alu_op <= ALU_OP_AND;
				
				when OPCODE_ORI =>
					reg_wr <= '1';
					extender <= '0';
					alu_src <= '1';
					alu_op <= ALU_OP_OR;
				
				when OPCODE_SLTI =>
					reg_wr <= '1';
					alu_src <= '1';
					alu_op <= ALU_OP_SLT;
					
				when OPCODE_SLTIU =>
					reg_wr <= '1';
					alu_src <= '1';
					alu_op <= ALU_OP_SLTU;
					
				when OPCODE_SB =>
					alu_src <= '1';
					alu_op <= ALU_OP_ADD;
					byte <= '1';
					mem_wr <= '1';
				
				when OPCODE_SH =>
					alu_src <= '1';
					alu_op <= ALU_OP_ADD;
					half <= '1';
					mem_wr <= '1';
				
				when OPCODE_SW =>
					alu_src <= '1';
					alu_op <= ALU_OP_ADD;
					mem_wr <= '1';
				
				when OPCODE_LBU =>
					reg_wr <= '1';
					alu_src <= '1';
					alu_op <= ALU_OP_ADD;
					byte <= '1';
					mem_rd <= '1';
					mem2reg <= '1';
					
				when OPCODE_LHU =>
					reg_wr <= '1';
					alu_src <= '1';
					alu_op <= ALU_OP_ADD;
					half <= '1';
					mem_rd <= '1';
					mem2reg <= '1';
				
				when OPCODE_LW =>
					reg_wr <= '1';
					alu_src <= '1';
					alu_op <= ALU_OP_ADD;
					mem_rd <= '1';
					mem2reg <= '1';
				
				when OPCODE_BEQ =>
					beq <= '1';
					alu_op <= ALU_OP_SUB;
				
				when OPCODE_BNE =>
					bne <= '1';
					alu_op <= ALU_OP_SUB;
				
				when OPCODE_J =>
					jump <= '1';
					
				when OPCODE_JAL =>
					jump <= '1';
					reg_wr <= '1';
					pc2reg31 <= '1';
					
				when others => null;
				
			end case;
		end if;
	end process;
	
end arch;