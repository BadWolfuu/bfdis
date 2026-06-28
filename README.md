# bfdis
"disasembles" brainfuck into an assembly like for better debugging

## building
  `odin build .`

## usage
  `bfdis [flags] (file)`

### instructions:
	mvr ARG:	move pointer to the right ARG times ">"
	mvl ARG:	move pointer to the left ARG times "<"
	inc ARG:	increment cell at the pointer ARG times "+"
	dec ARG:	decrement cell at the pointer ARG times "-"
	prt ARG:	print cell at the pointer ARG times as a character "."
	rin ARG:	read user input into the cell at pointer ARG times ","
	obr ARG:	jump past mathing 'cbr' on line ARG if the cell at pointer is 0 "["
	cbr ARG:	jump back to mathing 'obr' in line ARG if the cell at pointer is nonzero 
