# OCRStudioSDK SDK Overview

This document contains brief introduction to OCRStudioSDK SDK interface - a main programmatic interface for OCRStudioSDK product.

* [:warning: Personalized signature :warning:](#warning-personalized-signature-warning)
* [General Usage Workflow](#general-usage-workflow)
  * [Video Authentication Workflow](#video-authentication-workflow)
* [Factory methods and memory ownership](#factory-methods-and-memory-ownership)
* [Configuration files](#configuration-files)
* [Session parameters](#session-parameters)
* [Output modes](#output-modes)
* [Session options](#session-options)
* [Java API Specifics](#java-api-specifics)
  * [Object deallocation](#object-deallocation)
* [RFID Support](#rfid-support)
  * [NFC Workflow for Android](#nfc-workflow-for-android)
  * [NFC Workflow for iOS](#nfc-workflow-for-ios)

## :warning: Personalized signature :warning:

Users are required to use a personalized signature for starting a session. The signature is validated offline and locks to the copy of the native library, thus ensures that only an authorized client may use it. The signature is a string with 256 characters.

You will need to manually copy the signature string and pass it as an argument for the `CreateSession()` method ([see item 6 below](#general-usage-workflow)). Do NOT keep the signature in any asset files, only inside code. If possible, clients are encouraged to keep the signature in a controlled server and load it into the application via a secure channel, to ensure that signature and the library are separated.

Your signature: `51e71860c1072888a4447653d5b2289b31d82a0592d937b00306c9c90dbbf8ab9c7af505965299a474568dc5703f56a98be2a0b05f654e1d6298d22861be916f3215e51bf2c9872ce76201b943fad83e0a6ada6cd339e02adb48c24ac8a528f82911425ee3859047ade1a2c2ff5a53fe715b19f3e393a9b52a57424fc8d81e94`

## General Usage Workflow

1. Create `OCRStudioSDKInstance`:

    ```cpp
    // C++
    std::unique_ptr<ocrstudio::OCRStudioSDKInstance> engine_instance(ocrstudio::OCRStudioSDKInstance::CreateFromPath(
        configuration_file_path));
    ```

    ```java
    // Java
    OCRStudioSDKInstance engine_instance = OCRStudioSDKInstance.CreateFromPath(configuration_file_path);
    ```

    Configuration process might take a while but it only needs to be performed once during the program lifetime. Configured `OCRStudioSDKInstance` is used to spawn OCRStudioSDKSessions which have actual recognition methods.

    The second parameter to the `CreateFromPath()` method is a json string for enabling lazy configuration (`true` by default), enabling delayed initialization (`false` by default), allowed concurrent threads (`0` by default).
    If lazy configuration is enabled, some of the internal structured will be allocated and initialized only when first needed. If you disable the lazy configuration, all the internal structures and components will be initialized in the `CreateFromPath()` method.
    If delayed initialization is disabled, the internal engines will be initialized in the `CreateFromPath()` method. If you able the delayed initialization, the internal engines initialization will be delaied until the `CreateSession()` method is called.
    You can allow number of concurrent threads while configuring the engine. `0` value of allowed concurrent threads parameter means unlimited.

    See more about configuration files in [Configuration Files](#configuration-files).

2. Set parameters of the created session, encoded in JSON.
    You should set `session_type`, `target_group_type`. Optional you are able to set `target_masks`, `output_modes` and other `options`.

    ```cpp
    // C++
    std::string session_params = "{";
    session_params += "\"session_type\": \"document_recognition\", "; // Setting document recognition session. Set "video_recognition\" for document recognition session in a video stream
    session_params += "\"target_group_type\": \"default\", "; // Setting default session mode
    session_params += "\"target_masks\": \"mrz.*\", "; // (optional settings) Enabling MRZ in a session
    session_params += "\"options\": {\"enableMultiThreading\":\"false\"}, "; // (optional settings) Disabling multithreading in a session
    session_params += "\"output_modes\": ["; // (optional settings)
    session_params += "\"character_alternatives\", "; // Output character alternatives for recognized fields
    session_params += "\"field_geometry\" "; // Output information about the geometry of recognized fields
    session_params += "] ";
    session_params += "}";
    ```

    ```java
    // Java
    String session_params = "{";
    session_params += "\"session_type\": \"document_recognition\", "; // Setting document recognition session. Set "video_recognition\" for document recognition session in a video stream
    session_params += "\"target_group_type\": \"default\", "; // Setting default session mode
    session_params += "\"target_masks\": \"mrz.*\", "; // (optional settings) Enabling MRZ in a session
    session_params += "\"options\": {\"enableMultiThreading\":\"false\"}, "; // (optional settings) Disabling multithreading in a session
    session_params += "\"output_modes\": ["; // (oprtional settings)
    session_params += "\"character_alternatives\", "; // Output character alternatives for recognized fields
    session_params += "\"field_geometry\" "; // Output information about the geometry of recognized fields
    session_params += "] ";
    session_params += "}";
    ```

    See more about session parameters in [Session parameters](#session-parameters).

3. Subclass OCRStudioSDKDelegate and implement callbacks (not required):

    ```cpp
    // C++
    class OptionalDelegate : public ocrstudio::OCRStudioSDKDelegate { /* callbacks */ };

    // ...

    OptionalDelegate optional_delegate;
    ```

    ```java
    // Java
    class OptionalDelegate extends OCRStudioSDKDelegate { /* callbacks */ }

    // ...

    OptionalDelegate optional_delegate = new OptionalDelegate();
    ```

4. Create OCRStudioSDKSession:

    ```cpp
    // C++
    const char* signature = "... YOUR SIGNATURE HERE ...";
    std::unique_ptr<ocrstudio::OCRStudioSDKSession> session(
        engine_instance->CreateSession(signature, session_params.c_str(), &optional_delegate));
    ```

    ```java
    // Java
    String signature = "... YOUR SIGNATURE HERE ...";
    OCRStudioSDKSession session = engine_instance.CreateSession(signature, session_params, optional_delegate); 
    ```

    For explanation of signatures, [see above](#warning-personalized-signature-warning).

5. Create an OCRStudioSDKImage object which will be used for processing:

    ```cpp
    // C++
    std::unique_ptr<ocrstudio::OCRStudioSDKImage> image(
        ocrstudio::OCRStudioSDKImage::CreateFromFile(image_path.c_str())); // Loading from file
    ```

    ```java
    // Java
    OCRStudioSDKImage image = OCRStudioSDKImage.CreateFromFile(image_path); // Loading from file
    ```

6. Call `ProcessImage(...)` method for processing the image:

    ```cpp
    // C++
    session->ProcessImage(*image);
    ```

    ```java
    // Java
    session.ProcessImage(image);
    ```

7. Get `OCRStudioSDKResult` object:

    ```cpp
    // C++
    const ocrstudio::OCRStudioSDKResult& result = session->CurrentResult();
    ```

    ```java
    // Java
    OCRStudioSDKResult result = session.CurrentResult();
    ```

9. Use `OCRStudioSDKResult` fields to extract recognized information:

    ```cpp
    // C++
    for (int i = 0; i < result.TargetsCount(); ++i) {
      const ocrstudio::OCRStudioSDKTarget& target = result.TargetByIndex(i);

      std::string target_description =  target.Description(); // JSON string representation of the target type, specific type, types of items and attributes
      int strings_num = target.ItemsCountByType("string"); // Amount of recognized string fields
      for (auto it = target.ItemsBegin("string"); it != target.ItemsEnd("string"); it.Step()) {
        string field_description = it.Item().Description(); // JSON string representation of the recognized field result
      }
      bool is_final = target.IsFinal(); // target terminality flag value
    }
    bool is_result_final = result.AllTargetsFinal(); // result terminality flag value
    ```

    ```java
    // Java
    for (int i = 0; i < result.TargetsCount(); ++i) {
      OCRStudioSDKTarget target = result.TargetByIndex(i);
      
      String target_description = target.Description(); // JSON string representation of the target type, specific type, types of items and attributes
      int strings_num = target.ItemsCountByType("string"); // Amount of recognized string fields
      for (OCRStudioSDKItemIterator item_it = target.ItemsBegin("string"); !item_it.IsEqualTo(target.ItemsEnd("string")); item_it.Step()) {
        String field_description = item_it.Item().Description(); // JSON string representation of the recognized field result
      }
      boolean is_final = target.IsFinal(); // target terminality flag value
    }
    boolean is_result_final = result.AllTargetsFinal(); // result terminality flag value
    ```

    Apart from the text fields there also are image fields and other types of fields:

    ```cpp
    // C++
    for (int i = 0; i < result.TargetsCount(); ++i) {
      const ocrstudio::OCRStudioSDKTarget& target = result.TargetByIndex(i);

      for (auto it = target.ItemsBegin("image"); it != target.ItemsEnd("image"); it.Step()) {
        const std::string field_name = it.Item().Name();
        const ocrstudio::OCRStudioSDKImage image = it.Item().Image();
      }
    }
    ```

    ```java
    // Java
    for (int i = 0; i < result.TargetsCount(); ++i) {
      OCRStudioSDKTarget& target = result.TargetByIndex(i);

      for (auto it = target.ItemsBegin("image"); it != target.ItemsEnd("image"); it.Step()) {
        String field_name = it.Item().Name();
        OCRStudioSDKImage image = it.Item().Image();
      }
    }
    ```
### Video Authentication Workflow
The video authentication component performs advanced scanning of documents in a video stream. This feature assumes that you should follow instructions displayed on your device screen in real time. It allows you to recognize documents including double-sided identity documents within one session. For example, when you are scanning a double-sided document, you will be offered to scan the other side of this document after having scanned the first side.

Video authentication configuration is included in the config file and is read and called from this config file.
Video authentication is performed within the general workflow ([see](#general-usage-workflow)) with the following specifics.

Set parameters of the created session, encoded in JSON. Set the `video_authentication` parameter for recognizing documents including double-sided in a video stream and comparing the document photo with a selfie within a single session.
You should set `session_type`, `target_group_type`. Optional you are able to set `target_masks`, `output_modes` and other `options`.

To set video authentication - document (including double-sided) recognition in a video stream and document photo comparison with selfie:

    ```cpp
    // C++
    std::string session_params = "{";
    session_params += "\"session_type\": \"video_recognition\", "; // Setting video authentication
    session_params += "\"target_group_type\": \"default\", "; // Setting default session mode
    session_params += "\"target_masks\": \"mrz.*\", "; // (optional settings) Enabling MRZ in a session
    session_params += "\"options\": {\"enableMultiThreading\":\"false\"}, "; // (optional settings) Disabling multithreading in a session
    session_params += "\"output_modes\": ["; // (optional settings)
    session_params += "\"character_alternatives\", "; // Output character alternatives for recognized fields
    session_params += "\"field_geometry\" "; // Output information about the geometry of recognized fields
    session_params += "] ";
    session_params += "}";
    ```

    ```java
    // Java
    String session_params = "{";
    session_params += "\"session_type\": \"video_recognition\", "; // Setting video authentication
    session_params += "\"target_group_type\": \"default\", "; // Setting default session mode
    session_params += "\"target_masks\": \"mrz.*\", "; // (optional settings) Enabling MRZ in a session
    session_params += "\"options\": {\"enableMultiThreading\":\"false\"}, "; // (optional settings) Disabling multithreading in a session
    session_params += "\"output_modes\": ["; // (optional settings)
    session_params += "\"character_alternatives\", "; // Output character alternatives for recognized fields
    session_params += "\"field_geometry\" "; // Output information about the geometry of recognized fields
    session_params += "] ";
    session_params += "}";
   
    ```
See more about session parameters in [Session parameters](#session-parameters).
The further steps are implied in the general workflow, ([see](#general-usage-workflow))

After the session completion, the document will be recognized and the face comparison result will be output. If it has been passed successfully, the comparison confidence value in percents will be output. The confidence value shows how sure the system is that the person in the photo and the selfie are the same.

## Factory methods and memory ownership

Several OCRStudioSDK SDK classes have factory methods which return pointers to heap-allocated objects.  **Caller is responsible for deleting** such objects _(a caller is probably the one who is reading this right now)_.
We recommend using `std::unique_ptr<T>` for simple memory management and avoiding memory leaks.

In Java API for the objects which are no longer needed it is recommended to use `.delete()` method to force the deallocation of the native heap memory.

## Configuration files

Every delivery contains one or several _configuration files_ – archives containing everything needed for OCRStudioSDK engine to be created and configured. Usually they are named as `config_something.ocr` and located inside `config` folder.

## Session parameters

Assuming you already created the engine instanсe like this:

```cpp
// C++
// create recognition engine with configuration file path
std::unique_ptr<ocrstudio::OCRStudioSDKInstance> engine_instance(ocrstudio::OCRStudioSDKInstance::CreateFromPath(
    configuration_file_path));
```

```java
// Java
// create recognition engine with configuration file path
OCRStudioSDKInstance engine_instance = OCRStudioSDKInstance.CreateFromPath(configuration_file_path);
```

In order to create a session you need to specify `session_type` and `target_group_type` in the session parameters, and you can also set `target_masks`, `output_modes` and other `options`.

There are four types of sessions: `document_recognition` for recognizing document fields in an image `face_matching` for determining the degree of similarity of faces in several images, `video_recognition` for recognizing document fields in a video stream and `video_authentication` for recognizing double-sided documents in a video stream and comparing the document photo with a selfie within a single session. The `video_recognition`, `video_authentication` and `face_matching` types are available if they are included in the delivered config file.

A _target group_ represents one internal engine. A configuration file can contain settings for several different target groups.

A _target_ is simply a string encoding real world document type you want to recognize, for example, `are.id.*` or `deu.id.type1`. In order to enable some of the targets you may use `target_masks` parameter. You can set one or more targets.
For convenience it's possible to use **wildcards** (using asterisk symbol) while enabling or disabling document types. When using document types related methods, each passed document type is matched against all supported document types. All matches in supported document types are added to the enabled document types list. For example, document type `are.id.*` can be matched with `are.*`, `*id*` and of course a single asterisk `*`.

You can only enable targets that belong to the same target group for a single session. If you do otherwise then an exception will be thrown during session creation.
It's always better to enable the minimum number of targets as possible if you know exactly what are you going to recognize because the system will spend less time deciding which target out of all enabled ones has been presented to it.

Based on the list of supported targets in the configuration file, and on the target masks provided by the caller, the engine is determining which internal engine to use in the session. However, what if there have to be multiple engines which support a certain target? For example, a USA Passport (`usa.passport.*`) can be recognized both in the internal engine for recognition of all USA documents, and in the internal engine for recognition of all international passports. To sort this out there is a concept of target group types. There is always a mode called `default`.

To get the list of available session types and target groups (indicating available target group types and targets) in the provided configuration file, you can use engine instance `Description` method:

```cpp
// C++
std::string engine_instance_description = engine_instance->Description(); // JSON string representation available properties for sessions creation
```

```java
// Java
String engine_instance_description = engine_instance->Description(); // JSON string representation available properties for sessions creation
```

Within any given configuration file there is a strict invariant: there cannot be target groups which belong to the same target group types and for which the subsets of supported targets intersect.

## Output modes

In order you are free to get information about possible character alternatives and about fields geometry using "output_mode" param in session params.

| Output mode name      | Description                    |
|----------------------:|                   ------------:|
| character_alternatives| Information about possible alternatives for each recognized character of text fields |
|field_geometry         | Information about fields geometry |

## Session options

Some configuration file options can be overridden by specifying new values in the session parameters used to create the session.

Option values are always represented as strings, so if you want to pass an integer or boolean it should be converted to string first.

|                                   Option name |                           Value type |                                             Default | Description                                                                                                                                                                            |
|----------------------------------------------:|-------------------------------------:|----------------------------------------------------:|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `enableMultiThreading`                 | `"true"` or `"false"`                | true                                                | Enables parallel execution of internal algorithms                                                                                                                                      |
| `extractTemplateImages`                 | `"true"` or `"false"`                | false                                               | Extracts rectified template images (document pages) in the ImageFields section of the RecognitionResult                                                                                |
| `sessionTimeout`                       | Double value                         | `0.0` for server configs, `5.0` for mobile configs  | Session timeout in seconds                                                                                                                                                             |

## Java API Specifics

OCRStudioSDK SDK has Java API which is automatically generated from C++ interface by SWIG tool.

Java interface is the same as C++ except minor differences, please see the provided Java sample.

There are several drawbacks related to Java memory management that you need to consider.

#### Object deallocation

Even though garbage collection is present and works, it's strongly advised to manually call `obj.delete()` functions for our API objects because they are wrappers to the heap-allocated memory and their heap size is unknown to the garbage collector.

```java
OCRStudioSDKInstance engine_instance = OCRStudioSDKInstance.CreateFromPath(configuration_file_path); // or any other object

// ...

engine_instance.delete(); // forces and immediately guarantees wrapped C++ object deallocation
```

This is important because from garbage collector's point of view these objects occupy several bytes of Java memory while their actual heap-allocated size may be up to several dozens of megabytes. GC doesn't know that and decides to keep them in memory – several bytes won't hurt, right?

You don't want such objects to remain in your memory when they are no longer needed so call `obj.delete()` manually.

## RFID Support
Our SDK includes facilities to read RFID chip data for identity documents with an RFID chip which complies with international standards (ISO/ICAO Doc 9303 eMRTD). Our SDK can also be used to parse and perform document authentication checks if your product configuration supports parsing such data.

The  module of our SDK perfoming RFID reading supports the Android and iOS platforms.

### NFC Workflow for Android
In this section, the general description of the workflow for Android description is presented. The code sample is included in the delivery package, you can find it in directory /sample/app/src/main/java/ai/ocrstudio/sdk/sample/nfc/.

The module of the SDK which performs RFID reading is based on the NFC SDK available in public repositories, see <https://developer.android.com/develop/connectivity/nfc/nfc>.
NFC tags are read at the system level.

1. Check if NFC is supported by the device. If NFC is supported, enable the NFC adaptor.
For these purpose, use the *NfcAdapterExt* class – the NfcAdapter class extension.
An *Intent* encapsulating NFC tag is created and is passed to the *Activity*. The Activity must have launchMode: singleTop (the onNewIntent is called, otherwise a new Activity will be created).  In order for the Activity to accept this Intent, either specify the appropriate flag in the manifest or call the *enableForegroundDispatch* method from the NFC adapter (to work only in active mode - foreground mode).

Use the NfcAdapterExt class.

2.	Read the passport tag calling the *getPassportTag* method of the NfcAdapterExt class.

3.	Use the *PassportData* and *FaceImage* classes to store the read passport data and photo.
Implement the read photo (FaceImage) as a *FaceImageSuccess* or *FaceImageError* class instance.

Basing on the read data, a key is formed.

4.	Use the *PassportKey* class to store the key.

5.	After the key is formed, create a separate thread for reading the passport data from the NFC chip using this key. Save the read passport data in the *NfcModel.passportData* field.

To do it, use the *PassportReader* class.

6.	Use the *NfcModel.nfcState* variable of the *NfcModel* class to follow the state of the passport reading process.

The application monitors these changes (process states) and changes the UI accordingly.

7.	Verify the result data with the help of *nfcState.postValue(NfcState.Checking)*.

Use the *SessionNfcResult*, *SessionNfcResultError*, *SessionNfcResultSeccess* classes to store the verification results.

8.	Update the NfcModel.nfcState state.

The following classes are used:
+ **FaceImage**	- describes the photo that was read. An interface that can be implemented as FaceImageSuccess or FaceImageError;
+ **FaceImageError** - describes a photo reading error;
+ **FaceImageSuccess** - describes a photo that has been successfully read;
+ **NfcAdapterExt**	- checks if the device supports NFC. Enables/disables the NFC adaptor;
+ **NfcModel**	- describes logics of NFC operation at high level;
+ **NFCState** - passes the current state of NfcModel;
+ **PassportData** -	stores read passport data;
+ **PassportKey** -	stores NFC key data;
+ **PassportReader** - implements reading of passport data using a tag.

### NFC Workflow for iOS
In this section, the general description of the workflow for iOS is presented. The code sample is included in the delivery package, you can find it in directory /Samples/Swift/OCRStudioSDKSample/.

For working with RFID, use iOS 15.0 and later.

1. Enable NFC reading:

a. In the Info.plist and Info-rfid.plist files, set the *com.apple.developer.nfc.readersession.iso7816.select-identifiers* target items:
* A0000002471001;
* A0000002472001;
* 00000000000000

```XML
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
	<array>
		<string>A0000002471001</string>
		<string>A0000002472001</string>
		<string>00000000000000</string>
	</array>
  ```

b. In the Info.plist and Info-rfid.plist files, set the *NFCReaderUsageDescription* target value to "For NFC tag reading":

```XML
<key>NFCReaderUsageDescription</key>
	<string>For NFC tag reading</string>
  ```
c. In Xcode or another client you use to manage the project, in the *Signing & Capabilities* section, enable the *Near Field Communication Tag Reading* option.

2. Create the document recognition session.
3. Recognize the document with the device using the *ProcessImage* method.
4. After the session completion, get the recognition result using the *currentResult* method. The result will be displayed on the device screen.
5. In our SDK the external open source NFCPassportReader library (for working with the sample) available by link https://github.com/AndyQ/NFCPassportReader is added. You can add this library to your project using the *Product Dependencies* package.
6. Create a string structure including the session data and the read NFC data in the JSON format.
7. Pass the created string structure to the *ProcessData* method.
The data read from the document are compared with the data read from the chip.
8. The *currentResult* method returns the recognition results and checks results.
The *fraud_attempt* item in the session description shows that we can obtain the check result in this SDK using the ProcessData method.
The possible values:
+ **not_detected** - the document data complies with the chip data, fraud has not been detected;
+ **detected** - the document data do not comply with the chip data, fraud has been detected;
+ **undefined** - data has not been found or could not be read.
