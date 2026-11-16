package com.college.bridge.holiday.application.notice;

import java.util.regex.Pattern;

/** Cleans text typed by admins before it becomes an official notice (no HTML, no control characters). */
public final class NoticeTextSanitizer {

    private static final Pattern HTML_TAG = Pattern.compile("<[^>]*>");
    private static final Pattern CONTROL_EXCEPT_NEWLINE = Pattern.compile("[\\p{Cntrl}&&[^\\n]]");
    private static final Pattern BLANK_LINES = Pattern.compile("\\n{3,}");

    private NoticeTextSanitizer() {}

    public static String clean(String text) {
        if (text == null) return "";
        String cleaned = HTML_TAG.matcher(text).replaceAll("");
        cleaned = CONTROL_EXCEPT_NEWLINE.matcher(cleaned).replaceAll(" ");
        cleaned = BLANK_LINES.matcher(cleaned).replaceAll("\n\n");
        return cleaned.trim();
    }
}
