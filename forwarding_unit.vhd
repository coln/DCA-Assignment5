library ieee;
use ieee.std_logic_1164.all;
use work.lib.all;

entity forwarding_unit is
	generic (
		WIDTH : positive := 32
	);
	port (
		IDEX_rs_in : in std_logic_vector(WIDTH-1 downto 0);
		IDEX_rt_in : in std_logic_vector(WIDTH-1 downto 0);
		EXMEM_rd_in : in std_logic_vector(WIDTH-1 downto 0);
		EXMEM_rt_in : in std_logic_vector(WIDTH-1 downto 0);
		MEMWB_rd_in : in std_logic_vector(WIDTH-1 downto 0);
		MEMWB_rt_in : in std_logic_vector(WIDTH-1 downto 0);
		EXMEM_alu_in : in std_logic_vector(WIDTH-1 downto 0);
		MEMWB_alu_in : in std_logic_vector(WIDTH-1 downto 0);
		
		-- Control signals
		EXMEM_rt_to_IDEX_rs : in std_logic;
		EXMEM_rt_to_IDEX_rt : in std_logic;
		MEMWB_rt_to_IDEX_rs : in std_logic;
		MEMWB_rt_to_IDEX_rt : in std_logic;
		EXMEM_rd_to_IDEX_rs : in std_logic;
		EXMEM_rd_to_IDEX_rt : in std_logic;
		MEMWB_rd_to_IDEX_rs : in std_logic;
		MEMWB_rd_to_IDEX_rt : in std_logic;
		EXMEM_alu_to_IDEX_rs : in std_logic;
		EXMEM_alu_to_IDEX_rt : in std_logic;
		MEMWB_alu_to_IDEX_rs : in std_logic;
		MEMWB_alu_to_IDEX_rt : in std_logic;
		
		IDEX_rs_out : out std_logic_vector(WIDTH-1 downto 0);
		IDEX_rt_out : out std_logic_vector(WIDTH-1 downto 0)
	);
end entity;

architecture arch of forwarding_unit is
begin
	
	-- Forward exmem.rd to idex.rs
	process(IDEX_rs_in, IDEX_rt_in, EXMEM_rd_in, EXMEM_rt_in, MEMWB_rd_in, MEMWB_rt_in,
			EXMEM_alu_in, MEMWB_alu_in, 
			EXMEM_rt_to_IDEX_rs, EXMEM_rt_to_IDEX_rt, MEMWB_rt_to_IDEX_rs, MEMWB_rt_to_IDEX_rt,
			EXMEM_rd_to_IDEX_rs, EXMEM_rd_to_IDEX_rt, MEMWB_rd_to_IDEX_rs, MEMWB_rd_to_IDEX_rt,
			EXMEM_alu_to_IDEX_rs, EXMEM_alu_to_IDEX_rt, MEMWB_alu_to_IDEX_rs, MEMWB_alu_to_IDEX_rt
		)
	begin
		IDEX_rs_out <= IDEX_rs_in;
		IDEX_rt_out <= IDEX_rs_in;
		
		if(EXMEM_rd_to_IDEX_rs = '1') then
			IDEX_rs_out <= EXMEM_rd_in;
		elsif(MEMWB_rd_to_IDEX_rs = '1') then
			IDEX_rs_out <= MEMWB_rd_in;
		elsif(EXMEM_rt_to_IDEX_rs = '1') then
			IDEX_rs_out <= EXMEM_rt_in;
		elsif(MEMWB_rt_to_IDEX_rs = '1') then
			IDEX_rs_out <= MEMWB_rt_in;
		elsif(EXMEM_alu_to_IDEX_rs = '1') then
			IDEX_rs_out <= EXMEM_alu_in;
		elsif(MEMWB_alu_to_IDEX_rs = '1') then
			IDEX_rs_out <= MEMWB_alu_in;
		end if;
		
		if(EXMEM_rd_to_IDEX_rt = '1') then
			IDEX_rt_out <= EXMEM_rd_in;
		elsif(MEMWB_rd_to_IDEX_rt = '1') then
			IDEX_rt_out <= MEMWB_rd_in;
		elsif(EXMEM_rt_to_IDEX_rt = '1') then
			IDEX_rt_out <= EXMEM_rt_in;
		elsif(MEMWB_rt_to_IDEX_rt = '1') then
			IDEX_rt_out <= MEMWB_rt_in;
		elsif(EXMEM_alu_to_IDEX_rt = '1') then
			IDEX_rt_out <= EXMEM_alu_in;
		elsif(MEMWB_alu_to_IDEX_rt = '1') then
			IDEX_rt_out <= MEMWB_alu_in;
		end if;
		
		
	end process;
	
	
	---- Stage 3 forwarding muxes
	--U_FW_EX_ALU_INPUT_A : entity work.mux4
	--	generic map (
	--		WIDTH => WIDTH
	--	)
	--	port map (
	--		sel => forward_IDEX_reg_output_A_sel,
	--		in0 => ID_reg_output_A_out,
	--		in1 => EX_alu_output_out,
	--		in2 => WB_reg_write_data_out,
	--		in3 => (others => '0'),
	--		output => forward_IDEX_reg_output_A
	--	);
	
	--U_FW_EX_ALU_INPUT_B : entity work.mux4
	--	generic map (
	--		WIDTH => WIDTH
	--	)
	--	port map (
	--		sel => forward_IDEX_reg_output_B_sel,
	--		in0 => ID_reg_output_B_out,
	--		in1 => EX_alu_output_out,
	--		in2 => WB_reg_write_data_out,
	--		in3 => (others => '0'),
	--		output => forward_IDEX_reg_output_B
	--	);
	
	--IDEX_lui_A <= EX_instruction_out(ITYPE_IMMEDIATE_RANGE) & forward_IDEX_reg_output_A(WIDTH-ITYPE_IMMEDIATE_WIDTH-1 downto 0);
	--IDEX_lui_B <= EX_instruction_out(ITYPE_IMMEDIATE_RANGE) & forward_IDEX_reg_output_B(WIDTH-ITYPE_IMMEDIATE_WIDTH-1 downto 0);
	--EXMEM_lui_A <= EX_instruction_out(ITYPE_IMMEDIATE_RANGE) & EX_reg_output_B_out(WIDTH-ITYPE_IMMEDIATE_WIDTH-1 downto 0);
	--EXMEM_lui_B <= EX_instruction_out(ITYPE_IMMEDIATE_RANGE) & EX_reg_output_B_out(WIDTH-ITYPE_IMMEDIATE_WIDTH-1 downto 0);
	--U_FW_EX_UI_A : entity work.mux4
	--	generic map (
	--		WIDTH => WIDTH
	--	)
	--	port map (
	--		sel => forward_IDEX_ui_A_sel,
	--		in0 => forward_IDEX_reg_output_A,
	--		in1 => IDEX_lui_A,
	--		in2 => EXMEM_lui_A,
	--		in3 => (others => '0'),
	--		output => forward_IDEX_ui_A
	--	);
	--U_FW_EX_UI_B : entity work.mux4
	--	generic map (
	--		WIDTH => WIDTH
	--	)
	--	port map (
	--		sel => forward_IDEX_ui_B_sel,
	--		in0 => forward_IDEX_reg_output_B,
	--		in1 => IDEX_lui_B,
	--		in2 => EXMEM_lui_B,
	--		in3 => (others => '0'),
	--		output => forward_IDEX_ui_B
	--	);

end arch;