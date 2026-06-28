package bfdis

import "core:os"
import "core:fmt"
import "core:reflect"
import "core:mem"

main :: proc() {
	if len(os.args) < 2 {
		fmt.println("missing argument: file")
		fmt.print(HELP_STRING)
		os.exit(0)
	}


	filename := os.args[1]

	switch filename {
		case "--help":
			fmt.print(HELP_STRING)
			os.exit(0)
		case :
			s := filename[:]
			if s[0] == '-' {
				fmt.println("invalid argument:",filename)
				fmt.print(HELP_STRING)
				os.exit(0)
			}
	}

	data,read_err := os.read_entire_file(filename,context.allocator)
	if read_err != nil {
		fmt.eprintf("could not load %s\n\tError: %v\n",filename,read_err)
		os.exit(1)
	}

	src_line:int = 1
	src_pos:int = 1
	asm_line:int = 1
	skip:int = 0

	instructions:[dynamic]Instruction
	bracket_stack:[dynamic]Bracket
	
	data_loop:for op,i in data {
		if skip > 0 {
			skip -= 1
			src_pos +=1
			continue data_loop
		}

		append_err:mem.Allocator_Error
		
		switch op {
			case '>':
				n:= peek_and_count(i,op,data)
				skip = n
				_,append_err = append(&instructions,Instruction{opcode = .mvr, arg = n+1, line = asm_line,src_line = src_line, src_pos = src_pos})
			case '<':
				n:= peek_and_count(i,op,data)
				skip = n
				_,append_err = append(&instructions,Instruction{opcode = .mvl, arg = n+1, line = asm_line,src_line = src_line, src_pos = src_pos})
			case '+':
				n:= peek_and_count(i,op,data)
				skip = n
				_,append_err = append(&instructions,Instruction{opcode = .inc, arg = n+1, line = asm_line,src_line = src_line, src_pos = src_pos})
			case '-':
				n:= peek_and_count(i,op,data)
				skip = n
				_,append_err = append(&instructions,Instruction{opcode = .dec, arg = n+1, line = asm_line,src_line = src_line, src_pos = src_pos})
			case '.':
				n:= peek_and_count(i,op,data)
				skip = n
				_,append_err = append(&instructions,Instruction{opcode = .prt, arg = n+1, line = asm_line,src_line = src_line, src_pos = src_pos})
			case ',':
				n:= peek_and_count(i,op,data)
				skip = n
				_,append_err = append(&instructions,Instruction{opcode = .rin, arg = n+1, line = asm_line,src_line = src_line, src_pos = src_pos})
			case '[':
				_,append_err = append(&instructions,Instruction{opcode = .obr, arg = 0, line = asm_line,src_line = src_line, src_pos = src_pos})
				_,append_err = append(&bracket_stack,asm_line-1)
			case ']':
				open_bracket,bracket_ok := pop_safe(&bracket_stack)
				if bracket_ok == false {
					fmt.eprintf(
						"Error: more closing brackets then opening brackets\n\t no matching pair found for ']' at %d:%d\n",
						src_line,src_pos
					)
					os.exit(1)
				}
				instructions[open_bracket].arg = asm_line
				_,append_err = append(&instructions,Instruction{opcode = .cbr, arg = open_bracket+1, line = asm_line,src_line = src_line, src_pos = src_pos})
			case '\n':
				src_line += 1
				src_pos = 0
				asm_line -= 1
			case:
				asm_line -= 1
		}

		if append_err != nil {
			fmt.eprintf("Fatal Error: %v\n",append_err)
			os.exit(1)
		}

		src_pos += 1
		asm_line += 1
	}

	if len(bracket_stack) > 0 {
		idx:= pop(&bracket_stack)
		bracket := instructions[idx]
		fmt.eprintf(
			"Error: more opening brackets then opening brackets\n\t no matching pair found for '[' at %d:%d\n",
			bracket.src_line,bracket.src_pos
		)
		os.exit(1)

		
	}

	fmt.print("[line]\t[src]\t[instruction]\n")
	for ins in instructions {
		code_string := reflect.enum_string(ins.opcode)
		fmt.printf(" %d\t%d:%d\t%s %d\n",ins.line,ins.src_line,ins.src_pos,code_string,ins.arg)
	}

	
}

peek_and_count :: proc(pos:int,char:u8,data:[]u8) -> (num:int) {
	for i:= pos+1;data[i] == char && i < len(data);i+=1 {
		num +=1
	}
	return
}

HELP_STRING :: `usage:
	bfdis [flags] (file)

flags:
	--help	print this help message

instructions:
	mvr ARG:	move pointer to the right ARG times ">"
	mvl ARG:	move pointer to the left ARG times "<"
	inc ARG:	increment cell at the pointer ARG times "+"
	dec ARG:	decrement cell at the pointer ARG times "-"
	prt ARG:	print cell at the pointer ARG times as a character "."
	rin ARG:	read user input into the cell at pointer ARG times ","
	obr ARG:	jump past mathing 'cbr' on line ARG if the cell at pointer is 0 "["
	cbr ARG:	jump back to mathing 'obr' in line ARG if the cell at pointer is nonzero 
`

Bracket :: int

Instruction :: struct {
	opcode:Opcodes,
	arg:int,
	line:int,
	src_line:int,
	src_pos:int
}

Opcodes :: enum(u8) {
	mvr, // move pointer left
	mvl, // move pointer right
	inc, // increment cell
	dec, // decrement cel
	prt, // print cell
	rin, // read input
	obr, // open bracket jump
	cbr, // closed bracket jmp
}
