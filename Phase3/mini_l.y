%{
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <vector>
#include <sstream>

using namespace std;

int yylex(void);
void yyerror(const char *s);
extern int currLine, currPos;
FILE *yyin;
vector <char*> varBank; //sym_table
vector <char*> varType; //sym_type
vector <char*> paramBank; //param_table
vector <char*> statementBank; //stmnt_vctr
vector <char*> tempBank; //op
vector <char*> functionBank; //func_table
vector <vector<char*>> labelBank; //if_label
vector <vector<char*>> loopLabelBank; //loop_label
vector <char*> inputBank; //read_queue
vector <char*> paramVector; //param_queue
int labelCount=0; //label_count
int tempCount=0; //temp_var_count
bool checkIntVar(char*); //in_sym_table
bool checkArrVar(char*); //in_arr_table
bool checkFunction(char*); //in_func_table

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

func_name:	FUNCTION IDENT
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


declaration:	identifiers COLON INTEGER {varType.push_back("INTEGER");}
		| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER  {varType.push_back(*($5));}
		| error {yyerrok;yyclearin;}
		;

identifiers:	IDENT COMMA identifiers {varBank.push_back(*($1));varType.push_back("INTEGER");}
		| IDENT {varBank.push_back(*($1));if(inParam) paramBank.push_back(*($1));}
		;

/*------------------------------------------------ */

/*----------------- Statement ----------------- */
statements:
		| statement SEMICOLON statements
		;

statement: 	IDENT ASSIGN expression
		{
			if(!checkIntVar($1)) ;//exit(1);
			statementBank.push_back("= "+*($1)+", "+tempBank.back());
			tempBank.pop_back();
		}
		| IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET
		{
			if(!checkArrVar($1)) ;//exit(1);
			char* src = tempBank.back();
			tempBank.pop_back();
			char* index = tempBank.back();
			tempBank.pop_back();
			statementBank.push_back("[]= "+*($1)+", "+index+", "+src);
		}
		| if_statement statements ENDIF
		{
			stringstream ss;
			string strTemp;
			ss<<": "<<labelBank.back().at(1);
			strTemp=ss.str();
			char* charTemp=new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);
			labelBank.pop_back();
		}
		| else_if_statement statements ENDIF
		{
			stringstream ss;
			string strTemp;
			ss<<": "<<labelBank.back().at(2);
			strTemp=ss.str();
			char* charTemp=new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);
			labelBank.pop_back();
		}
		| while_statement statements ENDLOOP
		{
			stringstream ss;
			string strTemp;
			ss.str("");
			ss<<":= "<<loopLabelBank.back().at(0);
			strTemp=ss.str();
			char* charTemp=new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			ss.str("");
			char* charTemp2;
			ss<<": "<<loopLabelBank.back().at(2);
			strTemp=ss.str();
			char* charTemp2=new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);
			loopLabelBank.pop_back();
		}
		| do_statement WHILE bool_exp
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss<<"?:= "<<loopLabelBank.back().at(0)<<", "<<tempBank.back();
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.pop_back();
			loopLabelBank.pop_back();
		}
		| READ IDENT read_comma
		{
			if(!checkIntVar(*($2))) ;//exit(0);
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss<<".< "<<*($2);
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			while(!inputBank.empty()) {
				statementBank.push_back(inputBank.top());
				inputBank.pop_back();
			}
		}
		| READ IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET read_comma
		{
			if(!checkIntVar(*($2))) ;//exit(0);

			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");

			ss.str("");
			ss<<".< "<<charTemp;
			strTemp=ss.str();
			char*charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			inputBank.push_back(charTemp2);

			ss.str("");
			ss<<"[]= _"<<*($2)<<", "<<tempBank.back()<<", "<< charTemp;
			strTemp=ss.str();
			char*charTemp3 = new char[strTemp.size()+1];
			strcpy(charTemp3, strTemp.c_str());
			inputBank.push_back(charTemp3);

			tempBank.pop_back();

			while(!inputBank.empty()) {
				statementBank.push_back(inputBank.top());
				inputBank.pop_back();
			}
		}
		| comma_loop
		| WRITE reduce_term comma_loop
		{
			while(!tempBank.empty()) {
				stringstream ss;
				string strTemp;
				ss.str("");
				ss<< ".> "<<tempBank.front() ;
				tempBank.erase(tempBank.begin());
				strTemp=ss.str();
				char* charTemp = new char[strTemp.size()+1];
				strcpy(charTemp, strTemp.c_str());
				statementBank.push_back(charTemp);
			}
			tempBank.clear();
		}
		| CONTINUE
		{
			if(!loopLabelBank.empty()) {
				if(loopLabelBank.back()[0][0]=='_')  //symbol can be change to
				{
					stringstream ss;
					string strTemp;
					ss.str("");
					ss<< ":= "<<loopLabelBank.back()[1] ;
					strTemp=ss.str();
					char* charTemp = new char[strTemp.size()+1];
					strcpy(charTemp, strTemp.c_str());
					statementBank.push_back(charTemp);
				}
				else {
					stringstream ss;
					string strTemp;
					ss.str("");
					ss<< ":= "<<loopLabelBank.back()[0] ;
					strTemp=ss.str();
					char* charTemp = new char[strTemp.size()+1];
					strcpy(charTemp, strTemp.c_str());
					statementBank.push_back(charTemp);
				}
			}
		}
		| RETURN expression
		{
			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "ret "<<tempBank.back() ;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);
			tempBank.pop_back();
		}
		| error {yyerrok;yyclearin;}
		;

/*vars:		{printf("vars -> epsilon\n");}
		| var COMMA vars {printf("vars -> var COMMA vars\n");}
		| var {printf("vars -> var\n");}
		; */
/*--------------------------------------------- */
if_statement:	IF bool_exp THEN
	{
		stringstream ss;
		string strTemp;
		char* charTemp;
		ss<<"__label__"<<++labelCount;
		strTemp=ss.str();
		charTemp = new char[strTemp.size()+1];
		strcpy(charTemp, strTemp.c_str());
		vector<char*>temp;
		temp.push_back(charTemp);

		char* charTemp2;
		ss.str("");
		ss<<"__label__"<<++labelCount;
		strTemp=ss.str();
		charTemp2 = new char[strTemp.size()+1];
		strcpy(charTemp2, strTemp.c_str());
		temp.push_back(charTemp2);

		char* charTempz;
		ss.str("");
		ss<<"__label__"<<++labelCount;
		strTemp=ss.str();
		charTempz = new char[strTemp.size()+1];
		strcpy(charTempz, strTemp.c_str());
		temp.push_back(charTempz);

		labelBank.push_back(temp);

		ss.str("");
		ss<<"?:= "<<labelBank.back().at(0)<<", "<<tempBank.back();
		strTemp=ss.str();
		char* charTemp3=new char[strTemp.size()+1];
		strcpy(charTemp3, strTemp.c_str());
		statementBank.push_back(charTemp3);

		tempBank.pop_back();

		ss.str("");
		ss<<":= "<<labelBank.back().at(1);
		strTemp=ss.str();
		char* charTemp4=new char[strTemp.size()+1];
		strcpy(charTemp4, strTemp.c_str());
		statementBank.push_back(charTemp4);

		ss.str("");
		ss<<": "<<labelBank.back().at(0);
		strTemp=ss.str();
		char* charTemp5=new char[strTemp.size()+1];
		strcpy(charTemp5, strTemp.c_str());
		statementBank.push_back(charTemp5);
	}
	;

else_if_statement:	if_statement statements ELSE
	{
		stringstream ss;
		string strTemp;
		ss.str("");
		ss<<":= "<<labelBank.back().at(2);
		strTemp=ss.str();
		char* charTemp=new char[strTemp.size()+1];
		strcpy(charTemp, strTemp.c_str());
		statementBank.push_back(charTemp);

		ss.str("");
		char* charTemp2;
		ss<<": "<<labelBank.back().at(1);
		strTemp=ss.str();
		char* charTemp2=new char[strTemp.size()+1];
		strcpy(charTemp2, strTemp.c_str());
		statementBank.push_back(charTemp2);
	}
	;

while_statement: 	while_loop bool_exp BEGINLOOP
	{
		stringstream ss;
		string strTemp;
		ss.str("");
		ss<<"?:= "<<loopLabelBank.back().at(1)<<", "<<tempBank.back();
		strTemp=ss.str();
		char* charTemp3=new char[strTemp.size()+1];
		strcpy(charTemp3, strTemp.c_str());
		statementBank.push_back(charTemp3);

		tempBank.pop_back();

		ss.str("");
		ss<<":= "<<loopLabelBank.back().at(2);
		strTemp=ss.str();
		char* charTemp4=new char[strTemp.size()+1];
		strcpy(charTemp4, strTemp.c_str());
		statementBank.push_back(charTemp4);

		ss.str("");
		ss<<": "<<loopLabelBank.back().at(1);
		strTemp=ss.str();
		char* charTemp5=new char[strTemp.size()+1];
		strcpy(charTemp5, strTemp.c_str());
		statementBank.push_back(charTemp5);
	}
	;

while_loop:	WHILE
	{
		stringstream ss;
		string strTemp;
		char* charTemp;
		ss<<"__label__"<<++labelCount;
		strTemp=ss.str();
		charTemp = new char[strTemp.size()+1];
		strcpy(charTemp, strTemp.c_str());
		vector<char*>temp;
		temp.push_back(charTemp);

		char* charTemp2;
		ss.str("");
		ss<<"__label__"<<++labelCount;
		strTemp=ss.str();
		charTemp2 = new char[strTemp.size()+1];
		strcpy(charTemp2, strTemp.c_str());
		temp.push_back(charTemp2);

		char* charTempz;
		ss.str("");
		ss<<"__label__"<<++labelCount;
		strTemp=ss.str();
		charTempz = new char[strTemp.size()+1];
		strcpy(charTempz, strTemp.c_str());
		temp.push_back(charTempz);

		loopLabelBank.push_back(temp);

		ss.str("");
		ss<<": "<<loopLabelBank.back().at(0);
		strTemp=ss.str();
		char* charTemp5=new char[strTemp.size()+1];
		strcpy(charTemp5, strTemp.c_str());
		statementBank.push_back(charTemp5);
	}
	;

do_statement:	do_loop statements ENDLOOP
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss<<": "<<loopLabelBank.back().at(1);
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);
		}
		;

do_loop:	DO BEGINLOOP
		{
			stringstream ss;
			string strTemp, temp2;
			char* charTemp;
			ss<<"__label__"<<++labelCount;
			strTemp=ss.str();
			temp2=strTemp;
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			vector<char*>temp;
			temp.push_back(charTemp);

			char* charTemp2;
			ss.str("");
			ss<<"__label__"<<++labelCount;
			strTemp=ss.str();
			charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			temp.push_back(charTemp2);

			loopLabelBank.push_back(temp);

			ss.str("");
			ss<<": "<<temp2;
			temp2=ss.str();
			char* charTempz = new char[temp2.size()+1];
			strcpy(charTempz, temp2.c_str());
			statementBank.push_back(charTempz);
		}
		;

read_comma:	COMMA IDENT read_comma
		{
			//char*temp=*($2);
			if(!checkIntVar(*($2))) ;//exit(0);

			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<".< "<<*($2);
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			inputBank.push_back(charTemp);
		}
		| COMMA IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET read_comma
		{
			//char*temp=*($2);
			if(!checkIntVar(*($2))) ;//exit(0);

			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");

			ss.str("");
			ss<<".< "<<charTemp;
			strTemp=ss.str();
			char*charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			inputBank.push_back(charTemp2);

			ss.str("");
			ss<<"[]= _"<<*($2)<<", "<<tempBank.back()<<", "<< charTemp;
			strTemp=ss.str();
			char*charTemp3 = new char[strTemp.size()+1];
			strcpy(charTemp3, strTemp.c_str());
			inputBank.push_back(charTemp3);

			tempBank.pop_back();
		}
		|
		;

comma_loop:
		| COMMA reduce_term comma_loop
		;

reduce_term:	var
		{
			stringstream ss;
			string strTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			char*charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");

			char* temp=varBank.back();
			if(temp[0]=='[') {
				ss.str("");
				char subbuff[4];
				memcpy(subbuff, &buff[strlen(buff)-3], 3);
				subbuff[3]='\0';
				ss<< "=[] "<<charTemp<<", "<< subbuff;
				strTemp=ss.str();
				char* charTemp2 = new char[strTemp.size()+1];
				strcpy(charTemp2, strTemp.c_str());
				statementBank.push_back(charTemp2);
			}
			else {
				stringstream ss;
				string strTemp;
				ss.str("");
				ss<< "= "<<charTemp<<", "<<tempBank.back();
				strTemp=ss.str();
				char* charTemp3 = new char[strTemp.size()+1];
				strcpy(charTemp3, strTemp.c_str());
				statementBank.push_back(charTemp3);
			}
			tempBank.pop_back();
			tempBank.push_back(charTemp);
		}
		| NUMBER
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");

			ss.str("");
			ss<< "= "<< charTemp<<", "<<  $1;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);
			tempBank.push_back(charTemp);
		}
		| L_PAREN expression R_PAREN
		;

/*----------------- Bool Expression ----------------- */
bool_exp:	relation_and_exp
		| relation_and_exp OR bool_exp
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "|| "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);

		}
		;
/*--------------------------------------------------- */

/*----------------- Relation And Expression ----------------- */
relation_and_exp: relation_exp
 		| relation_exp AND relation_and_exp
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "&& "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		;
/*----------------------------------------------------------- */

/*----------------- Relation Expression ----------------- */
relation_exp: 	NOT relation_exp2
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "! "<<charTemp<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| relation_exp2
		;

relation_exp2:	expression EQ expression
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "== "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| expression NEQ expression
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "!= "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| expression LT expression
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "< "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| expression GT expression
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "> "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| expression LTE expression
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "<= "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| expression GTE expression
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< ">= "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| TRUE
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< ">= "<<charTemp<<", 1";
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| FALSE
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< ">= "<<charTemp<<", 0";
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| L_PAREN bool_exp R_PAREN
		;
/*------------------------------------------------------- */

/*----------------- Comp ----------------- */
/*comp:		EQ {printf("comp -> EQ \n");}
		| NEQ {printf("comp -> NEQ \n");}
		| LT {printf("comp -> LT \n");}
		| GT {printf("comp -> GT \n");}
		| LTE {printf("comp -> LTE \n");}
		| GTE {printf("comp -> GTE \n");}
		; */
/*---------------------------------------- */

/*----------------- Expression ----------------- */
expression:	mult_exp expr_branch
		;

expr_branch:
		| ADD mult_exp expr_branch
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "+ "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| SUB mult_exp expr_branch
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "- "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		;
/*---------------------------------------------- */

/*----------------- Multiplicative Expression ----------------- */
mult_exp:	term mult_branch
		;

mult_branch:
		| MULT term mult_branch
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "* "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| DIV term mult_branch
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "/ "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		| MOD term mult_branch
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");
			char* temp=tempBank.back();
			tempBank.pop_back();
			char* temp2=tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "% "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.push_back(charTemp);
		}
		;
/*------------------------------------------------------------- */

/*----------------- Term ----------------- */
term:		reduce_term
		| SUB reduce_term
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "- "<<charTemp<<", 0, "<<tempBank.back();
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			tempBank.pop_back();
			tempBank.push_back(charTemp);
		}
		| IDENT term_paren
		{
			stringstream ss;
			string strTemp;
			char* charTemp;
			ss.str("");
			ss<<"__temp__"<<tempCount++;
			strTemp=ss.str();
			charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			varType.push_back("INTEGER");

			if(!checkFunction(*($1))); //exit(1);
			ss.str("");
			ss<< "call "<<*($1)<<", "<<charTemp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);
			tempBank.push_back(charTemp);

		}
		;

term_paren:	L_PAREN term_expr R_PAREN
		{
			while(!paramVector.empty()) {
				stringstream ss;
				string strTemp;
				ss.str("");
				ss<< "param "<<paramVector.back();
				strTemp=ss.str();
				char* charTemp = new char[strTemp.size()+1];
				strcpy(charTemp, strTemp.c_str());
				statementBank.push_back(charTemp);
				paramVector.pop_back();
			}
		}
		| L_PAREN R_PAREN
		;

term_expr:	expression
		{
			paramVector.push_back(tempBank.back());
			tempBank.pop_back();
		}
		| expression COMMA term_expr
		{
			paramVector.push_back(tempBank.back());
			tempBank.pop_back();
		}

expressions:	expression {printf("expressions -> expression\n");}
		| expression COMMA expressions {printf("expressions -> expression COMMA expressions\n");}
		;
/*---------------------------------------- */


/*----------------- Var ----------------- */
var:		IDENT
		{
			if(!checkIntVar(*($1))) ; //exit(1);
			tempBank.push_back(*($1));
		}
		| IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET
		{
			char* temp = tempBank.back();
			tempBank.pop_back();
			if(!checkArrVar(*($1))) ; //exit(1);

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "[] "<<*($1)<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			tempBank.push_back(charTemp);
		}
		;
/*--------------------------------------- */
%%



void yyerror(const char* s) {
	printf("Syntax error at line %d: %s",currLine, s);
}

bool checkIntVar(char*s){
	for(unsigned i =0; i<varBank.size();i++) {
		if(varBank[i]==s) {
			if(varType[i]=="INTEGER") return true;
			else {
				printf("Error");
				return false;
			}
		}
	}
	printf("Not exist error");
	return false;
}

bool checkArrVar(char*s){
	for(unsigned i =0; i<varBank.size();i++) {
		if(varBank[i]==s) {
			if(varType[i]=="INTEGER") {
				return false;
				printf("Error");
			}
			else return true;
		}
	}
	printf("Not exist error");
	return false;
}

bool checkFunction(char*s) {
	for(unsigned i =0; i<functionBank.size();i++) {
		if(functionBank[i]==s) return true;
	}
	printf("Not exist error");
	return false;
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
