# ValKey Database Plans

## Local Instance

* for development
* for production of small sites

## Client Connections

The strategy is to use a connection per domain e.g., 

* userDb (users, contacts) search by email
* sessionDb (search by email)
* messageDb (email, sms, etc) insert, process, remove
* availabilityDb (availability, appointment, calendar, booking waitlist, timeslot) ?
* orderDb (cartItems, payments, orders, settlement) search by email

###### dpw | 2025-07-10 | 81YC442voyLc
