%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char* s);

int current_line = 1;
int control_line;

typedef enum {
	formal_parameter,
	mark,
  conditional_mark,
	function,
	variable,
} InputType;

typedef enum {
	t_int,
	t_float,
	t_char,
	boolean,
	array,
	unknown,
	unassigned,
} DataType;

typedef struct {
	InputType input;
	char *name;
	DataType data_type;
	unsigned int parameters;
	unsigned int dimensions;
	int dimension_size_1;
	int dimension_size_2;
} InputST;

#define ST_MAX 500

unsigned int top = 0, function_top;
unsigned int sub_program = 0, var_declaration = 0;
unsigned int dimensions, dimension_size_1, dimension_size_2;
unsigned int func = 0, parameter_position = 0;
char functionID[100];

InputST ST[ST_MAX];

DataType type_TMP, type_array;

typedef struct {
	int attribute;
	char *lexeme;
	DataType type;
	DataType type_array;
	unsigned int dimensions;
	int dimension_size_1;
	int dimension_size_2;
} attributes;

#define YYSTYPE attributes

%}

%error-verbose

%token MAIN
%token TYPE
%token LEFT_PAR
%token RIGHT_PAR
%token LEFT_BRACE
%token RIGHT_BRACE
%token LEFT_BRACKET
%token RIGHT_BRACKET
%token LVDS
%token LVDE
%token COMMA
%token SEMICOLON
%token DOT
%token ASSIGN
%token UNARY_OPERATOR
%token PLUS_OR_MINUS_OPERATOR
%token BINARY_OPERATOR
%token IF
%token ELSE
%token WHILE
%token DO
%token UNTIL
%token INPUT
%token OUPUT
%token RETURN
%token CONSTANT
%token STRING
%token ID

%left BINARY_OPERATOR
%right UNARY_OPERATOR
%left PLUS_OR_MINUS_OPERATOR


%%

program : program_header block;

program_header : MAIN LEFT_PAR RIGHT_PAR;

block : LEFT_BRACE local_var_declaration sub_programs_declaration sentences RIGHT_BRACE
      | LEFT_BRACE local_var_declaration sub_programs_declaration RIGHT_BRACE
      | LEFT_BRACE local_var_declaration sentences RIGHT_BRACE
      | LEFT_BRACE sub_programs_declaration sentences RIGHT_BRACE
      | LEFT_BRACE sub_programs_declaration RIGHT_BRACE
      | LEFT_BRACE sentences RIGHT_BRACE
      | LEFT_BRACE RIGHT_BRACE;

sub_programs_declaration : sub_programs_declaration sub_program
                         | sub_program;

sub_program : subprogram_header block;

subprogram_header : TYPE ID LEFT_PAR parameters RIGHT_PAR
                  | TYPE ID LEFT_PAR RIGHT_PAR;

parameters : parameters COMMA TYPE ID
           | TYPE ID
           | error;

local_var_declaration : LVDS local_var_declarations LVDE;

local_var_declarations : local_var_declarations var_declaration
                       | var_declaration;

var_declaration : TYPE var_list SEMICOLON
                | error;

var_list : var_list COMMA id_or_array_id
         | id_or_array_id
         | error;

id_or_array_id : ID
               | array_id;

array_id : ID LEFT_BRACKET CONSTANT RIGHT_BRACKET
         | ID LEFT_BRACKET CONSTANT COMMA CONSTANT RIGHT_BRACKET;

sentences : sentences sentence
          | sentence;

sentence : block
         | assign
         | if
         | while
         | do_until
         | input
         | output
         | return
         | error;

assign : ID ASSIGN expression SEMICOLON;

if : IF LEFT_PAR expression RIGHT_PAR sentence
    | IF LEFT_PAR expression RIGHT_PAR sentence else;

else : ELSE sentence;

while : WHILE LEFT_PAR expression RIGHT_PAR LEFT_BRACE sentences RIGHT_BRACE;

do_until : DO expression UNTIL LEFT_PAR expression RIGHT_PAR SEMICOLON;

input : INPUT var_list SEMICOLON;

output : OUPUT expression SEMICOLON;

return : RETURN expression SEMICOLON;

expression_list : expression_list COMMA expression
                | expression;

expression : LEFT_PAR expression RIGHT_PAR
           | UNARY_OPERATOR expression
           | expression BINARY_OPERATOR expression
           | expression PLUS_OR_MINUS_OPERATOR expression
           | PLUS_OR_MINUS_OPERATOR expression
           | id_or_array_id
           | CONSTANT
           | STRING
           | aggregate
           | function_call
           | error;

constants_list: constants_list COMMA CONSTANT
              | constants_list SEMICOLON CONSTANT
              | CONSTANT;

aggregate : LEFT_BRACKET constants_list RIGHT_BRACKET;

function_call : ID LEFT_PAR expression_list RIGHT_PAR;

%%

#include "lex.yy.c"

void yyerror(const char* s) {
  fprintf(stderr, "Line %d. Parse error: %s\n", current_line, s);
}
