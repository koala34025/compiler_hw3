%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "function.h"

int yylex();
void yyerror(char *s);

%}

%union {
    int intVal;
    double douVal;
    char* strVal;
}

%token <strVal> TYPECONST TYPESIGNED TYPEUNSIGNED TYPELONG TYPESHORT TYPEINT TYPECHAR TYPEFLOAT TYPEDOUBLE TYPEVOID

%token <strVal> IF ELSE
%token <strVal> SWITCH CASE DEFAULT
%token <strVal> WHILE DO
%token <strVal> FOR
%token <strVal> RETURN BREAK CONTINUE
%token <strVal> NUL

%token <strVal> ID
%token <intVal> INT
%token <douVal> DOUBLE
%token <strVal> CHAR
%token <strVal> STRING

%token <strVal> '+' '-' '*' '/' '%' '=' '!' '~' '^' '&' '|' '<' '>'
%token <strVal> ':' ';' ',' '.' '[' ']' '(' ')' '{' '}'
%token <strVal> INC DEC 
%token <strVal> LESSEQUAL GREATEREQUAL EQUAL NOTEQUAL
%token <strVal> AND OR
%token <strVal> RSHIFT LSHIFT

%token <strVal> CODEGEN DIGITALWRITE DELAY HIGH LOW
%token <strVal> EXTDSPCODEGEN TYPEUINT32 __RV__UKADD8 __RV__CMPEQ8 __RV__UCMPLT8 __RV__UKSUB8

%start S
%type <strVal> program var_decl
%type <strVal> scalar_decl
%type <strVal> array_decl
%type <strVal> func_decl
%type <strVal> func_defin
%type <strVal> compound_statement stmts_and_var_decls stmt
%type <strVal> if_stmt
%type <strVal> switch_stmt switch_clauses switch_clause switch_stmts
%type <strVal> while_stmt
%type <strVal> for_stmt for_init for_cond for_update
%type <strVal> return_stmt

%type <strVal> codegen_decl codegen_defin digital_write_stmt delay_stmt
%type <intVal> expr expr_p14 expr_p12 expr_p11 expr_p10 expr_p9 expr_p8 expr_p7 expr_p6 expr_p5 expr_p4 expr_p3 expr_p2 expr_p1 terminal
%type <intVal> type

%%

S: program {}
 ;

//--------------------------------------------//

// program := program var_decl
//          | program func_decl
//          | program func_defin
//          | ε
program
    : program var_decl {}
    | program codegen_decl {}
    | program codegen_defin {}
    | program func_decl {}
    | program func_defin {}
    | /* ε */ {}
    ;

// var_decl := scalar_decl
//           | array_decl
var_decl: scalar_decl {}
        | array_decl {}
        ;

//--------------------------------------------//

// scalar_decl := type indents ';'
scalar_decl
    : type ID ';' {
        install_symbol($2);
        set_local_vars($2);
        set_type($2, $1);
    }
    | type ID '=' expr ';' {
        install_symbol($2);
        set_local_vars($2);
        set_type($2, $1);
        // t0 = expr (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // ID = t0
        fprintf(codegen, "sw t0, %d(fp)\n", get_byte_offset($2));
        fprintf(codegen, "\n");
    }
    | type ID '=' expr ',' {
        install_symbol($2);
        set_local_vars($2);
        set_type($2, $1);
        // t0 = expr (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // ID = t0
        fprintf(codegen, "sw t0, %d(fp)\n", get_byte_offset($2));
        fprintf(codegen, "\n");
    } '*' ID '=' expr ';' {
        install_symbol($8);
        set_local_vars($8);
        set_type($8, $1);
        // t0 = expr (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // ID = t0
        fprintf(codegen, "sw t0, %d(fp)\n", get_byte_offset($8));
        fprintf(codegen, "\n");
    }
    | type ID '=' expr ',' {
        install_symbol($2);
        set_local_vars($2);
        set_type($2, $1);
        // t0 = expr (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // ID = t0
        fprintf(codegen, "sw t0, %d(fp)\n", get_byte_offset($2));
        fprintf(codegen, "\n");
    } ID '=' expr ';' {
        install_symbol($7);
        set_local_vars($7);
        set_type($7, $1);
        // t0 = expr (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // ID = t0
        fprintf(codegen, "sw t0, %d(fp)\n", get_byte_offset($7));
        fprintf(codegen, "\n");
    }
    ;

type
    : TYPEINT {
        $$ = T_INT;
    }
    | TYPECONST TYPEINT {
        $$ = T_INT;
    }
    | TYPEINT '*' {
        $$ = T_POINTER;
    }
    | TYPECONST TYPEINT '*' {
        $$ = T_POINTER;
    }
    | TYPEUINT32 {
        $$ = T_INT;
    }
    ;

//--------------------------------------------//

// array_decl := type arrays ';'
array_decl
    : type ID '[' INT ']' ';' {
        install_symbol($2);
        set_local_vars($2);
        set_type($2, T_POINTER);
        for (int i = 0; i < $4; i++) {
            install_symbol("");
            set_local_vars("");
            set_type("", $1);
        }
        // t0 = ID[0]'s address
        fprintf(codegen, "addi t0, fp, %d\n", get_byte_offset($2) - 4);
        // ID = t0
        fprintf(codegen, "sw t0, %d(fp)\n", get_byte_offset($2));
    }
    ;

//--------------------------------------------//

codegen_decl
    : TYPEVOID CODEGEN '(' ')' ';' {
        install_symbol($2);
        set_global_vars($2);
        $$ = $2;
    }
    | type EXTDSPCODEGEN '(' type ID ',' type ID ')' ';' {
        install_symbol($2);
        set_global_vars($2);
        $$ = $2;
    }
    ;

codegen_defin
    : TYPEVOID CODEGEN '(' ')' '{' {
        cur_exe_func = strdup($2);
        cur_scope++;
        set_scope_and_offset_of_param($2, 0);
        /* Section A */
        fprintf(codegen, ".global %s\n", $2);
        fprintf(codegen, "%s:\n", $2);
        // move sp, save ra, save old fp, move fp
        fprintf(codegen, "addi sp, sp, %d\n", -FRAME_SIZE);
        fprintf(codegen, "sw ra, %d(sp)\n", FRAME_SIZE-4);
        fprintf(codegen, "sw fp, %d(sp)\n", FRAME_SIZE-8);
        fprintf(codegen, "addi fp, sp, %d\n", FRAME_SIZE);
        fprintf(codegen, "\n");
    } stmts_and_var_decls {
        /* Section B */
        // restore ra, restore old fp, remove the frame
        fprintf(codegen, "lw ra, %d(sp)\n", FRAME_SIZE-4);
        fprintf(codegen, "lw fp, %d(sp)\n", FRAME_SIZE-8);
        fprintf(codegen, "addi sp, sp, %d\n", FRAME_SIZE);
        fprintf(codegen, "jr ra\n");
        fprintf(codegen, "\n");
        pop_up_symbol(cur_scope);
        cur_scope--;
    } '}'
    | type EXTDSPCODEGEN '(' type ID ',' type ID ')' '{' {
        cur_exe_func = strdup($2);
        cur_scope++;
        install_symbol($5); set_type($5, $4);
        install_symbol($8); set_type($8, $7);
        set_scope_and_offset_of_param($2, 2);
        /* Section A */
        fprintf(codegen, ".global %s\n", $2);
        fprintf(codegen, "%s:\n", $2);
        // move sp, save ra, save old fp, move fp
        fprintf(codegen, "addi sp, sp, %d\n", -FRAME_SIZE);
        fprintf(codegen, "sw ra, %d(sp)\n", FRAME_SIZE-4);
        fprintf(codegen, "sw fp, %d(sp)\n", FRAME_SIZE-8);
        fprintf(codegen, "addi fp, sp, %d\n", FRAME_SIZE);
        // push the arguments onto the stack
        fprintf(codegen, "sw a0, %d(fp)\n", -12);
        fprintf(codegen, "sw a1, %d(fp)\n", -16);
        fprintf(codegen, "\n");
    } stmts_and_var_decls {
        pop_up_symbol(cur_scope);
        cur_scope--;
    } '}' {
        $$ = $2;
    }
    ;
//--------------------------------------------//

// func_decl := type ident '(' parameters ')' ';'
//            | type '*' ident '(' parameters ')' ';'
func_decl
    : type ID '(' type ID ',' type ID ')' ';' {
        install_symbol($2);
        set_global_vars($2);
        $$ = $2;
    }
    ;

//--------------------------------------------//

// func_defin := type ident '(' parameters ')' compound_statement
//             | type '*' ident '(' parameters ')' compound_statement
func_defin
    : type ID '(' type ID ',' type ID ')' '{' {
        cur_exe_func = strdup($2);
        cur_scope++;
        install_symbol($5); set_type($5, $4);
        install_symbol($8); set_type($8, $7);
        set_scope_and_offset_of_param($2, 2);
        /* Section A */
        fprintf(codegen, ".global %s\n", $2);
        fprintf(codegen, "%s:\n", $2);
        // move sp, save ra, save old fp, move fp
        fprintf(codegen, "addi sp, sp, %d\n", -FRAME_SIZE);
        fprintf(codegen, "sw ra, %d(sp)\n", FRAME_SIZE-4);
        fprintf(codegen, "sw fp, %d(sp)\n", FRAME_SIZE-8);
        fprintf(codegen, "addi fp, sp, %d\n", FRAME_SIZE);
        // push the arguments onto the stack
        fprintf(codegen, "sw a0, %d(fp)\n", -12);
        fprintf(codegen, "sw a1, %d(fp)\n", -16);
        fprintf(codegen, "\n");
    } stmts_and_var_decls {
        pop_up_symbol(cur_scope);
        cur_scope--;
    } '}' {
        $$ = $2;
    }
    ;

//--------------------------------------------//

// expr := expr_p14
expr: expr_p14 {}
    ;

// expr_p14 := expr_p12 '=' expr_p14
//           | expr_p12
expr_p14
    : terminal '=' expr_p14 {
        // t0 = expr (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t1 = variable (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // *variable = t0
        fprintf(codegen, "sw t0, 0(t1)\n");
        fprintf(codegen, "\n");
        $$ = $1;
    }
    | expr_p12 {}
    ;

// expr_p12 := expr_p12 '||' expr_p11
//           | expr_p11
expr_p12: expr_p12 OR expr_p11 {}
        | expr_p11 {   }
        ;

// expr_p11 := expr_p11 '&&' expr_p10
//           | expr_p10
expr_p11: expr_p11 AND expr_p10 {}
        | expr_p10 {   }
        ;

// expr_p10 := expr_p10 '|' expr_p9
//           | expr_p9
expr_p10: expr_p10 '|' expr_p9 {}
        | expr_p9 {   }
        ;

// expr_p9 := expr_p9 '^' expr_p8
//          | expr_p8
expr_p9: expr_p9 '^' expr_p8 {}
       | expr_p8 {   }
       ;

// expr_p8 := expr_p8 '&' expr_p7
//          | expr_p7
expr_p8: expr_p8 '&' expr_p7 {}
       | expr_p7 {   }
       ;

// expr_p7 := expr_p7 '==' expr_p6
//          | expr_p7 '!=' expr_p6
//          | expr_p6
expr_p7
    : expr_p7 EQUAL expr_p6 {
        // t0 = expr2 (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t1 = expr1 (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t2 = (t1 == t0) ? 1 : 0
        fprintf(codegen, "xor t2, t1, t0\n");
        fprintf(codegen, "sltu t2, zero, t2\n");
        fprintf(codegen, "xori t2, t2, 1\n");
        // push t2
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t2, 0(sp)\n");
        $$ = $1;
    }
    | expr_p7 NOTEQUAL expr_p6 {
        // t0 = expr2 (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t1 = expr1 (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t2 = (t1 != t0) ? 1 : 0
        fprintf(codegen, "xor t2, t1, t0\n");
        fprintf(codegen, "sltu t2, zero, t2\n");
        // push t2
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t2, 0(sp)\n");
        $$ = $1;
    }
    | expr_p6 {}
    ;

// expr_p6 := expr_p6 '<' expr_p5
//          | expr_p6 '>' expr_p5
//          | expr_p6 '<=' expr_p5
//          | expr_p6 '>=' expr_p5
//          | expr_p5
expr_p6
    : expr_p6 '<' expr_p5 {
        // t0 = expr2 (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t1 = expr1 (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t2 = (t1 < t0) ? 1 : 0
        fprintf(codegen, "slt t2, t1, t0\n");
        // push t2
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t2, 0(sp)\n");
        $$ = $1;
    }
    | expr_p6 '>' expr_p5 {}
    | expr_p6 LESSEQUAL expr_p5 {}
    | expr_p6 GREATEREQUAL expr_p5 {}
    | expr_p5 {}
    ;

// expr_p5 := expr_p5 '<<' expr_p4
//          | expr_p5 '>>' expr_p4
//          | expr_p4
expr_p5: expr_p5 LSHIFT expr_p4 {}
       | expr_p5 RSHIFT expr_p4 {}
       | expr_p4 {}
       ;

// expr_p4 := expr_p4 '+' expr_p3
//          | expr_p4 '-' expr_p3
//          | expr_p3
expr_p4
    : expr_p4 '+' expr_p3 {
        if ($1 == T_POINTER) {
            // t0 = expr2 * 4 (pop)
            fprintf(codegen, "lw t0, 0(sp)\n");
            fprintf(codegen, "addi sp, sp, 4\n");
            fprintf(codegen, "slli t0, t0, 2\n");
            // t1 = expr1 (pop)
            fprintf(codegen, "lw t1, 0(sp)\n");
            fprintf(codegen, "addi sp, sp, 4\n");
            // t0 = t1 - t0
            fprintf(codegen, "sub t0, t1, t0\n");
            // push t0
            fprintf(codegen, "addi sp, sp, -4\n");
            fprintf(codegen, "sw t0, 0(sp)\n");
            fprintf(codegen, "\n");
        } else {
            // t0 = expr2 (pop)
            fprintf(codegen, "lw t0, 0(sp)\n");
            fprintf(codegen, "addi sp, sp, 4\n");
            // t1 = expr1 (pop)
            fprintf(codegen, "lw t1, 0(sp)\n");
            fprintf(codegen, "addi sp, sp, 4\n");
            // t0 = t1 + t0
            fprintf(codegen, "add t0, t1, t0\n");
            // push t0
            fprintf(codegen, "addi sp, sp, -4\n");
            fprintf(codegen, "sw t0, 0(sp)\n");
            fprintf(codegen, "\n");
        }
        $$ = $1;
    }
    | expr_p4 '-' expr_p3 {
        if ($1 == T_POINTER) {
            // t0 = expr2 * 4 (pop)
            fprintf(codegen, "lw t0, 0(sp)\n");
            fprintf(codegen, "addi sp, sp, 4\n");
            fprintf(codegen, "slli t0, t0, 2\n");
            // t1 = expr1 (pop)
            fprintf(codegen, "lw t1, 0(sp)\n");
            fprintf(codegen, "addi sp, sp, 4\n");
            // t0 = t1 + t0
            fprintf(codegen, "add t0, t1, t0\n");
            // push t0
            fprintf(codegen, "addi sp, sp, -4\n");
            fprintf(codegen, "sw t0, 0(sp)\n");
            fprintf(codegen, "\n");
        } else {
            // t0 = expr2 (pop)
            fprintf(codegen, "lw t0, 0(sp)\n");
            fprintf(codegen, "addi sp, sp, 4\n");
            // t1 = expr1 (pop)
            fprintf(codegen, "lw t1, 0(sp)\n");
            fprintf(codegen, "addi sp, sp, 4\n");
            // t0 = t1 - t0
            fprintf(codegen, "sub t0, t1, t0\n");
            // push t0
            fprintf(codegen, "addi sp, sp, -4\n");
            fprintf(codegen, "sw t0, 0(sp)\n");
            fprintf(codegen, "\n");
        }
        $$ = $1;
    }
    | expr_p3 {}
    ;

// expr_p3 := expr_p3 '*' expr_p2
//          | expr_p3 '/' expr_p2
//          | expr_p3 '%' expr_p2
//          | expr_p2
expr_p3
    : expr_p3 '*' expr_p2 {
        // t0 = expr2 (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t1 = expr1 (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t0 = t1 * t0
        fprintf(codegen, "mul t0, t1, t0\n");
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = $1;
    }
    | expr_p3 '/' expr_p2 {
        // t0 = expr2 (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t1 = expr1 (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t0 = t1 / t0
        fprintf(codegen, "div t0, t1, t0\n");
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = $1;
    }
    | expr_p3 '%' expr_p2 {}
    | expr_p2 {}
    ;

// expr_p2 := '++' expr_p2
//          | '--' expr_p2
//          | '+' expr_p2
//          | '-' expr_p2
//          | '!' expr_p2
//          | '~' expr_p2
//          | '(' type ')' expr_p2
//          | '(' type '*' ')' expr_p2
//          | '*' expr_p2
//          | '&' expr_p2
//          | expr_p1
expr_p2
    : INC expr_p2 {}
    | DEC expr_p2 {}
    | '+' expr_p2 {}
    | '-' expr_p2 {
        // t0 = expr (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t0 = -t0
        fprintf(codegen, "sub t0, zero, t0\n");
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = $2;
    }
    | '!' expr_p2 {}
    | '~' expr_p2 {}
    | '(' type ')' expr_p2 {}
    | '&' terminal {
        $$ = $2;
    }
    | expr_p1 {}
    ;

// expr_p1 := expr_p1 '++'
//          | expr_p1 '--'
//          | expr_p1 '(' args ')'
//          | terminal
expr_p1
    : expr_p1 INC {}
    | expr_p1 DEC {}
    | ID '(' expr ',' expr ')' {
        /* Section C */
        // a1 = expr2 (pop)
        fprintf(codegen, "lw a1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // a0 = expr1 (pop)
        fprintf(codegen, "lw a0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // call ID()
        fprintf(codegen, "jal ra, %s\n", $1);
        fprintf(codegen, "\n");
        /* Section D */
        // push the function return value onto stack
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw a0, 0(sp)\n");
        $$ = T_INT;
    }
    | __RV__UKADD8 '(' expr ',' expr ')' {
        // t0 = expr2 (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t1 = expr1 (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t0 = t1 + t0
        fprintf(codegen, "ukadd8 t0, t1, t0\n");
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = T_INT;
    }
    | __RV__CMPEQ8 '(' expr ',' expr ')' {
        // t0 = expr2 (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t1 = expr1 (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t0 = (t1 == t0) ? 1 : 0
        fprintf(codegen, "cmpeq8 t0, t1, t0\n");
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = T_INT;
    }
    | __RV__UCMPLT8 '(' expr ',' expr ')' {
        // t0 = expr2 (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t1 = expr1 (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t0 = (t1 < t0) ? 1 : 0
        fprintf(codegen, "ucmplt8 t0, t1, t0\n");
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = T_INT;
    }
    | __RV__UKSUB8 '(' expr ',' expr ')' {
        // t0 = expr2 (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t1 = expr1 (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t0 = t1 - t0
        fprintf(codegen, "uksub8 t0, t1, t0\n");
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = T_INT;
    }
    | terminal {
        // t0 = variable (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t1 = *variable
        fprintf(codegen, "lw t1, 0(t0)\n");
        // push t1
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t1, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = $1;
    }
    | INT {
        // t0 = INT_NUM
        fprintf(codegen, "li t0, %d\n", $1);
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = $1;
    }
    | '(' expr ')' {
        $$ = $2;
    }
    ;

// terminal := scalar
//           | array
//           | int
//           | double
//           | char
//           | string
//           | null
//           | '(' expr ')'
terminal
    : ID {
        int idx = look_up_symbol($1);
        // t0 = ID's address
        fprintf(codegen, "addi t0, fp, %d\n", get_byte_offset($1));
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = table[idx].type;
    }
    | ID '[' expr ']' {
        // ID is a pointer
        // t0 = ID's value (ID[0]'s address)
        fprintf(codegen, "lw t0, %d(fp)\n", get_byte_offset($1));
        // t1 = expr * 4 (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        fprintf(codegen, "slli t1, t1, 2\n");
        // t0 = ID[expr]'s address
        fprintf(codegen, "sub t0, t0, t1\n");
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = T_INT;
    }
    | '*' ID {
        // ID is a pointer
        // t0 = ID's value (an address)
        fprintf(codegen, "lw t0, %d(fp)\n", get_byte_offset($2));
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = T_INT;
    }
    | '*' '(' ID '+' expr ')' {
        // ID is a pointer
        // t0 = ID's value (ID[0]'s address)
        fprintf(codegen, "lw t0, %d(fp)\n", get_byte_offset($3));
        // t1 = expr * 4 (pop)
        fprintf(codegen, "lw t1, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        fprintf(codegen, "slli t1, t1, 2\n");
        // t0 = ID[expr]'s address
        fprintf(codegen, "sub t0, t0, t1\n");
        // push t0
        fprintf(codegen, "addi sp, sp, -4\n");
        fprintf(codegen, "sw t0, 0(sp)\n");
        fprintf(codegen, "\n");
        $$ = T_INT;
    }
    | DOUBLE {}
    | CHAR {}
    | STRING {}
    | NUL {}
    ;

//--------------------------------------------//

// compound_statement := '{' stmts_and_var_decls '}'
compound_statement
    : '{' {
        cur_scope++;
    } stmts_and_var_decls {
        pop_up_symbol(cur_scope);
        cur_scope--;
    } '}'
    ;

// stmts_and_var_decls := stmts_and_var_decls stmt
//                      | stmts_and_var_decls var_decl
//                      | ε
stmts_and_var_decls
    : stmts_and_var_decls stmt {}
    | stmts_and_var_decls var_decl {}
    | /* ε */ {  }
    ;

// stmt := expr ';'
//       | if_stmt
//       | switch_stmt
//       | while_stmt
//       | for_stmt
//       | return_stmt
//       | compound_statement
stmt
    : expr ';' {}
    | if_stmt {
        // end_if
        fprintf(codegen, ".IF%d0:\n", if_counter);
    }
    | if_else_stmt {}
    | switch_stmt {}
    | while_stmt {}
    | for_stmt {}
    | return_stmt {}
    | compound_statement {}
    | digital_write_stmt {}
    | delay_stmt {}
    ;

//--------------------------------------------//

// if_stmt := 'if' '(' expr ')' compound_statement
//          | 'if' '(' expr ')' compound_statement 'else' compound_statement
if_stmt
    : IF '(' expr ')' {
        if_counter++;
        // t0 = expr (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t0 == 0: jump to .IF10 (end_if / else)
        // t0 == 1: continue to do
        fprintf(codegen, "beq t0, zero, .IF%d0\n", if_counter);
        fprintf(codegen, "\n");
    } compound_statement 
    ;

if_else_stmt
    : if_stmt ELSE {
        // finish if part, jump to .IF11 (end_if)
        fprintf(codegen, "j .IF%d1\n", if_counter);
        // else
        fprintf(codegen, ".IF%d0:\n", if_counter);
    } compound_statement {
        // end_if
        if (is_for2_used == 0) {
            fprintf(codegen, ".IF%d1:\n", if_counter);
            is_for2_used = 1;
        }
        else {
            fprintf(codegen, ".IF11:\n");
        }
    }
    ;

//--------------------------------------------//

// switch_stmt := 'switch' '(' expr ')' '{' switch_clauses '}'
switch_stmt: SWITCH '(' expr ')' '{' switch_clauses '}' {}
           ;

// switch_clauses := switch_clauses switch_clause
//                 | ε
switch_clauses: switch_clauses switch_clause {}
              | /* ε */ {  }
              ;

// switch_clause := 'case' expr ':' switch_stmts
//                | 'default' ':' switch_stmts
switch_clause: CASE expr ':' switch_stmts {}
             | DEFAULT ':' switch_stmts {}
             ;

// switch_stmts := switch_stmts stmt
//               | ε
switch_stmts: switch_stmts stmt {}
            | /* ε */ {  }
            ;

//--------------------------------------------//

// while_stmt := 'while' '(' expr ')' stmt
//             | 'do' stmt 'while' '(' expr ')' ';'
while_stmt
    : WHILE '(' {
        fprintf(codegen, ".WHILE:\n");
    } expr ')' {
        // t0 = expr (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t0 == 0: jump to .END_WHILE
        // t0 == 1: continue to do
        fprintf(codegen, "beq t0, zero, .END_WHILE\n");
        fprintf(codegen, "\n");
    } stmt {
        fprintf(codegen, "j .WHILE\n");
        fprintf(codegen, "\n");
        fprintf(codegen, ".END_WHILE:\n");
    }
    | DO {
        fprintf(codegen, ".DOWHILE:\n");
    } stmt WHILE '(' expr ')' ';' {
        // t0 = expr (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t0 == 0: jump to .END_DOWHILE
        // t0 == 1: continue to do
        fprintf(codegen, "beq t0, zero, .END_DOWHILE\n");
        fprintf(codegen, "\n");
        fprintf(codegen, "j .DOWHILE\n");
        fprintf(codegen, "\n");
        fprintf(codegen, ".END_DOWHILE:\n");
    }
    ;

//--------------------------------------------//

// for_stmt := 'for' '(' for_init ';' for_cond ';' for_update ')' stmt
for_stmt
    : FOR '(' for_init ';' {
        for_counter++;
        fprintf(codegen, ".FOR%d:\n", for_counter);
    } for_cond ';' {
        // t0 = expr (pop)
        fprintf(codegen, "lw t0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // t0 == 0: jump to .END_FOR
        // t0 == 1: jump to .FOR_STMT
        fprintf(codegen, "beq t0, zero, .END_FOR%d\n", for_counter);
        fprintf(codegen, "\n");
        fprintf(codegen, "j .FOR%d_STMT\n", for_counter);
        fprintf(codegen, "\n");
        fprintf(codegen, ".FOR%d_UPDATE:\n", for_counter);
    } for_update ')' {
        fprintf(codegen, "j .FOR%d\n", for_counter);
        fprintf(codegen, "\n");
        fprintf(codegen, ".FOR%d_STMT:\n", for_counter);
    } stmt {
        fprintf(codegen, "j .FOR%d_UPDATE\n", for_counter);
        fprintf(codegen, "\n");
        fprintf(codegen, ".END_FOR%d:\n", for_counter);
    }
    ;

// for_init := expr
//           | ε
for_init
    : expr {}
    | /* ε */ {}
    ;

// for_cond := expr
//           | ε
for_cond
    : expr {}
    | /* ε */ {}
    ;

// for_update := expr
//            | ε
for_update
    : expr {}
    | /* ε */ {}
    ;

//--------------------------------------------//

// return_stmt := 'return' expr ';'
//              | 'return' ';'
//              | 'break' ';'
//              | 'continue' ';'
return_stmt
    : RETURN expr ';' {
        /* Section B */
        // a0 = function return value (pop)
        fprintf(codegen, "lw a0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // restore ra, restore old fp, remove the frame
        fprintf(codegen, "lw ra, %d(sp)\n", FRAME_SIZE-4);
        fprintf(codegen, "lw fp, %d(sp)\n", FRAME_SIZE-8);
        fprintf(codegen, "addi sp, sp, %d\n", FRAME_SIZE);
        fprintf(codegen, "jr ra");
        fprintf(codegen, "\n");
    }
    | RETURN ';' {}
    | BREAK ';' {
        fprintf(codegen, "j .END_WHILE\n");
    }
    | CONTINUE ';' {}
    ;

//--------------------------------------------//

digital_write_stmt
    : DIGITALWRITE '(' expr ',' HIGH ')' ';' {
        // a0 = expr (pop)
        fprintf(codegen, "lw a0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // a1 = 1
        fprintf(codegen, "li a1, 1\n");
        // call digitalWrite()
        fprintf(codegen, "jal ra, digitalWrite\n");
        fprintf(codegen, "\n");
    }
    | DIGITALWRITE '(' expr ',' LOW ')' ';' {
        // a0 = expr (pop)
        fprintf(codegen, "lw a0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // a1 = 1
        fprintf(codegen, "li a1, 0\n");
        // call digitalWrite()
        fprintf(codegen, "jal ra, digitalWrite\n");
        fprintf(codegen, "\n");
    }
    ;

delay_stmt
    : DELAY '(' expr ')' ';' {
        // a0 = expr (pop)
        fprintf(codegen, "lw a0, 0(sp)\n");
        fprintf(codegen, "addi sp, sp, 4\n");
        // call delay()
        fprintf(codegen, "jal ra, delay\n");
        fprintf(codegen, "\n");
    }
    ;

//--------------------------------------------//
%%

void yyerror(char *s) {
    fprintf(stderr, "Error: %s\n", s);
    exit(1);
}

int main() {
    init();
    codegen = fopen("codegen.S", "w");
    yyparse();
    fclose(codegen);
    return 0;
}