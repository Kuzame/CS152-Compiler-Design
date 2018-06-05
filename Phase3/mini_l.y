%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);
extern int currLine, currPos;
FILE *yyin;
vector <string> varBank; //sym_table
vector <string> varType; //sym_type
vector <string> paramBank; //param_table
vector <string statementBank; //stmnt_vctr
bool inParam=false;
%}

%union{
char* sval;
}

%error-verbose
%start begin
%token L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY IF ENDIF FUNCTION COLON SEMICOLON COMMA INTEGER ARRAY OF THEN ELSE WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE TRUE FALSE RETURN
%token <sval> NUMBER
%token <sval> IDENT
%left  ADD MULT DIV SUB MOD AND OR LT LTE GT GTE EQ NEQ
%right NOT ASSIGN

%%
begin:		functions
		;

/*----------------- Function ----------------- */
functions:	
		| function functions 
		;

function:	func_name SEMICOLON begin_params declarations end_params BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY 
		{
			int temp=0;
			for(unsigned i=0;i<varBank.size();i++) {
				if(varType=="INTEGER") {
					printf(". %s\n", varBank[i]);
				}
				else {
					printf(".[] %s, %s\n", varBank[i], varType[i]);
				}
			}
			

			while(!paramBank.empty()) {
				printf("= %s, $%s\n", paramBank.front(), temp++);
				paramBank.erase(paramBank.begin());
			}

			for(unsigned i=0;i<statementBank.size();i++) printf("%s\n", statementBank[i]);
			printf("endfunc\n");
			varBank.clear();
			varType.clear();
			paramBank.clear();
			statementBank.clear();
		}
		| error{yyerrok;yyclearin;}
		;

func_name:	FUNCTION ident
		{
			varBank.push_back(*($2));
			printf("func %s\n", $2);
		}
		;

begin_params:	BEGIN_PARAMS {inParam=true;}
		;

end_params:	END_PARAMS {inParams=false;}
		;

declarations:	
		| declaration SEMICOLON declarations
		;
/*-------------------------------------------- */

/*----------------- Declaration ----------------- */


declaration:	identifiers COLON INTEGER {}
		| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER  {printf("declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER\n");}
		| error {yyerrok;yyclearin;}
		;

identifiers:	ident COMMA identifiers {printf("identifiers -> ident COMMA identifiers\n");}
		| ident {printf("identifiers -> ident\n");}
		;

ident:		IDENT {printf("ident -> IDENT %s\n", $1);}
		;
/*------------------------------------------------ */

/*----------------- Statement ----------------- */
statements:	{printf("statements -> epsilon\n");}
		| statement SEMICOLON statements {printf("statements -> statement SEMICOLON statements\n");}
		;

statement: 	var ASSIGN expression{printf("statement -> var ASSIGN expression\n");}
		| IF bool_exp THEN statements ENDIF {printf("statement -> IF bool_exp THEN statements ENDIF\n");}
		| IF bool_exp THEN statements ELSE statements ENDIF {printf("statement -> IF bool_exp THEN statements ELSE statements ENDIF\n");}
		| WHILE bool_exp BEGINLOOP statements ENDLOOP {printf("statement -> WHILE bool_exp BEGINLOOP statements ENDLOOP\n");}
		| DO BEGINLOOP statements ENDLOOP WHILE bool_exp {printf("statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_exp\n");}
		| READ vars {printf("statement -> READ vars\n");}
		| WRITE vars {printf("statement -> WRITE vars\n");}
		| CONTINUE {printf("statement -> CONTINUE\n");}
		| RETURN expression {printf("statement -> RETURN expression\n");}
		| error {yyerrok;yyclearin;}
		;
vars:		{printf("vars -> epsilon\n");}
		| var COMMA vars {printf("vars -> var COMMA vars\n");}
		| var {printf("vars -> var\n");}
		;
/*--------------------------------------------- */

/*----------------- Bool Expression ----------------- */
bool_exp:	relation_and_exp {printf("bool_exp -> relation_and_exp\n");}
		| relation_and_exp OR bool_exp {printf("bool_exp -> relation_and_exp OR relation_and_exp\n");}
		;
/*--------------------------------------------------- */

/*----------------- Relation And Expression ----------------- */
relation_and_exp: relation_exp {printf("relation_and_exp -> relation_exp\n");}
 		| relation_exp AND relation_and_exp {printf("relation_and_exp -> relation_exp AND relation_exp\n");}
		;
/*----------------------------------------------------------- */

/*----------------- Relation Expression ----------------- */
relation_exp: 	NOT relation_exp2 {printf("relation_exp -> NOT relation_exp\n");}
		| relation_exp2 {printf("relation_exp -> relation_exp\n");}
		;

relation_exp2:	expression comp expression {printf("relation_exp -> expression comp expression\n");}
		| TRUE {printf("relation_exp -> TRUE\n");}
		| FALSE {printf("relation_exp -> FALSE\n");}
		| L_PAREN bool_exp R_PAREN {printf("relation_exp -> L_PAREN bool_exp R_PAREN\n");}
		;
/*------------------------------------------------------- */

/*----------------- Comp ----------------- */
comp:		EQ {printf("comp -> EQ \n");}
		| NEQ {printf("comp -> NEQ \n");}
		| LT {printf("comp -> LT \n");}
		| GT {printf("comp -> GT \n");}
		| LTE {printf("comp -> LTE \n");}
		| GTE {printf("comp -> GTE \n");}
		;
/*---------------------------------------- */

/*----------------- Expression ----------------- */
expression:	 mult_exp ADD expression {printf("expression -> multiplicative_expression ADD multiplicative_expression\n");}
		| mult_exp SUB expression {printf("expression -> multiplicative_expression SUB multiplicative_expression\n");}
		| mult_exp {printf("expression -> multiplicative_expression\n");}
		|;
/*---------------------------------------------- */

/*----------------- Multiplicative Expression ----------------- */
mult_exp:	term MULT term {printf("multiplicative_expression -> term MULT term\n");}
		| term DIV term {printf("multiplicative_expression -> term DIV term\n");}
		| term MOD term {printf("multiplicative_expression -> term MOD term\n");}
		| term {printf("multiplicative_expression -> term\n");} /*if this is on top, will print i], k[, k;*/
		;
/*------------------------------------------------------------- */

/*----------------- Term ----------------- */
term:		term2 {}
		| SUB var {printf("term -> SUB var\n");}
		| SUB NUMBER {printf("term -> SUB NUMBER %s\n", $2);}
		| SUB L_PAREN expression R_PAREN {printf("term -> SUB L_PAREN expression R_PAREN\n");}
		| ident L_PAREN expressions R_PAREN {printf("term -> IDENT L_PAREN expressions R_PAREN\n");}
		;

term2:		var {printf("term -> var\n");}
		| NUMBER {printf("term -> NUMBER %s\n", $1);}
		| L_PAREN expression R_PAREN {printf("L_PAREN expression R_PAREN\n");}
		;

expressions:	expression {printf("expressions -> expression\n");}
		| expression COMMA expressions {printf("expressions -> expression COMMA expressions\n");}
		; 
/*---------------------------------------- */


/*----------------- Var ----------------- */
var:		ident {printf("var -> IDENT\n");}
		| ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET {printf("var -> IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n");}
		;
/*--------------------------------------- */
%%



void yyerror(const char* s)
{
	printf("Syntax error at line %d: %s",currLine, s);
}

int main(int argc, char **argv) {
   if (argc > 1) {
      yyin = fopen(argv[1], "r");
      if (yyin == NULL){
         printf("syntax: %s filename\n", argv[0]);
      }//end if
   }//end if
   yyparse(); // Calls yylex() for tokens.
   return 0;
}
