%{

#include <stdio.h>
#include <stdlib.h>

extern int yylex();
extern int yyparse();

void yyerror(const char* s);
%}

%token T_NUMBER
%token T_PLUS T_MINUS T_MULTIPLY T_DIVIDE T_LEFT T_RIGHT
%token T_NEWLINE T_QUIT
%left T_PLUS T_MINUS
%left T_MULTIPLY T_DIVIDE


%start calculation

%%

calculation:
	   | calculation line
;

line: T_NEWLINE
    | expression T_NEWLINE
    | T_QUIT T_NEWLINE
;

expression: T_NUMBER
	  | expression T_PLUS expression
	  | expression T_MINUS expression
	  | expression T_MULTIPLY expression
	  | expression T_DIVIDE expression
	  | T_LEFT expression T_RIGHT
  ;

%%

int main() {
		yyparse();
}

void yyerror(const char* s) {
	fprintf(stderr, "Parse error: %s\n", s);
	exit(1);
}
