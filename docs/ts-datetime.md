# Datetime

Of course! In the TypeScript/Node.js ecosystem, handling dates is a crucial task. Here’s a breakdown of the available "types" for dates, from the built-in basics to the modern, recommended libraries.

### 1. The Built-in `Date` Object

TypeScript, as a superset of JavaScript, uses the standard JavaScript `Date` object. This is the most fundamental way to represent a date and time.

**Type:** `Date`

This object stores a date as the number of milliseconds that have passed since the Unix Epoch (January 1, 1970, 00:00:00 UTC).

**How to Use It:**

```typescript
// 1. Create a date object for the current time
const now: Date = new Date();
console.log('Current time:', now.toISOString()); // e.g., "2023-10-27T14:30:00.123Z"

// 2. Create a date from a specific string (ISO 8601 format is recommended)
const specificDate: Date = new Date('2024-01-15T10:00:00Z');
console.log('Specific date:', specificDate.toUTCString()); // "Mon, 15 Jan 2024 10:00:00 GMT"

// 3. Create a date from components (year, month, day, etc.)
// Watch out! Months are 0-indexed (0 = January, 11 = December)
const birthday: Date = new Date(1995, 4, 23); // May 23, 1995
console.log('Birthday:', birthday.toLocaleDateString('en-US')); // "5/23/1995"

// 4. Getting components from a date
console.log('Year:', specificDate.getFullYear()); // 2024
console.log('Month (0-indexed):', specificDate.getMonth()); // 0 (for January)
console.log('Day of month:', specificDate.getDate()); // 15
```

**Pros:**
*   Built-in, no external dependencies needed.
*   Fine for very simple, quick tasks.

**Cons (Important!):**
*   **Mutable:** Methods like `setDate()` or `setHours()` modify the original `Date` object, which can lead to unexpected bugs.
*   **Inconsistent Parsing:** `new Date("some string")` can behave differently across JavaScript engines. Always prefer the ISO 8601 format (`YYYY-MM-DDTHH:mm:ss.sssZ`).
*   **Confusing Timezones:** It primarily works with the user's system timezone or UTC, which can be tricky to manage reliably.
*   **Clunky API:** The 0-indexed months and other quirks make the API error-prone.

---

### 2. Primitives for Representing Dates

Often, you don't pass the `Date` object around directly, especially in APIs or databases. Instead, you use primitive types that are easier to serialize.

#### a) Date Strings (ISO 8601)

**Type:** `string`

This is the most common and recommended way to represent a date as a string. It's unambiguous, machine-readable, and human-readable.

```typescript
// It's good practice to use a type alias to be more explicit
type ISODateString = string;

const eventStart: ISODateString = "2024-07-26T09:00:00Z";

// You can easily convert it to a Date object when you need to manipulate it
const eventDateObject: Date = new Date(eventStart);

console.log(`Event starts at: ${eventDateObject.toLocaleString()}`);
```

#### b) Timestamps (Unix Milliseconds)

**Type:** `number`

This represents the date as the number of milliseconds since the Unix Epoch. It's a pure, timezone-agnostic representation, excellent for calculations and storage.

```typescript
// A type alias makes the code's intent clearer
type Timestamp = number;

// Get the current timestamp
const rightNow: Timestamp = Date.now();
console.log('Timestamp:', rightNow); // e.g., 1698417000123

// Get a timestamp from a Date object
const myDate = new Date('2024-01-01T00:00:00Z');
const myTimestamp: Timestamp = myDate.getTime();
console.log('Timestamp for 2024:', myTimestamp); // 1704067200000

// Create a Date object from a timestamp
const dateFromTimestamp = new Date(myTimestamp);
console.log('Date from timestamp:', dateFromTimestamp.toISOString());
```

---

### 3. Popular Libraries (The Modern & Recommended Approach)

For almost any serious Node.js application, you should use a dedicated date library. They solve all the problems of the native `Date` object.

#### a) `date-fns` (Highly Recommended)

A modern, immutable, and tree-shakable library. It provides a huge set of simple, pure functions to manipulate dates.

**Installation:**
```bash
npm install date-fns
```

**How to Use It:**

```typescript
import { format, addDays, isAfter } from 'date-fns';

// date-fns works with native Date objects
const today = new Date();

// Add 5 days to today (returns a NEW Date object, 'today' is not changed)
const futureDate = addDays(today, 5);

// Format the dates for display
const formattedToday = format(today, 'MM/dd/yyyy');       // "10/27/2023"
const formattedFuture = format(futureDate, 'eeee, MMMM do'); // "Wednesday, November 1st"

console.log(`Today is ${formattedToday}`);
console.log(`In 5 days, it will be ${formattedFuture}`);

// Compare dates easily
console.log('Is the future date after today?', isAfter(futureDate, today)); // true
```
**Why it's great:** Immutable, predictable, great TypeScript support, and because it's functional, it's very "tree-shakable" (your final bundle only includes the functions you actually use).

#### b) `Luxon`

From the creators of the original Moment.js, Luxon is its modern successor. It's an object-oriented library that wraps date objects in its own `DateTime` class.

**Installation:**
```bash
npm install luxon
npm install --save-dev @types/luxon # TypeScript types
```

**How to Use It:**
```typescript
import { DateTime } from 'luxon';

// Create a DateTime object
const now = DateTime.now();

// Add time (returns a NEW DateTime object)
const futureDateTime = now.plus({ days: 5, hours: 2 });

// Format for display
console.log(now.toFormat('MM/dd/yyyy HH:mm'));       // "10/27/2023 14:30"
console.log(futureDateTime.toFormat('ff')); // Full format with timezone

// Excellent timezone support
const tokyoTime = now.setZone('Asia/Tokyo');
console.log(`The time in Tokyo is: ${tokyoTime.toFormat('HH:mm')}`);

console.log('Is the future date after now?', futureDateTime > now); // true
```
**Why it's great:** Immutable, powerful object-oriented API, and best-in-class timezone and internationalization support.

---

### Summary and Recommendation

| Option | Type | Key Characteristics | Best For... |
| :--- | :--- | :--- | :--- |
| **Built-in `Date`** | `Date` | Mutable, basic API, timezone-sensitive | Extremely simple scripts where no manipulation is needed. |
| **ISO String** | `string` | Immutable, standard, serializable | API communication (JSON payloads), database storage. |
| **Timestamp** | `number` | Immutable, timezone-agnostic, efficient | Calculations, comparisons, and efficient storage. |
| **`date-fns`** | `Date` (as input/output) | **Recommended.** Immutable, functional, tree-shakable. | New projects, developers who prefer a functional style. |
| **`Luxon`** | `DateTime` (wrapper object) | **Recommended.** Immutable, object-oriented, great timezone support. | Projects with complex timezone needs or for developers who prefer a chainable, OO API. |

For any new Node.js + TypeScript project, your best choice is to use **`date-fns`** or **`Luxon`**. They are reliable, predictable, and will save you from countless bugs related to mutability and timezones.

##

Excellent question! This delves into high-resolution time, which is crucial for things like performance benchmarking, logging, and certain types of real-time applications.

The short answer is: **Yes, you can get nanosecond precision in Node.js**, and from that, you can easily calculate microseconds. However, you **cannot** get this level of precision from the standard `Date` object.

Let's break down how to do it.

### The Problem with `Date`

The built-in `Date` object in JavaScript (and therefore TypeScript) has a precision of **one millisecond**.

```typescript
console.log(Date.now()); // 1698425871123 (milliseconds since epoch)
```

There is no way to get finer granularity from `Date`. For that, you need to use Node.js's built-in high-resolution time capabilities.

---

### The Node.js Solution: `process.hrtime()`

Node.js provides a `process.hrtime()` method specifically for high-resolution time measurements. This time is **not** related to the time of day (it's not a "wall clock"). Instead, it's a **monotonic clock** that starts at an arbitrary point in the past and increases continuously. It's perfect for measuring time differences with high accuracy.

#### Modern Approach (Recommended): `process.hrtime.bigint()`

Since Node.js v10.7.0, a simpler version that returns a `bigint` is available. This is the best way to work with nanoseconds today as it avoids floating-point inaccuracies.

**Type:** `bigint` (representing total nanoseconds)

**How to Use It:**

```typescript
// Get the current high-resolution time as a bigint of nanoseconds
const start: bigint = process.hrtime.bigint();
console.log(`Start (nanoseconds): ${start}`);
// e.g., 51941765432101n

// Simulate some work
for (let i = 0; i < 1000000; i++) {
  // some quick operation
}

const end: bigint = process.hrtime.bigint();
console.log(`End (nanoseconds):   ${end}`);

// Calculate the difference
const durationInNanoseconds: bigint = end - start;
console.log(`\nOperation took ${durationInNanoseconds} nanoseconds.`);

// --- How to get microseconds ---
// To convert nanoseconds to microseconds, divide by 1000.
// Use bigint division by adding 'n' to the number.
const durationInMicroseconds: bigint = durationInNanoseconds / 1000n;
console.log(`That's ${durationInMicroseconds} microseconds.`);

// --- For context, convert to milliseconds ---
const durationInMilliseconds = Number(durationInNanoseconds / 1000000n);
console.log(`And roughly ${durationInMilliseconds} milliseconds.`);
```

### How to Get Microseconds or Nanoseconds at any Instant

If you just need a function to grab the current high-resolution timestamp, you can write simple helpers:

```typescript
/**
 * Returns the current high-resolution time in nanoseconds as a bigint.
 * This is a monotonic clock, not related to the wall-clock time of day.
 */
function getNanoseconds(): bigint {
  return process.hrtime.bigint();
}

/**
 * Returns the current high-resolution time in microseconds.
 * Note: This involves integer division, so it loses the sub-microsecond precision.
 */
function getMicroseconds(): bigint {
  return process.hrtime.bigint() / 1000n;
}

const now_ns = getNanoseconds();
const now_us = getMicroseconds();

console.log(`Current hrtime (ns): ${now_ns}`);
console.log(`Current hrtime (µs): ${now_us}`);
```

---

### Important Distinction: Wall Clock vs. Monotonic Clock

It's critical to understand the difference between these two types of time:

| Feature | `Date.now()` (Wall Clock) | `process.hrtime.bigint()` (Monotonic Clock) |
| :--- | :--- | :--- |
| **Purpose** | Tells you the current time and date in the real world. | Measures elapsed time between two points. |
| **Unit** | Milliseconds | **Nanoseconds** |
| **Stability** | **Can go backward!** Can be adjusted by the system administrator or synchronized via NTP (Network Time Protocol). | **Always moves forward.** Not affected by system time changes. It's perfectly reliable for duration measurement. |
| **Reference Point** | Unix Epoch (Jan 1, 1970 UTC) | An arbitrary, fixed point in time when the Node.js process started. |
| **Use Case** | Timestamps, scheduling events ("run this at 5 PM"). | Performance benchmarking, physics simulations, high-frequency logging. |

You **cannot** convert an `hrtime` value into a human-readable date like "October 27, 2023" because its starting point is arbitrary.

### Summary Table

| Method | Runtime | Unit | Precision | Type | Use Case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Date.now()` | Node.js & Browser | Milliseconds | Millisecond | `number` | Wall-clock time, timestamps. |
| `performance.now()` | Browser & Node.js¹ | Milliseconds | **Microsecond** | `number` | Measuring elapsed time in browsers. |
| `process.hrtime.bigint()` | **Node.js only** | **Nanoseconds** | **Nanosecond** | `bigint` | **High-precision duration measurement in Node.js.** |

¹*In Node.js, `performance.now()` from the `perf_hooks` module provides a similar microsecond-precision monotonic clock as the browser, returning a `number` representing milliseconds.*

## For TypeScript

Here are some popular 3rd party libraries for handling dates in TypeScript:

* [date-fns](https://date-fns.org/) - A modern, modular date utility library with excellent TypeScript support. It provides over 200 functions for manipulating, formatting, and parsing dates. Each function is a pure function that can be imported individually, making it tree-shakable and lightweight.
* Day.js - A lightweight (2KB) alternative to Moment.js with a similar API. It's immutable, has good TypeScript definitions, and supports plugins for extended functionality like timezone handling and advanced formatting.
* Luxon - Created by the Moment.js team as a successor. It's built on top of the Intl API, provides excellent timezone support, and has first-class TypeScript support. It's more powerful than Day.js but larger in size.
* js-joda - A JavaScript port of Java's JSR-310 date/time API. It's immutable, type-safe, and provides a rich set of date/time operations. Good for complex date arithmetic and business logic.
* Tempo - A newer library focused on being lightweight and TypeScript-first, with modern ES6+ features and good tree-shaking support.

For most projects, date-fns or Day.js are excellent choices due to their modern APIs, good TypeScript support, and active maintenance. Luxon is great if you need robust timezone handling, while js-joda works well for complex date calculations.

**Recommendation:**

*   For knowing **what time it is**, use `new Date()` or a library like `date-fns` or `Luxon`.
*   For **measuring how long something takes** in Node.js with the highest precision, always use **`process.hrtime.bigint()`**.

###### dpw | 2025-07-09 | 81WAQyffGINO
