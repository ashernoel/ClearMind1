//
//  RecordViewController .swift
//  ClearMind
//
//  Created by Asher Noel on 12/4/19.
//  Copyright © 2019 Asher Noel. All rights reserved.
//

import Foundation
import UIKit
import Speech
import AWSAppSync
import AVKit
import SoundAnalysis

class RecordViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    // MARK: -Variables
    
    //Connect with AWS
    var appSyncClient: AWSAppSyncClient?

    // Inititialzie the Speech Transcription
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Initialize the Speech Classification
    private var soundClassifier = GenderSoundClassification()
    var inputFormat: AVAudioFormat!
    var analyzer: SNAudioStreamAnalyzer!
    var resultsObserver = ResultsObserver()
    let analysisQueue = DispatchQueue(label: "com.custom.AnalysisQueue")
    
    //MARK: -IBOUtlets
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var textView : UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
        
        // Connect to AWS
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appSyncClient = appDelegate.appSyncClient
        
        // Gender Classifier settings
        resultsObserver.delegate = self
        inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        analyzer = SNAudioStreamAnalyzer(format: inputFormat)
        buildUI()
        
    }
    
    override public func viewDidAppear(_ animated: Bool) {
       // Configure the SFSpeechRecognizer object already
       // stored in a local member variable.
       speechRecognizer.delegate = self

       // Make the authorization request
       SFSpeechRecognizer.requestAuthorization { authStatus in

       // The authorization status results in changes to the
       // app’s interface, so process the results on the app’s
       // main queue.
          OperationQueue.main.addOperation {
             switch authStatus {
                case .authorized:
                   self.recordButton.isEnabled = true

                case .denied:
                   self.recordButton.isEnabled = false
                   self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)

                case .restricted:
                   self.recordButton.isEnabled = false
                   self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)

                case .notDetermined:
                   self.recordButton.isEnabled = false
                   self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
            }
          }
       }
    }
    
    private func startRecording() throws {

        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSession.Category.record)
        try audioSession.setMode(AVAudioSession.Mode.measurement)
        try audioSession.setActive(true)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }

        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true

        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result = result {
                self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.recordButton.isEnabled = true
                self.recordButton.setTitle("Start Recording", for: [])
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start Speech Classifier
        do {
             let request = try SNClassifySoundRequest(mlModel: soundClassifier.model)
             try analyzer.add(request, withObserver: resultsObserver)
         } catch {
             print("Unable to prepare request: \(error.localizedDescription)")
             return
         }
        
         audioEngine.inputNode.installTap(onBus: 0, bufferSize: 8000, format: inputFormat) { buffer, time in
                 self.analysisQueue.async {
                     self.analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
                 }
         }
        
        // Start Audio engine

        audioEngine.prepare()
        try audioEngine.start()
        textView.text = "(Recording started...)"
    }

    // MARK: SFSpeechRecognizerDelegate

    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setTitle("Start Recording", for: [])
        } else {
            recordButton.isEnabled = false
            recordButton.setTitle("Recognition not available", for: .disabled)
        }
    }

    // MARK: Interface Builder actions

    @IBAction func recordButtonTapped() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("Stopping", for: .disabled)
            
            // End audio engine for Speech Classifier
            endAudioEngine()
            
            // Update AWS with the transcription
            runMutation()
  
        } else {
            try! startRecording()
            recordButton.setTitle("Stop recording", for: [])
            

        }
    }
    
    // Update AWS with the new transcribed text
    func runMutation() {
        let mutationInput = CreateRecordingInput(content: textView.text)
        appSyncClient?.perform(mutation: CreateRecordingMutation(input: mutationInput)) { (result, error) in
            if let error = error as? AWSAppSyncClientError {
                print("Error occurred: \(error.localizedDescription )")
            }
            if let resultError = result?.errors {
                print("Error saving the item on server: \(resultError)")
                return
            }
            print("Mutation complete.")
        }
        
    }
    
    let transcribedText:UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .center
        view.textAlignment = .center
        view.numberOfLines = 0
        view.font = UIFont.systemFont(ofSize: 20)
        return view
    }()
    
    let placeholderText:UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .center
        view.textAlignment = .center
        view.numberOfLines = 0
        view.text = "Gender Classification by\nSound as you Speak..."
        view.font = UIFont.systemFont(ofSize: 25)
        return view
    }()

    
    func buildUI()
    {
        self.view.addSubview(placeholderText)
        self.view.addSubview(transcribedText)

        NSLayoutConstraint.activate(
            [transcribedText.centerYAnchor.constraint(equalTo: view.centerYAnchor),
             transcribedText.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
             transcribedText.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
             transcribedText.heightAnchor.constraint(equalToConstant: 100),
             transcribedText.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ]
        )
        
        NSLayoutConstraint.activate(
            [placeholderText.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
             placeholderText.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
             placeholderText.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
             placeholderText.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ]
        )
       
    }
    
    private func endAudioEngine() {
        audioEngine.isAutoShutdownEnabled = true
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}

protocol GenderClassifierDelegate {
    func displayPredictionResult(identifier: String, confidence: Double)
}

extension RecordViewController: GenderClassifierDelegate {
    func displayPredictionResult(identifier: String, confidence: Double) {
        DispatchQueue.main.async {
            self.transcribedText.text = ("Recognition: \(identifier)\nConfidence \(confidence)")
        }
    }
}


class ResultsObserver: NSObject, SNResultsObserving {
    var delegate: GenderClassifierDelegate?
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
            let classification = result.classifications.first else { return }
        
        let confidence = classification.confidence * 100.0
        
        if confidence > 60 {
            delegate?.displayPredictionResult(identifier: classification.identifier, confidence: confidence)
        }
    }
}
