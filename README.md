# Advertiser iOS

This is a bare bones iOS app to demonstrate the ability of two **backgrounded** apps to
discover each other and share their unique installation identifier.

The app has no user interface whatsoever.  It presents a black screen.

All code is in AppDelegate.swift

## Basic operation:

* On first run, the app generates a 32 bit unique installation identifier
* The app exposes two GATT services:
* The first service has a static UUID of 2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6
* The second service has a device-specific UUID of BBBBBBBB-BBBB-BBBB-BBBB-BBCCXXXXXXXX,
  where the last 32 bits are the unique installation identifier
* The app will scan for other devices hosting the first static GATT service UUID
* The app will connect to discovered devices wit the static GATT service UUID, discover
  all services, and parse out the 32 bit installation identifier from any service UUID
  of the form BBBBBBBB-BBBB-BBBB-BBBB-BBCCXXXXXXXX
* The app will continually track the RSSI of nearby identified devices

## Background operation:

The app manages to run continuously in the background on iOS using a trick that uses the
following combination:

1. Declare background mode location in Info.plist
2. Request and obtain "always" location permission from the user.  If this is not obtained,
   the technique won't work.
3. Start location updates with 3KM accuracy (so only the cell radio is used for location.)
4. Start a background thread that keeps the app going.  The background thread is also a
   convenient place to kick off connection retries and rssi readings, so it is used for
   that purpose as well.

## How do I know what it is doing?

Since there is no user interface, you have to look at the debug console for log messages.