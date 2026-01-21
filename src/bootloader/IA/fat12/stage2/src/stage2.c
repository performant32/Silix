#include "teletype.h"

#define ENDL "\12 \15"
extern void print();
void start(){
    PrintChar('g');
    PrintString("Hello Stage2" ENDL);
    PrintChar('h');
    PrintString("Done" ENDL);
    //start();
}
