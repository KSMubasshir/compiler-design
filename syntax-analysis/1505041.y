%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include "1505041_symbolTable.h"

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
FILE* fp;
FILE* logF;
FILE* errF;

SymbolTable symTable;
int idArguments,n;
extern int line_count;
extern int error_count;
vector<string> arguments;
vector<symbolInfo> parameters; 
string typeOfVariable;
char* printedTable;
void myPrint(string codeSegment){
	n = codeSegment.length();
	printedTable=new char[n+1]; 
	strcpy(printedTable, codeSegment.c_str());
	fprintf(logF,"%s\n",printedTable);
}
char* converter(string codeSegment){
	n = codeSegment.length();
	printedTable=new char[n+1]; 
	strcpy(printedTable, codeSegment.c_str());
	return printedTable;
}



void yyerror(const char *s)
{
	printf("%d: %s\n\n", line_count, s);
}

%}

%union{
symbolInfo* sVal;
}


%token IF ELSE FOR WHILE DO BREAK CONTINUE INT FLOAT CHAR DOUBLE VOID RETURN SWITCH CASE DEFAULT INCOP DECOP ASSIGNOP LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD SEMICOLON COMMA STRING NOT COMMENT PRINTLN

%token <sVal>ID  
%token <sVal>ADDOP
%token <sVal>MULOP
%token <sVal>RELOP
%token <sVal>BITOP
%token <sVal>LOGICOP
%token <sVal>CONST_INT
%token <sVal>CONST_CHAR 
%token <sVal>CONST_FLOAT 


%type <sVal>type_specifier expression logic_expression rel_expression simple_expression term unary_expression factor variable parameter_list statement statements compound_statement start program unit var_declaration func_declaration func_definition declaration_list expression_statement argument_list arguments



%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%error-verbose


%%




start : program
	{
		fprintf(logF,"At line no: %d  start : program\n\n",line_count);
		$$->code=$1->code;
		myPrint($$->code);
		fprintf(logF,"%s\n",symTable.PrintAll());
	}
	;



program : program unit 
	{
		fprintf(logF,"At line no: %d  program : program unit\n\n",line_count);
		$$->code=$1->code+"\n"+$2->code;
		myPrint($$->code);
	}
	| unit
	{
		fprintf(logF,"At line no: %d  program : unit\n\n",line_count);
		$$->code=$1->code;
		myPrint($$->code);
	}
	;


	
unit : var_declaration
	{
		fprintf(logF,"At line no: %d  unit : var_declaration\n\n",line_count);
		$$->code=$1->code;
		myPrint($$->code);
	}
     | func_declaration
	{
		fprintf(logF,"At line no: %d  unit : func_declaration\n\n",line_count);
		$$->code=$1->code;
		myPrint($$->code);
	}
     | func_definition
	{
		fprintf(logF,"At line no: %d  unit : func_definition\n\n",line_count);
		$$->code=$1->code;
		myPrint($$->code);
	}
     ;
   


  
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		fprintf(logF,"At line no: %d func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n",line_count);
		$$->code="\n"+$1->code+" "+$2->getName()+"("+$4->code+");\n";
		myPrint($$->code);
		symbolInfo *temp = symTable.LookUp($2->getName(), "FUNC");
		if(temp != NULL){
			fprintf(errF,"Error at line %d:  Function %s already declared\n\n",line_count,converter($2->getName()));
			error_count++;
		}
		else{
			temp = new symbolInfo($2->getName(), "ID");				
			temp->setTypeOfId("FUNC");
			temp->setFuncRet($1->getTypeOfVar());
			for(int i = 0; i<arguments.size(); i++){
				temp->listOfParameters.push_back(arguments[i]);					
			}
			arguments.clear();
			symTable.InsertSymbol(temp);
		}
		
	}
		| type_specifier ID LPAREN RPAREN SEMICOLON
	
	{
		fprintf(logF,"At line no: %d func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n",line_count);
		$$->code="\n"+$1->code+" "+$2->getName()+"();\n";
		myPrint($$->code);
		symbolInfo *temp = symTable.LookUp($2->getName(), "FUNC");
		if(temp != NULL){
			fprintf(errF,"Error at line %d:  Function %s already declared\n\n",line_count,converter($2->getName()));
			error_count++;
		}
		else{
			temp = new symbolInfo($2->getName(), "ID");				
			temp->setTypeOfId("FUNC");
			temp->setFuncRet($1->getTypeOfVar());
			symTable.InsertSymbol(temp);
		}
		
	}
		| type_specifier ID LPAREN RPAREN error
	{
		fprintf(errF,"Error at line %d: ; missing\n\n",line_count);
		error_count++;
	}
		;
	



	 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
		{
			fprintf(logF,"At line no: %d func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n",line_count);
			
			symbolInfo *temp=symTable.LookUp($2->getName(), "FUNC");
			$$->code=$1->code+" "+$2->getName()+"("+$4->code+")"+$6->code+"\n";
			myPrint($$->code);
			if(arguments.size() != idArguments){
				fprintf(errF,"Error at line %d Parameter mismatch for Function %s\n\n",line_count,converter($2->getName()));
				arguments.clear();
				idArguments = 0;
				error_count++;
			}												
			if(temp != NULL){
				if(temp->getFuncIsDefined()== true){
					fprintf(errF,"Error at line %d Function %s already defined\n\n",line_count,converter($2->getName()));
					error_count++;
					arguments.clear();
					idArguments = 0;
				}
				else if(temp->getFuncRet() != $1->getTypeOfVar()){
					fprintf(errF,"Error at line %d Function %s: return type doesn't match declaration\n\n",line_count,converter($2->getName()));
					error_count++;
					arguments.clear();
					idArguments = 0; 
				} 
				else if(temp->listOfParameters.size() != arguments.size()){
					fprintf(errF,"Error at line %d Function %s:Parameter list doesn not match declaration\n\n",line_count,converter($2->getName()));
					arguments.clear();
					idArguments = 0;
					error_count++;					
				}
				else{
					for(int i = 0; i<temp->listOfParameters.size(); i++){
						if(temp->listOfParameters[i] != arguments[i]){
							fprintf(errF,"Error at line %d Function %s:argument mismatch\n\n",line_count,converter($2->getName()));
							arguments.clear();
							idArguments = 0;
							error_count++;	
						}
					}				
				}
			}
			else{
				symbolInfo* temp = new symbolInfo($2->getName(), "ID");
				temp->setTypeOfId("FUNC");
				temp->setFuncRet($1->getTypeOfVar());
				symTable.InsertSymbol(temp);
				for(int i = 0; i<arguments.size(); i++){
					temp->listOfParameters.push_back(arguments[i]);					
				}
				temp->setFuncIsDefined();
			}
			arguments.clear();
			idArguments = 0;
			
		}
		| type_specifier ID LPAREN RPAREN compound_statement
		{
			fprintf(logF,"At line no: %d func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n",line_count);
			$$->code=$1->code+" "+$2->getName()+"()"+$5->code+"\n";
			myPrint($$->code);
			symbolInfo *temp=symTable.LookUp($2->getName(), "FUNC");
			if(arguments.size() != idArguments){
				fprintf(errF,"Error at line %d Parameter mismatch for Function %s\n\n",line_count,converter($2->getName()));
				arguments.clear();
				idArguments = 0;
				error_count++;
			}												
			if(temp != NULL){
				if(temp->getFuncIsDefined()== true){
					fprintf(errF,"Error at line %d Function %s already defined\n\n",line_count,converter($2->getName()));
					error_count++;
					arguments.clear();
					idArguments = 0;
				}
				else if(temp->getFuncRet() != $1->getTypeOfVar()){
					fprintf(errF,"Error at line %d Function %s: return type doesn't match declaration\n\n",line_count,converter($2->getName()));
					error_count++;
					arguments.clear();
					idArguments = 0; 
				} 
				else if(temp->listOfParameters.size() != arguments.size()){
					fprintf(errF,"Error at line %d Function %s:Parameter list doesn not match declaration\n\n",line_count,converter($2->getName()));
					arguments.clear();
					idArguments = 0;
					error_count++;					
				}
				else{
					for(int i = 0; i<temp->listOfParameters.size(); i++){
						if(temp->listOfParameters[i] != arguments[i]){
							fprintf(errF,"Error at line %d Function %s:argument mismatch\n\n",line_count,converter($2->getName()));
							arguments.clear();
							idArguments = 0;
							error_count++;	
						}
					}				
				}
			}
			else{
				symbolInfo* temp = new symbolInfo($2->getName(), "ID");
				temp->setTypeOfId("FUNC");
				temp->setFuncRet($1->getTypeOfVar());
				symTable.InsertSymbol(temp);
				for(int i = 0; i<arguments.size(); i++){
					temp->listOfParameters.push_back(arguments[i]);					
				}
				temp->setFuncIsDefined();
			}
			arguments.clear();
			idArguments = 0;
			
		}
 		;				





parameter_list  : parameter_list COMMA type_specifier ID
		{
			fprintf(logF,"At line no: %d parameter_list  : parameter_list COMMA type_specifier ID\n\n",line_count);
			$$->code=$1->code+","+$3->code+" "+$4->getName();
			myPrint($$->code);
			arguments.push_back(typeOfVariable);
			idArguments++;
			$4->setTypeOfId("VAR");
			$4->setTypeOfVar(typeOfVariable);
			symbolInfo* temp = new symbolInfo($4->getName(), $4->getType());
			temp->setTypeOfId("VAR");		
			parameters.push_back(*temp);
		}
		| parameter_list COMMA type_specifier
		{
			fprintf(logF,"At line no: %d parameter_list  : parameter_list COMMA type_specifier\n\n",line_count);
			$$->code=$1->code+","+$3->code;
			myPrint($$->code);
			arguments.push_back($3->getTypeOfVar());
		}
 		| type_specifier ID
		{
			fprintf(logF,"At line no: %d parameter_list : type_specifier ID\n\n",line_count);
			$$->code=$1->code+" "+$2->getName();
			myPrint($$->code);
			arguments.push_back(typeOfVariable);
			idArguments++;
			$2->setTypeOfId("VAR");
			$2->setTypeOfVar(typeOfVariable);
			parameters.push_back(*$2);
		}
		| type_specifier
		{
			fprintf(logF,"At line no: %d parameter_list : type_specifier\n\n",line_count);
			$$->code=$1->code;
			myPrint($$->code);
			arguments.push_back(typeOfVariable);
		}
 		;

 



		
compound_statement : LCURL 
		{
			symTable.EnterScope(); 
			for(int i = 0; i<parameters.size(); i++) 
				symTable.InsertSymbol(&parameters[i]);
			parameters.clear();
		} statements
		{
			
		}RCURL
		{
			fprintf(logF,"At line no: %d compound_statement : LCURL statements RCURL \n\n",line_count);
			$$->code="{\n\t"+$3->code+"\n";
			$$->code+="}";
			myPrint($$->code);
			fprintf(logF,"%s\n",symTable.PrintAll());
			fprintf(logF,"%s\n",symTable.ExitScope());
		}
 		    | LCURL RCURL
		{
			$$->code="{\n}";
			myPrint($$->code);
			fprintf(logF,"At line no: %d compound_statement : LCURL RCURL \n\n",line_count);
		}
 		    ;
 




		    
var_declaration : type_specifier declaration_list SEMICOLON
		{	
			fprintf(logF,"At line no: %d var_declaration : type_specifier declaration_list SEMICOLON\n\n",line_count);
			$$->code=$1->code+" "+$2->code+";";
			myPrint($$->code);
		}
		|type_specifier declaration_list error
		{
			fprintf(errF,"Error at line %d: ; missing\n\n",line_count);
			error_count++;
		} 		 		
 		;
 		 





type_specifier	:  	INT
			{
				fprintf(logF,"At line no: %d type_specifier : INT\n\n",line_count);
				symbolInfo* s= new symbolInfo("INT");
				typeOfVariable="INT";
				$$ = s;
				$$->code="int";
				myPrint($$->code);
			}
			| FLOAT
			{	
				fprintf(logF,"At line no: %d type_specifier : FLOAT\n\n",line_count);
				symbolInfo* s= new symbolInfo("FLOAT");
				typeOfVariable="FLOAT";
				$$ = s;
				$$->code="float";
				myPrint($$->code);
			}
			| VOID
			{
				fprintf(logF,"At line no: %d type_specifier : VOID\n\n",line_count);
				symbolInfo* s= new symbolInfo("VOID");
				typeOfVariable="VOID";
				$$ = s;
				$$->code="void";
				myPrint($$->code);
			}
			;
 	





	
declaration_list : declaration_list COMMA ID
			{
				fprintf(logF,"At line no: %d declaration_list : declaration_list COMMA ID\n\n",line_count);
				$$->code=$1->code+","+$3->getName();
				myPrint($$->code);
				if(typeOfVariable == "VOID"){
					fprintf(errF,"Error at line %d:variable type can't be void\n\n",line_count);
					error_count++;
				}
				else{
					symbolInfo* temp= symTable.LookUp($3->getName(), "VAR");
					if(temp != NULL){
						fprintf(errF,"Error at line  %d :Multiple declaration of variable %s\n\n",line_count,converter($3->getName()));	
						error_count++;	
					}
					else{
						symbolInfo* temp2 = new symbolInfo($3->getName(), "ID");
						temp2->setTypeOfVar(typeOfVariable);
						temp2->setTypeOfId("VAR");
						symTable.InsertSymbol(temp2);
					}
				}
			}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
			{ 
				fprintf(logF,"At line no: %d declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n",line_count);
				$$->code=$1->code+","+$3->getName()+"["+$5->getName()+"]";
				myPrint($$->code);
				if(typeOfVariable == "VOID"){
					fprintf(errF,"Error at line %d:variable type can't be void\n\n",line_count);
					error_count++;
				}
				else{
					symbolInfo* temp = symTable.LookUp($3->getName(), "ARRAY");
					if(temp!= NULL){
						fprintf(errF,"Error at line  %d :Multiple declaration of variable %s\n\n",line_count,converter($3->getName()));	
						error_count++;			
					}
					else{
						symbolInfo* temp2 = new symbolInfo($3->getName(), "ID");
						temp2->setTypeOfVar(typeOfVariable);
						temp2->setTypeOfId("ARRAY");
						symTable.InsertSymbol(temp2);						
					}
				}
			}
 		  | ID
			{
				fprintf(logF,"At line no: %d declaration_list : ID\n\n",line_count);
				$$->code=$1->getName();
				myPrint($$->code);
				if(typeOfVariable == "VOID"){
					fprintf(errF,"Error at line %d:variable type can't be void\n\n",line_count);
					error_count++;				}
				else{
					symbolInfo* temp= symTable.LookUp($1->getName(), "VAR");
					if(temp!= NULL){
						fprintf(errF,"Error at line  %d :Multiple declaration of variable %s\n\n",line_count,converter($1->getName()));	
						error_count++;		
					}
					else{
						symbolInfo* temp2 = new symbolInfo($1->getName(), "ID");
						temp2->setTypeOfVar(typeOfVariable);
						temp2->setTypeOfId("VAR");
						symTable.InsertSymbol(temp2);		
					}
				}
			}
 		  | ID LTHIRD CONST_INT RTHIRD
			{
				fprintf(logF,"At line no: %d declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n",line_count);
				$$->code=$1->getName()+"["+$3->getName()+"]";
				myPrint($$->code);
				if(typeOfVariable == "VOID"){
					fprintf(errF,"Error at line %d:variable type can't be void\n\n",line_count);
					error_count++;				
				}
				else{
					symbolInfo* temp = symTable.LookUp($1->getName(), "ARRAY");
					if(temp!= NULL){
						fprintf(errF,"Error at line  %d :Multiple declaration of variable %s\n\n",line_count,converter($1->getName()));	
						error_count++;		
					}
					else{
						symbolInfo* temp2 = new symbolInfo($1->getName(), "ID");
						temp2->setTypeOfVar(typeOfVariable);
						temp2->setTypeOfId("ARRAY");
						symTable.InsertSymbol(temp2);
					}
				}
			}
 		  ;
 		  



statements : statement
		{
			fprintf(logF,"At line no: %d statements : statement\n\n",line_count);
			$$->code=$1->code;
			myPrint($$->code);
		}
	   | statements statement
		{
			fprintf(logF,"At line no: %d statements : statements statement\n\n",line_count);
			$$->code=$1->code+"\n\t"+$2->code;
			myPrint($$->code);
		}
	   ;






	   
statement : var_declaration
		{
			fprintf(logF,"At line no: %d statement : var_declaration\n\n",line_count);
			$$->code=$1->code;
			myPrint($$->code);
		}
	  | expression_statement
		{
			fprintf(logF,"At line no: %d statement : expression_statement\n\n",line_count);
			$$->code=$1->code;
			myPrint($$->code);
		}
	  | compound_statement
		{
			fprintf(logF,"At line no: %d statement : compound_statement\n\n",line_count);
			$$->code=$1->code;
			myPrint($$->code);
		}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
		{
			fprintf(logF,"At line no: %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n",line_count);
			$$->code="for("+$3->code+" "+$4->code+" "+$5->code+")"+$7->code;
			myPrint($$->code);
		}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
		{
			fprintf(logF,"At line no: %d statement : IF LPAREN expression RPAREN statement\n\n",line_count);
			$$->code="if("+$3->code+")"+$5->code;
			myPrint($$->code);
		}
	  | IF LPAREN expression RPAREN statement ELSE statement
		{
			fprintf(logF,"At line no: %d statement : IF LPAREN expression RPAREN statement ELSE statement\n\n",line_count);
			$$->code="if("+$3->code+")"+$5->code+"\nelse"+$7->code;
			myPrint($$->code);
		}
	  | WHILE LPAREN expression RPAREN statement
		{
			fprintf(logF,"At line no: %d statement : WHILE LPAREN expression RPAREN statement\n\n",line_count);
			$$->code="while("+$3->code+")"+$5->code;
			myPrint($$->code);
		}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
		{
			fprintf(logF,"At line no: %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n",line_count);
			$$->code="println("+$3->code+");";
			myPrint($$->code);
		}
	  | PRINTLN LPAREN ID RPAREN error
		{
			fprintf(errF,"Error at line %d: ; missing\n\n",line_count);
			error_count++;
		} 
	  | RETURN expression SEMICOLON
		{
			fprintf(logF,"At line no: %d statement : RETURN expression SEMICOLON\n\n",line_count);
			$$->code="return "+$2->code+";";
			myPrint($$->code);
		}
	  |RETURN expression error
		{
			fprintf(errF,"Error at line %d: ; missing\n\n",line_count);
			error_count++;
		} 
	  ;
	  




expression_statement 	: SEMICOLON
		{
			fprintf(logF,"At line no: %d expression_statement : SEMICOLON\n\n",line_count);
			$$->code=";";
			myPrint($$->code);
		}			
			| expression SEMICOLON 
		{
			fprintf(logF,"At line no: %d expression_statement : expression SEMICOLON\n\n",line_count);
			$$->code=$1->code+";";
			myPrint($$->code);
		}
			|expression error
		{
			fprintf(errF,"Error at line %d: ; missing\n\n",line_count);
			error_count++;
		} 
			;




	  
variable : ID 
		{	
			fprintf(logF,"At line no: %d variable : ID \n\n",line_count);
			symbolInfo* temp = symTable.LookUp($1->getName(),"VAR");
			symbolInfo* temp1 = symTable.LookUp($1->getName(),"ARRAY");
			if(temp == NULL){
				fprintf(errF,"Error at line %d : Undeclared variable %s\n\n",line_count,converter($1->getName()));				
				error_count++;
			}
			else{
				if(temp1!=NULL){
					fprintf(errF,"Error at line %d : Array %s used without indexing\n\n",line_count,converter($1->getName()));				
					error_count++;
				}
				else $$ = temp;
			}
			$$->code=$1->getName();
			myPrint($$->code);
		}		
	 | ID LTHIRD expression RTHIRD 
		{	
			fprintf(logF,"At line no: %d variable : ID LTHIRD expression RTHIRD\n\n",line_count);
			symbolInfo* temp = symTable.LookUp($1->getName(),"ARRAY");
			symbolInfo* temp1 = symTable.LookUp($1->getName(),"VAR");
			symbolInfo* temp2 = symTable.LookUp($1->getName(),"FUNC");
			if(temp == NULL){
				if(temp1==NULL&&temp2==NULL){
					fprintf(errF,"Error at line %d : Undeclared array %s\n\n",line_count,converter($1->getName()));				
					error_count++;
				}
				else{
					fprintf(errF,"Error at line %d : Non array type %s indexed\n\n",line_count,converter($1->getName()));				
					error_count++;
				}
								
			}
			else{
				if($3->getTypeOfVar()!="INT"){
					fprintf(errF,"Error at line %d : Non-integer Array Index\n\n",line_count);
					error_count++;
				}
				else{
					$$ = temp;
				}
			}	
			$$->code=$1->getName()+"["+$3->code+"]";
			myPrint($$->code);		
		} 
		
	 ;



	 
expression : logic_expression
		{	
			fprintf(logF,"At line no: %d expression : logic_expression\n\n",line_count);
			$$ = $1;
			$$->code=$1->code;
			myPrint($$->code);
		}	
	   | variable ASSIGNOP logic_expression 
		{
			fprintf(logF,"At line no: %d expression : variable ASSIGNOP logic_expression\n\n",line_count);
			string typeOfVar = $1->getTypeOfVar();
			if($1->getTypeOfVar()=="INT"&&$3->getTypeOfVar()=="FLOAT"){
				fprintf(errF,"Warning at line no: %d Assigning floating point number in integer type variable\n\n",line_count);
			}
			else if($1->getTypeOfVar()!=$3->getTypeOfVar()){
				fprintf(errF,"Error at line no: %d Type Mismatch\n\n",line_count);
				error_count++;
			}
			$$ = $1;
			$$->code=$1->code+"="+$3->code;
			myPrint($$->code);
		}	
	   ;
			
logic_expression : rel_expression 
		{	
			fprintf(logF,"At line no: %d logic_expression : rel_expression\n\n",line_count);
			$$ = $1; 
			$$->code=$1->code;
			myPrint($$->code);
		}	
		 | rel_expression LOGICOP rel_expression
		{	
			fprintf(logF,"At line no: %d logic_expression : rel_expression LOGICOP rel_expression\n\n",line_count);
			symbolInfo* temp = new symbolInfo("INT");
			$$ = temp;
			$$->code=$1->code+" "+$2->getName()+" "+$3->code;
			myPrint($$->code);		
		}	
		 ;
			
rel_expression	: simple_expression 
		{
			fprintf(logF,"At line no: %d rel_expression : simple_expression \n\n",line_count);
			$$ = $1;
			$$->code=$1->code;
			myPrint($$->code);
		}
		| simple_expression RELOP simple_expression	
		{
			fprintf(logF,"At line no: %d rel_expression : simple_expression RELOP simple_expression\n\n",line_count);
			symbolInfo* temp = new symbolInfo("INT");
			string relop = $2->getName();
			string type1 = $1->getTypeOfVar();
			string type2 = $3->getTypeOfVar();
			if(relop == "=="){
				if(type1 != type2){
					fprintf(errF,"At line %d: Type mismatch for == operand\n\n",line_count);			
				}
			}
			else if(relop == "!="){
				if(type1 != type2){
					fprintf(errF,"At line %d: Type mismatch for != operand\n\n",line_count);					
				}
			}
			else if(relop == "<=" || relop == "<"){
			}
			else if(relop == ">=" || relop == ">"){
			}
			$$ = temp;
			$$->code=$1->code+" "+$2->getName()+" "+$3->code;
			myPrint($$->code);	
		}
		;
				
simple_expression : term 
		{
			fprintf(logF,"At line no: %d simple_expression : term \n\n",line_count);
			$$ = $1;
			$$->code=$1->code;
			myPrint($$->code);
		}
		  | simple_expression ADDOP term
	{       
			fprintf(logF,"At line no: %d simple_expression : simple_expression ADDOP term \n\n",line_count);
			if($1->getTypeOfId() == "VAR"){
				if($3->getTypeOfId() == "VAR"){						
					if($1->getTypeOfVar() == "FLOAT"){
						symbolInfo* temp = new symbolInfo("FLOAT");
						$$ = temp;
					}
					else if($3->getTypeOfVar() == "FLOAT"){
						symbolInfo* temp = new symbolInfo("FLOAT");
						$$ = temp;
					}
					else if($3->getTypeOfVar() == "INT" && $1->getTypeOfVar() == "INT"){
						symbolInfo* temp = new symbolInfo("INT");
						$$ = temp;
					}
				}
				else if($3->getTypeOfId() == "ARRAY"){						
					if($1->getTypeOfVar() == "FLOAT"){
						symbolInfo* temp = new symbolInfo("FLOAT");
						$$ = temp;
					}
					else if($3->getTypeOfVar() == "FLOAT"){
						symbolInfo* temp = new symbolInfo("FLOAT");
						$$ = temp;
					}
					else if($3->getTypeOfVar() == "INT" && $1->getTypeOfVar() == "INT"){
						symbolInfo* temp = new symbolInfo("INT");
						$$ = temp;
					}
				}
			}
			else if($1->getTypeOfId() == "ARRAY"){
				if($3->getTypeOfId() == "VAR"){						
					if($1->getTypeOfVar() == "FLOAT"){
						symbolInfo* temp = new symbolInfo("FLOAT");
						$$ = temp;
					}
					else if($3->getTypeOfVar() == "FLOAT"){
						symbolInfo* temp = new symbolInfo("FLOAT");
						$$ = temp;
					}
					else if($3->getTypeOfVar() == "INT" && $1->getTypeOfVar() == "INT"){
						symbolInfo* temp = new symbolInfo("INT");
						$$ = temp;
					}
				}
				else if($3->getTypeOfId() == "ARRAY"){						
					if($1->getTypeOfVar() == "FLOAT"){
						symbolInfo* temp = new symbolInfo("FLOAT");
						$$ = temp;
					}
					else if($3->getTypeOfVar() == "FLOAT"){
						symbolInfo* temp = new symbolInfo("FLOAT");
						$$ = temp;
					}
					else if($3->getTypeOfVar() == "INT" && $1->getTypeOfVar() == "INT"){
						symbolInfo* temp = new symbolInfo("INT");
						$$ = temp;
					}
				}
			}
			$$->code=$1->code+$2->getName()+$3->code;
			myPrint($$->code);
		} 
		;	


		
term :	unary_expression
		{
			fprintf(logF,"At line no: %d term : unary_expression \n\n",line_count);
			$$ = $1;
			$$->code=$1->code;
			myPrint($$->code);
		}
     |  term MULOP unary_expression
		{
			fprintf(logF,"At line no: %d term : term MULOP unary_expression \n\n",line_count);
			string mulop = $2->getName();
			if(mulop == "*")
			{
				if($1->getTypeOfId() == "VAR"){	
					if($3->getTypeOfId() == "VAR"){		
						if($1->getTypeOfVar() == "FLOAT"){
							symbolInfo* temp = new symbolInfo("FLOAT");
							$$ = temp;
						}
						else if($3->getTypeOfVar() == "FLOAT"){
							symbolInfo* temp = new symbolInfo("FLOAT");
							$$ = temp;
						}
						else if($3->getTypeOfVar() == "INT" && $1->getTypeOfVar() == "INT"){
							symbolInfo* temp = new symbolInfo("INT");
							$$ = temp;
						}
					}
					else if($3->getTypeOfId() == "ARRAY"){		
						if($1->getTypeOfVar() == "FLOAT"){
							symbolInfo* temp = new symbolInfo("FLOAT");
							$$ = temp;
						}
						else if($3->getTypeOfVar() == "FLOAT"){
							symbolInfo* temp = new symbolInfo("FLOAT");
							$$ = temp;
						}
						else if($3->getTypeOfVar() == "INT" && $1->getTypeOfVar() == "INT"){
							symbolInfo* temp = new symbolInfo("INT");
							$$ = temp;
						}
					}
				}
				else if($1->getTypeOfId() == "ARRAY"){	
					if($3->getTypeOfId() == "VAR"){		
						if($1->getTypeOfVar() == "FLOAT"){
							symbolInfo* temp = new symbolInfo("FLOAT");
							$$ = temp;
						}
						else if($3->getTypeOfVar() == "FLOAT"){
							symbolInfo* temp = new symbolInfo("FLOAT");
							$$ = temp;
						}
						else if($3->getTypeOfVar() == "INT" && $1->getTypeOfVar() == "INT"){
							symbolInfo* temp = new symbolInfo("INT");
							$$ = temp;
						}
					}
					else if($3->getTypeOfId() == "ARRAY"){		
						if($1->getTypeOfVar() == "FLOAT"){
							symbolInfo* temp = new symbolInfo("FLOAT");
							$$ = temp;
						}
						else if($3->getTypeOfVar() == "FLOAT"){
							symbolInfo* temp = new symbolInfo("FLOAT");
							$$ = temp;
						}
						else if($3->getTypeOfVar() == "INT" && $1->getTypeOfVar() == "INT"){
							symbolInfo* temp = new symbolInfo("INT");
							$$ = temp;
						}
					}
				}
			}
			
			else if(mulop == "/")
			{
				if($1->getTypeOfVar() == "FLOAT"){
					symbolInfo* temp = new symbolInfo("FLOAT");
					$$ = temp;
				}
				else if($3->getTypeOfVar() == "FLOAT"){
					symbolInfo* temp = new symbolInfo("FLOAT");				
					$$ = temp;
				}
				else if($3->getTypeOfVar() == "INT" && $1->getTypeOfVar() == "INT"){
					symbolInfo* temp = new symbolInfo("INT");
					$$ = temp;
				}
			}
			
			else if(mulop == "%"){
				symbolInfo* temp = new symbolInfo("INT");
				temp->setTypeOfId("VAR");
				if(!($1->getTypeOfVar() == "INT" && $3->getTypeOfVar() == "INT")){
					fprintf(errF,"Error at line %d : Integer operand on modulus operator\n\n",line_count);
					error_count++;
				}
				$$ = temp;
			}
			$$->code=$1->code+mulop+$3->code;
			myPrint($$->code);
		}
     ;



unary_expression : ADDOP unary_expression 
			{
				fprintf(logF,"At line no: %d unary_expression : ADDOP unary_expression  \n\n",line_count);
				$$ = $2;
				$$->code=$1->getName()+$2->code;
				myPrint($$->code);
			} 
		 | NOT unary_expression 
			{
				fprintf(logF,"At line no: %d unary_expression : NOT unary_expression  \n\n",line_count);
				symbolInfo* temp = new symbolInfo("INT");
				temp->setTypeOfId("VAR");
				$$=temp;
				$$->code="!"+$2->code;
				myPrint($$->code);
			}
		 | factor 
			{
				fprintf(logF,"At line no: %d unary_expression : factor  \n\n",line_count);
				$$ = $1;
				$$->code=$1->code;
				myPrint($$->code);
			}
		 ;
	
factor	: variable 
	{
		fprintf(logF,"At line no: %d factor : variable \n\n",line_count);
		$$->code=$1->code;
		myPrint($$->code);
	}
	| ID LPAREN argument_list RPAREN
 	{	//todo func
		fprintf(logF,"At line no: %d factor : ID LPAREN argument_list RPAREN\n\n",line_count);
		symbolInfo *temp=new symbolInfo();
		temp = symTable.LookUp($1->getName(), "FUNC");
		if(temp == NULL){
			fprintf(errF,"Error at line %d : Undeclared function %s\n\n",line_count,converter($1->getName()));
		}
		else{
			if(temp->getFuncRet() == "VOID"){
				fprintf(errF,"Error at line %d : Function %s returns void\n\n",line_count,converter($1->getName()));
			} 
			else{ 
				symbolInfo *temp2 = new symbolInfo($1->getFuncRet());
				$$ = temp2;
			}
		}
		$$->code=$1->getName()+"("+$3->code+")";
		myPrint($$->code);
	}
	| LPAREN expression RPAREN
	{	//todo func
		fprintf(logF,"At line no: %d factor : LPAREN expression RPAREN\n\n",line_count);
		$$ = $2;
		$$->code="("+$2->code+")";
		myPrint($$->code);
	}
	| CONST_INT 
	{
		fprintf(logF,"At line no: %d factor : CONST_INT\n\n",line_count);
		$1->setTypeOfVar("INT");			
		$1->setTypeOfId("VAR");
		$$ = $1;
		$$->code=$1->getName();
		myPrint($$->code);
	}
	| CONST_FLOAT
	{
		fprintf(logF,"At line no: %d factor : CONST_FLOAT\n\n",line_count);
		$1->setTypeOfVar("FLOAT");			
		$1->setTypeOfId("VAR");
		$$ = $1;
		$$->code=$1->getName();
		myPrint($$->code);
	}
	| variable INCOP 
	{
		fprintf(logF,"At line no: %d factor : variable INCOP \n\n",line_count);
		$$ = $1;
		$$->code=$1->code+"++";
		myPrint($$->code);
	}
	| variable DECOP
	{
		fprintf(logF,"At line no: %d factor : variable DECOP \n\n",line_count);
		$$ = $1;
		$$->code=$1->code+"--";
		myPrint($$->code);
	}
	;
	
argument_list : arguments
	{
		fprintf(logF,"At line no: %d argument_list : arguments \n\n",line_count);
		$$->code=$1->code;
		myPrint($$->code);
	}
        ;
	
arguments : arguments COMMA logic_expression
	{
		fprintf(logF,"At line no: %d arguments : arguments COMMA logic_expression\n\n",line_count);
		$$->code=$1->code+","+$3->code;
		myPrint($$->code);
	}
	      | logic_expression
	{
		fprintf(logF,"At line no: %d arguments : logic_expression\n\n",line_count);
		$$->code=$1->code;
		myPrint($$->code);
	}
	      ;
 

%%
int main(int argc,char *argv[])
{

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n\n");
		exit(1);
	}

	logF=fopen("1505041_log.txt","w");
	errF=fopen("1505041_error.txt","w");

	yyin=fp;
	yyparse();
	
	fprintf(logF,"Total lines %d\n\n",line_count);
	fprintf(logF,"Total errors %d\n\n",error_count);
	fprintf(errF,"Total errors %d\n\n",error_count);
	fclose(logF);
	fclose(errF);
	
	return 0;
}

