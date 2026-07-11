package com.stata.sfi;

import java.util.ArrayList;
import java.util.List;

public final class Data {
    private static final class Var {
        String name;
        final boolean string;
        final Object[] values;
        String label = "";
        Var(String name, boolean string, int nobs) {
            this.name = name;
            this.string = string;
            this.values = new Object[nobs + 1];
        }
    }

    private static final int NOBS = 2;
    private static final List<Var> VARS = new ArrayList<>();
    private static final int[] PARSED = {1, 2, 3, 4, 5};

    static {
        Var lat = addInitial("lat", false);
        Var lon = addInitial("lon", false);
        Var a3a = addInitial("a3a", true);
        Var a3x = addInitial("a3x", true);
        Var tid = addInitial("tid", true);
        lat.values[1] = 10.5d; lon.values[1] = 10.5d;
        a3a.values[1] = "North"; a3x.values[1] = "Alpha"; tid.values[1] = "case-1";
        lat.values[2] = 20.0d; lon.values[2] = 20.0d;
        a3a.values[2] = ""; a3x.values[2] = ""; tid.values[2] = "case-2";
    }

    private static Var addInitial(String name, boolean string) {
        Var variable = new Var(name, string, NOBS);
        VARS.add(variable);
        return variable;
    }

    private static Var variable(int index) {
        if (index < 1 || index > VARS.size()) {
            throw new IllegalArgumentException("invalid variable index " + index);
        }
        return VARS.get(index - 1);
    }

    public static int getParsedVarCount() { return PARSED.length; }
    public static int mapParsedVarIndex(int v) { return PARSED[v - 1]; }
    public static boolean isVarTypeString(int v) { return variable(v).string; }
    public static long getObsParsedIn1() { return 1; }
    public static long getObsParsedIn2() { return NOBS; }
    public static boolean isParsedIfTrue(long o) { return o >= 1 && o <= NOBS; }

    public static int getVarIndex(String name) {
        for (int i = 0; i < VARS.size(); i++) {
            if (VARS.get(i).name.equals(name)) return i + 1;
        }
        return 0;
    }

    public static String getStr(int v, long o) {
        Object value = variable(v).values[(int)o];
        return value == null ? "" : String.valueOf(value);
    }

    public static double getNum(int v, long o) {
        Object value = variable(v).values[(int)o];
        return value instanceof Number ? ((Number)value).doubleValue() : Double.NaN;
    }

    public static String getFormattedValue(int v, long o, boolean labels) {
        double value = getNum(v, o);
        return Double.isNaN(value) ? "" : Double.toString(value);
    }

    private static int add(String name, boolean string) {
        if (getVarIndex(name) > 0) return 110;
        VARS.add(new Var(name, string, NOBS));
        return 0;
    }

    public static int addVarStr(String n, int l) { return add(n, true); }
    public static int addVarByte(String n) { return add(n, false); }
    public static int addVarStrL(String n) { return add(n, true); }

    public static int setVarLabel(int v, String l) {
        variable(v).label = l;
        return 0;
    }

    public static int storeStr(int v, long o, String s) {
        Var variable = variable(v);
        if (!variable.string || o < 1 || o > NOBS) return 109;
        variable.values[(int)o] = s;
        return 0;
    }

    public static int storeNum(int v, long o, double d) {
        Var variable = variable(v);
        if (variable.string || o < 1 || o > NOBS) return 109;
        variable.values[(int)o] = d;
        return 0;
    }

    public static int renameVar(int v, String n) {
        if (getVarIndex(n) > 0) return 110;
        variable(v).name = n;
        return 0;
    }

    public static int dropVar(int v) {
        if (v < 1 || v > VARS.size()) return 111;
        VARS.remove(v - 1);
        return 0;
    }

    public static void updateModified() { }

    public static String value(String variableName, int observation) {
        int index = getVarIndex(variableName);
        if (index <= 0) return "<missing-variable>";
        Object value = variable(index).values[observation];
        return value == null ? "" : String.valueOf(value);
    }
}
