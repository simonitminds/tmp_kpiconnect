# Move to Notifications

- AuctionEmailNotificationHandler
- AuctionEmailNotifier
- AuctionEmailSupervisor
- AuctionEventHandler
- AuctionNotifier
- AuctionReminderTimer



# Add to Notifications

- NotificationsSupervisor
  - spawns individual processes for handling email tasks
- NotificationEvent
  - same as AuctionEvent, but for notifications
- NotificationEventStorage
  - same as AuctionEventStorage, but for notifications
- EmailAggregate
  - Aggregate for state of email notifications in response to an Event



# Notification Events

Notifications aggregate maps the domain of a single Event. This can include multiple emails sent to different users (e.g. buyer and suppliers), all under one banner.

- `event_received`
  - an event came into the Notifications context and needs to be handled
- `email_requested`
  - the context attempted to send an email in response to the event.
  - includes list of users who need emails delivered.
- `email_delivered`
  - email delivery was successful and the event has been fully handled
  - individual event for every email sent.
  - includes content of the sent email.
- `email_failed`
  - email delivery was not successful and should be re-attempted.
  - individual event for every email sent.
- `event_processed`
  - no more work needs to be done for this event. Similar to `auction_finalized`
  - only happens when all emails in the `requested` event have successfully been delivered.
  - on rebuild, this event signals that the aggregate does not need replaying.



# Notification Supervisor

In place of `AuctionEmailSupervisor` which exists for the duration of an auction, and `AuctionEmailNotificationHandler` which listens for all events on an auction, create an `EmailSupervisor` that exists for the duration of an event's processing.

The parent context receives an event over PubSub and creates a new `EmailSupervisor` process in response. The supervisor starts a `NotificationAggregate` for the event and kicks off the process by sending it a `send_email` command.

The command determines who needs to receive emails, and starts a `Task` to generate and send the emails through Bamboo. Each email runs in its own `Task`, and on successful completion, sends a `mark_email_delivered` command, or a `mark_email_failed` command when an email could not be sent.
