/**
  Copyright (c) 2024-2024, OCR Studio
  All rights reserved.
*/

import UIKit

protocol SampleViewControllerProtocol : class {
  func setTargetGroupAndMask(targetGroup: String, targetMask: String)
}

class SampleViewController: UIViewController,
                            UIImagePickerControllerDelegate,
                            UINavigationControllerDelegate,
                            SampleViewControllerProtocol,
                            OCRStudioSDKInitializationDelegate {
  var currentDocumenttypeMask : String?
  
  func setTargetGroupAndMask(targetGroup: String, targetMask: String) {
    ocrController.sessionParams().setTargetGroupType(targetGroup)
    self.currentDocumenttypeMask = targetGroup + " : " + targetMask
    
    ocrController.sessionParams().clearTargetMasks()
    ocrController.sessionParams().addTargetMask(targetMask)
    
    ocrController.configureDocumentTypeLabel(self.currentDocumenttypeMask!)
    print("Current mode is \(targetGroup), doc type mask is \(targetMask)")
    
    ocrController.setRoiWithOffsetX(0.0, andY: 0.0, orientation: UIDeviceOrientation.portrait, displayRoi: false)
    ocrController.shouldDisplayRoi = false
    
  }
  
  // Gallery-related
  
  let photoLibraryImagePicker : UIImagePickerController = {
    let picker = UIImagePickerController()
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
      picker.sourceType = .photoLibrary
      picker.modalPresentationStyle = .fullScreen
    }
    return picker
  }()
  
  // Photo-related
  
  let photoCameraImagePicker : UIImagePickerController = {
    let picker = UIImagePickerController()
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
      picker.sourceType = .camera
      picker.modalPresentationStyle = .fullScreen
    }
    return picker
  }()
  
  
  // Selfie-related
  
  var currentPhotoImage : OBJCOCRStudioSDKImage? = nil;
  
  func reinitSelfieButton() {
    self.selfieButton.isEnabled = false
    self.selfieButton.isHidden = true
    self.currentPhotoImage = nil;
  }
  
  let selfieImagePicker : UIImagePickerController = {
    let picker = UIImagePickerController()
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
      picker.sourceType = UIImagePickerController.SourceType.camera
      picker.modalPresentationStyle = .fullScreen
      picker.cameraFlashMode = .off
      picker.cameraDevice = .front
      picker.cameraCaptureMode = .photo
    }
    return picker
  }()
  
  // View-related
  
  var pickerImageActivityIndicator:UIActivityIndicatorView!
  var pickerImageActivityIndicatorContainer:UIView!
  var pickerIAIContainerBackground:UIView!
  
  var docTypeListViewController : DocTypesListController!
    
  var resultTableView : UITableView = {
    var resultTableView = UITableView()
    resultTableView.register(TextFieldCell.self, forCellReuseIdentifier: "TextCell")
    resultTableView.register(ImageViewCell.self, forCellReuseIdentifier: "ImageCell")
    resultTableView.estimatedRowHeight = 100
    resultTableView.translatesAutoresizingMaskIntoConstraints = false
    return resultTableView
  }()
    
  func setTableViewAnchors() {
    if #available(iOS 11.0, *) {
      resultTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
      resultTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
      resultTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
      resultTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
    } else {
      resultTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
      resultTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
      resultTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
      resultTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }
    resultTableView.estimatedRowHeight = 600
    resultTableView.allowsSelection = false
  }
    
  private var resultTextFields = [(fieldName: String, value: String)]()
  private var resultImageFields = [(fieldName: String, value: UIImage)]()
  private var resultTableFields = [(fieldName: String, value: String)]()
    
  func setResult(result: OBJCOCRStudioSDKResultRef) {
    resultTextFields.removeAll()
    resultImageFields.removeAll()
    resultTableFields.removeAll()
    
    print(result.targetsCount())
    if result.targetsCount() == 0 {
        resultTextFields.append(("Document not found", "Last session parameters:\n\tSession type: \(ocrController.sessionParams().getSessionType())\n\tTarget Group Type: \(ocrController.sessionParams().getTargetGroupType() )\n\tTarget Masks: \(ocrController.sessionParams().getTargetMasks())"))
    } else {
      for tr_i in 0...result.targetsCount() - 1 {
        let target = result.target(by: tr_i)
        print(result.target(by: tr_i).description())
        var itemTypes : [String] = []
        let data = Data(result.target(by: tr_i).description().utf8)
        do {
          if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let docType = json["specific_type"] as? String {
              resultTextFields.append(("Document type", docType))
            }
            if let jsonItemTypes = json["item_types"] as? [String] {
              itemTypes = jsonItemTypes
            }
          }
        } catch let error as NSError {
          print("Failed to load: \(error.localizedDescription)")
        }
        
        for itemType in itemTypes {
          let item_it = target.itemsBegin(itemType)
          let item_end =  target.itemsEnd(itemType)
          while !item_it.isEqual(to: item_end) {
            debugPrint((item_it.item().name(), item_it.item().value()))
            if itemType == "string" {
              resultTextFields.append((item_it.item().name(), item_it.item().value()))
            } else if itemType == "image" || itemType == "template" {
              if item_it.item().hasImage() {
                resultImageFields.append((item_it.item().name(), item_it.item().image().convertToUIImage()))
                // Registering photo for selfie check
                if item_it.item().name() == "photo" {
                  if ocrController.sessionParams().hasSessionType("face_matching") {
                      self.selfieButton.isHidden = false
                      self.selfieButton.isEnabled = true
                      self.currentPhotoImage = item_it.item().image().deepCopy()
                    }
                }
              }
            } else if itemType == "table" {
              resultTableFields.append((item_it.item().name(), item_it.item().value()))
            } else { //new or raw field type
              
            }
            item_it.step()
          }
        }
      }
    }
    
    resultTextFields.sort(by: {
        return $0.0 < $1.0
    })
    resultImageFields.sort(by: {
        return $0.0 < $1.0
    })
    
    resultTableFields.sort(by: {
        return $0.0 < $1.0
    })
  }
    
  let cameraButton: UIButton = {
    let button = UIButton(type: .roundedRect)
    button.autoresizingMask = .flexibleWidth
    button.setTitle("...", for: .normal)
    button.isEnabled = false
    button.layer.borderColor = UIColor.blue.cgColor
    return button
  }()
    
  let galleryButton: UIButton = {
    let button = UIButton(type: .roundedRect)
    button.autoresizingMask = .flexibleWidth
    button.setTitle("...", for: .normal)
    button.isEnabled = false
    button.layer.borderColor = UIColor.blue.cgColor
    return button
  }()
  
  let photoButton: UIButton = {
    let button = UIButton(type: .roundedRect)
    button.autoresizingMask = .flexibleWidth
    button.setTitle("...", for: .normal)
    button.isEnabled = false
    button.layer.borderColor = UIColor.blue.cgColor
    return button
  }()
    
  let documentListButton: UIButton = {
    let button = UIButton(type: .roundedRect)
    button.autoresizingMask = .flexibleWidth
    button.setTitle("Initializing...", for: .normal)
    button.isEnabled = false
    button.layer.borderColor = UIColor.blue.cgColor
    return button
  }()
    
  let selfieButton : UIButton = {
    let button = UIButton(type: .roundedRect)
    button.autoresizingMask = .flexibleWidth
    button.setTitle("Compare with selfie", for: .normal)
    button.isEnabled = false
    button.isHidden = true
    button.layer.borderColor = UIColor.blue.cgColor
    return button
  }()
  
  let resultTextView: UITextView = {
    let view = UITextView()
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.isEditable = false
    view.font = UIFont(name: "Menlo-Regular", size: 12)
    return view
  }()
    
  let resultImageView: UIImageView = {
    let view = UIImageView()
    view.contentMode = .scaleAspectFit
    view.backgroundColor = UIColor(white: 0.9, alpha: 0.5)
    return view
  }()
                    
  let engineInstance : OCRStudioSDKInstance = {
    let signature = "Place your signature here (see doc\README.html)"
    return OCRStudioSDKInstance(signature: signature)
  }()
  
  func ocrStudioSDKInitialized() {
    self.galleryButton.setTitle("Gallery", for: .normal)
    self.photoButton.setTitle("Photo", for: .normal)
    self.cameraButton.setTitle("Camera", for: .normal)
    self.documentListButton.setTitle("Select type", for: .normal)
    self.documentListButton.isEnabled = true
    
    self.ocrController.attachEngineInstance(self.engineInstance)
  }
  
  let ocrController: OCRStudioSDKViewController = {
    let ocrController = OCRStudioSDKViewController(lockedOrientation: false, withTorch: false, withBestDevice: true)
    ocrController.modalPresentationStyle = .fullScreen
    ocrController.captureButtonDelegate = ocrController
    
    // configure optional visualization properties (they are NO by default)
    ocrController.displayZonesQuadrangles = true
    ocrController.displayDocumentQuadrangle = true
    ocrController.displayProcessingFeedback = true
    
    return ocrController
  }()
    
  override func viewDidLayoutSubviews() {
    let bottomSafeArea: CGFloat
    let topSafeArea: CGFloat
    
    // safe area for phones with notch
    
    if #available(iOS 11.0, *) {
      bottomSafeArea = view.safeAreaInsets.bottom
      topSafeArea = view.safeAreaInsets.top
    } else {
      bottomSafeArea = bottomLayoutGuide.length
      topSafeArea = topLayoutGuide.length
    }
    
    let buttonHeight: CGFloat = 50
    
    cameraButton.frame = CGRect(x: 0,
                                y: view.bounds.size.height - bottomSafeArea - buttonHeight,
                                width: view.bounds.size.width/4,
                                height: buttonHeight)
    
    galleryButton.frame = CGRect(x: view.bounds.size.width/4,
                                 y: view.bounds.size.height - bottomSafeArea - buttonHeight,
                                 width: view.bounds.size.width/4,
                                 height: buttonHeight)
    
    photoButton.frame = CGRect(x: view.bounds.size.width/2,
                                 y: view.bounds.size.height - bottomSafeArea - buttonHeight,
                                 width: view.bounds.size.width/4,
                                 height: buttonHeight)
    
    documentListButton.frame = CGRect(x: view.bounds.size.width*3/4,
                                      y: view.bounds.size.height - bottomSafeArea - buttonHeight,
                                      width: view.bounds.size.width/4,
                                      height: buttonHeight)
    
    selfieButton.frame = CGRect(x: view.bounds.size.width/2,
                                y: topSafeArea,
                                width: view.bounds.size.width/2,
                                height: buttonHeight)
  }
    
  override func viewDidLoad() {
    super.viewDidLoad()
    ocrController.ocrDelegate = self
    
    if #available(iOS 13.0, *) {
      self.view.backgroundColor = .systemBackground
    } else {
      self.view.backgroundColor = .white
    }
    
    view.addSubview(resultTableView)
    setTableViewAnchors()
    resultTableView.delegate = self
    resultTableView.dataSource = self
    
    view.addSubview(cameraButton)
    view.addSubview(galleryButton)
    view.addSubview(photoButton)
    view.addSubview(documentListButton)
    view.addSubview(selfieButton)
    
    cameraButton.addTarget(
        self, action:#selector(showocrViewController), for: .touchUpInside)
    galleryButton.addTarget(
        self, action: #selector(showGalleryImagePickerToProcessImage), for: .touchUpInside)
    photoButton.addTarget(
        self, action: #selector(showPhotoImagePickerToProcessImage), for: .touchUpInside)
    documentListButton.addTarget(
        self, action: #selector(showDocumenttypeList), for: .touchUpInside)
    selfieButton.addTarget(
        self, action: #selector(showSelfiePicker), for: .touchUpInside)
    
    setupImagePickerActivityBackground()
    
    self.engineInstance.setInitializationDelegate(self)
    
    DispatchQueue.main.async {
      
      let configPaths = Bundle.main.paths(forResourcesOfType: "ocr", inDirectory: "config")
      
      if configPaths.count == 1 {
        
        self.engineInstance.initializeEngine(configPaths[0])
        // parcing infrormation from config file
        var modesList = [String]() // modes are not sorted
        var docTypesList = [String:[String]]()
        if self.engineInstance.engine != nil {
          let data = Data(self.engineInstance.engine!.description.utf8)
          do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
              // getting list of supported session types and enabling corresponding buttons
              if let names = json["session_types"] as? [String] {
                debugPrint("session_types", names)
                self.ocrController.sessionParams().initSessionTypes(with: names)
                if self.ocrController.sessionParams().hasSessionType("document_recognition") {
                  self.galleryButton.isEnabled = true
                  self.photoButton.isEnabled = true
                }
                if self.ocrController.sessionParams().hasSessionType("video_recognition") {
                  self.cameraButton.isEnabled = true
                }
              }
              // getting list of supported document modes and types
              if let targetGroups = json["target_groups"] as? [[String: Any]] {
                for targetGroup in targetGroups {
                  if let targetGroupType = targetGroup["target_group_type"] as? String,
                    let targetMasks = targetGroup["target_masks"] as? [String] {
                    // Use the extracted values as needed
                    if !modesList.contains(targetGroupType) {
                      modesList.append(targetGroupType)
                      docTypesList[targetGroupType] = []
                    }
                    for targetMask in targetMasks {
                      docTypesList[targetGroupType]?.append(targetMask)
                    }
                  }
                }
              }
            }
          } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
          }
        }
        
        if (modesList.count == 1) && (docTypesList[modesList[0]]!.count) == 1 {
          self.setTargetGroupAndMask(
            targetGroup: modesList[0],
            targetMask: docTypesList[modesList[0]]![0])
        }
        
        self.docTypeListViewController = DocTypesListController(docTypesList: docTypesList)
        self.docTypeListViewController.delegateSampSID = self
      
      } else {
        NSLog("No config file at folder")
      }
    }
  }
    
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
    
   
  func showAlert(msg: String) {
    let alert = UIAlertController(title: "Warning", message: msg, preferredStyle: .alert)
    alert.addAction(UIAlertAction(
        title: NSLocalizedString("OK", comment: "Default action"),
        style: .default,
        handler: { _ in
      NSLog("The \"OK\" alert occured.")
    }))
    self.present(alert, animated: true, completion: nil)
  }
    
  @objc func showGalleryImagePickerToProcessImage() {
    if currentDocumenttypeMask != nil {
        ocrController.sessionParams().setSessionType("document_recognition")
      self.photoLibraryImagePicker.delegate = self
      DispatchQueue.main.async {
        self.pickerIAIContainerBackground.isHidden = true
        self.pickerImageActivityIndicatorContainer.isHidden = true
      }
      
      self.present(self.photoLibraryImagePicker, animated: true, completion: nil)
    } else {
      showAlert(msg: "Select document type")
    }
    self.reinitSelfieButton()
  }
  
  @objc func showPhotoImagePickerToProcessImage() {
    if currentDocumenttypeMask != nil {
        ocrController.sessionParams().setSessionType("document_recognition")
      self.photoCameraImagePicker.delegate = self
      DispatchQueue.main.async {
        self.pickerIAIContainerBackground.isHidden = true
        self.pickerImageActivityIndicatorContainer.isHidden = true
      }
      
      self.present(self.photoCameraImagePicker, animated: true, completion: nil)
    } else {
      showAlert(msg: "Select document type")
    }
    self.reinitSelfieButton()
  }
    
  @objc func showocrViewController() {
    if currentDocumenttypeMask != nil {
      ocrController.sessionParams().setSessionType("video_recognition")
      present(ocrController, animated: true, completion: {
        print("sample: ocrViewController presented")
      })
    } else {
      showAlert(msg: "Select document type")
    }
    self.reinitSelfieButton()
  }
    
  @objc func showDocumenttypeList() {
    present(docTypeListViewController, animated: true, completion: nil)
  }
  
  @objc func showSelfiePicker() {
    if self.currentPhotoImage == nil {
      return
    }
    self.selfieImagePicker.delegate = self
    self.present(self.selfieImagePicker, animated: true, completion: nil)
  }
}

// MARK: TableView

extension SampleViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return resultTextFields.count + resultImageFields.count + resultTableFields.count
  }
    
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if (indexPath.row < resultTextFields.count) {
      let cell = resultTableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath) as! TextFieldCell
      cell.fieldName.text = resultTextFields[indexPath.row].fieldName
      cell.resultTextView.text = resultTextFields[indexPath.row].value
      return cell
    } else {
      let cell = resultTableView.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath) as! ImageViewCell
      cell.fieldName.text = resultImageFields[indexPath.row - resultTextFields.count].fieldName
      cell.imageFieldView.image = resultImageFields[indexPath.row - resultTextFields.count].value
      return cell
    } 
  }
    
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }
}

extension SampleViewController {
    
  func pickImageByUIImage(image: UIImage) {
    self.setupImagePickerActivity()
    self.pickerImageActivityIndicator.startAnimating()
    DispatchQueue.main.async { [weak self] in
      self?.ocrController.processUIImage(image)
      self?.pickerImageActivityIndicator.stopAnimating()
    }
  }
  
  func pickSelfie(image: UIImage) {
    if let photoImage = self.currentPhotoImage {
        let selfieImage = OBJCOCRStudioSDKImage(from: image)
      let similarityResult = self.engineInstance.compareFaces(fromDocument: photoImage.getRef(), andSelfie: selfieImage.getRef())
      
      var status = ""
      var sim = ""
        let target: OBJCOCRStudioSDKTargetRef = similarityResult.getRef().target(by: 0)
      let item_it = target.itemsBegin("string")
      let item_end =  target.itemsEnd("string")
      while !item_it.isEqual(to: item_end) {
        debugPrint((item_it.item().name(), item_it.item().value()))
        if item_it.item().name() == "status" {
          status = item_it.item().value()
        }
        if item_it.item().name() == "similarity_estimation" {
          sim = item_it.item().value()
        }
        item_it.step()
      }
      
      for i in 0..<resultTextFields.count {
        if resultTextFields[i].fieldName == "Selfie check score" {
          resultTextFields.remove(at: i)
          break
        }
      }
      self.resultTextFields.append(("Selfie check score", "\(sim)"))
      self.resultTextFields.sort(by: {
          return $0.0 < $1.0
      })
      self.resultTableView.reloadData()
      self.dismiss(animated: true, completion: nil)
    }
  }
    
  func initImagePickerActivityContainer() -> UIView {
    let activityWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)/5
    let activityContainer = UIView()
    activityContainer.backgroundColor = .black
    activityContainer.alpha = 0.8
    activityContainer.layer.cornerRadius = 10
    
    self.photoLibraryImagePicker.view.addSubview(activityContainer)
    
    activityContainer.translatesAutoresizingMaskIntoConstraints = false
    activityContainer.centerXAnchor.constraint(equalTo: self.photoLibraryImagePicker.view.centerXAnchor).isActive = true
    activityContainer.centerYAnchor.constraint(equalTo: self.photoLibraryImagePicker.view.centerYAnchor).isActive = true
    activityContainer.widthAnchor.constraint(equalToConstant: activityWidth).isActive = true
    activityContainer.heightAnchor.constraint(equalToConstant: activityWidth).isActive = true
    activityContainer.isHidden = true
    
    return activityContainer
  }
  
  func initImagePickerContainerBackground() {
    self.pickerIAIContainerBackground = UIView()
    self.pickerIAIContainerBackground.alpha = 0.2
    self.pickerIAIContainerBackground.backgroundColor = .gray
    self.pickerIAIContainerBackground.isUserInteractionEnabled = false
    self.pickerIAIContainerBackground.isHidden = true
    
    self.photoLibraryImagePicker.view.addSubview(self.pickerIAIContainerBackground)
    
    self.pickerIAIContainerBackground.translatesAutoresizingMaskIntoConstraints = false
    self.pickerIAIContainerBackground.centerXAnchor.constraint(equalTo: self.photoLibraryImagePicker.view.centerXAnchor).isActive = true
    self.pickerIAIContainerBackground.centerYAnchor.constraint(equalTo: self.photoLibraryImagePicker.view.centerYAnchor).isActive = true
    
    self.pickerIAIContainerBackground.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width).isActive = true
    self.pickerIAIContainerBackground.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
  }
  
  func addImagePickerActivityToContainer() {
    self.pickerImageActivityIndicator = UIActivityIndicatorView()
    self.pickerImageActivityIndicator.activityIndicatorViewStyle = .whiteLarge
    self.pickerImageActivityIndicator.color = .red
    self.pickerImageActivityIndicatorContainer.addSubview(self.pickerImageActivityIndicator)
    self.pickerImageActivityIndicatorContainer.center  = self.pickerImageActivityIndicator.center
    self.pickerImageActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
    self.pickerImageActivityIndicator.centerXAnchor.constraint(equalTo: self.pickerImageActivityIndicatorContainer.centerXAnchor).isActive = true
    self.pickerImageActivityIndicator.centerYAnchor.constraint(equalTo: self.pickerImageActivityIndicatorContainer.centerYAnchor).isActive = true
  }
  
  func setupImagePickerActivityBackground() {
    initImagePickerContainerBackground()
    self.pickerImageActivityIndicatorContainer = initImagePickerActivityContainer()
    self.addImagePickerActivityToContainer()
  }
  
  func setupImagePickerActivity() {
    self.pickerIAIContainerBackground.isHidden = false
    self.pickerImageActivityIndicatorContainer.isHidden = false
    self.pickerImageActivityIndicator.isHidden = false
  }
    
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if picker == self.photoLibraryImagePicker || picker == self.photoCameraImagePicker {
      pickImageByUIImage(image: info[UIImagePickerControllerOriginalImage] as! UIImage)
    } else if picker == self.selfieImagePicker {
      pickSelfie(image: info[UIImagePickerControllerOriginalImage] as! UIImage)
    } else {
      // noop
    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    self.resultTextView.text = "Recognition cancelled by user!"
    self.resultImageView.image = nil
    self.dismiss(animated: true, completion: nil)
  }
}

extension SampleViewController: OCRStudioSDKViewControllerDelegate {
  func ocrViewControllerDidRecognize(_ result: OBJCOCRStudioSDKResult, from buffer: CMSampleBuffer?) {
    let resultRef = result.getRef()
    if resultRef.allTargetsFinal() {
      self.setResult(result: resultRef)
      resultTableView.reloadData()
      dismiss(animated: true, completion: nil)
    }
  }
  
  func ocrViewControllerDidRecognizeSingleImage(_ result: OBJCOCRStudioSDKResult) {
    self.setResult(result: result.getRef())
    resultTableView.reloadData()
    dismiss(animated: true, completion: nil)
  }
  
  func ocrViewControllerDidCancel() {
    resultTextView.text = "Recognition cancelled by user!"
    resultImageView.image = nil
    dismiss(animated: true, completion: nil)
  }
  
  func ocrViewControllerDidStop(_ result: OBJCOCRStudioSDKResult) {
    self.setResult(result: result.getRef())
    resultTableView.reloadData()
    dismiss(animated: true, completion: nil)
  }
}
