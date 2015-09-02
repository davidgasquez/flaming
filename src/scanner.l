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

int             {yylval.type = t_int; return TYPE;}
float           {yylval.type = t_float; return TYPE;}
char            {yylval.type = t_char; return TYPE;}
boolean         {yylval.type = boolean; return TYPE;}

false           {yylval.lexeme = strdup (yytext); yylval.attribute = 0; yylval.type = boolean; return CONSTANT;}
true            {yylval.lexeme = strdup (yytext); yylval.attribute = 1; yylval.type = boolean; return CONSTANT;}

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

"!"             {yylval.attribute = 0; yylval.type = boolean; return UNARY_OPERATOR;}

"-"             {yylval.attribute = 0; yylval.type = t_int; return PLUS_OR_MINUS_OPERATOR;}
"+"             {yylval.attribute = 1; yylval.type = t_int; return PLUS_OR_MINUS_OPERATOR;}

"*"             {yylval.attribute = 0; yylval.type = t_int; return BINARY_OPERATOR;}
"/"             {yylval.attribute = 1; yylval.type = t_int; return BINARY_OPERATOR;}
">"             {yylval.attribute = 2; yylval.type = boolean; return BINARY_OPERATOR;}
"<"             {yylval.attribute = 3; yylval.type = boolean; return BINARY_OPERATOR;}
">="            {yylval.attribute = 4; yylval.type = boolean; return BINARY_OPERATOR;}
"<="            {yylval.attribute = 5; yylval.type = boolean; return BINARY_OPERATOR;}
"=="            {yylval.attribute = 6; yylval.type = boolean; return BINARY_OPERATOR;}
"!="            {yylval.attribute = 7; yylval.type = boolean; return BINARY_OPERATOR;}
"||"            {yylval.attribute = 8; yylval.type = boolean; return BINARY_OPERATOR;}
"&&"            {yylval.attribute = 9; yylval.type = boolean; return BINARY_OPERATOR;}
"**"            {yylval.attribute = 10; yylval.type = array; return BINARY_OPERATOR;}

"if"            {control_line = current_line; return IF;}
"else"          {return ELSE;}
"while"         {control_line = current_line; return WHILE;}
"do"            {return DO;}
"until"         {control_line = current_line; return UNTIL;}
"input"         {return INPUT;}
"output"        {return OUPUT;}
"return"        {return RETURN;}

{digit}+              {yylval.lexeme = strdup(yytext); yylval.attribute = CONSTANT; yylval.type = t_int; return CONSTANT;}
{digit}+\.{digit}+    {yylval.lexeme = strdup(yytext); yylval.attribute = CONSTANT; yylval.type = t_float; return CONSTANT;}
"\'"{char}"\'"        {yylval.lexeme = strdup(yytext); yylval.attribute = CONSTANT; yylval.type = t_char; return CONSTANT;}
"\""{char}+"\""       {yylval.lexeme = strdup(yytext); yylval.attribute = CONSTANT; return STRING;}
{letter}[a-zA-Z0-9_]* {yylval.lexeme = strdup(yytext); yylval.attribute = ID; return ID;}
{whitespace}+         {}
\n                    {current_line++;}

. {
  fprintf(stderr,"Line %d. Lexic error: %s\n",
          current_line, yytext);
}

%%
