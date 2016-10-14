# Trip

## Summary
GPX parser. Made to analyze the track of a boat transfer from Kalmar to Rostock with more than 90.000 GPS locations. Track has been recorded with [Transas iSailor](http://isailor.us/).

## Algorithm
Using the [Haversine formula](https://en.wikipedia.org/wiki/Haversine_formula) to calculate distances from two given locations.

## Code
Written in Swift3 as a quick & dirty hack. 

## Current state
Currently calculates the overall distance and the maximum speed for a duration of at least 15 seconds.

## Dependencies
Depends on [AEXML](https://github.com/tadija/AEXML) wich comes on stage using the [Swift Package Manager](https://github.com/apple/swift-package-manager).
