# Calendar Booking Project

## Core features and functionality

### The Medical Provider

* **As a Provider, I want to** define my recurring weekly availability and block off specific time slots **so that** patients can only book appointments when I am available.
* **As a Provider, I want to** set the duration of standard appointment slots (e.g., 30, 45, 60 minutes) **so that** my calendar is scheduled efficiently.
* **As a Provider, I want to** view and manage patient-uploaded documents within the patient's profile **so that** I can inspect their medical history and test results.
* **As a Provider, I want to** send secure, private messages to patients via the application, with notifications sent to their email or SMS, **so that** I can communicate with them efficiently.
* **As a Provider, I want to** create and configure my cancellation policy **so that** patients understand the terms before booking.

### The Patient

* **As a Patient, I want to** sign up and sign in to the application **so that** I can access provider services.
* **As a Patient, I want to** send secure, private messages to the provider **so that** I can ask questions about my treatment or appointments.
* **As a Patient, I want to** upload my medical history, test results, or other relevant documents **so that** my provider can review them.
* **As a Patient, I want to** view the provider's open time slots and book an appointment **so that** I can schedule a visit.
* **As a Patient, I want to** cancel a previously booked appointment **so that** I can manage my schedule.
* **As a Patient, I want to** be able to view the provider's cancellation policy **so that** I am aware of any potential fees.
* **As a Patient, I want to** pay for services with a credit card **so that** I can complete the booking process. The system will require card details to hold a booking and will charge based on the provider's policies.

## Target audience

1.  Medical Providers that offer services at scheduled times, such as therapists, chiropractors, specialists, and other single-person or small clinics.
2.  Clients / patients that visit providers by booking appointment slots.

## Platform

This application will be a responsive web application designed to run in a browser on desktops, mobile phones, and tablets, likely utilizing a mobile-first design philosophy.

## User interface and experience concepts

The UI/UX will be defined by a set of Figma mockups that will serve as the single source of truth for the application's appearance and user flow. These mockups will be translated directly into Vue components.

## Data storage and management needs

* The application will be hosted on **DigitalOcean** Droplets.
* Appointment and booking data are stored in Valkey. Valkey will be used as a primary, persistent datastore, with AOF (Append Only File) persistence enabled for data durability and regular backups configured.
* Authentication uses Firebase through a back-end service. Firebase maintains the list of user credentials.
* User authorization roles and permissions are stored in Valkey.
* Patient reports will be stored in **DigitalOcean** Storage Buckets. These buckets will be configured with encryption at rest, and all access will be tightly controlled through secure, time-limited methods.

## User authentication and security requirements

Achieving HIPAA **compliant** status is a core requirement. All development and operational practices must adhere to its standards. This includes, but is not limited to:

* **Data Encryption:** All data will be encrypted in transit (using TLS 1.2+) and at rest (for databases and file storage).
* **Access Control:** User authorization will be strictly enforced to ensure patients can only view their own data and providers can only view the data of their own patients.
* **Audit Trails:** The system will log all access to Protected Health Information (PHI), including who accessed the data, what data was accessed, and when.

## Potential third-party integrations

* **Google Calendar:** Initially integrated via an iframe for the MVP, with a plan to migrate to the Google Calendar API for a fully custom interface.
* **Firebase Authentication:** For managing user sign-up and sign-in.
* **Google Email Services (Gmail API):** For sending transactional email notifications for messages and appointments.
* **Payment Processor:** Integration with a service like Stripe, which supports the Google Pay API for payment processing.

## Scalability considerations

The initial architecture will serve single-provider clinics. However, the data model will be designed to support multi-tenancy from the outset. This will allow the application to scale to support larger clinics with multiple providers in the future without a major re-architecture.

## MVP (Minimum Viable Product)

Our MVP will use Google Calendar in an iframe and support these features:

**For the Patient User:**

* A clean, minimalist landing page where patients can sign-up and sign-in, with a design guided by our Figma mockups.
* Sign-up form.
* Sign-in form.
* When signed in, a single-page view shows:
    * **Calendar View:** Displays open slots where the patient can schedule appointments.
    * **Messaging View:** Allows the patient to send and receive private messages with the provider.
* A sign-out option in the header that returns the user to the landing page.

**For the Provider user:**

* A landing page for provider sign-in.
* When signed in, the provider has access to separate Calendar and Messaging pages.
* **Calendar Page:**
    * Shows details of future appointments.
    * Ability to open or close appointment booking slots.
    * Ability to create **additional** notes for any appointment, past or present.
    * Ability to set and manage policies (e.g., cancellation policy).
* **Messaging Page:**
    * Shows a summary list of new messages and a search bar.
    * Clicking on a message summary opens a detail view.
* A search feature to find a specific patient and view all messages and documents related to them.

### Customer Pain Points (problem we are trying to solve)

* Current medical scheduling systems are scaled for larger clinics and are not user-friendly to the Provider or Patient.
* Google Calendar is familiar to many people and easy to use.

### Future

As we test our MVP, we will determine if any of these new features would be worth the effort:

* Replacing the iframe with the Google Calendar API to present a fully custom, branded interface.
* Expanding the Provider's search to include full-text search across stored documents and messages.

## Potential technical challenges

* Ensuring a seamless and secure integration with the Google Calendar API post-MVP will require careful handling of OAuth2 authentication and data synchronization logic.
* Implementing a robust and verifiable audit trail system to meet HIPAA compliance requirements for all actions involving Protected Health Information (PHI).

## Team and Workflow

* **Team:** The project will be developed by a two-member team.
* **Frontend Development:** Initial UI will be mocked up in HTML/CSS and progressively migrated to a component-based Vue.js architecture.
* **Workflow:** We will adopt a feature-branch workflow using Git. Each feature or bugfix will be developed in its own branch, reviewed via a pull request, and then merged into the main development branch.

###### dpw | 2025-07-15
