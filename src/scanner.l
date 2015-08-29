%{
#include <stdio.h>
%}

%option noyywrap

letter          [a-z]
digit           [0-9]
whitespace      [ \t]
char            [^\"\""]

%%;
"main"          {return MAIN;}

int             {return TYPE;}
float           {return TYPE;}
boolean         {return TYPE;}
char            {return TYPE;}
true            {return CONSTANT;}
false           {return CONSTANT;}

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
"="             {return ASSIGN;}

"!"             {return UNARY_OPERATOR;}

"-"             {return PLUS_OR_MINUS_OPERATOR;}
"+"             {return PLUS_OR_MINUS_OPERATOR;}

"*"             {return BINARY_OPERATOR;}
"/"             {return BINARY_OPERATOR;}
"+="            {return BINARY_OPERATOR;}
"-="            {return BINARY_OPERATOR;}
"*="            {return BINARY_OPERATOR;}
"/="            {return BINARY_OPERATOR;}
">"             {return BINARY_OPERATOR;}
"<"             {return BINARY_OPERATOR;}
">="            {return BINARY_OPERATOR;}
"<="            {return BINARY_OPERATOR;}
"=="            {return BINARY_OPERATOR;}
"!="            {return BINARY_OPERATOR;}
"||"            {return BINARY_OPERATOR;}
"&&"            {return BINARY_OPERATOR;}
"**"            {return BINARY_OPERATOR;}

"if"            {return IF;}
"else"          {return ELSE;}
"while"         {return WHILE;}
"do"            {return DO;}
"until"            {return UNTIL;}
"input"         {return INPUT;}
"output"        {return OUPUT;}
"return"        {return RETURN;}

{digit}+            {return CONSTANT;}
{digit}+\.{digit}+  {return CONSTANT;}
"\'"{char}"\'"      {return CONSTANT;}
"\""{char}+"\""     {return STRING;}
{letter}+           {return ID;}
{whitespace}+       {}
\n                  {current_line++;}

. {
  fprintf(stderr,"\n(linea - %d) Error léxico: token %s\n",
          current_line, yytext);
}

%%
