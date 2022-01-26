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
SymbolTable symTable;
int idArguments,n;
extern int line_count;
extern int error_count;
vector<string> arguments;
vector<symbolInfo> parameters; 
string typeOfVariable;
char* printedTable;

//added for icg
int labelCount=0;
int tempCount=0;
string ret;
vector<string> vars;
vector<string> arrs;
vector<int> arrsizes;

char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return lb;
}

char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
	return t;
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
		$1->code+="\n\nOUT_DEC PROC  \n\n\tPUSH AX\n\tPUSH BX\n\tPUSH CX\n\tPUSH DX\n\tOR AX,AX\n \tJGE ENDIF\n\tPUSH AX\n\tMOV DL,'-'\n\tMOV AH,2\n\tINT 21H\n\tPOP AX\n\tNEG AX\nENDIF:\n\tXOR CX,CX\n\tMOV BX,10D\nREPEAT:\n\tXOR DX,DX\n\tDIV BX\n\tPUSH DX\n\tINC CX\n\tOR AX,AX\n\tJNE REPEAT\n\tMOV AH,2\nPRINT_LOOP:\n\tPOP DX\n\tOR DL,30H\n\tINT 21H\n\tloop PRINT_LOOP\n\tPOP DX\n\tPOP CX\n\tPOP BX\n\tPOP AX\n\tRET\n\nOUT_DEC ENDP\n";
		ofstream fout;
		fout.open("Code.asm");
		fout << ".MODEL SMALL\n.STACK 100H\n\n.DATA\n" ;
		for(int i = 0; i<vars.size() ; i++){
			fout << vars[i] << " DW ?\n";			
		}

		for(int i = 0 ; i< arrs.size() ; i++){
			fout << arrs[i] << " DW " << arrsizes[i] << " DUP(?)\n";
		}

		fout << "\n.CODE \n"; 
		fout << "MOV AX,@DATA \n";
		fout << "MOV DS,AX \n";
		fout << $1->code;
	}
	;



program : program unit 
	{
		$$ = $1;
		$$->code += $2->code;
	}
	| unit
	;


	
unit : var_declaration

     | func_declaration
	
     | func_definition
     ;
   



func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		symbolInfo *temp = symTable.LookUp($2->getName(), "FUNC");
		if(temp != NULL){
			fprintf(logF,"Error at line %d:  Function %s already declared\n\n",line_count,converter($2->getName()));
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
		symbolInfo *temp = symTable.LookUp($2->getName(), "FUNC");
		if(temp != NULL){
			fprintf(logF,"Error at line %d:  Function %s already declared\n\n",line_count,converter($2->getName()));
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
		fprintf(logF,"Error at line %d: ; missing\n\n",line_count);
		error_count++;
	}
		;
	



	 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
		{	
			symbolInfo *temp=symTable.LookUp($2->getName(), "FUNC");
			if(arguments.size() != idArguments){
				fprintf(logF,"Error at line %d Parameter mismatch for Function %s\n\n",line_count,converter($2->getName()));
				arguments.clear();
				idArguments = 0;
				error_count++;
			}												
			if(temp != NULL){
				if(temp->getFuncIsDefined()== true){
					fprintf(logF,"Error at line %d Function %s already defined\n\n",line_count,converter($2->getName()));
					error_count++;
					arguments.clear();
					idArguments = 0;
				}
				else if(temp->getFuncRet() != $1->getTypeOfVar()){
					fprintf(logF,"Error at line %d Function %s: return type doesn't match declaration\n\n",line_count,converter($2->getName()));
					error_count++;
					arguments.clear();
					idArguments = 0; 
				} 
				else if(temp->listOfParameters.size() != arguments.size()){
					fprintf(logF,"Error at line %d Function %s:Parameter list doesn not match declaration\n\n",line_count,converter($2->getName()));
					arguments.clear();
					idArguments = 0;
					error_count++;					
				}
				else{
					for(int i = 0; i<temp->listOfParameters.size(); i++){
						if(temp->listOfParameters[i] != arguments[i]){
							fprintf(logF,"Error at line %d Function %s:argument mismatch\n\n",line_count,converter($2->getName()));
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

				$$->code = $2->getName() + " PROC  \n\n";
				$$->code += $6->code;
				if($2->getName()!="main"){
					$$->code+=string(ret)+":\n";
				}
				if(arguments.size()!=0){
					$$->code+="\tPOP BP\n";
				}
				if($2->getName()!="main"){
					$$->code+="\tRET ";
				}
		
				int p=arguments.size()*2;
				if(p){
					string Result;       

					ostringstream convert;  
	
					convert << p;    

					Result = convert.str(); 
					$$->code+=Result+"\n";
				}
				$$->code+="\n";
				if($2->getName()=="main"){
					$$->code+="\tMOV AH,4CH\n\tINT 21H\n";
				}
				$$->code += "\n" + $2->getName() + " ENDP\n\n";
				arguments.clear();
				idArguments = 0;
				ret = "";
				arguments.clear();
				idArguments = 0;
			
		}
		| type_specifier ID LPAREN RPAREN compound_statement
		{
			symbolInfo *temp=symTable.LookUp($2->getName(), "FUNC");
			if(arguments.size() != idArguments){
				fprintf(logF,"Error at line %d Parameter mismatch for Function %s\n\n",line_count,converter($2->getName()));
				arguments.clear();
				idArguments = 0;
				error_count++;
			}												
			if(temp != NULL){
				if(temp->getFuncIsDefined()== true){
					fprintf(logF,"Error at line %d Function %s already defined\n\n",line_count,converter($2->getName()));
					error_count++;
					arguments.clear();
					idArguments = 0;
				}
				else if(temp->getFuncRet() != $1->getTypeOfVar()){
					fprintf(logF,"Error at line %d Function %s: return type doesn't match declaration\n\n",line_count,converter($2->getName()));
					error_count++;
					arguments.clear();
					idArguments = 0; 
				} 
				else if(temp->listOfParameters.size() != arguments.size()){
					fprintf(logF,"Error at line %d Function %s:Parameter list doesn not match declaration\n\n",line_count,converter($2->getName()));
					arguments.clear();
					idArguments = 0;
					error_count++;					
				}
				else{
					for(int i = 0; i<temp->listOfParameters.size(); i++){
						if(temp->listOfParameters[i] != arguments[i]){
							fprintf(logF,"Error at line %d Function %s:argument mismatch\n\n",line_count,converter($2->getName()));
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
			$$->code = $2->getName() + " PROC  \n\n";
			$$->code += $5->code;
			//cout<<$5->code<<endl;
			if($2->getName()!="main"){
				$$->code+=string(ret)+":\n";
			}
			if(arguments.size()!=0){
				$$->code+="\tPOP BP\n";
			}
			if($2->getName()!="main"){
				$$->code+="\tRET ";
			}
	
			int p=arguments.size()*2;
			if(p){
				string Result;       

				ostringstream convert;  

				convert << p;    

				Result = convert.str(); 
				$$->code+=Result+"\n";
			}
			$$->code+="\n";
			if($2->getName()=="main"){
				$$->code+="\tMOV AH,4CH\n\tINT 21H\n";
			}
			$$->code += "\n" + $2->getName() + " ENDP\n\n";
			arguments.clear();
			idArguments = 0;
			ret = "";
		}
 		;				





parameter_list  : parameter_list COMMA type_specifier ID
		{
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
			arguments.push_back($3->getTypeOfVar());
		}
 		| type_specifier ID
		{
			arguments.push_back(typeOfVariable);
			idArguments++;
			$2->setTypeOfId("VAR");
			$2->setTypeOfVar(typeOfVariable);
			parameters.push_back(*$2);
		}
		| type_specifier
		{
			arguments.push_back(typeOfVariable);
		}
 		;

 



		
compound_statement : LCURL 
		{
			symTable.EnterScope(); 
			for(int i = 0; i<parameters.size(); i++) 
				symTable.InsertSymbol(&parameters[i]);
			parameters.clear();
		}
		 statements RCURL
		{
			symTable.ExitScope();
			$$=$3;
		}
 		    | LCURL RCURL
		{
		}
 		    ;
 




		    
var_declaration : type_specifier declaration_list SEMICOLON
		{	
		}
		|type_specifier declaration_list error
		{
			fprintf(logF,"Error at line %d: ; missing\n\n",line_count);
			error_count++;
		} 		 		
 		;
 		 





type_specifier	:  	INT
			{
				symbolInfo* s= new symbolInfo("INT");
				typeOfVariable="INT";
				$$ = s;
			}
			| FLOAT
			{	
				symbolInfo* s= new symbolInfo("FLOAT");
				typeOfVariable="FLOAT";
				$$ = s;
			}
			| VOID
			{
				symbolInfo* s= new symbolInfo("VOID");
				typeOfVariable="VOID";
				$$ = s;
			}
			;
 	





	
declaration_list : declaration_list COMMA ID
			{
				if(typeOfVariable == "VOID"){
					fprintf(logF,"Error at line %d:variable type can't be void\n\n",line_count);
					error_count++;
				}
				else{
					symbolInfo* temp= symTable.LookUp($3->getName(), "VAR");
					if(temp != NULL){
						fprintf(logF,"Error at line  %d :Multiple declaration of variable %s\n\n",line_count,converter($3->getName()));	
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
				if(typeOfVariable == "VOID"){
					fprintf(logF,"Error at line %d:variable type can't be void\n\n",line_count);
					error_count++;
				}
				else{
					symbolInfo* temp = symTable.LookUp($3->getName(), "ARRAY");
					if(temp!= NULL){
						fprintf(logF,"Error at line  %d :Multiple declaration of variable %s\n\n",line_count,converter($3->getName()));	
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
				if(typeOfVariable == "VOID"){
					fprintf(logF,"Error at line %d:variable type can't be void\n\n",line_count);
					error_count++;				}
				else{
					symbolInfo* temp;//= symTable.LookUp($1->getName(), "VAR");
					if(temp!= NULL){
						fprintf(logF,"Error at line  %d :Multiple declaration of variable %s\n\n",line_count,converter($1->getName()));	
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
				if(typeOfVariable == "VOID"){
					fprintf(logF,"Error at line %d:variable type can't be void\n\n",line_count);
					error_count++;				
				}
				else{
					symbolInfo* temp = symTable.LookUp($1->getName(), "ARRAY");
					if(temp!= NULL){
						fprintf(logF,"Error at line  %d :Multiple declaration of variable %s\n\n",line_count,converter($1->getName()));	
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
	   | statements statement
		{
			$$=$1;
			$$->code += $2->code;
		}
	   ;






	   
statement : var_declaration
	  | expression_statement
	  | compound_statement
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
		{
			$$=$3;
			char *lbl1 = newLabel();
			char *lbl2 = newLabel();
			$$->code+= string(lbl1) + ":\n";
			$$->code+=$4->code;
			$$->code+="\tMOV AX , "+$4->getName()+"\n";
			$$->code+="\tCMP AX , 0\n";
			$$->code+="\tJE "+string(lbl2)+"\n";
			$$->code+=$7->code;
			$$->code+=$5->code;
			$$->code+="\tJMP "+string(lbl1)+"\n";
			$$->code+=string(lbl2)+":\n";
		}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
		{
			$$=$3;
			char *lbl=newLabel();
			$$->code+="\tMOV AX, "+$3->getName()+"\n";
			$$->code+="\tCMP AX, 0\n";
			$$->code+="\tJE "+string(lbl)+"\n";
			$$->code+=$5->code;
			$$->code+=string(lbl)+":\n";
		}
	  | IF LPAREN expression RPAREN statement ELSE statement
		{
			$$=$3;
			char *lbl1=newLabel();
			char *lbl2=newLabel();
			$$->code+="\tMOV AX,"+$3->getName()+"\n";
			$$->code+="\tCMP AX,0\n";
			$$->code+="\tJE "+string(lbl1)+"\n";
			$$->code+=$5->code;
			$$->code+="\tJMP "+string(lbl2)+"\n";
			$$->code+=string(lbl1)+":\n";
			$$->code+=$7->code;
			$$->code+=string(lbl2)+":\n";
		}
	  | WHILE LPAREN expression RPAREN statement
		{
			char * lbl1 = newLabel();
			char * lbl2 = newLabel();
			$$->code= string(lbl1) + ":\n"; 
			$$->code+=$3->code;
			$$->code+="\tMOV AX , "+$3->getName()+"\n";
			$$->code+="\tCMP AX , 0\n";
			$$->code+="\tJE "+string(lbl2)+"\n";
			$$->code+=$5->code;
			$$->code+="\tJMP "+string(lbl1)+"\n";
			$$->code+=string(lbl2)+":\n";
		}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
		{
			$$->code += "\tMOV AX, " + $3->getName() +"\n";
			$$->code += "\tCALL OUT_DEC\n";
		}
	  | PRINTLN LPAREN ID RPAREN error
		{
			fprintf(logF,"Error at line %d: ; missing\n\n",line_count);
			error_count++;
		} 
	  | RETURN expression SEMICOLON
		{
			$$=$2;
			$$->code+="\tMOV DX,"+$2->getName()+"\n";
			$$->code+="\tJMP   "+string(ret)+"\n";
		}
	  |RETURN expression error
		{
			fprintf(logF,"Error at line %d: ; missing\n\n",line_count);
			error_count++;
		} 
	  ;
	  




expression_statement 	: SEMICOLON
		{
			$$->code="";
			tempCount = 0;
		}			
			| expression SEMICOLON 
		{
			$$=$1;
			tempCount = 0;
		}
			|expression error
		{
			fprintf(logF,"Error at line %d: ; missing\n\n",line_count);
			error_count++;
		} 
			;




	  
variable : ID 
		{	
			symbolInfo* temp = symTable.LookUp($1->getName(),"VAR");
			symbolInfo* temp1 = symTable.LookUp($1->getName(),"ARRAY");
			if(temp == NULL){
				fprintf(logF,"Error at line %d : Undeclared variable %s\n\n",line_count,converter($1->getName()));				
				error_count++;
			}
			else{
				if(temp1!=NULL){
					fprintf(logF,"Error at line %d : Array %s used without indexing\n\n",line_count,converter($1->getName()));				
					error_count++;
				}
				else {
					$$ = temp;
					$$->code="";
					$$->setName($$->getName()+to_string(symTable.getScopeNum()));
					vars.push_back($$->getName());
					$$->setType("notarray");
				}
			}
		}		
	 | ID LTHIRD expression RTHIRD 
		{
			symbolInfo* temp = symTable.LookUp($1->getName(),"ARRAY");
			symbolInfo* temp1= symTable.LookUp($1->getName(),"VAR");
			symbolInfo* temp2 = symTable.LookUp($1->getName(),"FUNC");
			if(temp == NULL){
				if(temp1==NULL&&temp2==NULL){
					fprintf(logF,"Error at line %d : Undeclared array %s\n\n",line_count,converter($1->getName()));				
					error_count++;
				}
				else{
					fprintf(logF,"Error at line %d : Non array type %s indexed\n\n",line_count,converter($1->getName()));				
					error_count++;
				}
								
			}
			else{
				if($3->getTypeOfVar()!="INT"){
					fprintf(logF,"Error at line %d : Non-integer Array Index\n\n",line_count);
					error_count++;
				}
				else{
					$$ = temp;
					$$->setName($$->getName()+to_string(symTable.getScopeNum()));
					//arrs.push_back($$->getName());
					$$->code=$3->code ;
					$$->code += "\tMOV BX, " +$3->getName() +"\n";
					$$->code += "\tADD BX, BX\n";
				}
			}		
		} 
		
	 ;



	 
expression : logic_expression	
	   | variable ASSIGNOP logic_expression 
		{
			string typeOfVar = $1->getTypeOfVar();
			if($1->getTypeOfVar()=="INT"&&$3->getTypeOfVar()=="FLOAT"){
				fprintf(logF,"Warning at line no: %d Assigning floating point number in integer type variable\n\n",line_count);
			}
			else if($1->getTypeOfVar()!=$3->getTypeOfVar()){
				fprintf(logF,"Error at line no: %d Type Mismatch\n\n",line_count);
				error_count++;
			}
			else{
				$$=$1;
				$$->code=$3->code+$1->code;
				$$->code+="\tMOV AX, "+$3->getName()+"\n";
				if($$->getType()=="notarray"){ 
					$$->code+= "\tMOV "+$1->getName()+", AX\n";
				}
				
				else{
					$$->code+= "\tMOV  "+$1->getName()+"[BX], AX\n";
				}
			}
		}	
	   ;
			
logic_expression : rel_expression 
		 | rel_expression LOGICOP rel_expression
		{	
			$$=$1;
			$$->code+=$3->code;
			char * lbl1 = newLabel();
			char * lbl2 = newLabel();
			char * temp = newTemp();
			if($2->getName()=="&&"){
				$$->code += "\tMOV AX , " + $1->getName() +"\n";
				$$->code += "\tCMP AX , 0\n";
		 		$$->code += "\tJE " + string(lbl1) +"\n";
				$$->code += "\tMOV AX , " + $3->getName() +"\n";
				$$->code += "\tCMP AX , 0\n";
				$$->code += "\tJE " + string(lbl1) +"\n";
				$$->code += "\tMOV " + string(temp) + " , 1\n";
				$$->code += "\tJMP " + string(lbl2) + "\n";
				$$->code += string(lbl1) + ":\n" ;
				$$->code += "\tMOV " + string(temp) + ", 0\n";
				$$->code += string(lbl2) + ":\n";
				$$->setName(temp);
				
			}
			else if($2->getName()=="||"){
				$$->code += "\tMOV AX , " + $1->getName() +"\n";
				$$->code += "\tCMP AX , 0\n";
		 		$$->code += "\tJNE " + string(lbl1) +"\n";
				$$->code += "\tMOV AX , " + $3->getName() +"\n";
				$$->code += "\tCMP AX , 0\n";
				$$->code += "\tJNE " + string(lbl1) +"\n";
				$$->code += "\tMOV " + string(temp) + " , 0\n";
				$$->code += "\tJMP " + string(lbl2) + "\n";
				$$->code += string(lbl1) + ":\n" ;
				$$->code += "\tMOV " + string(temp) + ", 1\n";
				$$->code += string(lbl2) + ":\n";
				$$->setName(temp);
				
			}
			
		}	
		 ;
			
rel_expression	: simple_expression
		| simple_expression RELOP simple_expression	
		{
			symbolInfo* Temp = new symbolInfo("INT");
			string relop = $2->getName();
			string type1 = $1->getTypeOfVar();
			string type2 = $3->getTypeOfVar();
			if(relop == "=="){
				if(type1 != type2){
					fprintf(logF,"At line %d: Type mismatch for == operand\n\n",line_count);
					error_count++;			
				}
			}
			else if(relop == "!="){
				if(type1 != type2){
					fprintf(logF,"At line %d: Type mismatch for != operand\n\n",line_count);	
					error_count++;				
				}
			}
			else if(relop == "<=" || relop == "<"){
			}
			else if(relop == ">=" || relop == ">"){
			}
			$$ = $1;
			$$->code+=$3->code;
			$$->code+="\tMOV AX, " + $1->getName()+"\n";
			$$->code+="\tCMP AX, " + $3->getName()+"\n";
			char *temp=newTemp();
			char *lbl1=newLabel();
			char *lbl2=newLabel();
			if($2->getName()=="<"){
				$$->code+="\tJL " + string(lbl1)+"\n";
			}
			else if($2->getName()=="<="){
				$$->code+="\tJLE " + string(lbl1)+"\n";
			}
			else if($2->getName()==">"){
				$$->code+="\tJG " + string(lbl1)+"\n";
			}
			else if($2->getName()==">="){
				$$->code+="\tJGE " + string(lbl1)+"\n";
			}
			else if($2->getName()=="=="){
				$$->code+="\tJE " + string(lbl1)+"\n";
			}
			else if($2->getName()=="!="){
				$$->code+="\tJNE " + string(lbl1)+"\n";
			}
			
			$$->code+="\tMOV "+string(temp) +", 0\n";
			$$->code+="\tJMP "+string(lbl2) +"\n";
			$$->code+=string(lbl1)+":\n";
			$$->code+= "\tMOV "+string(temp)+", 1\n";
			$$->code+=string(lbl2)+":\n";
			$$->setName(temp);
		}
		;
				
simple_expression : term
		  | simple_expression ADDOP term
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
			$$=$1;
			$$->code+=$3->code;
			if($2->getName()=="+"){
				char* temp = newTemp();
				$$->code += "\tMOV AX, " + $1->getName() + "\n";
				$$->code += "\tADD AX, " + $3->getName() + "\n";
				$$->code += "\tMOV " + string(temp) +" , AX\n";
				$$->setName(string(temp));
			}
			else if($2->getName() == "-"){
				char* temp = newTemp();
				$$->code += "\tMOV AX, " + $1->getName() + "\n";
				$$->code += "\tSUB AX, " + $3->getName() + "\n";
				$$->code += "\tMOV " + string(temp) +" , AX\n";
				$$->setName(string(temp));
			}
		} 
		;	


		
term :	unary_expression
     |  term MULOP unary_expression
		{
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
					fprintf(logF,"Error at line %d : Integer operand on modulus operator\n\n",line_count);
					error_count++;
				}
				$$ = temp;
			}
			//$$->code=$1->code+mulop+$3->code;
			$$=$1;
			$$->code += $3->code;
			$$->code += "\tMOV AX, "+ $1->getName()+"\n";
			$$->code += "\tMOV BX, "+ $3->getName() +"\n";
			char *temp=newTemp();
			if($2->getName()=="*"){
				$$->code += "\tMUL BX\n";
				$$->code += "\tMOV "+ string(temp) + ", AX\n";
			}
			else if($2->getName()=="/"){
				$$->code += "\tXOR DX , DX\n";
				$$->code += "\tDIV BX\n";
				$$->code += "\tMOV " + string(temp) + " , AX\n";
			}
			else{
				$$->code += "\tXOR DX , DX\n";
				$$->code += "\tDIV BX\n";
				$$->code += "\tMOV " + string(temp) + " , DX\n";
			}
			$$->setName(temp);
		}
     ;



unary_expression : ADDOP unary_expression 
			{

				if($1->getName() == "+"){
					$$=$2;
				}
				else if($1->getName() == "-")
				{
					$$ = $2;
					$$->code += "\tMOV AX, " + $2->getName() + "\n";
					$$->code += "\tNEG AX\n";
					$$->code += "\tMOV " + $2->getName() + " , AX\n";
				}

			} 
		 | NOT unary_expression 
			{
				symbolInfo* Temp = new symbolInfo("INT");
				Temp->setTypeOfId("VAR");
				$$=Temp;
				char *temp=newTemp();
				$$->code="\tMOV AX, " + $2->getName() + "\n";
				$$->code+="\tNOT AX\n";
				$$->code+="\tMOV "+string(temp)+", AX";
			}
		 | factor
		 ;
	
factor	: variable 
	{
		if($$->getType()=="notarray"){
			
		}
		
		else{
			char *temp= newTemp();
			$$->code+="\tMOV AX, " + $1->getName() + "[BX]\n";
			$$->code+= "\tMOV " + string(temp) + ", AX\n";
			$$->setName(temp);
		}
	}
	| ID LPAREN argument_list RPAREN
 	{
		symbolInfo *temp=new symbolInfo();
		temp = symTable.LookUp($1->getName(), "FUNC");
		if(temp == NULL){
			fprintf(logF,"Error at line %d : Undeclared function %s\n\n",line_count,converter($1->getName()));
		}
		else{
			if(temp->getFuncRet() == "VOID"){
				fprintf(logF,"Error at line %d : Function %s returns void\n\n",line_count,converter($1->getName()));
			} 
			else{ 
				symbolInfo *temp2 = new symbolInfo($1->getFuncRet());
				$$ = temp2;
			}
		}
	}
	| LPAREN expression RPAREN
	{
		$$ = $2;
	}
	| CONST_INT 
	{
		$1->setTypeOfVar("INT");			
		$1->setTypeOfId("VAR");
		$$ = $1;
	}
	| CONST_FLOAT
	{
		$1->setTypeOfVar("FLOAT");			
		$1->setTypeOfId("VAR");
		$$ = $1;
	}
	| variable INCOP 
	{
		$$ = $1;
		$$->code += "\tMOV AX , " + $$->getName()+ "\n";
		$$->code += "\tADD AX , 1\n";
		$$->code += "\tMOV " + $$->getName() + " , AX\n";
		
	}
	| variable DECOP
	{
		$$ = $1;
		$$->code += "\tMOV AX , " + $$->getName()+ "\n";
		$$->code += "\tSUB AX , 1\n";
		$$->code += "\tMOV " + $$->getName() + " , AX\n";
	}
	;
	
argument_list : arguments
        ;
	
arguments : arguments COMMA logic_expression
	      | logic_expression
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

	yyin=fp;
	yyparse();
	
	fprintf(logF,"Total lines %d\n\n",line_count);
	fprintf(logF,"Total errors %d\n\n",error_count);
	fclose(logF);
	
	return 0;
}

