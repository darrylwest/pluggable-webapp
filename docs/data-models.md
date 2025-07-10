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

The base model is used by all models to create a consistent way of creating, updating and locking models.

* key: createTxKey()
* dateCreated: number // Date.now()
* lastUpdate: number  // Date.now()
* version: number     // for optimistic locking

Implementation

```typescript
export interface BaseModel {
    key: string;
    dateCreated: number;
    lastUpdated: number;
    version: number;
}
```

### Contact Model

### Address Model

### User Model

### Availability Model

### Appointment Model

## Validations

Each data model has it's own way of validaing itself.

###### dpw | 2025-07-10 | 81VOlU6XYyhM

