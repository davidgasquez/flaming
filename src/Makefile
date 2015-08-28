
all: flaming
	 rm parser.tab.c lex.yy.c parser.tab.h

parser.tab.c parser.tab.h:	parser.y
	bison -d parser.y

lex.yy.c: scanner.l parser.tab.h
	flex scanner.l

flaming: lex.yy.c parser.tab.c parser.tab.h
	gcc -o flaming parser.tab.c lex.yy.c -lfl

clean:
	rm flaming parser.tab.c lex.yy.c parser.tab.h
