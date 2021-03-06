// $ANTLR 2.7.6 (2005-12-22): "src/com/xruby/compiler/parser/ruby.g" -> "RubyLexerBase.java"$

package com.xruby.compiler.parser;

public interface RubyTokenTypes {
	int EOF = 1;
	int NULL_TREE_LOOKAHEAD = 3;
	int RPAREN_IN_METHOD_DEFINATION = 4;
	int BODY = 5;
	int CALL = 6;
	int ARG = 7;
	int COMPSTMT = 8;
	int SYMBOL = 9;
	int BLOCK = 10;
	int MULTIPLE_ASSIGN = 11;
	int MULTIPLE_ASSIGN_WITH_EXTRA_COMMA = 12;
	int BLOCK_ARG = 13;
	int BLOCK_ARG_WITH_EXTRA_COMMA = 14;
	int MRHS = 15;
	int NESTED_LHS = 16;
	int SINGLETON_METHOD = 17;
	int STRING = 18;
	int SEMI = 19;
	int LINE_BREAK = 20;
	int IF_MODIFIER = 21;
	int UNLESS_MODIFIER = 22;
	int WHILE_MODIFIER = 23;
	int UNTIL_MODIFIER = 24;
	int RESCUE_MODIFIER = 25;
	int LCURLY_BLOCK = 26;
	int RCURLY = 27;
	int COMMA = 28;
	int REST_ARG_PREFIX = 29;
	int ASSIGN = 30;
	int ASSIGN_WITH_NO_LEADING_SPACE = 31;
	int LPAREN_WITH_NO_LEADING_SPACE = 32;
	int LPAREN = 33;
	int RPAREN = 34;
	int IDENTIFIER = 35;
	int CONSTANT = 36;
	int FUNCTION = 37;
	int LITERAL_undef = 38;
	int LITERAL_alias = 39;
	int GLOBAL_VARIABLE = 40;
	int LITERAL_do = 41;
	int LITERAL_end = 42;
	int BOR = 43;
	int LOGICAL_OR = 44;
	int COLON_WITH_NO_FOLLOWING_SPACE = 45;
	int INSTANCE_VARIABLE = 46;
	int CLASS_VARIABLE = 47;
	int UNARY_PLUS_MINUS_METHOD_NAME = 48;
	int LITERAL_and = 49;
	int LITERAL_or = 50;
	int LITERAL_not = 51;
	int QUESTION = 52;
	int COLON = 53;
	int PLUS_ASSIGN = 54;
	int MINUS_ASSIGN = 55;
	int STAR_ASSIGN = 56;
	int DIV_ASSIGN = 57;
	int MOD_ASSIGN = 58;
	int POWER_ASSIGN = 59;
	int BAND_ASSIGN = 60;
	int BXOR_ASSIGN = 61;
	int BOR_ASSIGN = 62;
	int LEFT_SHIFT_ASSIGN = 63;
	int RIGHT_SHIFT_ASSIGN = 64;
	int LOGICAL_AND_ASSIGN = 65;
	int LOGICAL_OR_ASSIGN = 66;
	int INCLUSIVE_RANGE = 67;
	int EXCLUSIVE_RANGE = 68;
	int LOGICAL_AND = 69;
	int COMPARE = 70;
	int EQUAL = 71;
	int CASE_EQUAL = 72;
	int NOT_EQUAL = 73;
	int MATCH = 74;
	int NOT_MATCH = 75;
	int LESS_THAN = 76;
	int GREATER_THAN = 77;
	int LESS_OR_EQUAL = 78;
	int GREATER_OR_EQUAL = 79;
	int BXOR = 80;
	int BAND = 81;
	int LEFT_SHIFT = 82;
	int RIGHT_SHIFT = 83;
	int PLUS = 84;
	int MINUS = 85;
	int STAR = 86;
	int DIV = 87;
	int MOD = 88;
	int POWER = 89;
	int BNOT = 90;
	int NOT = 91;
	int LITERAL_return = 92;
	int LITERAL_break = 93;
	int LITERAL_next = 94;
	int DOT = 95;
	int COLON2 = 96;
	int LBRACK_ARRAY_ACCESS = 97;
	int RBRACK = 98;
	int EMPTY_ARRAY_ACCESS = 99;
	int UNARY_PLUS = 100;
	int UNARY_MINUS = 101;
	int ASSOC = 102;
	int BLOCK_ARG_PREFIX = 103;
	int LITERAL_nil = 104;
	int LITERAL_true = 105;
	int LITERAL_false = 106;
	int LITERAL___FILE__ = 107;
	int LITERAL___LINE__ = 108;
	int DOUBLE_QUOTE_STRING = 109;
	int SINGLE_QUOTE_STRING = 110;
	int STRING_BEFORE_EXPRESSION_SUBSTITUTION = 111;
	int STRING_BETWEEN_EXPRESSION_SUBSTITUTION = 112;
	int STRING_AFTER_EXPRESSION_SUBSTITUTION = 113;
	int REGEX = 114;
	int REGEX_BEFORE_EXPRESSION_SUBSTITUTION = 115;
	int COMMAND_OUTPUT = 116;
	int COMMAND_OUTPUT_BEFORE_EXPRESSION_SUBSTITUTION = 117;
	int HERE_DOC_BEGIN = 118;
	int HERE_DOC_CONTENT = 119;
	int HERE_DOC_BEFORE_EXPRESSION_SUBSTITUTION = 120;
	int HERE_DOC_BETWEEN_EXPRESSION_SUBSTITUTION = 121;
	int HERE_DOC_AFTER_EXPRESSION_SUBSTITUTION = 122;
	int W_ARRAY = 123;
	int INTEGER = 124;
	int HEX = 125;
	int BINARY = 126;
	int OCTAL = 127;
	int FLOAT = 128;
	int ASCII_VALUE = 129;
	int LITERAL_self = 130;
	int LITERAL_super = 131;
	int LEADING_COLON2 = 132;
	int LITERAL_retry = 133;
	int LITERAL_yield = 134;
	int LITERAL_redo = 135;
	int EMPTY_ARRAY = 136;
	int LBRACK = 137;
	int LCURLY_HASH = 138;
	int LITERAL_rescue = 139;
	int LITERAL_else = 140;
	int LITERAL_ensure = 141;
	int LITERAL_begin = 142;
	int LITERAL_if = 143;
	int LITERAL_elsif = 144;
	int LITERAL_unless = 145;
	int LITERAL_case = 146;
	int LITERAL_for = 147;
	int LITERAL_in = 148;
	int LITERAL_while = 149;
	int LITERAL_until = 150;
	int LITERAL_module = 151;
	int LITERAL_class = 152;
	int LITERAL_def = 153;
	int SINGLE_QUOTE = 154;
	// "defined?" = 155
	int LITERAL_BEGIN = 156;
	int LITERAL_then = 157;
	int LITERAL_when = 158;
	int LITERAL_END = 159;
	int DO_IN_CONDITION = 160;
	int PURE_LINE_BREAK = 161;
	int LINE_FEED = 162;
	int REGEX_MODIFIER = 163;
	int SPECIAL_STRING = 164;
	int STRING_CHAR = 165;
	int ANYTHING_OTHER_THAN_LINE_FEED_AND_POUND = 166;
	int HERE_DOC_DELIMITER = 167;
	int RDOC = 168;
	int ANYTHING_OTHER_THAN_LINE_FEED = 169;
	int LINE = 170;
	int ESC = 171;
	int IDENTIFIER_CONSTANT_AND_KEYWORD = 172;
	int UNDER_SCORE = 173;
	int FLOAT_WITH_LEADING_DOT = 174;
	int NON_ZERO_DECIMAL = 175;
	int OCTAL_CONTENT = 176;
	int HEX_CONTENT = 177;
	int BINARY_CONTENT = 178;
	int EXPONENT = 179;
	int COMMENT = 180;
	int WHITE_SPACE_CHAR = 181;
	int WHITE_SPACE = 182;
	int LINE_CONTINUATION = 183;
	int END_OF_FILE = 184;
}
