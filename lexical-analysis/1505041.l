%option noyywrap

%x STRING
%x COMMENT
%x COMMENT2
%x CHARACTER
%x IFILE


%{
#include<cstdio>
#include<cstdlib>
#include<string>
#include<vector>
#include "1505041_symbolTable.h"

using namespace std;

int line_count=1;
int error_count=0;

FILE *logout;
FILE *tokenout;

SymbolTable symTable;



%}

/* some complex named patterns */
/* Universal Character Name */
UCN (\\u[0-9a-fA-F]{4}|\\U[0-9a-fA-F]{8})
/* float exponent */
EXP ([Ee][-+]?[0-9]+)
/* integer length */
ILEN ([Uu](L|l|LL|ll)?|(L|l|LL|ll)[Uu]?)
SCMEND [^\\][\n]



WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \n
CHAR [ -~]{-}[']
%%
{NEWLINE} {line_count++;}

"if"	{
			fprintf(tokenout,"<IF>");
			fprintf(logout,"\nLine no %d: TOKEN <IF> Lexeme %s found\n",line_count,yytext);
		}
		
"else"	{
			fprintf(tokenout,"<ELSE>");
			fprintf(logout,"\nLine no %d: TOKEN <ELSE> Lexeme %s found\n",line_count,yytext);
		}

"for"	{
			fprintf(tokenout,"<FOR>");
			fprintf(logout,"\nLine no %d: TOKEN <FOR> Lexeme %s found\n",line_count,yytext);
		}


"while"	{
			fprintf(tokenout,"<WHILE>");
			fprintf(logout,"\nLine no %d: TOKEN <WHILE> Lexeme %s found\n",line_count,yytext);
		}

"do"	{
			fprintf(tokenout,"<DO>");
			fprintf(logout,"\nLine no %d: TOKEN <DO> Lexeme %s found\n",line_count,yytext);
		}


"break"	{
			fprintf(tokenout,"<BREAK>");
			fprintf(logout,"\nLine no %d: TOKEN <BREAK> Lexeme %s found\n",line_count,yytext);
		}

"int"	{
			fprintf(tokenout,"<INT>");
			fprintf(logout,"\nLine no %d: TOKEN <INT> Lexeme %s found\n",line_count,yytext);
		}

"char"	{
			fprintf(tokenout,"<CHAR>");
			fprintf(logout,"\nLine no %d: TOKEN <CHAR> Lexeme %s found\n",line_count,yytext);
		}

"float"	{
			fprintf(tokenout,"<FLOAT>");
			fprintf(logout,"\nLine no %d: TOKEN <FLOAT> Lexeme %s found\n",line_count,yytext);
		}

"double"	{
			fprintf(tokenout,"<DOUBLE>");
			fprintf(logout,"\nLine no %d: TOKEN <DOUBLE> Lexeme %s found\n",line_count,yytext);
		}


"void"	{
			fprintf(tokenout,"<VOID>");
			fprintf(logout,"\nLine no %d: TOKEN <VOID> Lexeme %s found\n",line_count,yytext);
		}

"return"	{
			fprintf(tokenout,"<RETURN>");
			fprintf(logout,"\nLine no %d: TOKEN <RETURN> Lexeme %s found\n",line_count,yytext);
		}


"switch"	{
			fprintf(tokenout,"<SWITCH>");
			fprintf(logout,"\nLine no %d: TOKEN <SWITCH> Lexeme %s found\n",line_count,yytext);
		}

"case"	{
			fprintf(tokenout,"<CASE>");
			fprintf(logout,"\nLine no %d: TOKEN <CASE> Lexeme %s found\n",line_count,yytext);
		}

"default"	{
			fprintf(tokenout,"<DEFAULT>");
			fprintf(logout,"\nLine no %d: TOKEN <DEFAULT> Lexeme %s found\n",line_count,yytext);
		}

"continue"	{
			fprintf(tokenout,"<CONTINUE>");
			fprintf(logout,"\nLine no %d: TOKEN <CONTINUE> Lexeme %s found\n",line_count,yytext);
		}




{DIGIT}+ 	{
				fprintf(tokenout,"<CONST_INT,%s>",yytext);
				fprintf(logout,"\nLine no %d: TOKEN <CONST_INT> Lexeme %s found\n",line_count,yytext);
				
				symTable.Insert(string(yytext),"CONST_INT");
				fprintf(logout,"%s",symTable.PrintAll());
			}



{DIGIT}*\.?{DIGIT}+([eE][-+]?{DIGIT}+)? {
				
				fprintf(tokenout,"<CONST_FLOAT,%s>",yytext);
				fprintf(logout,"\nLine no %d: TOKEN <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
				
				symTable.Insert(string(yytext),"CONST_FLOAT");
				fprintf(logout,"%s",symTable.PrintAll());
			
			}

[0-9]*(\.[0-9]+)?(E[+-]?[0-9]*\.[0-9]*) {
					fprintf(logout,"\nError at line %d: Ill formed number %s",line_count,yytext);
					error_count++;
				}
[0-9]*(\.[0-9]+)(\.[0-9\.E+-]*)  {
					fprintf(logout,"\nError at line %d: Too many decimal point %s",line_count,yytext);
					error_count++;
				}


"'" 			{  	
				BEGIN CHARACTER; 
			}
<CHARACTER>"'"	{ 	
				BEGIN INITIAL;
			}

<CHARACTER>\\[ntafrbv0\"\\]    {
				fprintf(logout,"\nLine no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
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
				fprintf(tokenout,"<CONST_CHAR,%s>",yytext);
				symTable.Insert(yytext,"CONST_CHAR");
				fprintf(logout,"%s",symTable.PrintAll());
			}
				

<CHARACTER>([ -~]{-}['\\])	{ 	
				
				fprintf(tokenout,"<CONST_CHAR,%s>",yytext);
				fprintf(logout,"\nLine no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
				
				symTable.Insert(string(yytext),"CONST_CHAR");
				fprintf(logout,"%s",symTable.PrintAll());
			}
<CHARACTER>([ -~]{-}['\\])+	{ 	
				fprintf(logout,"\nError at line %d: Multi character constant error '%s'\n",line_count,yytext);
				error_count++;
			}
 /*
('([ -~]{-}['\\]))|('\\')	{ 	
				fprintf(logout,"\nError at line %d:  Unterminated character %s\n",line_count,yytext);
				error_count++;
			}
 */
('([ -~]{-}['])*[^'\n]?)
				{ 	
				fprintf(logout,"\nError at line %d:  Unrecognized character %s\n",line_count,yytext);
				error_count++;
				}


"+"		|

"-"		{
			fprintf(tokenout,"<ADDOP,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <ADDOP> Lexeme %s found\n",line_count,yytext);
			symTable.Insert(string(yytext),"ADDOP");
			fprintf(logout,"%s",symTable.PrintAll());
			
		}

"*" | 
"/" |
"%"		{	
			fprintf(tokenout,"<MULOP,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <MULOP> Lexeme %s found\n",line_count,yytext);
			symTable.Insert(string(yytext),"MULOP");
			fprintf(logout,"%s",symTable.PrintAll());
		}
		

"++" | 
"--" 		{	
			fprintf(tokenout,"<INCOP,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <INCOP> Lexeme %s found\n",line_count,yytext);
			symTable.Insert(string(yytext),"INCOP");
			fprintf(logout,"%s",symTable.PrintAll());
		}


"<"   | 
"<="  |
">"   |	
">="  |
"=="  |
"!="		{	
			fprintf(tokenout,"<RELOP,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <RELOP> Lexeme %s found\n",line_count,yytext);
			symTable.Insert(string(yytext),"RELOP");
			fprintf(logout,"%s",symTable.PrintAll());
		}


"=" 		{	
			fprintf(tokenout,"<ASSIGNOP,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
			symTable.Insert(string(yytext),"ASSIGNOP");
			fprintf(logout,"%s",symTable.PrintAll());
		}



"&&" | 
"||" 		{	
			fprintf(tokenout,"<LOGICOP,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <LOGICOP> Lexeme %s found\n",line_count,yytext);
			symTable.Insert(string(yytext),"LOGICOP");
			fprintf(logout,"%s",symTable.PrintAll());
		}


"&"   | 
"|"   |
"~"   |
"<<"  |	
">>"  		{	
			fprintf(tokenout,"<BITOP,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <BITOP> Lexeme %s found\n",line_count,yytext);
			symTable.Insert(string(yytext),"BITOP");
			fprintf(logout,"%s",symTable.PrintAll());
		}

"!"  		{	
			fprintf(tokenout,"<NOT,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <NOT> Lexeme %s found\n",line_count,yytext);
			symTable.Insert(string(yytext),"NOT");
			fprintf(logout,"%s",symTable.PrintAll());
		}


"("  		{	
			fprintf(tokenout,"<LPAREN,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <LPAREN> Lexeme %s found\n",line_count,yytext);
			//symTable.Insert(string(yytext),"LPAREN");
			//fprintf(logout,"%s",symTable.PrintAll());
		}

")"  		{	
			fprintf(tokenout,"<RPAREN,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <RPAREN> Lexeme %s found\n",line_count,yytext);
			//symTable.Insert(string(yytext),"RPAREN");
			//fprintf(logout,"%s",symTable.PrintAll());
		}			


"{"  		{	
			fprintf(tokenout,"<LCURL,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <LCURL> Lexeme %s found\n",line_count,yytext);
			//symTable.Insert(string(yytext),"LCURL");
			//fprintf(logout,"%s",symTable.PrintAll());
		}

"}"  		{	
			fprintf(tokenout,"<RCURL,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <RCURL> Lexeme %s found\n",line_count,yytext);
			//symTable.Insert(string(yytext),"RCURL");
			//fprintf(logout,"%s",symTable.PrintAll());
		}


"["  		{	
			fprintf(tokenout,"<LTHIRD,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <LTHIRD> Lexeme %s found\n",line_count,yytext);
			//symTable.Insert(string(yytext),"LTHIRD");
			//fprintf(logout,"%s",symTable.PrintAll());
		}


"]"  		{	
			fprintf(tokenout,"<RTHIRD,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <RTHIRD> Lexeme %s found\n",line_count,yytext);
			//symTable.Insert(string(yytext),"RTHIRD");
			//fprintf(logout,"%s",symTable.PrintAll());
		}



","  		{	
			fprintf(tokenout,"<COMMA,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <COMMA> Lexeme %s found\n",line_count,yytext);
			//symTable.Insert(string(yytext),"COMMA");
			//fprintf(logout,"%s",symTable.PrintAll());
		}


";"  		{	
			fprintf(tokenout,"<SEMICOLON,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <SEMICOLON> Lexeme %s found\n",line_count,yytext);
			//symTable.Insert(string(yytext),"SEMICOLON");
			//fprintf(logout,"%s",symTable.PrintAll());
		}

([_a-zA-Z]|{UCN})([_a-zA-Z0-9]|{UCN})* {
			fprintf(tokenout,"<ID,%s>",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <ID> Lexeme %s found\n",line_count,yytext);
			symTable.Insert(string(yytext),"ID");
			fprintf(logout,"%s",symTable.PrintAll());
		}

[0-9]+[a-zA-Z_0-9]+ 	{
			fprintf(logout,"\nError at line %d: Invalid prefix on ID or invalid suffix on Number %s\n",line_count,yytext);
			error_count++;
			}

\"	{ BEGIN STRING;} 

<STRING>\"	{ BEGIN INITIAL;}

<STRING>[^"]*		{ 	
			fprintf(logout,"\nLine no %d: TOKEN <STRING> Lexeme %s found\n",line_count,yytext);
			//yytext[yyleng-1]='\0';
			//yytext++;
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
			fprintf(tokenout,"<STRING,%s>",yytext);
		 	}


 /*(\"([^\"\n]|\\[\n])*)
 <STRING><<EOF>> 	{ 	
				fprintf(logout,"\nError at line %d:  Unterminated string %s\n",line_count,yytext);
				error_count++;
			}
	*/
 /* comments */
"/*" 			{  	
				BEGIN COMMENT; 
			}
<COMMENT>"*/" 		{ 	
				BEGIN INITIAL;
			}
<COMMENT>([^"*"]|"*"[^"/"])+	{ 	
				fprintf(logout,"\nLine no %d: TOKEN <COMMENT> Lexeme /*%s*/ found\n",line_count,yytext); 
 			}
 

"//" 			{  	
				BEGIN COMMENT2; 
			}
<COMMENT2>{SCMEND}		{ 	
				BEGIN INITIAL;
			}
 /*
<COMMENT2>[^{SCMEND}]*	{ 	
				fprintf(logout,"\nLine no %d: TOKEN <COMMENT>  Lexeme //%s found\n",line_count,yytext);
			}

 */


%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("1505041_log.txt","w");
	tokenout= fopen("1505041_token.txt","w");

	yyin= fin;
	yylex();
	
	fprintf(logout,"Total Lines: %d\n",line_count);
	fprintf(logout,"Total Errors: %d\n",error_count);

	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
}
