%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char* s);

int linea_actual = 1;
int linea_control;
typedef enum {
  marca,
  marca_condicional,
  funcion,
  variable,
  parametro_formal
} tipoEntrada;
typedef enum {
  entero,
  real,
  caracter,
  booleano,
  lista,
  desconocido,
  no_asignado
} dtipo;
typedef struct {
  tipoEntrada entrada;
  char *nombre;
  dtipo tipoDato;
  dtipo tipoDatoLista;
  unsigned int parametros;
} entradaTS;

#define MAX_TS 500
unsigned int TOPE = -1, topeF; /* Tope de la pila */
unsigned int subProg = 0,
             decVar = 0; /* Indicador de comienzo de bloque de un subprog */
unsigned int func = 0, posParam = 0;
char idFuncion[100];
entradaTS TS[MAX_TS]; /* Pila de la tabla de símbolos */
dtipo tipoTMP, tipoListaTMP;

typedef struct {
  int atrib;       /* Atributo del símbolo (si tiene) */
  char *lexema;    /* Nombre del lexema */
  dtipo tipo;      /* Tipo del símbolo */
  dtipo tipoLista; /* Si tipo es lista, tipo de la lista */
} atributos;
#define YYSTYPE atributos /* A partir de ahora, cada símbolo tiene */
                          /* una estructura de tipo atributos */
/* Lista de funciones y procedimientos para manejo de la TS */
void TS_InsertaMARCA() {
  TOPE++;
  if (subProg == 1) {
    TS[TOPE].entrada = marca;
    TS[TOPE].nombre = "MARCA_INICIAL";
    int topeTMP = TOPE;
    while (TS[topeTMP].entrada != funcion && topeTMP > 0) {
      if (TS[topeTMP].entrada == parametro_formal) {
        TOPE++;
        TS[TOPE].entrada = variable;
        TS[TOPE].nombre = TS[topeTMP].nombre;
        TS[TOPE].tipoDato = TS[topeTMP].tipoDato;
        if (TS[TOPE].tipoDato == lista)
          TS[TOPE].tipoDatoLista = TS[topeTMP].tipoDatoLista;
      }
      topeTMP--;
    }
  } else {
    TS[TOPE].entrada = marca_condicional;
    TS[TOPE].nombre = "MARCA_CONDICIONAL";
  }
}
void TS_VaciarENTRADAS() {
  while (TS[TOPE].entrada != marca && TS[TOPE].entrada != marca_condicional) {
    TOPE--;
  }
  TOPE--;
}
int existeVar(atributos a) {
  int topeTMP = TOPE;
  while (topeTMP >= 0) {
    // printf("%s %s\n", TS[topeTMP].nombre, a.lexema);
    if (TS[topeTMP].entrada == variable &&
        strcmp(TS[topeTMP].nombre, a.lexema) == 0) {
      return 1;
    }
    topeTMP--;
  }
  return 0;
}
int existeID(atributos a) {
  int topeTMP = TOPE;
  while (TS[topeTMP].entrada != marca &&
         TS[topeTMP].entrada != marca_condicional && topeTMP >= 0) {
    if (strcmp(TS[topeTMP].nombre, a.lexema) == 0) {
      return 1;
    }
    topeTMP--;
  }
  return 0;
}
void TS_InsertaIDENT(atributos a) {
  // printf("%d\n", a.tipo);
  if (existeID(a))
    fprintf(stderr, "[Linea %d]: %s: existe.\n", linea_actual, a.lexema);
  else {
    TOPE++;
    TS[TOPE].entrada = variable;
    TS[TOPE].nombre = a.lexema;
    TS[TOPE].tipoDato = tipoTMP;
    if (tipoTMP == lista) TS[TOPE].tipoDatoLista = tipoListaTMP;
  }
  // printf("ID: %s TIPO: %d\n", a.lexema, tipoTMP);
}
void TS_InsertaSUBPROG(atributos t, atributos a) {
  TOPE++;
  TS[TOPE].entrada = funcion;
  TS[TOPE].nombre = a.lexema;
  TS[TOPE].parametros = 0;
  TS[TOPE].tipoDato = t.tipo;
}
void TS_InsertaPARAMF(atributos a) {
  TOPE++;
  TS[TOPE].entrada = parametro_formal;
  TS[TOPE].nombre = a.lexema;
  TS[TOPE].tipoDato = a.tipo;
  if (a.tipo == lista) TS[TOPE].tipoDatoLista = a.tipoLista;
  int topeTMP = TOPE;
  while (TS[topeTMP].entrada != funcion && topeTMP >= 0) {
    topeTMP--;
  }
  TS[topeTMP].parametros++;
}
void comprobarExprLogica(atributos a) {
  if (a.tipo != booleano)
    fprintf(stderr, "[Linea %d]: no hay expresion tipo logica.\n",
            linea_control);
}
void comprobarExprLista(atributos a) {
  if (a.tipo != lista)
    fprintf(stderr, "[Linea %d]: el argumento no es de tipo lista.\n",
            linea_actual);
}
unsigned int asignaTipo(atributos a) {
  int topeTMP = TOPE;
  int existe = 0;
  unsigned int tipo = desconocido;
  // printf("tipo=%d",a.tipo);
  if (existeVar(a)) {
    while (existe == 0 && topeTMP >= 0) {
      if (!strcmp(TS[topeTMP].nombre, a.lexema)) {
        existe = 1;
        tipo = TS[topeTMP].tipoDato;
      }
      topeTMP--;
    }
    // printf("%s %d %d\n", a.lexema, a.tipo, tipo);
  } else
    fprintf(stderr, "[Linea %d]: %s: no definida.\n", linea_actual, a.lexema);
  return tipo;
}
unsigned int asignaTipoLista(atributos a) {
  int topeTMP = TOPE;
  int existe = 0;
  unsigned int tipo = desconocido;
  if (existeVar(a)) {
    while (existe == 0 && topeTMP >= 0) {
      if (!strcmp(TS[topeTMP].nombre, a.lexema)) {
        existe = 1;
        tipo = TS[topeTMP].tipoDatoLista;
      }
      topeTMP--;
    }
  }
  return tipo;
}
unsigned int comprobarTipoASSIGN(atributos a, atributos op, atributos b) {
  // printf("[Linea %d] %s %d | %s %d\n", linea_actual, a.lexema, asignaTipo(a),
  // b.lexema, b.tipo);
  unsigned int tipo = desconocido;
  int error = 0;
  if (existeVar(a) && b.tipo != desconocido) {
    tipo = asignaTipo(a);
    if (tipo != b.tipo) {
      if ((tipo == real || tipo == entero) &&
          (b.tipo == real || b.tipo == entero)) {
        error = 0;
      } else
        error = 1;
    } else if (tipo == lista) {
      unsigned int tipoLista = asignaTipoLista(a);
      if (tipoLista != b.tipoLista) error = 1;
    }
  }

  if (error && b.tipo != desconocido)
    fprintf(stderr, "[Linea %d]: tipos incompatibles al asignar.\n",
            linea_actual);
  return tipo;
}
unsigned int real_entero2(dtipo t1, dtipo t2) {
  if ((t1 == real || t1 == entero) && (t2 == real || t2 == entero)) return 1;
  return 0;
}
unsigned int real_entero(dtipo t) {
  if (t == real || t == entero) return 1;
  return 0;
}
unsigned int comprobarTipoBIN(atributos a, atributos op, atributos b) {
  // printf("[Linea %d] %s %d | %s %d\n", linea_actual, a.lexema, asignaTipo(a),
  // b.lexema, b.tipo);
  unsigned int tipo = op.tipo;
  int error = 1;
  switch (op.atrib) {
    case 0:  // -
    case 3:  // /
      if (a.tipo == lista && real_entero(b.tipo))
        error = 0;
      else
        error = !real_entero2(a.tipo, b.tipo);
      break;
    case 1:  // +
    case 2:  // *
      if (a.tipo == lista && real_entero(b.tipo)) {
        error = 0;
        tipo = lista;
      } else if (real_entero(a.tipo) && b.tipo == lista) {
        error = 0;
        tipo = entero;
      } else
        error = !real_entero2(a.tipo, b.tipo);
      break;
    case 4:   // &
    case 5:   // |
    case 6:   // ^
    case 7:   // >
    case 8:   // <
    case 9:   // >=
    case 10:  // <=
      error = !real_entero2(a.tipo, b.tipo);
      break;

    case 13:  // ||
    case 14:  // &&
      if (a.tipo == booleano && b.tipo == booleano) error = 0;
      break;
    case 15:  // %
    case 16:  // --
    case 18:  // @

      if (a.tipo == lista && b.tipo == entero) error = 0;
      break;
    case 19:  // ++
      if (a.tipo == lista &&
          (a.tipoLista == b.tipo || real_entero2(a.tipoLista, b.tipo)))
        error = 0;
      break;
    case 17:  // **
      if (a.tipo == lista && b.tipo == lista) error = 0;
      break;
    case 11:  // ==
    case 12:  // !=
    default:
      if (a.tipo != b.tipo) {
        error = !real_entero2(a.tipo, b.tipo);
      } else
        error = 0;
  }
  if (error && a.tipo != desconocido && b.tipo != desconocido)
    fprintf(stderr, "[Linea %d]: tipos incompatibles al operar.\n",
            linea_actual);
  return tipo;
}
unsigned int comprobarTipoUNIT(atributos op, atributos a) {
  // printf("[Linea %d] %s %d | %s %d\n", linea_actual, a.lexema, a.tipo,
  // op.lexema, op.tipo);
  unsigned int tipo = 0;
  int error = 1;
  switch (op.atrib) {
    case 0:  // ~a
      if (a.tipo == real || a.tipo == entero) {
        tipo = a.tipo;
        error = 0;
      }
      break;
    case 1:  // !a
      if (a.tipo == booleano) {
        tipo = booleano;
        error = 0;
      }
      break;

    case 2:  // #l
      if (a.tipo == lista) {
        tipo = entero;
        error = 0;
      }
      break;
    case 3:  // ?l
      if (a.tipo == lista) {
        tipo = a.tipoLista;
        error = 0;
      }
      break;
  }

  if (error && a.tipo != desconocido)
    fprintf(stderr, "[Linea %d]: tipo incompatible en la operacion sobre.\n ",
            linea_actual);
  return tipo;
}
unsigned int existeFuncionID(char *id) {
  int topeTMP = TOPE, existe = 0;

  while (topeTMP >= 0 && existe == 0) {
    if (TS[topeTMP].entrada == funcion && !strcmp(id, TS[topeTMP].nombre))
      existe = 1;
    else
      topeTMP--;
  }
  if (existe) topeF = topeTMP;
  return existe;
}
void existeFuncion(atributos a) {
  if (!existeFuncionID(a.lexema))
    fprintf(stderr, "[Linea %d]: %s: no existe o fuera de ambito.\n",
            linea_actual, a.lexema);
}
unsigned int asignaTipoFuncion(char *id) {
  unsigned int tipo = desconocido;
  // printf("%s, %d\n", TS[topeF].nombre, TS[topeF].tipoDato);
  if (existeFuncionID(id)) tipo = TS[topeF].tipoDato;
  return tipo;
}
void verificaNumPar(unsigned int num) {
  int topeTMP = topeF;
  if (existeFuncionID(idFuncion)) {
    if (TS[topeTMP].parametros != num) {
      fprintf(stderr, "[Linea %d]: %s: numero de  parametros incorrecto.\n",
              linea_actual, TS[topeTMP].nombre);
    }
  }
}
void verificaParam(atributos a, unsigned int pos) {
  int topeTMP = topeF;
  if (existeFuncionID(idFuncion)) {
    if (pos <= TS[topeTMP].parametros) {
      if (TS[topeTMP + pos].tipoDato == real && a.tipo == entero) {
        a.tipo = real;
      }
      // printf("param: %d: ,tipo = %d. lexema:%s, tipo= %d
      // \n",pos,TP[topeTMP+pos].tipoDato,a.lexema,a.tipo);
      if (TS[topeTMP].parametros == 0) {
        fprintf(stderr, "[Linea %d]: %s: no tiene parametros.\n", linea_actual,
                TS[topeTMP].nombre);
      } else if (TS[topeTMP + pos].tipoDato != a.tipo) {
        fprintf(stderr, "[Linea %d]: tipo del parametro %d incompatible.\n",
                linea_actual, pos);
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

block : LEFT_BRACE { TS_InsertaMARCA(); } local_var_declaration sub_programs_declaration sentences { TS_VaciarENTRADAS(); }RIGHT_BRACE

sub_programs_declaration : sub_programs_declaration sub_program
                         | ;

sub_program : subprogram_header {subProg = 1;} block {subProg = 0;};

subprogram_header : TYPE ID LEFT_PAR {TS_InsertaSUBPROG($1, $2);} parameters RIGHT_PAR
                  | TYPE ID LEFT_PAR RIGHT_PAR {TS_InsertaSUBPROG($1, $2);};

parameters : parameters COMMA TYPE ID {TS_InsertaPARAMF($4);}
           | TYPE ID {TS_InsertaPARAMF($2);}
           | error;

local_var_declaration : LVDS { decVar = 1; } local_var_declarations { decVar = 0; } LVDE
				              | ;

local_var_declarations : local_var_declarations var_declaration
                       | var_declaration;

var_declaration : TYPE {tipoTMP = $1.tipo; tipoListaTMP = $1.tipoLista;} var_list SEMICOLON
                | error;

var_list : var_list COMMA id_or_array_id {if(decVar)TS_InsertaIDENT($3);}
         | id_or_array_id {if(decVar)TS_InsertaIDENT($1);}
         | error;

id_or_array_id : ID
               | array_id;

array_id : ID LEFT_BRACKET CONSTANT RIGHT_BRACKET {$$.tipo=asignaTipoLista($1); strcpy($$.lexema,$1.lexema);}
         | ID LEFT_BRACKET CONSTANT COMMA CONSTANT RIGHT_BRACKET 	{$$.tipo=asignaTipoLista($1); strcpy($$.lexema,$1.lexema);};

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

assign : ID ASSIGN expression SEMICOLON {$1.tipo = asignaTipo($1);
																			   $1.tipoLista = asignaTipoLista($1);
																			   strcpy($1.lexema,$1.lexema);
																				 $$.tipo = comprobarTipoASSIGN($1,$2,$3);};

if : IF LEFT_PAR expression RIGHT_PAR sentence {comprobarExprLogica($3);}
   | IF LEFT_PAR expression RIGHT_PAR sentence else {comprobarExprLogica($3);};

else : ELSE sentence;

while : WHILE LEFT_PAR expression RIGHT_PAR LEFT_BRACE sentences RIGHT_BRACE {comprobarExprLogica($3);};

do_until : DO expression UNTIL LEFT_PAR expression RIGHT_PAR SEMICOLON {comprobarExprLogica($5);};

input : INPUT var_list SEMICOLON;

output : OUPUT expression SEMICOLON;

return : RETURN expression SEMICOLON;

expression_list : expression_list COMMA expression {if(func){	posParam++; verificaParam($3, posParam);}}
                | expression {if(func){ posParam++; verificaParam($1,posParam);}};

expression : LEFT_PAR expression RIGHT_PAR {$$ = $2;}
           | UNARY_OPERATOR expression { $$.tipo = comprobarTipoUNIT($1, $2);}
           | expression BINARY_OPERATOR expression {$$.tipo = comprobarTipoBIN($1, $2, $3);}
           | expression PLUS_OR_MINUS_OPERATOR expression {$$.tipo = comprobarTipoBIN($1, $2, $3);}
           | PLUS_OR_MINUS_OPERATOR expression { $$.tipo = comprobarTipoUNIT($1, $2);}
           | id_or_array_id {$$.tipo = asignaTipo($1); $$.tipoLista = asignaTipoLista($1); strcpy($$.lexema,$1.lexema);}
           | CONSTANT {$$.tipo = $1.tipo; if($$.tipo == lista)$$.tipoLista = $1.tipoLista; }
           | STRING
           | aggregate
           | function_call
           | error;

constants_list: constants_list COMMA CONSTANT
              | constants_list SEMICOLON CONSTANT
              | CONSTANT;

aggregate : LEFT_BRACKET constants_list RIGHT_BRACKET;

function_call : ID LEFT_PAR {strcpy(idFuncion,$1.lexema); func=1; existeFuncion($1);} expression_list RIGHT_PAR {func=0; verificaNumPar(posParam); posParam=0;$$.tipo = asignaTipoFuncion(idFuncion);}
							| ID LEFT_PAR {strcpy(idFuncion,$1.lexema); func=1; existeFuncion($1);} RIGHT_PAR;

%%

#include "lex.yy.c"

void yyerror(const char* s) {
  fprintf(stderr, "Line %d. Parse error: %s\n", linea_actual, s);
}
