#include<bits/stdc++.h>
#include<cstring>
#include<iostream>
#include <cstdlib>
#include<list>
#include <memory>

#define MAXSIZE 150

using namespace std;

int ID = 0;

class symbolInfo {
    string name;
    string type;
public:
    symbolInfo *next;

    symbolInfo() {
        next = NULL;
        name = "NULL";
        type = "NULL";
    }

    void setName(string Name) {
        name = Name;
    }

    string getName() {
        return name;
    }

    void setType(string Type) {
        type = Type;
    }

    string getType() {
        return type;
    }
};

class scopeTable {
    int id;
    int N;
    scopeTable *parentScope;
public:
    symbolInfo **ScopeTable;

    scopeTable(int n) {
        N = n;
        ScopeTable = new symbolInfo *[n];
        for (int i = 0; i < n; i++) {
            ScopeTable[i] = NULL;
        }
    }

    ~scopeTable() {
        for (int i = 0; i < N; i++) {
            symbolInfo *temp = ScopeTable[i];
            while (temp != NULL) {
                symbolInfo *prev = temp;
                temp = temp->next;
                delete prev;
            }
        }
        delete[] ScopeTable;
    }

    void setId(int Id) {
        id = Id;
    }

    int getId() {
        return id;
    }

    void setParent(scopeTable *parent) {
        parentScope = parent;
    }

    scopeTable *getParent() {
        return parentScope;
    }

    int myHash(string str, int N) {
        long Hash = 0;

        for (int i = 0; i < str.length(); i++) {
            Hash = (int) str[i] + (Hash << 6) + (Hash << 16) - Hash;
        }
        if (Hash < 0)
            Hash = -Hash;
        return Hash % N;
    }

    bool Insert(string name, string type) {
        if (LookUp2(name) != NULL) {
            cout << "<" << name << "," << type << "> already exists in current ScopeTable" << endl << endl;
            return false;
        }
        int bucketPosition = 0;
        int bucketNo = myHash(name, N);
        symbolInfo *prev = NULL;
        symbolInfo *newEntry = ScopeTable[bucketNo];
        while (newEntry != NULL) {
            prev = newEntry;
            newEntry = newEntry->next;
            bucketPosition++;
        }
        newEntry = new symbolInfo;
        newEntry->setName(name);
        newEntry->setType(type);
        if (prev == NULL) {
            ScopeTable[bucketNo] = newEntry;
        } else {
            prev->next = newEntry;
        }
        cout << " Inserted in ScopeTable# " << id << " at position " << bucketNo << ", " << bucketPosition << endl
             << endl;
        return true;
    }

    symbolInfo *LookUp(string str) {
        int bucketPosition = 0;
        bool flag = false;
        int bucketNo = myHash(str, N);
        symbolInfo *temp = ScopeTable[bucketNo];

        while (temp != NULL) {
            if (temp->getName() == str) {
                cout << " Found in ScopeTable# " << id << " at position " << bucketNo << ", " << bucketPosition << endl
                     << endl;
                return temp;
            }
            temp = temp->next;
            bucketPosition++;
        }
        cout << " Not Found" << endl << endl;
        return NULL;
    }

    symbolInfo *LookUp2(string str) {
        int bucketPosition = 0;
        bool flag = false;
        int bucketNo = myHash(str, N);
        symbolInfo *temp = ScopeTable[bucketNo];


        while (temp != NULL) {
            if (temp->getName() == str) {
                return temp;
            }
            temp = temp->next;
            bucketPosition++;
        }
        return NULL;
    }

    bool Delete(string str) {
        if (LookUp(str) == NULL) {
            cout << str << " not found" << endl << endl;
            return false;
        }
        int bucketNo = myHash(str, N);
        int bucketPosition = 0;
        symbolInfo *temp = ScopeTable[bucketNo];
        symbolInfo *prev = NULL;
        while (temp->next != NULL) {
            prev = temp;
            temp = temp->next;
            bucketPosition++;
        }
        if (prev != NULL) {
            prev->next = temp->next;
        }
        if (temp == ScopeTable[bucketNo]) {
            ScopeTable[bucketNo] = NULL;
        }
        cout << "Deleted entry at " << bucketNo << ", " << bucketPosition << " from current ScopeTable" << endl << endl;
        return true;
    }

    void Print() {
        cout << "ScopeTable # " << id << endl;
        symbolInfo *temp;
        for (int i = 0; i < N; i++) {
            temp = ScopeTable[i];
            cout << i << "-->";
            while (temp != NULL) {
                cout << "  < " << temp->getName() << " : " << temp->getType() << " >";
                temp = temp->next;
            }
            cout << endl;
        }
        cout << endl;
    }
};


class SymbolTable {
    scopeTable *List;
    int bucketSize;

public:
    scopeTable *curScTable;

    SymbolTable(int n) {
        List = NULL;
        bucketSize = n;
    }

    void EnterScope() {
        scopeTable *newScope;
        newScope = new scopeTable(bucketSize);
        ID++;
        newScope->setId(ID);
        if (List == NULL) {
            List = newScope;
            curScTable = newScope;
            newScope->setParent(NULL);
            return;
        }
        newScope->setParent(curScTable);
        curScTable = newScope;
    }

    void ExitScope() {
        if (List == curScTable) {
            List = NULL;
            ID = 0;
            return;
        }
        scopeTable *temp = curScTable;
        curScTable = curScTable->getParent();
        ID = curScTable->getId();
        delete temp;
    }

    bool Insert(string name, string type) {
        scopeTable *newScopeTable;
        newScopeTable = new scopeTable(bucketSize);
        newScopeTable->setParent(NULL);
        if (List == NULL) {
            ID++;
            newScopeTable->setId(ID);
            List = newScopeTable;
            curScTable = newScopeTable;
        }
        return curScTable->Insert(name, type);
    }

    bool Remove(string symbol) {
        return curScTable->Delete(symbol);
    }

    symbolInfo *LookUp(string symbol) {
        scopeTable *temp = curScTable;
        while (temp->getParent() != NULL) {

            symbolInfo *x = temp->LookUp(symbol);
            if (x == NULL && temp->getParent() != NULL) {
                temp = temp->getParent();
            } else {
                return x;
            }
        }
        return temp->LookUp(symbol);
    }

    void PrintCurrent() {
        curScTable->Print();
    }

    void PrintAll() {
        scopeTable *temp = curScTable;
        while (temp->getParent() != NULL) {
            temp->Print();
            temp = temp->getParent();
        }
        temp->Print();
    }
};

int main() {
    FILE *fp;
    fp = fopen("input.txt", "r");
    if (fp == NULL) {
        printf("ERROR OPENING FILE\n");
        return 1;
    }
    int n;
    fscanf(fp, "%d", &n);
    SymbolTable hashTable(n);
    char *str = new char[MAXSIZE];
    string name, type;
    while (fgets(str, MAXSIZE, fp) != NULL) {
        char s[15];
        istringstream iss(str);
        while (iss >> s) {
            if (!strcmp(s, "I")) {
                iss >> name;
                iss >> type;
                cout << "I " << name << " " << type << endl << endl;
                hashTable.Insert(name, type);
            }
            if (!strcmp(s, "L")) {
                iss >> name;
                cout << "L " << name << endl << endl;
                hashTable.LookUp(name);
            }
            if (!strcmp(s, "D")) {
                iss >> name;
                cout << "D " << name << endl << endl;
                hashTable.Remove(name);
            }
            if (!strcmp(s, "P")) {
                iss >> name;
                if (!strcmp(s, "C")) {
                    cout << "P C" << endl << endl;
                    hashTable.PrintCurrent();
                } else {
                    cout << "P A" << endl << endl;
                    hashTable.PrintAll();
                }
            }
            if (!strcmp(s, "S")) {
                cout << "S" << endl << endl;
                cout << " New ScopeTable with id " << ID + 1 << " created" << endl << endl;
                hashTable.EnterScope();
            }
            if (!strcmp(s, "E")) {
                cout << "E" << endl << endl;
                cout << " ScopeTable with id " << ID << " removed" << endl << endl;
                hashTable.ExitScope();
            }
        }
    }
    return 0;
}
