%x STRING
%x COMMENT
%x COMMENT2
%x CHARACTER
%x IFILE

%{
#include "1505041_symbolTable.h"
#include "y.tab.h"

using namespace std;

int line_count=1;
int error_count=0;
extern FILE *logF;

%}

UCN (\\u[0-9a-fA-F]{4}|\\U[0-9a-fA-F]{8})

ILEN ([Uu](L|l|LL|ll)?|(L|l|LL|ll)[Uu]?)
SCMEND [^\\][\n]

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \n
CHAR [ -~]{-}[']

%%

{NEWLINE} {line_count++;}

"if"	{return IF;}
		
"else"	{return ELSE;}

"for"	{return FOR;}

"while"	{return WHILE;}

"do"	{return DO;}

"break"	{return BREAK;}

"int"	{return INT;}

"char"	{return CHAR;}

"float"	{return FLOAT;}

"double" {return DOUBLE;}

"void"	{return VOID;}

"return" {return RETURN;}

"switch" {return SWITCH;}

"case"	{return CASE;}

"default" {return DEFAULT;}

"continue" {return CONTINUE;}

{DIGIT}+ 	{
			symbolInfo *symInfo= new  symbolInfo(string(yytext),"CONST_INT");
			yylval.sVal= symInfo;
			return CONST_INT;
			}

{DIGIT}*\.?{DIGIT}+([eE][-+]?{DIGIT}+)? {			
			symbolInfo *symInfo= new  symbolInfo(string(yytext),"CONST_FLOAT");
			yylval.sVal= symInfo;
			return CONST_FLOAT;
			}

[0-9]*(\.[0-9]+)?(E[+-]?[0-9]*\.[0-9]*) {
			fprintf(logF,"\nError at line %d: Ill formed number %s",line_count,yytext);
			error_count++;
					}

[0-9]*(\.[0-9]+)(\.[0-9\.E+-]*) {
			fprintf(logF,"\nError at line %d: Too many decimal point %s",line_count,yytext);
			error_count++;
				}


"'" 			{  	
				BEGIN CHARACTER; 
			}

<CHARACTER>"'"		{ 	
				BEGIN INITIAL;
			}

<CHARACTER>\\[ntafrbv0\"\\]    {
				char literal=yytext[1];
				char spChar;
				if(literal=='n') spChar = '\n';
				else if(literal=='t') spChar = '\t';
				else if(literal=='v') spChar = '\v';
				else if(literal=='a') spChar = '\a';
				else if(literal=='f') spChar = '\f';
				else if(literal=='r') spChar = '\r';
				else if(literal=='b') spChar = '\b';
				else if(literal=='0') spChar = '\0';
				yytext[0] = spChar;
				yytext[1] = '\0';
				symbolInfo* symInfo =new symbolInfo(string(yytext), "CONST_CHAR");
				yylval.sVal= symInfo;
				return CONST_CHAR;
			}
				

<CHARACTER>([ -~]{-}['\\])	{ 	
			symbolInfo* symInfo =new symbolInfo(string(yytext), "CONST_CHAR");
			yylval.sVal= symInfo;
			return CONST_CHAR;
			}

<CHARACTER>([ -~]{-}['\\])+	{
			fprintf(logF,"\nError at line %d: Multi character constant error '%s'\n",line_count,yytext);
			error_count++;
			}
 /*
('([ -~]{-}['\\]))|('\\')	{
			error_count++;
			}
 */
('([ -~]{-}['])*[^'\n]?)
				{
			fprintf(logF,"\nError at line %d:  Unrecognized character %s\n",line_count,yytext);
			error_count++;
				}


"+"		|

"-"		{
			symbolInfo *symInfo= new  symbolInfo(string(yytext),"ADDOP");
			yylval.sVal= symInfo;
			return ADDOP;
			
		}

"*" | 
"/" |
"%"		{	
			symbolInfo *symInfo= new  symbolInfo(string(yytext),"MULOP");
			yylval.sVal= symInfo;
			return MULOP;
		}
		

"<"   | 
"<="  |
">"   |	
">="  |
"=="  |
"!="		{	
			symbolInfo *symInfo= new  symbolInfo(string(yytext),"RELOP");
			yylval.sVal= symInfo;
			return RELOP;
		}


"=" 		{	
			symbolInfo *symInfo= new  symbolInfo(string(yytext),"ASSIGNOP");
			yylval.sVal= symInfo;
			return ASSIGNOP;
		}


"&&" | 
"||" 		{	
			symbolInfo *symInfo= new  symbolInfo(string(yytext),"LOGICOP");
			yylval.sVal= symInfo;
			return LOGICOP;
		}

"&"   | 
"|"   |
"~"   |
"<<"  |	
">>"  		{	
			symbolInfo *symInfo= new  symbolInfo(string(yytext),"BITOP");
			yylval.sVal= symInfo;
			return BITOP;
		}

"!"  		{	
			symbolInfo *symInfo= new  symbolInfo(string(yytext),"NOT");
			yylval.sVal= symInfo;
			return NOT;
		}

";" 	{return SEMICOLON;}
"," 	{return COMMA;}
"(" 	{return LPAREN;}
")" 	{return RPAREN;}
"{" 	{return LCURL;}
"}" 	{return RCURL;}
"[" 	{return LTHIRD;}
"]" 	{return RTHIRD;}
"++" 	{return INCOP;}
"--" 	{return DECOP;}

([_a-zA-Z]|{UCN})([_a-zA-Z0-9]|{UCN})* {
			symbolInfo *symInfo= new symbolInfo(string(yytext),"ID");
			yylval.sVal= symInfo;		
			return ID;
		}

[0-9]+[a-zA-Z_0-9]+ 	{
			fprintf(logF,"\nError at line %d: Invalid prefix on ID or invalid suffix on Number %s\n",line_count,yytext);
			error_count++;
			}

\"		{ BEGIN STRING;} 

<STRING>\"	{ BEGIN INITIAL;}

<STRING>[^"]*	{
			char literal;
			char spChar;
			for(int i=0;i<yyleng;i++){
				literal=yytext[i];
				if(literal=='\\'){
					literal	=yytext[i+1];
					if(literal=='n')      spChar = '\n';
					else if(literal=='t') spChar = '\t';
					else if(literal=='v') spChar = '\v';
					else if(literal=='a') spChar = '\a';
					else if(literal=='f') spChar = '\f';
					else if(literal=='r') spChar = '\r';
					else if(literal=='b') spChar = '\b';
					else if(literal=='0') spChar = '\0';
					else if(literal=='\n') {spChar = ' ';
							yytext[i+1]=' ';
								}
					yytext[i] = spChar;
					for(int j=i+1;j<yyleng;j++){
						yytext[j]=yytext[j+1];
					}
				}
			}
			symbolInfo *symInfo= new  symbolInfo(string(yytext),"STRING");
			yylval.sVal= symInfo;
			return STRING;
 		}

 /*(\"([^\"\n]|\\[\n])*)
 <STRING><<EOF>> 	{
				error_count++;
			}
*/

"/*" 			{  	
				BEGIN COMMENT; 
			}
<COMMENT>"*/" 		{ 	
				BEGIN INITIAL;
			}
<COMMENT>([^"*"]|"*"[^"/"])+	{ 	
				return COMMENT; 
 			}
 

"//" 			{  	
				BEGIN COMMENT2; 
			}
<COMMENT2>{SCMEND}		{ 	
				BEGIN INITIAL;
		}
 /*
<COMMENT2>[^{SCMEND}]*	{ 	
				return COMMENT;
			}
*/

%%

