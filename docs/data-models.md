# Typescript Data Models

## Overview

The model definitions are targeted for TypeScript

## Models

### Domain Key: TxKey

Function: `createTxKey`
File: txkey.tc

* a base62 date based key unique to a specific domain
* used for unique id in domain models
* uses crypto to generate random numbers
* uses process.hrtime.bigint() for high res nano second clock
* always 12 characters
* sortable, new keys always increase (dt + random)

### Base Model

The base model is used by all models to create a consistent way of creating, updating and locking models. Attributes include:

* key: string         // use createTxKey() to create a 12 char short key
* dateCreated: number // Date.now()
* lastUpdate: number  // Date.now()
* version: number     // for optimistic locking
* status: string      // the current status of the object, New, Pending, Active, Inactive, Verified, Deleted, Shipped, Completed, etc

Implementation:

```typescript
export interface BaseModel {
    key: string;
    dateCreated: number;
    lastUpdated: number;
    version: number;
    status: string;
}
```

### Contact Model

The contact model is used for email contacts, mailing lists etc.  No login, just optional name an email.

* extends BaseModel   // required
* first_name: string  // optional 
* last_name: string   // optional 
* email: string       // required
* phone: string       // optional
* ip_address: string  // required
* details: Map<string, string> // optional

Implementation:

```typescript

```

### Address Model

Physical addresses for shipto, billto, etc. Does not have a BaseModel extention.

* addr1: string     // required
* addr2: string     // optional
* addr3: string     // optional
* city: string      // required
* state: string     // required
* zip: string       // required
* latitude: number  // optional
* longitude: number // optional

### User Model

The user model extends contact model and uses address model

* roles: string                     // the roles that this user is authorized for
* preferences: Map<string, string>  // specific preference settings
* company_name: string              // optinal name of the company affiliation

### Availability Model

### Appointment Model

## Validations

Each data model has it's own way of validaing itself.

###### dpw | 2025-07-10 | 81VOlU6XYyhM

