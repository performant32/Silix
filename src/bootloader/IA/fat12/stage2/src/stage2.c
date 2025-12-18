#include "teletype.h"

#define ENDL "\12 \15"
extern void print();
void start(){
    PrintString("Hello Stage2" ENDL);
    PrintChar('g');
    PrintChar('h');
    PrintString("Done" ENDL);
    //start();
}
