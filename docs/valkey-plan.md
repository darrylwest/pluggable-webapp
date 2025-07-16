# ValKey Database Plans

## Local Instance

* for development
* for production of small sites

## **Warning: Why You Should Avoid SELECT in Production**

While client.select() works, using multiple databases via the SELECT command is a practice that is strongly discouraged by the Redis/Valkey community for modern applications.

Here’s why:

* Not Supported in Valkey Cluster: The SELECT command is disabled in Valkey Cluster mode. If you ever need to scale your application beyond a single Valkey instance, your entire data model based on separate databases will need a complete rewrite.
* Poor Logical Separation: It's not true isolation. A FLUSHALL command will wipe all keys from all databases, not just the currently selected one.
* Tooling and Module Complexity: Many third-party tools, backup scripts, and even some Valkey modules are designed to work primarily or exclusively with database 0.
* Operational Overhead: It becomes difficult to manage. "Which service uses DB 5 again? What's in DB 9?". This adds cognitive load for your team.
* No Cross-Database Operations: You cannot perform atomic operations (like a transaction with MULTI/EXEC) on keys that live in different databases.

## Domain Key Names

We will use routing keys where the first three characters point to the domain, e.g., followed by a separator character then a txkey (time base 12 character short key)

* `con` for contact, e.g. `con:81h17nQrSzhA`
* `usr` for user
* `msg` for messages, email, SMS, etc
* `ses` for session 
* `prd` product
* `ord` for order
* `crt` shopping cart item
* `otp` one time password

_These domains are examples but some applications don't support all domains._

## Client Connections

Core Connection Principle: **Isolate Different Workloads**

Here are the primary use cases for creating dedicated iovalkey clients:

1. Isolating Blocking Operations (Most Common Reason)
Some Valkey commands are "blocking," meaning they can hold a connection open for a long time waiting for something to happen. The classic examples are BLPOP, BRPOP, BRPOPLPUSH, and XREAD ... BLOCK ....
Scenario:
Client A (API Worker): Needs to do very fast GETs and SETs for user API requests. Response time must be in milliseconds.
Client B (Job Queue Worker): Uses BLPOP to wait for a new job to appear in a list. It might wait for seconds or even minutes.
If you used the same connection for both, when Client B calls BLPOP, the connection is blocked. Any request from Client A would have to wait until a job arrives and Client B's command completes. This would be disastrous for your API's performance.
Solution: You create two separate iovalkey instances.
apiClient handles the fast, non-blocking commands.
queueClient handles the slow, blocking BLPOP command.
They operate on independent TCP connections, so the queueClient's blocking call has zero impact on the apiClient's performance.
2. Pub/Sub Subscribers
When a client issues a SUBSCRIBE or PSUBSCRIBE command, it enters a special "subscriber mode." In this mode, the connection can only be used for listening to messages and cannot be used for any other commands (like GET, SET, etc.).
Therefore, you must have a dedicated client instance for any part of your application that subscribes to Pub/Sub channels.
3. High-Priority vs. Low-Priority Traffic
This is a more subtle form of workload isolation.

Scenario:

High-Priority: Serving real-time user requests from your web server.
Low-Priority: A background cron job that runs every hour to perform analytics, deleting thousands of old keys in a large pipeline.

While the background job's PIPELINE might not be a "blocking" command in the same way as BLPOP, it could still saturate the connection for a short period, potentially adding latency to your high-priority requests. Using a separate connection for the background job ensures your user-facing traffic always has a clear, responsive path to Valkey.


### Practical Implementation in Node.js/TypeScript

```typescript
// src/lib/valkey-clients.ts

import Valkey from 'iovalkey';

// Common options for all clients.
// When using a cluster, you would provide the cluster nodes here
// instead of a single host/port.
const connectionOptions = {
  host: process.env.VALKEY_HOST || '127.0.0.1',
  port: parseInt(process.env.VALKEY_PORT || '6379', 10),
  // Recommended options for production
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
};

/**
 * The primary client for fast, non-blocking API commands.
 * Used for most GET/SET/HGETALL operations.
 */
export const apiClient = new Valkey(connectionOptions);

/**
 * A dedicated client for long-running, blocking operations.
 * Use this for job queues (BLPOP, BRPOP).
 */
export const blockingClient = new Valkey(connectionOptions);

/**
 * A dedicated client for listening to Pub/Sub messages.
 * Once subscribed, this client cannot be used for other commands.
 */
export const subscriberClient = new Valkey(connectionOptions);


// It's good practice to add logging for connection events
apiClient.on('connect', () => console.log('API Client connected to Valkey.'));
apiClient.on('error', (err) => console.error('API Client Valkey Error', err));

blockingClient.on('connect', () => console.log('Blocking Client connected to Valkey.'));
blockingClient.on('error', (err) => console.error('Blocking Client Valkey Error', err));

subscriberClient.on('connect', () => console.log('Subscriber Client connected to Valkey.'));
subscriberClient.on('error', (err) => console.error('Subscriber Client Valkey Error', err));

// You would then import these clients wherever they are needed in your app:
// import { apiClient, blockingClient } from '../lib/valkey-clients';
```

### Downsides and Considerations

**Resource Usage**: Each connection consumes a file descriptor and memory on both the client and the Valkey server. Don't create hundreds of clients unnecessarily. A handful of specialized clients is usually sufficient.
Connection Pooling: iovalkey does not have a built-in connection pool. Each new Valkey() creates a single connection. For a high-traffic web application, you might place a connection pool library on top of this pattern, but for many Node.js apps, having a few persistent, long-lived clients as shown above is perfectly fine.

**Final Recommendation**

* Start with one primary apiClient for all your general-purpose, fast commands.
* Immediately create a separate subscriberClient the moment you need to use Pub/Sub.
* Immediately create a separate blockingClient the moment you need to use commands like BLPOP or XREAD BLOCK.
* Consider a backgroundClient if you have heavy, low-priority background jobs that could interfere with your primary API traffic.

## Client Cache

A local Valkey installation will act as a cache to the hosted version.  The cache will use select to switch between databases and include the following:

* user index where the user's email address is the key and the user's key is the value (db 0)
* user_cache : a LRU cache for user records where the max number of user records would be about 100 (db1)
* session_cache : all the active sessions.  this would elmininate having to use the hosted solution because tokens would be in memory and in Firebase. (db 2)
* message_queue : a LRU of messages in transit

###### dpw | 2025-07-16
