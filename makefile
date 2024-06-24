YACC=byacc
LEX=flex

all: codegen

codegen: y.tab.c lex.yy.c
	gcc -o codegen y.tab.c lex.yy.c function.c -lfl

y.tab.c: parser.y
	$(YACC) -d parser.y

lex.yy.c: scanner.l
	$(LEX) scanner.l

clean:
	rm -f codegen lex.yy.c y.tab.c y.tab.h

.PHONY: all clean