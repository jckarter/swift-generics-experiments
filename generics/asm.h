#define SYMCAT(a,b) a##b
#define SYMCAT2(a,b) SYMCAT(a,b)
#define SYM(x) SYMCAT2(__USER_LABEL_PREFIX__,x)
