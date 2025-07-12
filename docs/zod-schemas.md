# Zod Data Schemas

## Overview

The model definitions are targeted for TypeScript and provide a foundation for an appointment/calendar system.

## Core Models

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

###### dpw | 2025-07-11 | 81ZOyS3wzF6j
