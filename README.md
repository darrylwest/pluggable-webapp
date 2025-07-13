# Pluggable Web Application

## Primary Goals

* flexibility: swap logic modules with a minimum of side effects
* engineering specialties: assign tasks to engineers with a limited scope

[System Diagram](docs/system-diagram.md) | 


## Node/Typescript Dependencies

* node
* npm
* typescript
* tRPC for client/server and server-to-server
* zod for model validation
* eslint
* jest unit tests + coverage
* prettier
* winston and winston-daily-rotate-file for logging json 
* iovalkey for database
* dotenvx
* cors
* date-fns
* nodemon for the server

## Other Depandencies

* github actions

Notes:

* use mono repo with packages/client packages/server

Direct Function Calls: When both your main server application and your Firebase wrapper are part of the same server package (and thus the same Node.js process), createCallerFactory() allows you to call the tRPC procedures of your wrapper directly, without any HTTP or network overhead. It's like calling a local function.

End-to-End Type Safety: By having the tRPC router definitions for your wrapper within the server package, any other part of your server (or even your client, if you configure it to import types) can benefit from compile-time type checking and auto-completion for these calls.

Simplified Monorepo Management: It keeps related server-side logic co-located and makes dependency management straightforward within your monorepo.

###### dpw | 2025-07-12 | 81TpmjcnPhcn
