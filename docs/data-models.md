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

### Base Model

The base model is used by all models to create a consistent way of creating, updating and locking models.

```typescript
export function createTxKey(): string {
    // Implementation would go here
    // Returns a 12-character base62 string
}

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

```
export interface CancellationPolicy {
    advance_notice_required: number;     // minutes of advance notice required
    refund_policy: 'full' | 'partial' | 'none';
    partial_refund_percentage?: number;  // if partial refund
    waiting_list_notification_window: number; // minutes to notify waiting list
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
    start_time: string;                  // HH:MM format (24-hour)
    end_time: string;                    // HH:MM format (24-hour)
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
    requested_start_time: string;        // HH:MM
    requested_end_time: string;          // HH:MM
    confirmed_start_time?: string;       // HH:MM
    confirmed_end_time?: string;         // HH:MM
    service_type: string;                // type of service being booked
    booking_status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
    cancellation_reason?: string;        // reason if cancelled
    appointment_key?: string;            // reference to created AppointmentModel
    notes?: string;                      // additional booking notes
    payment_required: boolean;           // true if payment is needed
    payment_amount?: number;             // amount in cents
    payment_status?: 'pending' | 'paid' | 'refunded';
    waiting_list?: WaitingListEntry[];   // users waiting for this time slot
    allows_waiting_list: boolean;        // true if waiting list is enabled for this booking
}

export interface WaitingListEntry {
    user_key: string;                    // reference to UserModel on waiting list
    date_added: string;                  // YYYY-MM-DD
    priority: number;                    // 1 = highest priority, higher numbers = lower priority
    notification_preferences: NotificationPreference[];
    is_active: boolean;                  // false if user no longer wants to be notified
    max_wait_time?: number;              // optional: max minutes they'll wait for notification response
    auto_book: boolean;                  // true if they want automatic booking if slot opens
    notes?: string;                      // optional notes from the user
}

export interface NotificationPreference {
    method: 'email' | 'sms' | 'push' | 'phone';
    contact_info: string;                // email address, phone number, etc.
    is_primary: boolean;                 // true for the preferred notification method
}
```

## Waiting List Management System

### Waiting List Service Interface

```typescript
export interface WaitingListService {
    // Add user to waiting list
    addToWaitingList(
        bookingKey: string, 
        userKey: string, 
        preferences: WaitingListPreferences
    ): Promise<WaitingListEntry>;
    
    // Remove user from waiting list
    removeFromWaitingList(bookingKey: string, userKey: string): Promise<boolean>;
    processCancellation(bookingKey: string, reason: string): Promise<NotificationResult[]>;
    
    // Handle waiting list response
    handleWaitingListResponse(
        notificationKey: string, 
        response: 'accepted' | 'declined'
    ): Promise<BookingResult>;
    
    // Get waiting list position
    getWaitingListPosition(bookingKey: string, userKey: string): Promise<number>;
    
    // Clean up expired notifications
    cleanupExpiredNotifications(): Promise<void>;
}

export interface WaitingListPreferences {
    notification_methods: NotificationPreference[];
    auto_book: boolean;
    max_wait_time?: number;
    notes?: string;
}

export interface NotificationResult {
    user_key: string;
    success: boolean;
    notification_key?: string;
    error?: string;
}

export interface BookingResult {
    success: boolean;
    booking_key?: string;
    error?: string;
    position_in_queue?: number;
}
```

### Waiting List Workflow

```typescript
export enum WaitingListAction {
    ADD_TO_WAITLIST = 'add_to_waitlist',
    REMOVE_FROM_WAITLIST = 'remove_from_waitlist',
    NOTIFY_AVAILABLE = 'notify_available',
    RESPONSE_ACCEPTED = 'response_accepted',
    RESPONSE_DECLINED = 'response_declined',
    RESPONSE_EXPIRED = 'response_expired',
    AUTO_BOOK = 'auto_book'
}

export interface WaitingListEvent extends BaseModel {
    booking_key: string;
    user_key: string;
    action: WaitingListAction;
    previous_position?: number;
    new_position?: number;
    notification_key?: string;
    metadata?: Map<string, string>;
}
```

### Waiting List Notification Model

Tracks notifications sent to waiting list users when slots become available.

```typescript
export interface WaitingListNotificationModel extends BaseModel {
    booking_key: string;                 // reference to BookingModel that became available
    user_key: string;                    // reference to UserModel being notified
    notification_method: 'email' | 'sms' | 'push' | 'phone';
    sent_at: number;                     // Date.now() when notification was sent
    expires_at: number;                  // Date.now() when notification expires
    response_status: 'pending' | 'accepted' | 'declined' | 'expired';
    response_date?: number;              // Date.now() when user responded
    notification_content: string;        // the actual message sent
    retry_count: number;                 // number of retry attempts
    max_retries: number;                 // maximum retry attempts allowed
}
```

### Time Slot Model

Represents available time slots that can have waiting lists.

```typescript
export interface TimeSlotModel extends BaseModel {
    provider_key: string;                // reference to UserModel providing the service
    start_time: string;                  // HH:MM
    end_time: string;                    // HH:MM
    service_type: string;                // type of service for this slot
    is_available: boolean;               // true if slot is still available
    current_booking_key?: string;        // reference to current BookingModel if booked
    waiting_list: WaitingListEntry[];    // users waiting for this specific slot
    max_waiting_list_size?: number;      // optional limit on waiting list size
    slot_status: 'available' | 'booked' | 'blocked' | 'cancelled';
    cancellation_policy: CancellationPolicy;
    timezone: string;                    // timezone for this slot
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

## Waiting List Usage Examples

```typescript
// Adding a user to a waiting list
const waitingListService = new WaitingListService();

// User wants to be added to waiting list for a booked slot
const waitingListEntry = await waitingListService.addToWaitingList(
    "booking123", 
    "user456", 
    {
        notification_methods: [
            { method: 'email', contact_info: 'user@example.com', is_primary: true },
            { method: 'sms', contact_info: '+1234567890', is_primary: false }
        ],
        auto_book: false, // user wants to confirm before booking
        max_wait_time: 30, // will wait up to 30 minutes to respond
        notes: "Prefer morning appointments"
    }
);

// When a booking is cancelled, process the waiting list
const cancellationResults = await waitingListService.processCancellation(
    "booking123", 
    "User requested cancellation"
);

// Example of how the cancellation processing might work:
async function processCancellation(bookingKey: string, reason: string): Promise<NotificationResult[]> {
    // 1. Update booking status to cancelled
    const booking = await getBooking(bookingKey);
    booking.booking_status = 'cancelled';
    booking.cancellation_reason = reason;
    
    // 2. Get waiting list sorted by priority
    const waitingList = booking.waiting_list
        ?.filter(entry => entry.is_active)
        .sort((a, b) => a.priority - b.priority) || [];
    
    const results: NotificationResult[] = [];
    
    // 3. Notify users in priority order
    for (const entry of waitingList) {
        try {
            // Create notification
            const notification: WaitingListNotificationModel = {
                key: createTxKey(),
                dateCreated: Date.now(),
                lastUpdated: Date.now(),
                version: 1,
                status: 'pending',
                booking_key: bookingKey,
                user_key: entry.user_key,
                notification_method: entry.notification_preferences.find(p => p.is_primary)?.method || 'email',
                sent_at: Date.now(),
                expires_at: Date.now() + (entry.max_wait_time || 60) * 60 * 1000, // default 1 hour
                response_status: 'pending',
                notification_content: `A slot has become available for ${booking.service_type} on ${new Date(booking.requested_start_time).toLocaleString()}`,
                retry_count: 0,
                max_retries: 3
            };
            
            // Send notification via preferred method
            const sent = await sendNotification(notification);
            
            results.push({
                user_key: entry.user_key,
                success: sent,
                notification_key: sent ? notification.key : undefined,
                error: sent ? undefined : 'Failed to send notification'
            });
            
            // If auto-book is enabled and notification sent successfully
            if (entry.auto_book && sent) {
                // Automatically book the slot for this user
                const autoBookResult = await autoBookSlot(bookingKey, entry.user_key);
                if (autoBookResult.success) {
                    break; // Slot is now booked, stop notifying others
                }
            }
            
        } catch (error) {
            results.push({
                user_key: entry.user_key,
                success: false,
                error: error.message
            });
        }
    }
    
    return results;
}

// Creating a time slot with waiting list capability
const timeSlot: TimeSlotModel = {
    key: createTxKey(),
    dateCreated: Date.now(),
    lastUpdated: Date.now(),
    version: 1,
    status: 'available',
    provider_key: "provider123",
    start_time: Date.now() + 86400000, // tomorrow
    end_time: Date.now() + 86400000 + 3600000, // tomorrow + 1 hour
    service_type: "consultation",
    is_available: true,
    waiting_list: [],
    max_waiting_list_size: 10,
    slot_status: 'available',
    cancellation_policy: {
        advance_notice_required: 120, // 2 hours notice
        refund_policy: 'full',
        waiting_list_notification_window: 30 // 30 minutes to notify waiting list
    },
    timezone: "America/New_York"
};
```

## Waiting List Business Logic

```typescript
export class WaitingListManager {
    
    // Calculate priority based on various factors
    static calculatePriority(
        userKey: string, 
        dateAdded: number, 
        userTier?: string,
        previousCancellations?: number
    ): number {
        let priority = 100; // base priority
        
        // Earlier added users get higher priority (lower number)
        const hoursWaiting = (Date.now() - dateAdded) / (1000 * 60 * 60);
        priority -= Math.floor(hoursWaiting); // reduce by 1 for each hour waiting
        
        // Premium users get higher priority
        if (userTier === 'premium') priority -= 20;
        if (userTier === 'vip') priority -= 50;
        
        // Users with previous cancellations get lower priority
        if (previousCancellations) {
            priority += previousCancellations * 10;
        }
        
        return Math.max(1, priority); // minimum priority of 1
    }
    
    // Check if user can be added to waiting list
    static canAddToWaitingList(
        timeSlot: TimeSlotModel, 
        userKey: string
    ): { canAdd: boolean; reason?: string } {
        
        if (!timeSlot.is_available && timeSlot.slot_status !== 'booked') {
            return { canAdd: false, reason: 'Slot is not available for booking' };
        }
        
        if (timeSlot.current_booking_key && timeSlot.waiting_list.some(entry => entry.user_key === userKey)) {
            return { canAdd: false, reason: 'User already on waiting list' };
        }
        
        if (timeSlot.max_waiting_list_size && timeSlot.waiting_list.length >= timeSlot.max_waiting_list_size) {
            return { canAdd: false, reason: 'Waiting list is full' };
        }
        
        return { canAdd: true };
    }
}
```


###### dpw | 2025-07-11 | 81VOlU6XYyhM
