%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char* s);

int current_line = 1;
int control_line;

typedef enum {
  mark,
  conditional_mark,
  function,
  variable,
  formal_parameter
} input_type;
typedef enum {
  integer,
  real,
  character,
  boolean,
  array,
  unknown,
  not_assigned
} type;
typedef struct {
  input_type input;
  char *name;
  type data_type;
  type data_type_array;
  unsigned int parameters;
} symbol_table;

#define MAX_ST 500
unsigned int top = -1, function_top; /* Tope de la pila */
unsigned int sub_program = 0,
             variable_declarations = 0; /* Indicador de comienzo de bloque de un subprog */
unsigned int func = 0, param_position = 0;
char function_id[100];
symbol_table ST[MAX_ST]; /* Pila de la tabla de símbolos */

type tmp_type, tmp_array_type;

typedef struct {
  int attribute;       /* Atributo del símbolo (si tiene) */
  char *lexeme;    /* Nombre del lexeme */
  type type;      /* Tipo del símbolo */
  type type_array; /* Si type es array, type de la array */
} attributes;
#define YYSTYPE attributes /* A partir de ahora, cada símbolo tiene */
                          /* una estructura de type attributes */


void InsertMark() {
  top++;
  if (sub_program == 1) {
    ST[top].input = mark;
    ST[top].name = "start_mark";
    int tmp_top = top;
    while (ST[tmp_top].input != function && tmp_top > 0) {
      if (ST[tmp_top].input == formal_parameter) {
        top++;
        ST[top].input = variable;
        ST[top].name = ST[tmp_top].name;
        ST[top].data_type = ST[tmp_top].data_type;
        if (ST[top].data_type == array)
          ST[top].data_type_array = ST[tmp_top].data_type_array;
      }
      tmp_top--;
    }
  } else {
    ST[top].input = conditional_mark;
    ST[top].name = "conditional_mark";
  }
}

void EmptySymbolTable() {
  while (ST[top].input != mark && ST[top].input != conditional_mark) {
    top--;
  }
  top--;
}

int VariableExists(attributes a) {
  int tmp_top = top;
  while (tmp_top >= 0) {
    if (ST[tmp_top].input == variable &&
        strcmp(ST[tmp_top].name, a.lexeme) == 0) {
      return 1;
    }
    tmp_top--;
  }
  return 0;
}

int ExistsID(attributes a) {
  int tmp_top = top;
  while (ST[tmp_top].input != mark &&
         ST[tmp_top].input != conditional_mark && tmp_top >= 0) {
    if (strcmp(ST[tmp_top].name, a.lexeme) == 0) {
      return 1;
    }
    tmp_top--;
  }
  return 0;
}

void AddID(attributes a) {
  if (ExistsID(a))
    fprintf(stderr, "Line %d. Semantic error: '%s' already exists.\n", current_line, a.lexeme);
  else {
    top++;
    ST[top].input = variable;
    ST[top].name = a.lexeme;
    ST[top].data_type = tmp_type;
    if (tmp_type == array) ST[top].data_type_array = tmp_array_type;
  }
}

void AddSubProgram(attributes t, attributes a) {
  top++;
  ST[top].input = function;
  ST[top].name = a.lexeme;
  ST[top].parameters = 0;
  ST[top].data_type = t.type;
}

void AddFormalParameter(attributes a) {
  top++;

  ST[top].input = formal_parameter;
  ST[top].name = a.lexeme;
  ST[top].data_type = a.type;

  if (a.type == array) {
    ST[top].data_type_array = a.type_array;
  }

  int tmp_top = top;

  while (ST[tmp_top].input != function && tmp_top >= 0) {
    tmp_top--;
  }

  ST[tmp_top].parameters++;
}

void CheckLogicExpression(attributes a) {
  if (a.type != boolean)
    fprintf(stderr, "Line %d. Semantic error: Not a logical expression.\n",
            control_line);
}

unsigned int AssignType(attributes a) {
  int tmp_top = top;
  int existe = 0;
  unsigned int type = unknown;
  if (VariableExists(a)) {
    while (existe == 0 && tmp_top >= 0) {
      if (!strcmp(ST[tmp_top].name, a.lexeme)) {
        existe = 1;
        type = ST[tmp_top].data_type;
      }
      tmp_top--;
    }
  } else
    fprintf(stderr, "Line %d. Semantic error: Variable '%s' not defined.\n", current_line, a.lexeme);
  return type;
}

unsigned int AssignArrayType(attributes a) {
  int tmp_top = top;
  int exists = 0;
  unsigned int type = unknown;

  if (VariableExists(a)) {
    while (exists == 0 && tmp_top >= 0) {
      if (!strcmp(ST[tmp_top].name, a.lexeme)) {
        exists = 1;
        type = ST[tmp_top].data_type_array;
      }
      tmp_top--;
    }
  }
  return type;
}

unsigned int CheckAssignType(attributes a, attributes op, attributes b) {
  unsigned int type = unknown;
  int error = 0;
  if (VariableExists(a) && b.type != unknown) {
    type = AssignType(a);
    if (type != b.type) {
      if ((type == real || type == integer || type == array) &&
          (b.type == real || b.type == integer || b.type == array)) {
        error = 0;
      } else
        error = 1;
    } else if (type == array) {
      unsigned int type_array = AssignArrayType(a);
      if (type_array != b.type_array) error = 1;
    }
  }
  if (error && b.type != unknown)
    fprintf(stderr, "Line %d. Semantic error: Can't assign(incompatible types).\n",
            current_line);
  return type;
}

unsigned int RealOrInts(type t1, type t2) {
  if ((t1 == real || t1 == integer) && (t2 == real || t2 == integer)) return 1;
  return 0;
}

unsigned int CheckBynaryTypes(attributes a, attributes op, attributes b) {
  unsigned int type = op.type;
  int error = 1;
  switch (op.attribute) {
    case 11:  // -
    case 1:   // /
    case 12:  // +
    case 0:   // *
    case 2:   // >
    case 3:   // <
    case 4:   // >=
    case 5:   // <=
      error = !RealOrInts(a.type, b.type);
      break;
    case 8:   // ||
    case 9:   // &&
      if (a.type == boolean && b.type == boolean) error = 0;
      break;
    case 10:  // **
      if (a.type == array && b.type == array) error = 0;
      break;
    case 6:   // ==
    case 7:   // !=
    default:
      if (a.type != b.type) {
        error = !RealOrInts(a.type, b.type);
      } else
        error = 0;
  }
  if (error && a.type != unknown && b.type != unknown)
    fprintf(stderr, "Line %d. Semantic error: Can't operate(incompatible types).\n",
            current_line);
  return type;
}
unsigned int CheckUnaryType(attributes op, attributes a) {
  unsigned int type = 0;
  int error = 1;

  switch (op.attribute) {
    case 0:  // !a
      if (a.type == boolean) {
        type = boolean;
        error = 0;
      }
      break;
  }

  if (error && a.type != unknown)
    fprintf(stderr, "Line %d. Semantic error: Incompatible types.\n ",
            current_line);

  return type;
}

unsigned int ExistsFunctionID(char *id) {
  int tmp_top = top, exists = 0;

  while (tmp_top >= 0 && exists == 0) {
    if (ST[tmp_top].input == function && !strcmp(id, ST[tmp_top].name))
      exists = 1;
    else
      tmp_top--;
  }
  if (exists) function_top = tmp_top;
  return exists;
}

void ExistsFunction(attributes a) {
  if (!ExistsFunctionID(a.lexeme))
    fprintf(stderr, "Line %d. Semantic error: Function '%s' does not exists, or out of scope.\n",
            current_line, a.lexeme);
}

unsigned int AssignFunctionType(char *id) {
  unsigned int type = unknown;
  if (ExistsFunctionID(id)) type = ST[function_top].data_type;
  return type;
}
void CheckParenthesis(unsigned int num) {
  int tmp_top = function_top;
  if (ExistsFunctionID(function_id)) {
    if (ST[tmp_top].parameters != num) {
      fprintf(stderr, "Line %d. Semantic error: Function '%s' has wrong number of parameters.\n",
              current_line, ST[tmp_top].name);
    }
  }
}
void CheckParameters(attributes a, unsigned int pos) {
  int tmp_top = function_top;
  if (ExistsFunctionID(function_id)) {
    if (pos <= ST[tmp_top].parameters) {
      if (ST[tmp_top + pos].data_type == real && a.type == integer) {
        a.type = real;
      }
      if (ST[tmp_top].parameters == 0) {
        fprintf(stderr, "Line %d. Semantic error: '%s' does not have parameters.\n", current_line,
                ST[tmp_top].name);
      } else if (ST[tmp_top + pos].data_type != a.type) {
        fprintf(stderr, "Line %d. Semantic error: incompatible type of parameter %d..\n",
                current_line, pos);
      }
    }
  }
}


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

block : LEFT_BRACE { InsertMark(); } local_var_declaration sub_programs_declaration sentences { EmptySymbolTable(); }RIGHT_BRACE

sub_programs_declaration : sub_programs_declaration sub_program
                         | ;

sub_program : subprogram_header {sub_program = 1;} block {sub_program = 0;};

subprogram_header : TYPE ID LEFT_PAR {AddSubProgram($1, $2);} parameters RIGHT_PAR
                  | TYPE ID LEFT_PAR RIGHT_PAR {AddSubProgram($1, $2);};

parameters : parameters COMMA TYPE ID {AddFormalParameter($4);}
           | TYPE ID {AddFormalParameter($2);}
           | error;

local_var_declaration : LVDS {variable_declarations = 1;} local_var_declarations {variable_declarations = 0;} LVDE
				              | ;

local_var_declarations : local_var_declarations var_declaration
                       | var_declaration;

var_declaration : TYPE {tmp_type = $1.type; tmp_array_type = $1.type_array;} var_list SEMICOLON
                | error;

var_list : var_list COMMA id_or_array_id {if(variable_declarations)AddID($3);}
         | id_or_array_id {if(variable_declarations)AddID($1);}
         | error;

id_or_array_id : ID
               | array_id;

array_id : ID LEFT_BRACKET CONSTANT RIGHT_BRACKET {tmp_type = array;}
         | ID LEFT_BRACKET CONSTANT COMMA CONSTANT RIGHT_BRACKET 	{tmp_type = array;};

id_or_array_position : ID {$$.type=AssignType($1); strcpy($$.lexeme,$1.lexeme);}
					           | ID LEFT_BRACKET expression RIGHT_BRACKET {	$$.type=AssignArrayType($1); strcpy($$.lexeme,$1.lexeme);}
					           | ID LEFT_BRACKET expression COMMA expression RIGHT_BRACKET {	$$.type=AssignArrayType($1);strcpy($$.lexeme,$1.lexeme);};

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

assign : id_or_array_position ASSIGN expression SEMICOLON {$1.type = AssignType($1);
																			   $1.type_array = AssignArrayType($1);
																			   strcpy($1.lexeme,$1.lexeme);
																				 $$.type = CheckAssignType($1,$2,$3);};

if : IF LEFT_PAR expression RIGHT_PAR sentence {CheckLogicExpression($3);}
   | IF LEFT_PAR expression RIGHT_PAR sentence else {CheckLogicExpression($3);};

else : ELSE sentence;

while : WHILE LEFT_PAR expression RIGHT_PAR LEFT_BRACE sentences RIGHT_BRACE {CheckLogicExpression($3);};

do_until : DO expression UNTIL LEFT_PAR expression RIGHT_PAR SEMICOLON {CheckLogicExpression($5);};

input : INPUT var_list SEMICOLON;

output : OUPUT expression SEMICOLON;

return : RETURN expression SEMICOLON;

expression_list : expression_list COMMA expression {if(func){	param_position++; CheckParameters($3, param_position);}}
                | expression {if(func){ param_position++; CheckParameters($1,param_position);}};

expression : LEFT_PAR expression RIGHT_PAR {$$ = $2;}
           | UNARY_OPERATOR expression { $$.type = CheckUnaryType($1, $2);}
           | expression BINARY_OPERATOR expression {$$.type = CheckBynaryTypes($1, $2, $3);}
           | expression PLUS_OR_MINUS_OPERATOR expression {$$.type = CheckBynaryTypes($1, $2, $3);}
           | PLUS_OR_MINUS_OPERATOR expression { $$.type = CheckUnaryType($1, $2);}
           | id_or_array_position {$$.type = AssignType($1); $$.type_array = AssignArrayType($1); strcpy($$.lexeme,$1.lexeme);}
           | CONSTANT {$$.type = $1.type; if($$.type == array)$$.type_array = $1.type_array; }
           | STRING
           | aggregate
           | function_call
           | error;

constants_list: constants_list COMMA CONSTANT
              | constants_list SEMICOLON CONSTANT
              | CONSTANT;

aggregate : LEFT_BRACKET constants_list RIGHT_BRACKET;

function_call : ID LEFT_PAR {strcpy(function_id, $1.lexeme);
                             func=1; ExistsFunction($1);}
                             expression_list RIGHT_PAR {func=0;
                                                       CheckParenthesis(param_position);
                                                       param_position=0;$$.type = AssignFunctionType(function_id);}
							| ID LEFT_PAR {strcpy(function_id, $1.lexeme); func=1; ExistsFunction($1);} RIGHT_PAR;

%%

#include "lex.yy.c"

void yyerror(const char* s) {
  fprintf(stderr, "Line %d. Parse error: %s\n", current_line, s);
}
