%{
  X
#include
#include "karel.h"

extern int condbranch(), branch(), call(), bltin(), loopexec();
char instname[BUFSIZ];
Symbol *sp;

%}

%start prog
 /* Karel keywords */

%token AS BEGEXEC BEGIN BEGPROG DEFINST DO ELSE END ENDEXEC
%token ENDPROG IF ITERATE THEN TIMES WHILE

 /* interpreter types */

%token KEY BLTIN TEST NUMBER NAME


%% /* beginning of rules */


prog : BEGPROG deflist begexec stmtlist ENDEXEC ENDPROG {
  X startaddr = $3;
 code(RETURN);
 }
 | prog error
 { yyerrok; }
 ;

begexec : BEGEXEC {
  X strcpy(instname, "");
 fprintf(stderr, "main block:\n");
 $$ = progp;
 }
 ;

deflist : def
 | deflist ';' def
 ;

def : /* nothing */
 | definst AS stmt
 { code(RETURN); }
 ;

definst : DEFINST NAME {
  X strcpy(instname, yytext);
 fprintf(stderr, "%s:\n", instname);
 install(instname);
 }
 | DEFINST BLTIN
 { err("tried to redefine primitive instruction:",
 yytext); }
 | DEFINST TEST
 { err("tried to redefine logical test:", yytext); }
 ;

stmtlist : stmt
 | stmtlist ';' stmt
 ;

stmt : BEGIN stmtlist END
 | IF logictest THEN stmt {
  X setcode($2 + 1, condbranch);
 setcodeint($2 + 2, progp);
 }
 | IF logictest THEN stmt else stmt {
  X setcode($2 + 1, condbranch);
 setcodeint($2 + 2, $5 + 1);
 setcodeint($5, progp);
 }
 | iterate TIMES stmt {
  X code(RETURN);
 setcodeint($1, progp);
 }
 | WHILE logictest DO stmt {
  X setcode($2 + 1, condbranch);
 setcodeint($2 + 2, progp + 2);
 code(branch);
 codeint($2);
 }
 | NAME {
  X if ((sp = lookup(yytext)) == (Symbol *) 0)
 err(yytext, "undefined");
 else {
  X if (strcmp(yytext, instname) == 0)
 err("recursive procedure call:",
 yytext);
 else {
  X code(call);
 codeint(sp->addr);
 }
 }
 }
 | BLTIN {
  X if (strcmp(yytext, "turnoff") == 0)
 gotturnoff = 1;
 code(bltins[tokenid].func);
 }
 | error
 ;

logictest : TEST {
  X $$ = progp;
 code(bltins[tokenid].func);
 codeint(0); /* leave room for branch */
 codeint(0); /* instruction and address */
 }
 | NAME
 { err("invalid logical test:", yytext); }
 | BLTIN
 { err("invalid logical test:", yytext); }
 ;

else : ELSE {
  X code(branch);
 $$ = progp;
 codeint(0);
 };

iterate : ITERATE NUMBER {
  X code(loopexec);
 codeint(atoi(yytext));
 $$ = progp;
 codeint(0);
 }
 ;
