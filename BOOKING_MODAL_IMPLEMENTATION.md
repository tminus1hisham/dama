# Booking Modal Implementation Guide

## Summary

A fully functional **BookingModal** widget has been created in Flutter that replicates the React component's behavior for event booking and RSVP flow.

## Files Created/Modified

### New File
- **`lib/widgets/modals/booking_modal.dart`** (853 lines)
  - Complete booking modal implementation with state management
  - Handles both free (RSVP) and paid (M-Pesa) events
  - Four distinct states: idle, awaiting, success, failed

### Modified Files
- **`lib/views/dashboard/events.dart`**
  - Added import for BookingModal
  - Added state variables: `_bookingEvent` and `_isBookingModalOpen`
  - Added methods:
    - `_showBookingModal(event)` - Shows modal when RSVP clicked
    - `_closeBookingModal()` - Closes modal and resets state
    - `_handleBookingSuccess(eventId)` - Handles successful booking
  - Updated EventCard `onPressed` callbacks to show modal
  - Wrapped build layout in Stack to overlay modal
  - Fixed date field issue in MyEvents tab (changed `event.createdAt` → `event.eventDate`)
  - Added attendees count display for all events

## Component Architecture

### BookingModal States

1. **Idle State**
   - Shows booking form with event details
   - Phone input (for paid events only)
   - M-Pesa payment info badge
   - Total price calculation
   - "Confirm RSVP" or "Pay KES X" button

2. **Awaiting State**
   - Shows loading spinner
   - "Check Your Phone" title for paid events
   - Displays phone number for M-Pesa STK prompt
   - User must enter M-Pesa PIN
   - Cannot dismiss modal during this state

3. **Success State**
   - Displays checkmark with success animation
   - Shows ticket details (if server provided)
   - Ticket number display
   - "Download Ticket" button (if ticket available)
   - "Done" button to close

4. **Failed State**
   - Shows error icon
   - Displays error message from server
   - "Try Again" button to retry
   - "Close" button

## API Integration

The modal integrates with two API endpoints:

### Free Events
```dart
await _apiService.registerForEvent(eventId);
```
- Synchronous registration
- Immediate ticket confirmation
- Returns ticket number from server

### Paid Events
```dart
await _apiService.initiatePayment(
  objectId: eventId,
  amount: totalPrice,
  phoneNumber: formattedPhone,
  model: 'Event',
);
```
- Initiates M-Pesa STK Push to user's phone
- Server holds request until payment confirmed
- Waits for async payment callback
- Returns ticket only after payment success

## Phone Number Formatting

Automatic Kenyan phone number formatting:
- Accepts: `0712345678`, `+254712345678`, `254712345678`
- Converts all to: `254712345678` format
- Validates: Must be 12+ digits and start with `254`

## State Management Flow

```
EventCard (onPressed)
    ↓
_showBookingModal(event)
    ↓
setState({_bookingEvent = event, _isBookingModalOpen = true})
    ↓
BookingModal displays overlay
    ↓
User books/RSVPs
    ↓
_handleBookingSuccess(eventId)
    ↓
Refresh user events + close modal
```

## UI Features

- **Dark/Light Theme Support**
  - Automatically adapts to system theme
  - Uses constants from `theme_provider.dart`

- **Animations**
  - Smooth state transitions
  - Loading spinner during payment
  - Success checkmark animation

- **Input Validation**
  - Phone number format validation
  - Prevents booking with invalid number
  - Shows helpful error messages

- **Responsive Design**
  - Constrains to max 500px width
  - Handles different screen sizes
  - ScrollableContent for tall forms

## Testing Checklist

- [ ] Click "Book Now" on an unpaid event → Modal appears
- [ ] Enter valid Kenyan phone number → Button enables
- [ ] Enter invalid phone → Shows error snackbar
- [ ] Click "Confirm RSVP" on free event → Success after ~2s
- [ ] Click "Book Event" on paid event → M-Pesa prompt appears
- [ ] View ticket details after successful booking
- [ ] Download ticket JSON file
- [ ] Modal closes on success
- [ ] "My Events" tab refreshes after booking
- [ ] Dark mode styling works
- [ ] Light mode styling works

## Error Handling

All API errors are caught and displayed:
- Network errors → Show in failed state
- 401/403 unauthorized → Handled by ApiService
- Server validation errors → Displayed to user
- Parsing errors → Generic "booking failed" message

## Integration with Events Screen

When user RSVPs/books:
1. Modal shows with event details
2. User enters phone (if paid) and confirms
3. API processes booking
4. On success:
   - Ticket displayed (if available)
   - User events list refreshes automatically
   - Modal closes
   - Success snackbar shown

## Future Enhancements

- [ ] Add calendar integration (add to device calendar)
- [ ] Email ticket to user
- [ ] SMS receipt/confirmation
- [ ] Support for multiple ticket types
- [ ] Group booking (quantity > 1)
- [ ] Payment method selection (beyond M-Pesa)

## Known Limitations

- M-Pesa timeout handling not implemented
- Assumes mobile-only deployment (web untested)
- QR code generation handled by backend only
- No offline capability

## Deprecation Warnings

Some Flutter widgets use deprecated APIs:
- `withOpacity()` → Use `.withValues()` (cosmetic, safe for now)
- `Share.share()` → Use `SharePlus.instance.share()` (cosmetic, safe for now)

These are warnings only and don't affect functionality. Can be cleaned up in future refactors.
