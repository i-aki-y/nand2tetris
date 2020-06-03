LINE = COMMAND + COMMENT
COMMAND = A_COMMAND | C_COMMNAD | L_COMMAND
COMMENT = String that starts with "//"
A_COMMAND = @,VALUE
L_COMMAND = ( + SYMBOL + )
C_COMMAND = [DEST=]COMP[;JUMP]
VALUE = SYMBOL | DIGITS
DIGITS = [0-9]+
SYMBOL = [0-9A-Za-z_.:$]+
DEST = null | A | M | ...
COMP = 0 | 1 | -1 | A | ...
JUMP = null | JGT | JEQ | ...
