#include<bits/stdc++.h>
#include<cstring>
#include<iostream>
#include<list>
#include <memory>
#include<cstdio>
#include<cstdlib>
#include<string>
#include<vector>
#define MAXSIZE 150

using namespace std;
class symbolInfo
{
    string name;
    string type;
    string funcRet;
    string typeOfId;
    string typeOfVar;
    bool funcIsDefined = false; 
public:
    string code;	
    vector<string> listOfParameters; 
    symbolInfo* next;
    symbolInfo()
    {
        next=NULL;
        name="NULL";
        type="NULL";
	code="";
    }
	
    symbolInfo(string type)
    {
        /*next=NULL;
        name="NULL";
        type="NULL";*/
	code="";
	typeOfVar = type;
    }
    symbolInfo(string Name, string Type){
	code="";
        name = Name;
        type = Type;
    }
    void setName(string Name)
    {
        name=Name;
    }
    string getName()
    {
        return name;
    }
    void setType(string Type)
    {
        type=Type;
    }
    string getType()
    {
        return type;
    }
    void setTypeOfId(string type){
	typeOfId= type;	
    }
    string getTypeOfId(){
	return typeOfId;
    }
    void setTypeOfVar(string type){
	typeOfVar = type;
    }
    string getTypeOfVar(){
	return typeOfVar;
    }
    void setFuncRet(string type){
	funcRet = type;
    }
    string getFuncRet(){
	return funcRet;
    }
    void setFuncIsDefined(){ 
	funcIsDefined = true;	
    }
    bool getFuncIsDefined(){
 	return funcIsDefined;
    }
};

class scopeTable
{
    int id;
    int N;
    scopeTable* parentScope;
public:
    symbolInfo **ScopeTable;
    scopeTable(int n)
    {
        N=n;
        ScopeTable =new symbolInfo*[n];
        for(int i=0; i<n; i++){
            ScopeTable[i]=NULL;
        }
    }
    /*~scopeTable()
    {
        for(int i=0; i<N; i++)
        {
            symbolInfo* temp=ScopeTable[i];
            while(temp!=NULL)
            {
                symbolInfo *prev=temp;
                temp=temp->next;
                delete prev;
            }
        }
        delete[] ScopeTable;
    }
    */
    void setId(int Id)
    {
        id=Id;
    }
    int getId()
    {
        return id;
    }
    void setParent(scopeTable* parent)
    {
        parentScope=parent;
    }
    scopeTable* getParent()
    {
        return parentScope;
    }
    int myHash(string str,int N)
    {
        long Hash = 0;

        for(int i = 0; i < str.length(); i++)
        {
            Hash = (int)str[i] + (Hash << 6) + (Hash << 16) - Hash;
        }
        if(Hash<0)
            Hash=-Hash;
        return Hash%N;
    }

    bool Insert(string name,string type)
    {
        if(LookUp2(name,type)!=NULL)
        {
            //cout<<"<"<<name<<","<<type<<"> already exists in current ScopeTable"<<endl<<endl;
            return false;
        }
        int bucketPosition=0;
        int bucketNo=myHash(name,N);
        symbolInfo* prev=NULL;
        symbolInfo* newEntry=ScopeTable[bucketNo];
        while(newEntry!=NULL)
        {
            prev=newEntry;
            newEntry=newEntry->next;
            bucketPosition++;
        }
        newEntry=new symbolInfo;
        newEntry->setName(name);
        newEntry->setType(type);
        if(prev==NULL)
        {
            ScopeTable[bucketNo]=newEntry;
        }
        else
        {
            prev->next=newEntry;
        }
        //cout<<" Inserted in ScopeTable# "<<id<<" at position "<<bucketNo<<", "<<bucketPosition<<endl<<endl;
        return true;
    }
    bool InsertSymbol(symbolInfo* sym)
    {
 	string name=sym->getName();
	string type=sym->getType();
        if(LookUp2(name,type)!=NULL)
        {
            //cout<<"<"<<name<<","<<type<<"> already exists in current ScopeTable"<<endl<<endl;
            return false;
        }
        int bucketPosition=0;
        int bucketNo=myHash(name,N);
        symbolInfo* prev=NULL;
        symbolInfo* newEntry=ScopeTable[bucketNo];
        while(newEntry!=NULL)
        {
            prev=newEntry;
            newEntry=newEntry->next;
            bucketPosition++;
        }
        newEntry=sym;
        if(prev==NULL)
        {
            ScopeTable[bucketNo]=newEntry;
        }
        else
        {
            prev->next=newEntry;
        }
        //cout<<" Inserted in ScopeTable# "<<id<<" at position "<<bucketNo<<", "<<bucketPosition<<endl<<endl;
        return true;
    }
    symbolInfo* LookUp(string str,string type)
    {
        int bucketPosition=0;
        bool flag=false;
        int bucketNo=myHash(str,N);
        symbolInfo* temp=ScopeTable[bucketNo];

        while(temp!=NULL)
        {
            if(temp->getName()==str&&temp->getTypeOfId()==type)
            {
                //cout<<" Found in ScopeTable# "<<id<<" at position "<<bucketNo<<", "<<bucketPosition<<endl<<endl;
                return temp;
            }
            temp=temp->next;
            bucketPosition++;
        }
        //cout<<" Not Found"<<endl<<endl;
        return NULL;
    }
    symbolInfo* LookUp2(string str,string type)
    {
        int bucketPosition=0;
        bool flag=false;
        int bucketNo=myHash(str,N);
        symbolInfo* temp=ScopeTable[bucketNo];


        while(temp!=NULL)
        {
            if(temp->getName()==str&&temp->getTypeOfId()==type)
            {
                return temp;
            }
            temp=temp->next;
            bucketPosition++;
        }
        return NULL;
    }
    bool Delete(string str,string type)
    {
        if(LookUp(str,type)==NULL)
        {
            //cout<<str<<" not found"<<endl<<endl;
            return false;
        }
        int bucketNo=myHash(str,N);
        int bucketPosition=0;
        symbolInfo* temp=ScopeTable[bucketNo];
        symbolInfo* prev =NULL;
        while(temp->next!=NULL)
        {
            prev=temp;
            temp=temp->next;
            bucketPosition++;
        }
        if(prev!=NULL)
        {
            prev->next=temp->next;
        }
        if(temp==ScopeTable[bucketNo])
        {
            ScopeTable[bucketNo]=NULL;
        }
        //cout<<"Deleted entry at "<<bucketNo<<", "<<bucketPosition<<" from current ScopeTable"<<endl<<endl;
        return true;
    }

    string Print()
    {
	string strRet="\n ScopeTable # "+to_string(id)+"\n";
        symbolInfo* temp;
        for(int i=0; i<N; i++)
        {
            temp=ScopeTable[i];
	    if(temp==NULL) continue;
	    strRet=strRet+" "+to_string(i)+"-->";
            while(temp!=NULL)
            {
                strRet=strRet+" < "+temp->getName()+" : "+temp->getType()+" > ";
                temp=temp->next;
            }
		strRet=strRet+"\n";
        }
	return strRet;
   }
};


class SymbolTable
{
    scopeTable* List;
    int bucketSize;
    int IdOfTable;
    char* printedTable; 
public:
    scopeTable* curScTable;
	
    SymbolTable()
    {
        List=NULL;
        bucketSize=7;
	IdOfTable=0;
    }

    
    SymbolTable(int n)
    {
        List=NULL;
        bucketSize=n;
    }
    int getScopeNum(){
	return IdOfTable;
    }
    void EnterScope()
    {
        scopeTable *newScope;
        newScope=new scopeTable(bucketSize);
        IdOfTable++;
        newScope->setId(IdOfTable);
        if(List==NULL)
        {
            List=newScope;
            curScTable=newScope;
            newScope->setParent(NULL);
            return;
        }
        newScope->setParent(curScTable);
        curScTable=newScope;
    }
    char* ExitScope()
    {
        if(List==curScTable)
        {
            List=NULL;
            IdOfTable=0;
            return "";
        }
        scopeTable* temp=curScTable;
        curScTable=curScTable->getParent();
        IdOfTable=curScTable->getId();
        delete temp;
	string ret="";
	int n = ret.length(); 
    	printedTable=new char[n+1]; 
    	strcpy(printedTable, ret.c_str()); 
	return printedTable;
    }
    bool Insert(string name,string type)
    {
        scopeTable* newScopeTable;
        newScopeTable=new scopeTable(bucketSize);
        newScopeTable->setParent(NULL);
        if(List==NULL){
            IdOfTable++;
            newScopeTable->setId(IdOfTable);
            List=newScopeTable;
            curScTable=newScopeTable;
        }
        return curScTable->Insert(name,type);
    }
    bool InsertSymbol(symbolInfo* sym)
    {
        scopeTable* newScopeTable;
        newScopeTable=new scopeTable(bucketSize);
        newScopeTable->setParent(NULL);
        if(List==NULL){
            IdOfTable++;
            newScopeTable->setId(IdOfTable);
            List=newScopeTable;
            curScTable=newScopeTable;
        }
        return curScTable->InsertSymbol(sym);
    }
    bool Remove(string symbol,string type)
    {
        return curScTable->Delete(symbol,type);
    }
    symbolInfo* LookUp(string symbol,string type)
    {
        scopeTable* temp=curScTable;
        while(temp->getParent()!=NULL)
        {

            symbolInfo* x=temp->LookUp2(symbol,type);
            if(x==NULL&&temp->getParent()!=NULL){
                temp=temp->getParent();
            }
            else
            {
                return x;
            }
        }
        return temp->LookUp2(symbol,type);
    }
    string PrintCurrent(){
	string temp=curScTable->Print();
	return temp;
    }
    char* PrintAll(){
	string ret="";
        scopeTable* temp=curScTable;
        while(temp->getParent()!=NULL)
        {
            ret=ret+temp->Print();
            temp=temp->getParent();
        }
        ret=ret+temp->Print();
 
    	int n = ret.length(); 
    	printedTable=new char[n+1]; 
    	strcpy(printedTable, ret.c_str()); 
	return printedTable;
    
    }
	
};
