#include <stdio.h>
#include <stdlib.h>

extern "C" int yyparse (void);
extern FILE *yyin;

FILE *open_input(int argc, char *argv[]) {
    FILE *f= NULL;
    if (argc > 1) {
        f = fopen(argv[1],"r");
        if (f==NULL) {
            fprintf(stderr,"File ’%s’ not found\n",argv[1]);
            exit(1);
        } else printf("Reading file: %s.\n",argv[1]);
    } else printf("Reading standard input.\n");

    return f;
}

int main( int argc, char *argv[] ){
    yyin = open_input(argc,argv);
    return yyparse();
}
