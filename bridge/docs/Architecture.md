```mermaid
graph TD
    Client[Client] --> Auth[Auth Module: Rate Limiting & Auth]

    %% Broadcast Flow
    Auth --> Broadcast[Broadcast Module]
    Broadcast <--> RedisIdem[Idempotent Check - Redis]
    Broadcast --> MsgQueue[Messaging Queue]

    MsgQueue --> Worker[Worker Thread Pool: Max 2-3 Jobs]
    Worker <--> Cache[Cache - Redis / DB Tier]
    Worker --> SpringBatch[Spring Batching]
    SpringBatch --> VirtualThreads[Parallel FCM Multicast Processor - Virtual Threads]

    VirtualThreads --> FCM[Firebase FCM Multicast API]
    FCM --> Success[Success: sent_count++ & Delete Invalid Tokens]
    FCM --> Failure[Failure: Classify Error Code]

    Failure --> RetryQueue[Retry Queue: Exponential Backoff 2m-4m-8m-16m]
    RetryQueue -- "5 attempts exhausted" --> DLQ[Dead Letter Queue: status = DEAD]
    DLQ --> AdminAlert[Admin Dashboard Alert]

    %% AI & Class Module Flow
    Auth --> AIModule[AI Module]
    Auth --> ClassModule[Class Module]

    Patro[Nepali Calendar / Patro API] --> ClassDB[(Class DB)]
    ClassModule --> ClassDB
    AIModule --> HolidayJob[Scheduled Holiday Detection Job]
    ClassDB --> HolidayJob

    HolidayJob --> Claude[Claude LLM: Generate Message]
    Claude --> AdminQueue[Admin Approval Queue: PENDING_APPROVAL]
    AdminQueue -- "On Approve" --> MsgQueue
    AdminQueue -- "On Reject" --> Discarded[Rejected / Discarded]

    ![System Architecture Diagram](./docs/images/architecture-diagram.png)
```