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

## Demonstration Test

This demonstration test show the behavior of three phones all in the background from the
perspective of logs shown on the first phone.  The test shows two things:

1. A backgrounded iOS Device A (central) can exchange data with another backgrounded iOS 
   Device B (peripheral) for an extended period of ~55 minutes shown.
2. A backgrounded iOS Device A (central) can discover another backgrounded iOS Device C
   (peripheral) that comes into range.

### Test setup:

Use three test devices:

* Device A: iPhone 6 w/ iOS 11.4.1 w/ Advertiser app unique id E7DCE3FF
* Device B: iPhone 6 w/ iOS 10.2.1 w/ Advertiser app unique id BC00BD17
* Device C: iPhone 7 w/ iOS 13.4.1 w/ Advertiser app unique id 8337CA80

## Initial conditions of test:

Device A is connected to XCode
Device B is powered on, w/ Advertiser app installed but not running
Device C is powered off, w/ Advertiser app installed
XCode launches Advertiser app onto Device A

## Annotated logs

```
2020-04-13 14:57:36.662790 Advertiser[225:17180] Attempting to extend background running time
2020-04-13 14:57:36.663936 Advertiser[225:17236] My personal identity service is BBBBBBBB-BBBB-BBBB-BBBB-BBCCE7DCE3FF
true
2020-04-13 14:57:36.673036 Advertiser[225:17234] *** STARTED BACKGROUND THREAD
2020-04-13 14:57:36.685456 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:57:38.677050 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:57:40.685728 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:57:42.687907 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:57:44.695943 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:57:46.699883 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:57:48.709293 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:57:50.714708 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:57:52.725009 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:58:22.397039 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE

*** ANNOTATION: Manually launch Advertiser app on Device B, then hit the shoulder button to turn off the screen.

2020-04-13 14:59:49.654251 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:59:50.757581 Advertiser[225:17238] Discovered peripheral: C65D07AA-77B6-4CB5-A9DB-E26565650228 Services: none
2020-04-13 14:59:50.758186 Advertiser[225:17238] Connecting.  State is
2020-04-13 14:59:51.178778 Advertiser[225:17238] Connected
2020-04-13 14:59:51.179419 Advertiser[225:17238] Discovering services
2020-04-13 14:59:51.486068 Advertiser[225:17684] Discovered services
2020-04-13 14:59:51.567956 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:59:52.107472 Advertiser[225:17684] Found another service uuid we don't care about D0611E78-BBB4-4591-A5F8-487910AE4366
2020-04-13 14:59:52.108527 Advertiser[225:17684] Found another service uuid we don't care about 9FA480E0-4967-4542-9390-D343DC5D04AE
2020-04-13 14:59:52.109053 Advertiser[225:17684] Found the service uuid
2020-04-13 14:59:52.109893 Advertiser[225:17684] Found an device unique identifier service uuid: BBBBBBBB-BBBB-BBBB-BBBB-BBCCBC00BD17
2020-04-13 14:59:52.409739 Advertiser[225:17684] Found another service uuid we don't care about 180F
2020-04-13 14:59:52.410477 Advertiser[225:17684] Found another service uuid we don't care about 1805
2020-04-13 14:59:52.410986 Advertiser[225:17684] Found another service uuid we don't care about 180A
2020-04-13 14:59:52.411419 Advertiser[225:17684] Found device unique identifier: BC00BD17
2020-04-13 14:59:52.802269 Advertiser[225:17238] Read RSSI: -54 for BC00BD17
2020-04-13 14:59:53.958535 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:59:53.959169 Advertiser[225:17684] Read RSSI: -45 for BC00BD17
2020-04-13 14:59:55.221845 Advertiser[225:17238] Read RSSI: -45 for BC00BD17
2020-04-13 14:59:56.169948 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:59:56.181717 Advertiser[225:17684] Read RSSI: -46 for BC00BD17
2020-04-13 14:59:57.281897 Advertiser[225:17238] Read RSSI: -45 for BC00BD17
2020-04-13 14:59:58.415457 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 14:59:58.426919 Advertiser[225:17684] Read RSSI: -55 for BC00BD17
2020-04-13 14:59:59.532704 Advertiser[225:17238] Read RSSI: -24 for BC00BD17

...

*** ANNOTATION: At approximately 15:45:00, I take Device C over 50 meters away, power it on, launch the Advertiser app, and put it to
    the background.  I then walk back toward Device A & B so that it is in radio range.


2020-04-13 15:49:55.017412 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 15:49:55.021132 Advertiser[225:17236] Read RSSI: -22 for BC00BD17
2020-04-13 15:49:56.119009 Advertiser[225:17236] Read RSSI: -22 for BC00BD17
2020-04-13 15:49:57.186216 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 15:49:57.193002 Advertiser[225:17238] Read RSSI: -21 for BC00BD17
2020-04-13 15:49:58.306808 Advertiser[225:17236] Read RSSI: -21 for BC00BD17
2020-04-13 15:49:59.384490 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 15:49:59.386787 Advertiser[225:17236] Read RSSI: -22 for BC00BD17
2020-04-13 15:50:00.490149 Advertiser[225:17238] Read RSSI: -22 for BC00BD17
2020-04-13 15:50:01.590340 Advertiser[225:17234] C65D07AA-77B6-4CB5-A9DB-E26565650228 (BC00BD17) identified
2020-04-13 15:50:01.594323 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
2020-04-13 15:50:01.601728 Advertiser[225:17236] Read RSSI: -21 for BC00BD17
2020-04-13 15:50:01.702292 Advertiser[225:17238] Discovered peripheral: 80C49EB7-8E3F-45FB-B105-33D7BB10DC51 Services: none
2020-04-13 15:50:01.703880 Advertiser[225:17238] Connecting.  State is
2020-04-13 15:50:01.711492 Advertiser[225:17238] Connected
2020-04-13 15:50:01.712877 Advertiser[225:17238] Discovering services
2020-04-13 15:50:01.724550 Advertiser[225:17238] Discovered services
2020-04-13 15:50:01.732766 Advertiser[225:17238] Found another service uuid we don't care about D0611E78-BBB4-4591-A5F8-487910AE4366
2020-04-13 15:50:01.734280 Advertiser[225:17238] Found another service uuid we don't care about 9FA480E0-4967-4542-9390-D343DC5D04AE
2020-04-13 15:50:01.735376 Advertiser[225:17238] Found the service uuid
2020-04-13 15:50:01.736490 Advertiser[225:17238] Found an device unique identifier service uuid: BBBBBBBB-BBBB-BBBB-BBBB-BBCC8337CA80
2020-04-13 15:50:01.738980 Advertiser[225:17238] Found the service uuid
2020-04-13 15:50:01.740399 Advertiser[225:17238] Found an device unique identifier service uuid: BBBBBBBB-BBBB-BBBB-BBBB-BBCC8337CA80
2020-04-13 15:50:01.741618 Advertiser[225:17238] Found the service uuid
2020-04-13 15:50:01.742694 Advertiser[225:17238] Found an device unique identifier service uuid: BBBBBBBB-BBBB-BBBB-BBBB-BBCC8337CA80
2020-04-13 15:50:01.743856 Advertiser[225:17238] Found another service uuid we don't care about 180F
2020-04-13 15:50:01.744914 Advertiser[225:17238] Found another service uuid we don't care about 1805
2020-04-13 15:50:01.745952 Advertiser[225:17238] Found another service uuid we don't care about 180A
2020-04-13 15:50:01.746907 Advertiser[225:17238] Found device unique identifier: 8337CA80
2020-04-13 15:50:02.640077 Advertiser[225:17238] Read RSSI: -24 for BC00BD17
2020-04-13 15:50:02.642433 Advertiser[225:17238] Read RSSI: -102 for 8337CA80
2020-04-13 15:50:03.666654 Advertiser[225:17180] Thread 6804256 background time remaining: INFINITE
