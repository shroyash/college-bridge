package com.college.bridge.notification.fcm;

import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MessagingErrorCode;

import java.net.ConnectException;
import java.net.SocketTimeoutException;
import java.util.concurrent.TimeoutException;

public class FcmErrorClassifier {

    public enum ErrorCategory {
        TRANSIENT,
        UNREGISTERED,
        PERMANENT
    }

    public static ErrorCategory classify(Throwable throwable) {
        if (throwable == null) {
            return ErrorCategory.PERMANENT;
        }

        Throwable cause = throwable;
        while (cause != null) {
            if (cause instanceof SocketTimeoutException 
                    || cause instanceof ConnectException 
                    || cause instanceof TimeoutException) {
                return ErrorCategory.TRANSIENT;
            }

            if (cause instanceof FirebaseMessagingException fme) {
                MessagingErrorCode errorCode = fme.getMessagingErrorCode();
                if (errorCode != null) {
                    return switch (errorCode) {
                        case UNAVAILABLE, INTERNAL, QUOTA_EXCEEDED -> ErrorCategory.TRANSIENT;
                        case UNREGISTERED -> ErrorCategory.UNREGISTERED;
                        case INVALID_ARGUMENT, SENDER_ID_MISMATCH, THIRD_PARTY_AUTH_ERROR -> ErrorCategory.PERMANENT;
                    };
                }
            }
            cause = cause.getCause();
        }

        return ErrorCategory.PERMANENT;
    }

    public static boolean isTransient(Throwable throwable) {
        return classify(throwable) == ErrorCategory.TRANSIENT;
    }
}
