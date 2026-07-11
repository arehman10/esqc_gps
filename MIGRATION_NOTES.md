package com.stata.sfi;
public final class Data {
    public static int getParsedVarCount(){ return 0; }
    public static int mapParsedVarIndex(int v){ return v; }
    public static boolean isVarTypeString(int v){ return false; }
    public static long getObsParsedIn1(){ return 1; }
    public static long getObsParsedIn2(){ return 0; }
    public static boolean isParsedIfTrue(long o){ return false; }
    public static int getVarIndex(String n){ return 0; }
    public static String getStr(int v,long o){ return ""; }
    public static double getNum(int v,long o){ return 0; }
    public static String getFormattedValue(int v,long o,boolean labels){ return ""; }
    public static int addVarStr(String n,int l){ return 0; }
    public static int addVarByte(String n){ return 0; }
    public static int addVarStrL(String n){ return 0; }
    public static int setVarLabel(int v,String l){ return 0; }
    public static int storeStr(int v,long o,String s){ return 0; }
    public static int storeNum(int v,long o,double d){ return 0; }
    public static int renameVar(int v,String n){ return 0; }
    public static int dropVar(int v){ return 0; }
    public static void updateModified(){}
}
