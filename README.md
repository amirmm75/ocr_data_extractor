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

This package uses artemis_camera_kit library to gain OCR data and process its information.
Just pass the OcrData to the chosen function.
You can also use this package's useful functions and the special sort.

## Getting started

add the following code to your podfile

> platform :ios, '10.0'

add *artemis_camera_kit* package to pubspec.yaml file.

## Usage

The code below extracts all numbers of an image which have 6 or more digits and removes time and date.

```dart
OcrData? ocrData = await ArtemisCameraKitController().processImageFromPath(imagePath ?? '');
List<String> numbers = await OCRController().getNumberList(ocrData!);
```


The code below extracts all names of an image in a flight list and extracts details of it.
Takes a List<String> names and uses it for extraction.
Gets an int to set the strictness as the third input.
Strictness can be medium(0), hard(1) and alternative hard(2). the first is more accurate and second one is more sensitive.

```dart
OcrData? ocrData = await ArtemisCameraKitController().processImageFromPath(imagePath ?? '');
dynamic passengers = await OCRController().getNamesList(ocrData!, names, 0);
```

## Additional information

This package is most used for personal operations
