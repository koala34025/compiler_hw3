%{
#include "y.tab.h"
%}

%option noyywrap
%x COMMENT ML_COMMENT

ID          [a-zA-Z_][a-zA-Z_0-9]*
INTEGER     [0-9]+
DOUBLE      [0-9]+"."[0-9]*|[0-9]*"."[0-9]+
OP          "+"|"-"|"*"|"/"|"%"|"="|"!"|"~"|"^"|"&"|"|"|"<"|">"
PUNC        ":"|";"|","|"."|"["|"]"|"("|")"|"{"|"}"
CHAR        \'(\\.|[^'\\])\'|\'"\\"[0-7]{1,3}\'|\'"\\x"[0-9A-Fa-f]+\'|\'"\\u"[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]\'|\'"\\U"[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]\'
STRING      \"(\\.|[^"\\])*\"

%%

[ \t\n]          {}

"//"             {BEGIN(COMMENT);}
<COMMENT>\\\n    {}
<COMMENT>\n      {BEGIN(INITIAL);}
<COMMENT>.       {}

"/*"             {BEGIN(ML_COMMENT);}
<ML_COMMENT>"*/" {BEGIN(INITIAL);}
<ML_COMMENT>\n   {}
<ML_COMMENT>.    {}

"__rv__ukadd8"   {yylval.strVal = strdup(yytext); return __RV__UKADD8;}
"__rv__cmpeq8"   {yylval.strVal = strdup(yytext); return __RV__CMPEQ8;}
"__rv__ucmplt8"  {yylval.strVal = strdup(yytext); return __RV__UCMPLT8;}
"__rv__uksub8"   {yylval.strVal = strdup(yytext); return __RV__UKSUB8;}
"ext_dsp_codegen" {yylval.strVal = strdup(yytext); return EXTDSPCODEGEN;}
"codegen"        {yylval.strVal = strdup(yytext); return CODEGEN;}
"digitalWrite"   {yylval.strVal = strdup(yytext); return DIGITALWRITE;}
"delay"          {yylval.strVal = strdup(yytext); return DELAY;}
"HIGH"           {yylval.intVal = 1; return HIGH;}
"LOW"            {yylval.intVal = 0; return LOW;}

"uint32_t"       {yylval.strVal = strdup(yytext); return TYPEUINT32;}
"const"          {yylval.strVal = strdup(yytext); return TYPECONST;}
"signed"         {yylval.strVal = strdup(yytext); return TYPESIGNED;}
"unsigned"       {yylval.strVal = strdup(yytext); return TYPEUNSIGNED;}
"long"           {yylval.strVal = strdup(yytext); return TYPELONG;}
"short"          {yylval.strVal = strdup(yytext); return TYPESHORT;}
"int"            {yylval.strVal = strdup(yytext); return TYPEINT;}
"char"           {yylval.strVal = strdup(yytext); return TYPECHAR;}
"float"          {yylval.strVal = strdup(yytext); return TYPEFLOAT;}
"double"         {yylval.strVal = strdup(yytext); return TYPEDOUBLE;}
"void"           {yylval.strVal = strdup(yytext); return TYPEVOID;}

"if"             {yylval.strVal = strdup(yytext); return IF;}
"else"           {yylval.strVal = strdup(yytext); return ELSE;}
"switch"         {yylval.strVal = strdup(yytext); return SWITCH;}
"case"           {yylval.strVal = strdup(yytext); return CASE;}
"default"        {yylval.strVal = strdup(yytext); return DEFAULT;}
"while"          {yylval.strVal = strdup(yytext); return WHILE;}
"do"             {yylval.strVal = strdup(yytext); return DO;}
"for"            {yylval.strVal = strdup(yytext); return FOR;}
"return"         {yylval.strVal = strdup(yytext); return RETURN;}
"break"          {yylval.strVal = strdup(yytext); return BREAK;}
"continue"       {yylval.strVal = strdup(yytext); return CONTINUE;}
"NULL"           {yylval.strVal = strdup(yytext); return NUL;}

{ID}             {yylval.strVal = strdup(yytext); return ID;}
{INTEGER}        {yylval.intVal = atoi(yytext);   return INT;}
{DOUBLE}         {yylval.douVal = atof(yytext);   return DOUBLE;}
{OP}             {yylval.strVal = strdup(yytext); return yytext[0];}
{PUNC}           {yylval.strVal = strdup(yytext); return yytext[0];}
{CHAR}           {yylval.strVal = strdup(yytext); return CHAR;}
{STRING}         {yylval.strVal = strdup(yytext); return STRING;}

"++"             {yylval.strVal = strdup(yytext); return INC;}
"--"             {yylval.strVal = strdup(yytext); return DEC;}
"<="             {yylval.strVal = strdup(yytext); return LESSEQUAL;}
">="             {yylval.strVal = strdup(yytext); return GREATEREQUAL;}
"=="             {yylval.strVal = strdup(yytext); return EQUAL;}
"!="             {yylval.strVal = strdup(yytext); return NOTEQUAL;}
"&&"             {yylval.strVal = strdup(yytext); return AND;}
"||"             {yylval.strVal = strdup(yytext); return OR;}
">>"             {yylval.strVal = strdup(yytext); return RSHIFT;}
"<<"             {yylval.strVal = strdup(yytext); return LSHIFT;}

.                {}

%%
