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

int yyparse();
int yylex();
void yyerror(const char *s);
extern int currLine, currPos;

vector <char*> varBank; //sym_table
vector <char*> varType; //sym_type
vector <char*> paramBank; //param_table
vector <char*> statementBank; //stmnt_vctr
vector <char*> tempBank; //op
vector <char*> functionBank; //func_table
vector <vector<char*> > labelBank; //if_label
vector <vector<char*> > loopLabelBank; //loop_label
vector <char*> inputBank; //read_queue
vector <char*> paramVector; //param_queue
int labelCount=0; //label_count
int tempCount=0; //temp_var_count
bool checkIntVar(string); //in_sym_table
bool checkArrVar(string); //in_arr_table
bool checkFunction(string); //in_func_table

bool inParam=false;
%}

%union{
char* sval;
int val;
string * test;
}

%error-verbose
%start begin
%token L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY IF ENDIF FUNCTION COLON SEMICOLON COMMA INTEGER ARRAY OF THEN ELSE WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE TRUE FALSE RETURN
%token <val> NUMBER
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
				if(varType.at(i)=="INTEGER") {
					printf(". %s\n", varBank[i]);
				}
				else {
					printf(".[] %s, %s\n", varBank[i], varType[i]);
				}
			}


			while(!paramBank.empty()) {
				printf("= %s, $%d\n", paramBank.front(), temp++);
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
			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< *($2) ;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			functionBank.push_back(charTemp);
			//printf("func_name-------------varBank: %s\n", varBank.back());
			printf("func %s\n", $2);
		}
		;

begin_params:	BEGIN_PARAMS {inParam=true;}
		;

end_params:	END_PARAMS {inParam=false;}
		;

declarations:
		| declaration SEMICOLON declarations
		;
/*-------------------------------------------- */

/*----------------- Declaration ----------------- */
declaration:	identifiers COLON integer
		;

identifiers:	IDENT {
			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< *($1) ;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			//if(!checkIntVar(charTemp))
			varBank.push_back(charTemp);
			//printf("IDENT-------------varBank: <%s>\n", temp);
			if(inParam) paramBank.push_back(charTemp);
		}
		| IDENT COMMA identifiers {
			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< *($1) ;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varBank.push_back(charTemp);
			//printf("IDENTCOMMA-------------varBank: %s\n", varBank.back());
			varType.push_back("INTEGER");
		}
		;

integer:	INTEGER {
			varType.push_back("INTEGER");
		}
		| ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
		{
			/* cout<<"---------NUMBER IS: "<<$3<<endl; */
			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< $3 ;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			varType.push_back(charTemp);
		}
/*------------------------------------------------ */

/*----------------- Declaration ----------------- */
/*declaration:	identifiers COLON INTEGER {varType.push_back("INTEGER");}
		| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER  {varType.push_back($5);}
		| error {yyerrok;yyclearin;}
		;

identifiers:	IDENT COMMA identifiers {varBank.push_back($1);varType.push_back("INTEGER");}
		| IDENT {
			varBank.push_back($1);
			if(inParam) paramBank.push_back($1);
		}
		;*/
/*------------------------------------------------ */

/*----------------- Statement ----------------- */
statements:	statement SEMICOLON statements
		| statement SEMICOLON
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED\n";}
		;

statement: 	IDENT ASSIGN expression
		{
			stringstream a;
			a.str("");
			a<< *($1) ;

			string var = a.str();;
			if(!checkIntVar(var)) ;//exit(1);
			stringstream ss;
			string strTemp;
			ss.str("");
			char* removeParen=$1;
			int removeNumber;
			for(unsigned i=0;i<(int)strlen(removeParen);i++) {
				if(removeParen[i]=='(') {
					removeNumber=i;
					break;
				}
				else if(!((removeParen[i]>='a'&&removeParen[i]<='z')||(removeParen[i]>='A'&&removeParen[i]<='Z')||removeParen[i]=='_')) {
					removeNumber=i;
					break;
				}
			}
			char subbuff[removeNumber+1];
			memcpy(subbuff, &removeParen[0], removeNumber);
			subbuff[removeNumber]='\0';
			ss<< "= "<<*($1)<<", "<<tempBank.back() ;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);
			tempBank.pop_back();
		}
		| IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET ASSIGN expression
		{
			stringstream a;
			a.str("");
			a<< *($1) ;

			string var = a.str();;
			if(!checkArrVar(var)) ;//exit(1);
			char* src = tempBank.back();
			tempBank.pop_back();
			char* index = tempBank.back();
			tempBank.pop_back();

			stringstream ss;
			string strTemp;
			ss.str("");

			char* removeParen=$1;
			int removeNumber;
			for(unsigned i=0;i<(int)strlen(removeParen);i++) {
				if(removeParen[i]=='(') {
					removeNumber=i;
					break;
				}
				else if(!((removeParen[i]>='a'&&removeParen[i]<='z')||(removeParen[i]>='A'&&removeParen[i]<='Z')||removeParen[i]=='_')) {
					removeNumber=i;
					break;
				}
			}
			char subbuff[removeNumber+1];
			memcpy(subbuff, &removeParen[0], removeNumber);
			subbuff[removeNumber]='\0';

			ss<< "[]= "<<subbuff<<", "<<index<<", "<<src ;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);
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
			stringstream a;
			a.str("");
			a<< *($2) ;

			string var = a.str();;
			if(!checkIntVar(var)) ;//exit(1);
			stringstream ss;
			ss.str("");

			char* removeParen=$2;
			int removeNumber;
			for(unsigned i=0;i<(int)strlen(removeParen);i++) {
				if(removeParen[i]=='(') {
					removeNumber=i;
					break;
				}
				else if(!((removeParen[i]>='a'&&removeParen[i]<='z')||(removeParen[i]>='A'&&removeParen[i]<='Z')||removeParen[i]=='_')) {
					removeNumber=i;
					break;
				}
			}
			char subbuff[removeNumber+1];
			memcpy(subbuff, &removeParen[0], removeNumber);
			subbuff[removeNumber]='\0';

			ss<<".< "<<subbuff;
			string strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			statementBank.push_back(charTemp);

			while(!inputBank.empty()) {
				statementBank.push_back(inputBank.back());
				inputBank.pop_back();
			}
		}
		| READ IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET read_comma
		{
			stringstream a;
			a.str("");
			a<< *($2) ;

			string var = a.str();;
			if(!checkIntVar(var)) ;//exit(1);

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
				statementBank.push_back(inputBank.back());
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
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED\n";}
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
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED if_stat\n";}
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
		ss<<": "<<labelBank.back().at(1);
		strTemp=ss.str();
		char* charTemp2=new char[strTemp.size()+1];
		strcpy(charTemp2, strTemp.c_str());
		statementBank.push_back(charTemp2);
	}
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED elif_state\n";}
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
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED while\n";}
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
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED\n";}
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
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED do_state\n";}
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
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED do_loop\n";}
		;

read_comma:	COMMA IDENT read_comma
		{
			stringstream a;
			a.str("");
			a<< *($2) ;

			string var = a.str();;
			if(!checkIntVar(var)) ;//exit(1);

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
			stringstream a;
			a.str("");
			a<< *($2) ;

			string var = a.str();;
			if(!checkIntVar(var)) ;//exit(1);

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
		
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED read_comma\n";}
		;

comma_loop:
		| COMMA reduce_term comma_loop
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED comma_loop\n";}
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
				memcpy(subbuff, &temp[strlen(temp)-3], 3);
				subbuff[3]='\0';
				ss<< "=[] "<<charTemp<<", "<< subbuff;
				strTemp=ss.str();
				char* charTemp2 = new char[strTemp.size()+1];
				strcpy(charTemp2, strTemp.c_str());
				statementBank.push_back(charTemp2);
			}
			else {
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
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED reduce_term\n";}
		;

/*----------------- Bool Expression ----------------- */
bool_exp:	relation_and_exp
		| bool_exp OR relation_and_exp
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

			ss.str("");
			ss<< "|| "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

			tempBank.push_back(charTemp);
		}
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED bool_exp\n";}
		;
/*--------------------------------------------------- */

/*----------------- Relation And Expression ----------------- */
relation_and_exp: relation_exp
 		| relation_and_exp AND relation_exp
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


			ss.str("");
			ss<< "&& "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

			tempBank.push_back(charTemp);
		}
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED relationAndExp\n";}
		;
/*----------------------------------------------------------- */

/*----------------- Relation Expression ----------------- */
relation_exp: relation_exp2
		| NOT relation_exp2
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

			ss.str("");
			ss<< "! "<<charTemp<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

			tempBank.push_back(charTemp);
		}
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED relation_exp\n";}
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

			ss.str("");
			ss<< "== "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

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

			ss.str("");
			ss<< "!= "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

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

			ss.str("");
			ss<< "< "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

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

			ss.str("");
			ss<< "> "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

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

			ss.str("");
			ss<< "<= "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

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

			ss.str("");
			ss<< ">= "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

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

			ss.str("");
			ss<< "= "<<charTemp<<", 1";
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

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

			ss.str("");
			ss<< "= "<<charTemp<<", 0";
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

			tempBank.push_back(charTemp);
		}
		| L_PAREN bool_exp R_PAREN
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED relationexp2\n";}
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
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED expression\n";}
		;

expr_branch: 
		| ADD mult_exp expr_branch
		{
			//cout<<"--------- expr_branchADD"<<endl;
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
			

			ss.str("");
			ss<< "+ "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

			tempBank.push_back(charTemp);
		}
		| SUB mult_exp expr_branch
		{
			//cout<<"--------- expr_branchSUB"<<endl;
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


			ss.str("");
			ss<< "- "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

			tempBank.push_back(charTemp);
		}
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED expr_branch\n";}
		;
/*---------------------------------------------- */

/*----------------- Multiplicative Expression ----------------- */
mult_exp:	term mult_branch
		|
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED mult_exp\n";}
		;

mult_branch: {
			
			//cout<<"--------- mult_branchMULT"<<endl;
		}
		| MULT term mult_branch
		{
			//cout<<"--------- mult_branchMULT"<<endl;
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

			ss.str("");
			ss<< "* "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

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

			ss.str("");
			ss<< "/ "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

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

			ss.str("");
			ss<< "% "<<charTemp<<", "<<temp2<<", "<<temp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

			tempBank.push_back(charTemp);
		}
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED mult_branch\n";}
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

			ss.str("");
			ss<< "- "<<charTemp<<", 0, "<<tempBank.back();
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);

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

			stringstream a;
			a.str("");
			a<< *($1) ;

			string var = a.str();;
			if(!checkFunction(var)) ;//exit(1);
			ss.str("");
			char* removeParen=$1;
			int removeNumber;
			for(unsigned i=0;i<(int)strlen(removeParen);i++) {
				if(removeParen[i]=='(') {
					removeNumber=i;
					break;
				}
				else if(!((removeParen[i]>='a'&&removeParen[i]<='z')||(removeParen[i]>='A'&&removeParen[i]<='Z')||removeParen[i]=='_')) {
					removeNumber=i;
					break;
				}
			}
			char subbuff[removeNumber+1];
			memcpy(subbuff, &removeParen[0], removeNumber);
			subbuff[removeNumber]='\0';
			//cout<<subbuff<<endl;

			ss<< "call "<<subbuff<<", "<<charTemp;
			strTemp=ss.str();
			char* charTemp2 = new char[strTemp.size()+1];
			strcpy(charTemp2, strTemp.c_str());
			statementBank.push_back(charTemp2);
			tempBank.push_back(charTemp);

		}
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED term\n";}
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
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED termParen\n";}
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
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED term\n";}
		;

/*
expressions:	expression {printf("expressions -> expression\n");}
		| expression COMMA expressions {printf("expressions -> expression COMMA expressions\n");}
		; */
/*---------------------------------------- */


/*----------------- Var ----------------- */
var:		IDENT
		{
			//cout<<"------------var$1: "<<$1<<endl;
			stringstream a;
			a.str("");
			a<< *($1) ;

			string var = a.str();;
			//cout<<"------------var: "<<var<<endl;
			if(!checkIntVar(var)) ;//exit(1);
			stringstream ss;
			string strTemp;
			ss.str("");


			char* removeParen=$1;
			int removeNumber;
			for(unsigned i=0;i<(int)strlen(removeParen);i++) {
				if(removeParen[i]=='(') {
					removeNumber=i;
					break;
				}
				else if(!((removeParen[i]>='a'&&removeParen[i]<='z')||(removeParen[i]>='A'&&removeParen[i]<='Z')||removeParen[i]=='_')) {
					removeNumber=i;
					break;
				}
			}
			char subbuff[removeNumber+1];
			memcpy(subbuff, &removeParen[0], removeNumber);
			subbuff[removeNumber]='\0';

			ss<< *($1) ;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			tempBank.push_back(charTemp);
		}
		| IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET
		{
			char* temp = tempBank.back();
			tempBank.pop_back();
			stringstream a;
			a.str("");
			a<< *($1) ;

			string var = a.str();;
			if(!checkArrVar(var)) ;//exit(1);

			stringstream ss;
			string strTemp;
			ss.str("");
			ss<< "[] "<<*($1)<<", "<<temp;
			strTemp=ss.str();
			char* charTemp = new char[strTemp.size()+1];
			strcpy(charTemp, strTemp.c_str());
			tempBank.push_back(charTemp);
		}
		| error {yyerrok;yyclearin;cout<<"ERROR TRIGGERED term\n";}
		;
/*--------------------------------------- */
%%



void yyerror(const char* s) {
	printf("Syntax error at line %d: %s",currLine, s);
}

bool checkIntVar(string s){
	extern int currLine, currPos;
	string varbank,vartype, passed_s;
	stringstream ss;
	ss.str("");
	ss<< s ;
	/* cout<<"passed_s: "<<passed_s<<endl; */
	passed_s=ss.str();
	/* cout<<"passed_s: "<<passed_s<<endl; */

	for(unsigned i =0; i<varBank.size();i++) {
		ss.str("");
		ss<<varBank[i];
		varbank=ss.str();
		//cout<<"v: "<<varbank<< "| s: "<< passed_s<<endl; 
		//cout<<endl;
		if(varbank==passed_s) {
			ss.str("");
			ss<<varType[i];
			vartype=ss.str();
			/*for(unsigned x=0;x<varBank.size();x++) {
				cout<<"varBank["<<x<<"]="<<varBank[x]<<endl;
			}
			for(unsigned x=0;x<varType.size();x++) {
				cout<<"varType["<<x<<"]="<<varType[x]<<endl;
			}
			*/
			if(vartype=="INTEGER") return true;
			else {
				printf("checkIntVar Error");
				return false;
			}
		}
	}
	printf("checkIntVar/Semantic error - Not exist error at line %s column %s",currLine,currPos);
	return false;
}

bool checkArrVar(string s){
	extern int currLine, currPos;
	string varbank,vartype, passed_s;
	stringstream ss;
	ss.str("");
	ss<< s ;
	passed_s=ss.str();

	for(unsigned i =0; i<varBank.size();i++) {
		ss.str("");
		ss<<varBank[i];
		varbank=ss.str();
		

		if(varbank==passed_s) {
			ss.str("");
			ss<<varType[i];
			vartype=ss.str();
			/*for(unsigned x=0;x<varBank.size();x++) {
				cout<<"varBank["<<x<<"]="<<varBank[x]<<endl;
			}
			for(unsigned x=0;x<varType.size();x++) {
				cout<<"varType["<<x<<"]="<<varType[x]<<endl;
			} */
			if(vartype=="INTEGER") {
				printf("checkArrVar Error");
				return false;
			}
			else return true;
		}
	}
	printf("checkArrVar/Semantic error - Not exist error at line %s column %s",currLine,currPos);
	return false;
}

bool checkFunction(string s) {
	extern int currLine, currPos;
	string funcbank, passed_s;
	stringstream ss;
	ss.str("");
	ss<< s ;
	passed_s=ss.str();
	for(unsigned i =0; i<functionBank.size();i++) {
		ss.str("");
		ss<<functionBank[i];
		funcbank=ss.str();
		if(funcbank==passed_s) return true;
	}
	printf("checkFunction/Semantic error - Not exist error at line %s column %s",currLine,currPos);
	return false;
}

int main(int a, char **b)
{
	if ((a > 1) && (freopen(b[1], "r", stdin) == NULL))
	{
		cerr << b[0] << ", file " << b[1] << " can't be open"<<endl;
		exit( 1 );
	}

	yyparse();
	return 0;
}
