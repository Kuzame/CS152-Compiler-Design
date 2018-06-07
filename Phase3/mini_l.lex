%{
#define YY_NO_UNPUT

using namespace std;

#include <iostream>
#include <stdio.h>
#include <string>
#include <cstring>
#include <stdlib.h>
#include <vector>
#include <sstream>

#include "y.tab.h"
//#include <stdio.h>
//#include <stdlib.h>

//int yylex();
int yyerror(char *s);
%}

	int currLine = 1, currPos = 1;
DIGIT	[0-9]+
ID	[a-zA-Z_0-9]+

%%
"##".* 			{++currLine; currPos=1;}
"+"				{currPos += yyleng; return ADD;}
"-"				{currPos += yyleng; return SUB;}
"*"				{currPos += yyleng; return MULT;}
"/"				{currPos += yyleng; return DIV;}
"%"				{currPos += yyleng; return MOD;}
"("				{currPos += yyleng; return L_PAREN;}
")"				{currPos += yyleng; return R_PAREN;}
"["				{currPos += yyleng; return L_SQUARE_BRACKET;}
"]"				{currPos += yyleng; return R_SQUARE_BRACKET;}
"<"				{currPos += yyleng; return LT;}
"<="			{currPos += yyleng; return LTE;}
">"				{currPos += yyleng; return GT;}
">="			{currPos += yyleng; return GTE;}
"=="			{currPos += yyleng; return EQ;}
"<>"			{currPos += yyleng; return NEQ;}
"not"			{currPos += yyleng; return NOT;}
"and"			{currPos += yyleng; return AND;}
"or"			{currPos += yyleng; return OR;}
":="			{currPos += yyleng; return ASSIGN;}
"beginparams"	{currPos += yyleng; return BEGIN_PARAMS;}
"endparams"		{currPos += yyleng; return END_PARAMS;}
"beginlocals"	{currPos += yyleng; return BEGIN_LOCALS;}
"endlocals"		{currPos += yyleng; return END_LOCALS;}
"beginbody"		{currPos += yyleng; return BEGIN_BODY;}
"endbody"		{currPos += yyleng; return END_BODY;}
"if"			{currPos += yyleng; return IF;}
"endif"			{currPos += yyleng; return ENDIF;}
"function"		{currPos += yyleng; return FUNCTION;}
":"				{currPos += yyleng; return COLON;}
";"				{currPos += yyleng; return SEMICOLON;}
","				{currPos += yyleng; return COMMA;}
"integer"		{currPos += yyleng; return INTEGER;}
"array"			{currPos += yyleng; return ARRAY;}
"of"			{currPos += yyleng; return OF;}
"then"			{currPos += yyleng; return THEN;}
"else"			{currPos += yyleng; return ELSE;} 
"while"			{currPos += yyleng; return WHILE;}
"do"			{currPos += yyleng; return DO;}
"beginloop"		{currPos += yyleng; return BEGINLOOP;}
"endloop"		{currPos += yyleng; return ENDLOOP;}
"continue"		{currPos += yyleng; return CONTINUE;}
"read"			{currPos += yyleng; return READ;}
"write"			{currPos += yyleng; return WRITE;}
"true"			{currPos += yyleng; return TRUE;}
"false"			{currPos += yyleng; return FALSE;}
"return"		{currPos += yyleng; return RETURN;}
{DIGIT} 		{currPos += yyleng; yylval.val=atoi(yytext); return NUMBER;}
({DIGIT}|_+){ID}	{printf("Error at line %d, column %d: identifier \"%s\" must begin with letter\n", currLine, currPos, yytext); }
{ID}_+			{printf("Error at line %d, column %d: identifier \"%s\" cannot end with underscore\n", currLine, currPos, yytext); }
{ID}			{currPos += yyleng; yylval.sval=yytext; return IDENT;}
" "			{currPos += yyleng; }
"\n"			{currLine++; currPos = 1;}
"\t"			{currPos += yyleng; }

"="			{printf("Syntax error at line %d, column %d: \":=\" expected\n", currLine, currPos);}
. 				{printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext); }
%%
