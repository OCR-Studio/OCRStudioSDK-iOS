# OCRStudioSDK SDK Overview

This document contains brief introduction to OCRStudioSDK SDK interface - a main programmatic interface for OCRStudioSDK product.

  * [:warning: Personalized signature :warning:](#warning-personalized-signature-warning)
  * [General Usage Workflow](#general-usage-workflow)
  * [Factory methods and memory ownership](#factory-methods-and-memory-ownership)
  * [Configuration files](#configuration-files)
  * [Session parameters](#session-parameters)
  * [Session options](#session-options)
  * [Output modes](#output-modes)
  * [Java API Specifics](#java-api-specifics)
    - [Object deallocation](#object-deallocation)


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
    If delayed initialization is desabled, the internal engines will be initialized in the `CreateFromPath()` method. If you able the delayed initialization, the internal engines initialization will be delaied until the `CreateSession()` method is called.
    You can allow number of concurrent threads while configuring the engine. `0` value of allowed concurrent threads parameter means unlimited.

    See more about configuration files in [Configuration Files](#configuration-files).

2. Set parameters of the created session, encoded in JSON.
    You should set `session_type`, `target_group_type`. Optional you are able to set `target_masks`, `output_modes` and other `options`.
    ```cpp
    // C++
    std::string session_params = "{";
    session_params += "\"session_type\": \"document_recognition\", "; // Setting document recognition session
    session_params += "\"target_group_type\": \"default\", "; // Setting default session mode
    session_params += "\"target_masks\": \"mrz.*\", "; // (optional settings) Enabling MRZ in a session
    session_params += "\"options\": {\"enableMultiThreading\":\"false\"}, "; // (optional settings) Disabling multithreading in a session
    session_params += "\"output_modes\": ["; // (oprtional settings)
    session_params += "\"character_alternatives\", "; // Output character alternatives for recognized fields
    session_params += "\"field_geometry\" "; // Output information about the geometry of recognized fields
    session_params += "] ";
    session_params += "}";
    ```

    ```java
    // Java
    String session_params = "{";
    session_params += "\"session_type\": \"document_recognition\", "; // Setting document recognition session
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

##  Factory methods and memory ownership

Several OCRStudioSDK SDK classes have factory methods which return pointers to heap-allocated objects.  **Caller is responsible for deleting** such objects _(a caller is probably the one who is reading this right now)_.
We recommend using `std::unique_ptr<T>` for simple memory management and avoiding memory leaks.

In Java API for the objects which are no longer needed it is recommended to use `.delete()` method to force the deallocation of the native heap memory.


## Configuration files

Every delivery contains one or several _configuration files_ – archives containing everything needed for OCRStudioSDK engine to be created and configured. Usually they are named as `config_something.ocr` and located inside `config` folder.

## Session parameters

Assuming you already created the engine instanse like this:

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

There are two types of sessions: `document_recognition` for recognizing document fields and `face_matching` for determining the degree of similarity of faces in several images.

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

In order to get information about possible alternatives for each recognized character of text fields you can set in session parameters _"character_alternatives"_ output mode. If you want to get informatio about fields geometry you should use _"field_geometry"_ output mode.

## Session options

Some configuration file options can be overridden by specifying new values in the session parameters used to create the session.

Option values are always represented as strings, so if you want to pass an integer or boolean it should be converted to string first.


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
