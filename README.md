<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

**A Flutter package uses ocrkit for processing its output.**

## Features

Image texts extracted and processed to return the special data wanted.
Just pass the image path to the chosen function.

## Getting started

add the following code to your podfile

> platform :ios, '10.0'

## Usage

The code below extracts all numbers of an image which have 6 or more digits and removes time and date.

```dart
List<String> numbers = await OCRController().getNumberList(pickedFile!.path);
```


The code below extracts all names of an image in a flight list and extracts details of it.
Takes a List<String> names and uses it for extraction.
Gets an int to set the strictness as the third input.
Strictness can be medium(0), hard(1) and alternative hard(2). the first is more accurate and second one is more sensitive.

```dart
dynamic passengers = await OCRController().getNamesList(pickedFile.path, names, 0);
```

## Additional information

This package is most used for personal operations
