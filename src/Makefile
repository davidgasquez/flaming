
all: flaming
	rm lex.yy.c parser.output  parser.tab.c  parser.tab.h main.o parser.tab.o

flaming: main.o parser.tab.o
	gcc -o flaming main.o parser.tab.o

parser.tab.o: parser.tab.c
	gcc -c parser.tab.c

main.o: main.cc
	gcc -c main.cc

parser.tab.c: parser.y lex.yy.c
	bison -vd parser.y

lex.yy.c: scanner.l
	flex -ll scanner.l

clean:
	rm flaming lex.yy.c parser.output  parser.tab.c  parser.tab.h main.o parser.tab.o
