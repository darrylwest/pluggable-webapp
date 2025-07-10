# TypeScript Data Models

## Overview

The model definitions are targeted for TypeScript and provide a foundation for an appointment/calendar system.

## Core Models

### Domain Key: TxKey

Function: `createTxKey`
File: txkey.ts

* A base62 date-based key unique to a specific domain
* Used for unique ID in domain models
* Uses crypto to generate random numbers
* Uses process.hrtime.bigint() for high-resolution nanosecond clock
* Always 12 characters
* Sortable, new keys always increase (dt + random)

```typescript
export function createTxKey(): string {
    // Implementation would go here
    // Returns a 12-character base62 string
}
```

### Base Model

The base model is used by all models to create a consistent way of creating, updating and locking models.

```typescript
export interface BaseModel {
    key: string;           // use createTxKey() to create a 12 char short key
    dateCreated: number;   // Date.now()
    lastUpdated: number;   // Date.now()
    version: number;       // for optimistic locking
    status: string;        // New, Pending, Active, Inactive, Verified, Deleted, Shipped, Completed, etc
}
```

### Contact Model

The contact model is used for email contacts, mailing lists etc. No login, just optional name and email.

```typescript
export interface ContactModel extends BaseModel {
    first_name?: string;              // optional
    last_name?: string;               // optional
    email: string;                    // required
    phone?: string;                   // optional
    ip_address: string;               // required
    details?: Map<string, string>;    // optional
}
```

### Address Model

Physical addresses for shipto, billto, etc. Does not have a BaseModel extension.

```typescript
export interface AddressModel {
    addr1: string;        // required
    addr2?: string;       // optional
    addr3?: string;       // optional
    city: string;         // required
    state: string;        // required
    zip: string;          // required
    latitude?: number;    // optional
    longitude?: number;   // optional
}
```

### User Model

The user model extends contact model and uses address model.

```typescript
export interface UserModel extends ContactModel {
    roles: string;                          // the roles that this user is authorized for
    preferences?: Map<string, string>;      // specific preference settings
    company_name?: string;                  // optional name of the company affiliation
    addresses?: AddressModel[];             // array of addresses (home, work, billing, etc.)
}
```

## Appointment/Calendar System Models

### Availability Model

Defines when a user or resource is available for appointments.

```typescript
export interface AvailabilityModel extends BaseModel {
    user_key: string;                    // reference to UserModel
    day_of_week: number;                 // 0-6 (Sunday-Saturday)
    start_time: string;                  // HH:MM format (24-hour)
    end_time: string;                    // HH:MM format (24-hour)
    date_range_start?: number;           // specific date range start (Date.now())
    date_range_end?: number;             // specific date range end (Date.now())
    timezone: string;                    // timezone identifier (e.g., "America/New_York")
    is_recurring: boolean;               // true for weekly recurring availability
    exceptions?: AvailabilityException[]; // specific dates to exclude
}

export interface AvailabilityException {
    date: number;                        // Date.now() for the exception date
    reason?: string;                     // optional reason for unavailability
}
```

### Appointment Model

Represents scheduled appointments between users.

```typescript
export interface AppointmentModel extends BaseModel {
    title: string;                       // appointment title/subject
    description?: string;                // optional detailed description
    organizer_key: string;               // reference to UserModel who created appointment
    attendees: AppointmentAttendee[];    // list of attendees
    start_time: number;                  // Date.now() for appointment start
    end_time: number;                    // Date.now() for appointment end
    timezone: string;                    // timezone identifier
    location?: AppointmentLocation;      // optional location details
    appointment_type: string;            // "meeting", "call", "consultation", etc.
    is_recurring: boolean;               // true for recurring appointments
    recurrence_pattern?: RecurrencePattern; // pattern for recurring appointments
    reminders?: AppointmentReminder[];   // notification reminders
    metadata?: Map<string, string>;      // additional custom data
}

export interface AppointmentAttendee {
    user_key: string;                    // reference to UserModel
    status: 'pending' | 'accepted' | 'declined' | 'tentative';
    is_required: boolean;                // true if attendance is required
    role?: string;                       // optional role in the appointment
}

export interface AppointmentLocation {
    type: 'physical' | 'virtual' | 'phone';
    address?: AddressModel;              // for physical locations
    virtual_link?: string;               // for virtual meetings (Zoom, Teams, etc.)
    phone_number?: string;               // for phone conferences
    room_name?: string;                  // specific room or location name
}

export interface RecurrencePattern {
    frequency: 'daily' | 'weekly' | 'monthly' | 'yearly';
    interval: number;                    // every N days/weeks/months/years
    days_of_week?: number[];             // for weekly: [0,1,2,3,4,5,6]
    day_of_month?: number;               // for monthly: 1-31
    month_of_year?: number;              // for yearly: 1-12
    end_date?: number;                   // when recurrence ends (Date.now())
    max_occurrences?: number;            // max number of occurrences
}

export interface AppointmentReminder {
    minutes_before: number;              // how many minutes before appointment
    method: 'email' | 'sms' | 'push' | 'popup';
    message?: string;                    // optional custom reminder message
}
```

### Calendar Model

Represents a calendar that contains appointments.

```typescript
export interface CalendarModel extends BaseModel {
    name: string;                        // calendar name
    owner_key: string;                   // reference to UserModel
    color?: string;                      // hex color code for UI display
    is_public: boolean;                  // true if calendar is publicly viewable
    shared_with?: CalendarShare[];       // users who have access to this calendar
    timezone: string;                    // default timezone for this calendar
    description?: string;                // optional calendar description
}

export interface CalendarShare {
    user_key: string;                    // reference to UserModel
    permission: 'view' | 'edit' | 'admin';
    date_shared: number;                 // Date.now() when access was granted
}
```

### Booking Model

For appointment booking requests and management.

```typescript
export interface BookingModel extends BaseModel {
    requested_by_key: string;            // reference to UserModel making the request
    provider_key: string;                // reference to UserModel providing the service
    requested_start_time: number;        // Date.now() for requested start
    requested_end_time: number;          // Date.now() for requested end
    confirmed_start_time?: number;       // actual confirmed start time
    confirmed_end_time?: number;         // actual confirmed end time
    service_type: string;                // type of service being booked
    booking_status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
    cancellation_reason?: string;        // reason if cancelled
    appointment_key?: string;            // reference to created AppointmentModel
    notes?: string;                      // additional booking notes
    payment_required: boolean;           // true if payment is needed
    payment_amount?: number;             // amount in cents
    payment_status?: 'pending' | 'paid' | 'refunded';
}
```

## Validation Interfaces

Each data model should implement validation methods:

```typescript
export interface ModelValidator<T> {
    validate(model: T): ValidationResult;
    validateField(model: T, fieldName: keyof T): FieldValidationResult;
}

export interface ValidationResult {
    isValid: boolean;
    errors: ValidationError[];
}

export interface ValidationError {
    field: string;
    message: string;
    code: string;
}

export interface FieldValidationResult {
    isValid: boolean;
    error?: ValidationError;
}
```

## Helper Types and Enums

```typescript
export enum AppointmentStatus {
    DRAFT = 'draft',
    SCHEDULED = 'scheduled',
    IN_PROGRESS = 'in_progress',
    COMPLETED = 'completed',
    CANCELLED = 'cancelled',
    NO_SHOW = 'no_show'
}

export enum UserRole {
    ADMIN = 'admin',
    PROVIDER = 'provider',
    CLIENT = 'client',
    VIEWER = 'viewer'
}

export type TimeSlot = {
    start: number;      // Date.now()
    end: number;        // Date.now()
    available: boolean;
    reason?: string;    // reason if not available
};
```

## Usage Examples

```typescript
// Creating a new appointment
const appointment: AppointmentModel = {
    key: createTxKey(),
    dateCreated: Date.now(),
    lastUpdated: Date.now(),
    version: 1,
    status: AppointmentStatus.SCHEDULED,
    title: "Project Review Meeting",
    organizer_key: "user123",
    attendees: [
        {
            user_key: "user456",
            status: 'pending',
            is_required: true
        }
    ],
    start_time: Date.now() + 86400000, // tomorrow
    end_time: Date.now() + 86400000 + 3600000, // tomorrow + 1 hour
    timezone: "America/New_York",
    appointment_type: "meeting",
    is_recurring: false
};

// Creating availability
const availability: AvailabilityModel = {
    key: createTxKey(),
    dateCreated: Date.now(),
    lastUpdated: Date.now(),
    version: 1,
    status: "active",
    user_key: "user123",
    day_of_week: 1, // Monday
    start_time: "09:00",
    end_time: "17:00",
    timezone: "America/New_York",
    is_recurring: true
};
```


###### dpw | 2025-07-10 | 81VOlU6XYyhM | Updated with complete TypeScript implementations