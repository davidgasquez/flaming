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

false           {yylval.lexeme = strdup (yytext); yylval.attribute = 0; yylval.tipo = booleano; return CONSTANT;}
true            {yylval.lexeme = strdup (yytext); yylval.attribute = 1; yylval.tipo = booleano; return CONSTANT;}

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
"="             {yylval.attribute = ASSIGN; return ASSIGN;}

"!"             {yylval.attribute = 0; yylval.tipo = booleano; return UNARY_OPERATOR;}

"-"             {yylval.attribute = 11; yylval.tipo = entero; return PLUS_OR_MINUS_OPERATOR;}
"+"             {yylval.attribute = 12; yylval.tipo = entero; return PLUS_OR_MINUS_OPERATOR;}

"*"             {yylval.attribute = 0; yylval.tipo = entero; return BINARY_OPERATOR;}
"/"             {yylval.attribute = 1; yylval.tipo = entero; return BINARY_OPERATOR;}
">"             {yylval.attribute = 2; yylval.tipo = booleano; return BINARY_OPERATOR;}
"<"             {yylval.attribute = 3; yylval.tipo = booleano; return BINARY_OPERATOR;}
">="            {yylval.attribute = 4; yylval.tipo = booleano; return BINARY_OPERATOR;}
"<="            {yylval.attribute = 5; yylval.tipo = booleano; return BINARY_OPERATOR;}
"=="            {yylval.attribute = 6; yylval.tipo = booleano; return BINARY_OPERATOR;}
"!="            {yylval.attribute = 7; yylval.tipo = booleano; return BINARY_OPERATOR;}
"||"            {yylval.attribute = 8; yylval.tipo = booleano; return BINARY_OPERATOR;}
"&&"            {yylval.attribute = 9; yylval.tipo = booleano; return BINARY_OPERATOR;}
"**"            {yylval.attribute = 10; yylval.tipo = lista; return BINARY_OPERATOR;}

"if"            {control_line = current_line; return IF;}
"else"          {return ELSE;}
"while"         {control_line = current_line; return WHILE;}
"do"            {return DO;}
"until"         {control_line = current_line; return UNTIL;}
"input"         {return INPUT;}
"output"        {return OUPUT;}
"return"        {return RETURN;}

{digit}+              {yylval.lexeme = strdup(yytext); yylval.attribute = CONSTANT; yylval.tipo = entero; return CONSTANT;}
{digit}+\.{digit}+    {yylval.lexeme = strdup(yytext); yylval.attribute = CONSTANT; yylval.tipo = real; return CONSTANT;}
"\'"{char}"\'"        {yylval.lexeme = strdup(yytext); yylval.attribute = CONSTANT; yylval.tipo = caracter; return CONSTANT;}
"\""{char}+"\""       {yylval.lexeme = strdup(yytext); yylval.attribute = CONSTANT; return STRING;}
{letter}[a-zA-Z0-9_]* {yylval.lexeme = strdup(yytext); yylval.attribute = ID; return ID;}
{whitespace}+         {}
\n                    {current_line++;}

. {
  fprintf(stderr,"Line %d. Lexic error: %s\n",
          current_line, yytext);
}

%%
