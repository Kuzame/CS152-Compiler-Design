all:	bison flex compile

bison:
	bison -v -d --file-prefix=y mini_l.y

flex:
	flex mini_l.lex

compile:
	g++ -o mini_l y.tab.c lex.yy.c -lfl


clean:
	rm -f *.o lex.c parser mini_l lex.yy.c bison.c tok.h mini_l.tab.c mini_l.tab.h mini_l.output mini_l y.*
