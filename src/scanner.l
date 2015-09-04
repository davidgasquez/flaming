%{
#include <stdio.h>
%}

%option noyywrap

letter          [a-zA-Z]
digit           [0-9]
whitespace      [ \t]
char            [^\"\""]

%%;
"main"          {return MAIN;}

int             {yylval.tipo = entero; return TYPE;}
float           {yylval.tipo = real; return TYPE;}
char            {yylval.tipo = caracter; return TYPE;}
boolean         {yylval.tipo = booleano; return TYPE;}

false           {yylval.lexema = strdup (yytext); yylval.atrib = 0; yylval.tipo = booleano; return CONSTANT;}
true            {yylval.lexema = strdup (yytext); yylval.atrib = 1; yylval.tipo = booleano; return CONSTANT;}

"("             {return LEFT_PAR;}
")"             {return RIGHT_PAR;}
"{"             {return LEFT_BRACE;}
"}"             {return RIGHT_BRACE;}
"["             {return LEFT_BRACKET;}
"]"             {return RIGHT_BRACKET;}

"LVDS"          {return LVDS;}
"LVDE"          {return LVDE;}

","             {return COMMA;}
";"             {return SEMICOLON;}
"."             {return DOT;}
"="             {yylval.atrib = ASSIGN; return ASSIGN;}

"!"             {yylval.atrib = 0; yylval.tipo = booleano; return UNARY_OPERATOR;}

"-"             {yylval.atrib = 0; yylval.tipo = entero; return PLUS_OR_MINUS_OPERATOR;}
"+"             {yylval.atrib = 1; yylval.tipo = entero; return PLUS_OR_MINUS_OPERATOR;}

"*"             {yylval.atrib = 0; yylval.tipo = entero; return BINARY_OPERATOR;}
"/"             {yylval.atrib = 1; yylval.tipo = entero; return BINARY_OPERATOR;}
">"             {yylval.atrib = 2; yylval.tipo = booleano; return BINARY_OPERATOR;}
"<"             {yylval.atrib = 3; yylval.tipo = booleano; return BINARY_OPERATOR;}
">="            {yylval.atrib = 4; yylval.tipo = booleano; return BINARY_OPERATOR;}
"<="            {yylval.atrib = 5; yylval.tipo = booleano; return BINARY_OPERATOR;}
"=="            {yylval.atrib = 6; yylval.tipo = booleano; return BINARY_OPERATOR;}
"!="            {yylval.atrib = 7; yylval.tipo = booleano; return BINARY_OPERATOR;}
"||"            {yylval.atrib = 8; yylval.tipo = booleano; return BINARY_OPERATOR;}
"&&"            {yylval.atrib = 9; yylval.tipo = booleano; return BINARY_OPERATOR;}
"**"            {yylval.atrib = 10; yylval.tipo = lista; return BINARY_OPERATOR;}

"if"            {linea_control = linea_actual; return IF;}
"else"          {return ELSE;}
"while"         {linea_control = linea_actual; return WHILE;}
"do"            {return DO;}
"until"         {linea_control = linea_actual; return UNTIL;}
"input"         {return INPUT;}
"output"        {return OUPUT;}
"return"        {return RETURN;}

{digit}+              {yylval.lexema = strdup(yytext); yylval.atrib = CONSTANT; yylval.tipo = entero; return CONSTANT;}
{digit}+\.{digit}+    {yylval.lexema = strdup(yytext); yylval.atrib = CONSTANT; yylval.tipo = real; return CONSTANT;}
"\'"{char}"\'"        {yylval.lexema = strdup(yytext); yylval.atrib = CONSTANT; yylval.tipo = caracter; return CONSTANT;}
"\""{char}+"\""       {yylval.lexema = strdup(yytext); yylval.atrib = CONSTANT; return STRING;}
{letter}[a-zA-Z0-9_]* {yylval.lexema = strdup(yytext); yylval.atrib = ID; return ID;}
{whitespace}+         {}
\n                    {linea_actual++;}

. {
  fprintf(stderr,"Line %d. Lexic error: %s\n",
          linea_actual, yytext);
}

%%
