package com.stata.sfi;
import java.io.File;
public final class SFIToolkit {
    public static void displayln(String s){ System.out.println(s); }
    public static void errorln(String s){ System.err.println(s); }
    public static File resolvePath(String s){ return new File(s); }
}
