%{
#include "parser.h"
%}

%%
"+"	    { return ADD;}
"-"	    { return SUB;}
"*"	    { return MUL;}
"/"	    { return DIV;}
"%"	    { return MOD;}
"("     { return LPAREN;}
")"     { return RPAREN;}
[0-9]+  { return NUMBER;}
\n	    { return EOL;}
[ \t]   { /*ignore whitespace*/}
.       { printf("Invalid Character:%c\n", *yytext); }
%%

int yywrap(void){
	return 1;
}
