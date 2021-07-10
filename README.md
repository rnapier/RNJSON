# RNJSON

Data structure for encoding and decoding arbitrary JSON in Swift.

This is a full JSONEncoder/JSONDecoder replacement. That allows for features like maintaining exact decimal representations of numbers (avoiding
float rounding), maintaining key order, and allowing duplicate keys. If you just want "arbitrary JSON" that works with stdlib, see
https://stackoverflow.com/questions/65901928/swift-jsonencoder-encoding-class-containing-a-nested-raw-json-object-literal/65902852#65902852

(Note that this whole thing is very experimental. It's just a toy project I'm playing with. If it's useful, feel free to use it, but I don't
take it very seriously.)
