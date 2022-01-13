/* Author: Yash AGarwal
 * Filename: sim5.c
 * CSC 210
 * Purpose: This file implements a pipelined CPU by using data forwarding and stalls.
 * It used three regsiters ID/EX, EX/MEM, and MEM/WB for each of the phases of the CPU.
 * Instructions implemented are add, addu, addiu, sub, subu, addi, and, or, xor, nor,
 * slt, slti, lw, sw, beq, bne, j, andi, ori, lui, nop
*/
#include "sim5.h"
#include <stdio.h>

//This function reads the instruction and fills in the control bits
//and assigns it to the fieldsOut struct.
//param- instruction: the instruction passed
//fieldsOut: The struct which holds all the fields 
void extract_instructionFields(WORD instruction, InstructionFields *fieldsOut)
{
	//After taking the number of bits for each field it is shifted
        //by the size of that field plus the older shift
        fieldsOut->opcode = (instruction >> 26) & 0x3f;
        fieldsOut->rs = (instruction >> 21) & 0x1f;
        fieldsOut->rt = (instruction >> 16) & 0x1f;
        fieldsOut->rd = (instruction >> 11) & 0x1f;
        fieldsOut->shamt = (instruction >> 6) & 0x1f;
        fieldsOut->funct = instruction & 0x3f;
        fieldsOut->imm16 = instruction & 0xffff;
        fieldsOut->imm32 = signExtend16to32(instruction & 0xffff);
        fieldsOut->address =  instruction & 0x3ffffff;	
}

//This function reads in the control bits and the other pipeline registers 
//and checks if a stall is required. It checks for two kinds of stalls 
//lw data hazards and sw data hazards.
//param- fields- the instruction fields of the current instruction
//old_idex- the ID_EX register of the instruction 1 cycle ahead
//old_exmem- the EX_MEM register of the instruction 2 cycles ahead
int IDtoIF_get_stall(InstructionFields *fields,
                     ID_EX  *old_idex, EX_MEM *old_exmem){
	//checks for the lw stalls
	if(old_idex->memRead == 1)
	{
		if(fields->opcode == 0)
		{
			if(old_idex->rt == fields->rt || old_idex->rt == fields->rs)
				return 1;
		}
		if(old_idex->rt == fields->rs)
			return 1;
	}
	//checks for the sw stalls
	if(fields->opcode == 43){
		if(fields->rt == old_exmem->writeReg && old_exmem->regWrite == 1)
			{
			// R format instruction with writeReg not as $zero
			if(old_idex->regDst == 1 && old_idex->rd == fields->rt && old_idex->rd != 0){
				return 0;
				}
			// I format instruction with writeReg not as $zero
			if(old_idex->regDst == 0 && old_idex->rt == fields->rt && old_idex->rt != 0){
				return 0;
				}
			return 1;
			}	
	}
	return 0;
}

//This asks the ID phase if the current instruction (in ID) needs to perform
//a branch/jump. The parameters are the Fields for this instruction, along
//with the rsVal and rtVal for this instruction.
//return- 0 for the PC to advance as normal
//1 for the PC to jump to the relative branch destination
//2 for the PC to jump to the absolute jump destination
int IDtoIF_get_branchControl(InstructionFields *fields, WORD rsVal, WORD rtVal){
	if(fields->opcode == 4 && rsVal == rtVal)
		return 1;
	if(fields->opcode == 5 && rtVal != rsVal)
		return 1;
	if(fields->opcode == 2)
		return 2;
	return 0;

}

//This function models a simple branch adder in hardware - and thus, it will calculate this value
//on every clock cycle, and for every instruction - even if there is no
//possible way that it might be used.
//param- pcPlus4 - the current PC address plus 4
//fields: the fields of the current instruction
//return: the address to jump to
WORD calc_branchAddr(WORD pcPlus4, InstructionFields *fields){
	return (fields->imm32 << 2) + pcPlus4;	
}

//This function calculates the address to jump to if an 
//unconditional branch was performed.
//param- pcPlus4 - the current PC address plus 4
//fields: the fields of the current instruction
//return: the address to jump to
WORD calc_jumpAddr  (WORD pcPlus4, InstructionFields *fields){
	return ((fields->address << 2) + (pcPlus4 & 0xf0000000));
}

//This function implements the core of the ID phase. Its first parameter is
//the stall setting (exactly what you returned from IDtoIF get stall()).
//The next is the Fields for this instruction, followed by the rsVal and rtVal;
//last is a pointer to the (new) ID/EX pipeline register
//returns 1 if the instruction is valid otherwise 0
int execute_ID(int IDstall,
               InstructionFields *fields,
               WORD pcPlus4,
               WORD rsVal, WORD rtVal,
               ID_EX *new_idex){
	if(IDstall == 1){
		new_idex->rs = 0;
		new_idex->rt = 0;
		new_idex->rd = 0;
		new_idex->rsVal = 0;
		new_idex->rtVal = 0;
		new_idex->imm16 = 0;
		new_idex->imm32 = 0;
		new_idex->ALUsrc = 0;
		new_idex->ALU.op = 0;
		new_idex->ALU.bNegate = 0;
		new_idex->memRead = 0;
		new_idex->memWrite = 0;
		new_idex->memToReg = 0;
		new_idex->regDst = 0;
		new_idex->regWrite = 0;
		new_idex->extra1 = 0;
		new_idex->extra2 = 0;
		new_idex->extra3 = 0;
		return 1;
	}
	new_idex->rs = fields->rs;
	new_idex->rt = fields->rt;
	new_idex->rd = fields->rd;
	new_idex->imm16 = fields->imm16;
	new_idex->imm32 = signExtend16to32(fields->imm16); 
	new_idex->ALUsrc = 0;
        new_idex->ALU.op = 0;
	new_idex->ALU.bNegate = 0;
	new_idex->memRead = 0;
        new_idex->memWrite = 0;
        new_idex->memToReg = 0;
        new_idex->regDst = 0;
        new_idex->regWrite = 0;
	new_idex->extra1 = 0;
	new_idex->extra2 = 0;
	new_idex->extra3 = 0;
	new_idex->rsVal = rsVal;
	new_idex->rtVal = rtVal;
	switch(fields->opcode){
		//R-format instructions
		case 0:
			//sll
			{
			if(fields->funct == 0){
				new_idex->regDst = 1;
				new_idex->regWrite = 1;
				new_idex->ALU.op = 5;
				return 1;
			}
			//add, addu
			if(fields->funct == 32 || fields->funct == 33){
				new_idex->regDst = 1;
				new_idex->regWrite = 1;
				new_idex->ALU.op = 2;
				return 1;
			}
			//sub, subu
			if(fields->funct == 34 || fields->funct == 35){
				new_idex->regDst = 1;
				new_idex->regWrite = 1;
				new_idex->ALU.op = 2;
				new_idex->ALU.bNegate = 1;
				return 1;
			}
			//and
			if(fields->funct == 36){
				new_idex->regDst = 1;
				new_idex->regWrite = 1;
				new_idex->ALU.op = 0;
				return 1;
			}
			//or
			if(fields->funct == 37){
				new_idex->regDst = 1;
				new_idex->regWrite = 1;
				new_idex->ALU.op = 1;
				return 1;
			}
			//xor
			if(fields->funct == 38){
				new_idex->regDst = 1;
				new_idex->regWrite = 1;
				new_idex->ALU.op = 4;
				return 1;
			}
			//nor
			if(fields->funct == 39){
				new_idex->regDst = 1;
				new_idex->regWrite = 1;
				new_idex->ALU.op = 7;
				return 1;
			}	
			//slt
			if(fields->funct == 42){
				new_idex->regDst = 1;
				new_idex->regWrite = 1;
				new_idex->ALU.op = 3;
				new_idex->ALU.bNegate = 1;
				return 1;
			}
			break;
			}
		//j
		case 2:
			{
			new_idex->rs = 0;
			new_idex->rt = 0;
			new_idex->rd = 0;
			new_idex->rsVal = 0;
			new_idex-> rtVal = 0;
			return 1;
			}
		//beq
		case 4:
			{
			new_idex->rs = 0;
			new_idex->rt = 0;
			new_idex->rd = 0;
			new_idex->rsVal = 0;
			new_idex-> rtVal = 0;
			return 1;
			}
		//bne
		case 5:
			{
			new_idex->rs = 0;
			new_idex->rt = 0;
			new_idex->rd = 0;
			new_idex->rsVal = 0;
			new_idex-> rtVal = 0;
			return 1;
			}
		//addi
		case 8:
			{
			new_idex->ALU.op = 2;
			new_idex->ALUsrc = 1;
                        new_idex->regWrite = 1;
                        return 1;
			}
		//addiu
		case 9:
			{
			new_idex->ALU.op = 2;
			new_idex->ALUsrc = 1;
			new_idex->regWrite = 1;
			return 1;
			}
		//slti
		case 10:
			{
			new_idex->ALU.op = 3;
			new_idex->ALU.bNegate = 1;
			new_idex->ALUsrc = 1;
			new_idex->regWrite = 1;
			return 1;
			}
		//andi
		case 12:
			{
			new_idex->ALU.op = 0;
                        new_idex->ALUsrc = 2;
                        new_idex->regWrite = 1;
			return 1;
			}
		case 13:
			{
			new_idex->ALU.op = 1;
			new_idex->ALUsrc = 2;
			new_idex->regWrite = 1;
			return 1;
			}
		//lui
		case 15:
			{
			new_idex->ALU.op = 6;
			new_idex->ALUsrc = 1;
			new_idex->regWrite = 1;
			return 1;
			}
		//lw
		case 35:
			{
			new_idex->ALUsrc = 1;
			new_idex->ALU.op = 2;
			new_idex->memRead = 1;
			new_idex->memToReg = 1;
			new_idex->regWrite = 1;
			return 1;
			}
		//sw
		case 43:
			{
			new_idex->ALUsrc = 1;
			new_idex->ALU.op = 2;
			new_idex->memWrite = 1;
			return 1;
			}
	}
       return 0;	
}

//This function returns the value which should be delivered to input 1
//of the ALU. The first parameter is the current ID/EX register; it also has
//pointers to the current EX/MEM and MEM/WB registers.
//return - the first input to the ALU
WORD EX_getALUinput1(ID_EX *in, EX_MEM *old_exMem, MEM_WB *old_memWb){
	//checks the instruction one cycle ahead and if it modifies the first register
	if(old_exMem->regWrite == 1 && old_exMem->writeReg == in->rs)
		return old_exMem->aluResult;
	//checks the instruction 2 cycles ahead and if it modifies the first register
	if(old_memWb->regWrite == 1 && old_memWb->writeReg == in->rs)
		return old_memWb->aluResult;
	return in->rsVal;
}

//This is the same function, but for ALU input 2. 
// The first parameter is the current ID/EX register; it also has
//pointers to the current EX/MEM and MEM/WB registers.
//return - the second input to the ALU
WORD EX_getALUinput2(ID_EX *in, EX_MEM *old_exMem, MEM_WB *old_memWb){
	//I format instruction
	if(in->ALUsrc == 1)
		return in->imm32;
	//andi and ori
	if(in->ALUsrc == 2)
		return in->imm16 & 0x0000ffff;
	if(old_exMem->regWrite == 1 && old_exMem->writeReg == in->rt)
		return old_exMem->aluResult;
	if(old_memWb->regWrite == 1 && old_memWb->writeReg == in->rt)
                return old_memWb->aluResult;
	return in->rtVal;
}

//This function implements the core of the EX phase
//param: in- the ID_EX register
//input1- the first parameter
//input2- the second parameter
// new_exMem- the EX_MEM register 
void execute_EX(ID_EX *in, WORD input1, WORD input2,
                EX_MEM *new_exMem){
	if(in->ALU.op == 0)
		new_exMem->aluResult = input1 & input2;
	if(in->ALU.op == 1)
		new_exMem->aluResult = input1 | input2;
	if(in->ALU.op == 2 && in->ALU.bNegate == 0)
		new_exMem->aluResult = input1 + input2;
	if(in->ALU.op == 2 && in->ALU.bNegate == 1)
		new_exMem->aluResult = input1 - input2;
	if(in->ALU.op == 3)
		new_exMem->aluResult = input1 < input2;
	//xor
	if(in->ALU.op == 4)
		new_exMem->aluResult = input1 ^ input2;
	//nop
	if(in->ALU.op == 5)
		new_exMem->aluResult = 0;
	//lui
	if(in->ALU.op == 6)
		new_exMem->aluResult = input2 << 16;
	//nor
	if(in->ALU.op == 7)
		new_exMem->aluResult = ~(input1 | input2);
	new_exMem->rt = in->rt;
	new_exMem->rtVal = in->rtVal;
	new_exMem->memRead = in->memRead;
	new_exMem->memWrite = in->memWrite;
	new_exMem->memToReg = in->memToReg;
	if(in->regDst == 0)
		new_exMem->writeReg = in->rt;
	else
		new_exMem->writeReg = in->rd;
	new_exMem->regWrite = in->regWrite;
}

//It reads or writes to memory. It also handles the sw forwarding.
//in-> the EX_MEM register 
//old_memWb-> MEM_WB register that is ahead of current instruction
//mem- the array which represents the memory
//new_memWB-> the new MEM_WB register
void execute_MEM(EX_MEM *in, MEM_WB *old_memWb,
                 WORD *mem, MEM_WB *new_memwb){
	new_memwb->memToReg = in->memToReg;
	new_memwb->aluResult = in->aluResult;
	new_memwb->writeReg = in->writeReg;
	new_memwb->regWrite = in->regWrite;
	if(in->memRead == 1)
		new_memwb->memResult = mem[in->aluResult/4];
	else
		new_memwb->memResult = 0;
	//when the forwarding is from a R format instruction	
	if(in->memWrite == 1 && in->rt == old_memWb->writeReg && old_memWb->regWrite == 1 && old_memWb->memToReg == 0)
		mem[in->aluResult/4] = old_memWb->aluResult;
	//when the forwarding is from an I formatr instruction
	else if(in->memWrite == 1 && in->rt == old_memWb->writeReg && old_memWb->regWrite == 1 && old_memWb->memToReg == 1)
		mem[in->aluResult/4] = old_memWb->memResult;
	else if(in->memWrite == 1)
		mem[in->aluResult/4] = in->rtVal;
}

//This function writes to the registers if required
//in-> the MEM_WB register
//regs-> the array which holds all the registers
void execute_WB (MEM_WB *in, WORD *regs){
	if(in->regWrite == 1 && in->memToReg == 0)
		regs[in->writeReg] = in->aluResult;
	else if(in->regWrite == 1 && in->memToReg == 1)
		regs[in->writeReg] = in->memResult;
	
}

