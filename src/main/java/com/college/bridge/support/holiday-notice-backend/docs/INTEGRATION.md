# Holiday Notice: integration guide

Package: `com.college.bridge.holiday`. Copy `src/main` into your project, then do the 4 steps below.

Requires Spring Boot 3.2+ (RestClient), Java 17+, spring-boot-starter-{web,data-jpa,validation,security}, Lombok.
Method security must be enabled (`@EnableMethodSecurity`) for `@PreAuthorize`; change `hasRole('ADMIN')` to your role name.

## 1. Implement the 3 ports (the only code you must write)

### HolidayAiPort: delegate to your AI module
ONE call that returns both notices. Ask the model for strict JSON and parse it:

```
System: You write short official college notices. Output ONLY JSON, no markdown.
        Do not invent facts about the festival. Tone: formal, polite. Language: {language}.
        Title <= 80 chars, body <= 400 chars. The notice is sent on the morning of the date itself.
User:   Holiday: {name}. Date: {dateAd} ({dateBs} BS).
        Return: {"holiday_notice":{"title":"","body":""},"open_notice":{"title":"","body":""}}
        holiday_notice = the college is CLOSED that day.
        open_notice    = it is a public holiday but the college stays OPEN and classes run as usual.
```
Map the JSON to `GeneratedNotices(new Notice(..), new Notice(..), modelName)`. Throw on any failure;
the draft service retries (`holiday.notice.ai-max-attempts`) and then falls back to a template.
If you use Gemini's API, set the response MIME type to `application/json`.

### AdminPort
- `currentAdminId()`: read it from the SecurityContext.
- `activeAdminTokens()`: `select user_id, fcm_token from device_tokens where role = 'ADMIN' and active`.
- `removeTokens(...)`: delete those tokens.

### NepaliDateConverter
BS -> AD. Use any BS/AD library or a lookup table. Must parse the date format your API returns.
If the API already returns AD dates, make this `LocalDate.parse` and add the BS string some other way.

## 2. Migration + config
- `db/migration/V100__holiday_notice.sql` (PostgreSQL; MySQL notes at the top). Rename the version.
- Merge `application-holiday.yml` into your config; set the real API base URL.
- Have students/parents/staff apps subscribe to the `holiday.notice.audience-topic` FCM topic
  (you already have `subscribeTokensToTopic`).

## 3. Check the holiday API parsing
`HolidaySyncService` accepts either a JSON array or `{ "data": [...] }`, reading `name|title|holiday` and
`date|bs_date`. If the real response differs, edit the few lines marked "Adjust here". Add an auth header
in `HolidayConfig.holidayRestClient` if the API needs a key.

## 4. Mobile app
- Approval push carries `data.type = HOLIDAY_APPROVAL` and `data.holiday_id`: deep link to the screen
  calling `GET /api/admin/holiday-notices/{id}`.
- On app start also call `GET /api/admin/holiday-notices/pending` and show a banner. Push is only a nudge.

## Endpoints (ROLE_ADMIN)
| Method | Path | Purpose |
|---|---|---|
| GET | /api/admin/holiday-notices/pending | undecided holidays (today and future) |
| GET | /api/admin/holiday-notices/{holidayId} | both drafts + status |
| PUT | /api/admin/holiday-notices/{holidayId}/messages/{HOLIDAY\|OPEN} | edit text (DRAFT only) |
| POST | /api/admin/holiday-notices/{holidayId}/select `{"variant":"HOLIDAY"}` | choose variant, first wins, else 409 |
| POST | /api/admin/holiday-notices/{holidayId}/regenerate | fresh AI text (overwrites edits) |
| POST | /api/admin/holiday-notices/sync?year=2083 | manual holiday re-sync |

## Timeline (Asia/Kathmandu)
| Time | Job |
|---|---|
| 1st of month 02:00 | re-sync holidays (moved/added festivals) |
| 18:00 | tomorrow a holiday? create decision + 2 drafts (async), token-push admins |
| 20:00 | retry missing drafts, remind undecided admins |
| 06:00 (holiday day) | last reminder |
| every 10 min 07:00-19:50 | after `auto-select-at`, auto-pick HOLIDAY if nobody decided; send selected notice to topic |

## State machine (`holiday_decision.status`)
`DRAFT -> SELECTED -> SENDING -> SENT` (`SENDING -> SELECTED` on retryable failure, `-> FAILED` after 5 attempts, admins are pushed).
Every transition is a conditional UPDATE, so two admins or two server instances can never double-select or double-send.

## Known limits
- Delivery is at-least-once: a crash exactly between FCM accepting and the DB write can resend once after 15 min.
- If two holidays fall on the same date, two separate notices are created.
- Not compiled against your project (I don't have your pom or the rest of your code); expect to fix imports/versions.
