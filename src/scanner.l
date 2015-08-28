%{
#include <stdio.h>
#include "parser.tab.h"
%}

%%

[ \t]	;
[0-9]+	{return T_NUMBER; }
\n	{return T_NEWLINE;}
"+"	{return T_PLUS;}
"-"	{return T_MINUS;}
"*"	{return T_MULTIPLY;}
"/"	{return T_DIVIDE;}
"("	{return T_LEFT;}
")"	{return T_RIGHT;}
"quit"	{return T_QUIT;}

%%

int yywrap(void){
	return 1;
}
