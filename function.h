#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_TABLE_SIZE 5000
#define MAX_ARGUMENT_NUM 5
#define MAX_LOCAL_NUM 50
#define FRAME_SIZE (2 + MAX_ARGUMENT_NUM + MAX_LOCAL_NUM) * 4

#define T_FUNCTION 1
#define T_POINTER 2
#define T_INT 3

#define GLOBAL_MODE 4
#define LOCAL_MODE 5
#define ARGUMENT_MODE 6

struct symbol_entry {
    char *name;
    int scope;
    int type;
    int mode;
    int offset;
    int total_args;
    int total_locals;
};

extern struct symbol_entry table[MAX_TABLE_SIZE];
extern int cur_counter;
extern int cur_scope;
extern int if_counter;
extern int for_counter;
extern int is_for2_used;
extern char *cur_exe_func;
extern FILE *codegen;

void init();
void install_symbol(char *name);
void pop_up_symbol(int scope);
int look_up_symbol(char *name);
void set_type(char *name, int type);
void set_global_vars(char *name);
void set_local_vars(char *name);
void set_scope_and_offset_of_param(char *func_name, int total_args);
int get_byte_offset(char *name);
