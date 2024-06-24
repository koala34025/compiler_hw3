#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "function.h"

struct symbol_entry table[MAX_TABLE_SIZE];
int cur_counter = 0;
int cur_scope = 0;
int if_counter = 0;
int for_counter = 0;
int is_for2_used = 0;
char *cur_exe_func = NULL;
FILE *codegen = NULL;

void init() {
    memset(table, 0, sizeof(struct symbol_entry) * MAX_TABLE_SIZE);
}

void install_symbol(char *name) {
    if (cur_counter >= MAX_TABLE_SIZE) {
        printf("Symbol Table Full!\n");
        return;
    }
    table[cur_counter].scope = cur_scope;
    table[cur_counter].name = strdup(name);
    cur_counter++;
}

void pop_up_symbol(int scope) {
    int i;
    if (cur_counter == 0) return;
    for (i = cur_counter - 1; i >= 0; i--) {
        if (table[i].scope != scope)
            break;
    }
    if (i < 0) cur_counter = 0;
    else cur_counter = i + 1;
}

int look_up_symbol(char *name) {
    if (cur_counter == 0) return -1;
    for (int i = cur_counter - 1; i >= 0; i--) {
        if (!strcmp(name, table[i].name))
            return i;
    }
    return -1;
}

void set_type(char *name, int type) {
    int idx = look_up_symbol(name);
    table[idx].type = type;
}

void set_global_vars(char *name) {
    int idx = look_up_symbol(name);
    table[idx].mode = GLOBAL_MODE;
}

void set_local_vars(char *name) {
    int idx = look_up_symbol(name);
    int func_idx = look_up_symbol(cur_exe_func);
    int offset = ++table[func_idx].total_locals;
    table[idx].mode = LOCAL_MODE;
    table[idx].offset = offset;
}

void set_scope_and_offset_of_param(char *func_name, int total_args) {
    int idx = look_up_symbol(func_name);
    if (idx < 0) printf("Error in function header\n");
    else {
        table[idx].type = T_FUNCTION;
        table[idx].total_args = total_args;
        for (int i = cur_counter - 1, j = total_args; j > 0; i--, j--) {
            table[i].scope = cur_scope;
            table[i].offset = j;
            table[i].mode = ARGUMENT_MODE;
        }
    }
}

int get_byte_offset(char *name) {
    int idx = look_up_symbol(name);
    if (table[idx].mode == ARGUMENT_MODE)
        return (-4) * (2 + table[idx].offset);
    return (-4) * (2 + MAX_ARGUMENT_NUM + table[idx].offset);
}
