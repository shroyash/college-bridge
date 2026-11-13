package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.application.port.NoticeWriter;
import com.college.bridge.holiday.application.port.NoticeWriter.NoticeRequest;
import com.college.bridge.holiday.application.port.NoticeWriter.WrittenNotice;
import com.college.bridge.holiday.application.port.NoticeWriter.WrittenNotices;
import com.college.bridge.holiday.application.port.NoticeWritingException;
import com.college.bridge.holiday.config.HolidayProperties;
import com.college.bridge.holiday.domain.NoticeDraft;
import com.college.bridge.holiday.domain.PublicHoliday;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Policy for getting draft text: ask the writer, retry sensible failures with backoff,
 * and (when allowed) fall back to a static template. It knows nothing about Gemini, HTTP or the database.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class NoticeAuthoringService {

    private final NoticeWriter writer;
    private final HolidayProperties props;

    /** Empty if the writer could not deliver usable text. */
    public Optional<WrittenNotices> writeWithAi(PublicHoliday holiday) {
        NoticeRequest request = new NoticeRequest(
                holiday.getName(), holiday.getDateAd(), holiday.getDateBs(), props.notice().language());

        int maxAttempts = Math.max(1, props.notice().aiMaxAttempts());
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                WrittenNotices written = writer.write(request);
                if (isUsable(written)) {
                    return Optional.of(written);
                }
                log.warn("Writer returned unusable notices for holiday {} (attempt {}/{})",
                        holiday.getId(), attempt, maxAttempts);
            } catch (NoticeWritingException e) {
                log.warn("Writing failed for holiday {} (attempt {}/{}, retryable={}): {}",
                        holiday.getId(), attempt, maxAttempts, e.isRetryable(), e.getMessage());
                if (!e.isRetryable()) {
                    return Optional.empty(); // a retry cannot help (bad key, blocked prompt)
                }
            } catch (RuntimeException e) {
                log.warn("Unexpected writer error for holiday {} (attempt {}/{})",
                        holiday.getId(), attempt, maxAttempts, e);
            }
            if (attempt < maxAttempts) {
                pause(props.ai().retryBackoffMillis() * attempt);
            }
        }
        return Optional.empty();
    }

    /** AI text when possible, otherwise the static template. */
    public WrittenNotices writeWithFallback(PublicHoliday holiday) {
        return writeWithAi(holiday).orElseGet(() -> {
            log.warn("Using template drafts for holiday {}", holiday.getId());
            return StaticNoticeTemplates.forHoliday(holiday);
        });
    }

    private static boolean isUsable(WrittenNotices written) {
        return written != null && isUsable(written.closed()) && isUsable(written.open());
    }

    private static boolean isUsable(WrittenNotice notice) {
        return notice != null
                && notice.title() != null && !notice.title().isBlank()
                && notice.title().length() <= NoticeDraft.TITLE_MAX_LENGTH
                && notice.body() != null && !notice.body().isBlank()
                && notice.body().length() <= NoticeDraft.BODY_MAX_LENGTH;
    }

    private static void pause(long millis) {
        if (millis <= 0) return;
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
