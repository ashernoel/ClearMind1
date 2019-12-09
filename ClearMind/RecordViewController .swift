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
    @IBOutlet var textView: UITextView!
    @IBOutlet var genderClassification: UILabel!
    @IBOutlet var genderConfidence: UILabel!
    @IBOutlet var recordImage: UIImageView!
    
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
        
        // Build the UI
        buildUI()
        
    }
    
    override public func viewDidAppear(_ animated: Bool) {
       /
        / Configure the SFSpeechRecognizer object already
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

        // Start recording
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSession.Category.record)
        try audioSession.setMode(AVAudioSession.Mode.measurement)
        try audioSession.setActive(true)
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Rename inputnode to make code cleaner
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }

        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true

        // A recognition task represents a speech recognition session.
        // Keep a reference to the task so that it can be cancelled.
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
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Choose the processes that we want to happen: in our case, these are transcription and classification using two models.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
            self.analysisQueue.async {
                self.analyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
            }
        }
        
        // Start Speech Classifier with a request
        do {
             let request = try SNClassifySoundRequest(mlModel: soundClassifier.model)
             try analyzer.add(request, withObserver: resultsObserver)
         } catch {
             print("Unable to prepare request: \(error.localizedDescription)")
             return
         }
        
         
        // Start the entire Audio engine
        audioEngine.prepare()
        try audioEngine.start()
        textView.text = "(Recording started...)"
    }

    // MARK: SFSpeechRecognizerDelegate

    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
        } else {
            recordButton.isEnabled = false
        }
    }

    // MARK: Interface Builder actions

    @IBAction func recordButtonTapped() {
        if audioEngine.isRunning {
            
            // Stop recording audio and remove the Tap for next time
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            audioEngine.inputNode.removeTap(onBus: 0)

            // Update AWS with the transcription if there are new words
            if textView.text != "(Recording started...)" {
                runMutation()
            }
            
            // Change the image to start recording
            recordImage.image = UIImage(named:"startRecording")
            
        } else {
            
            // Do the opposite of the above
            try! startRecording()
            recordImage.image = UIImage(named:"stopRecording")

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
    
    func buildUI()
    {
        
        // This changes the background image
        recordButton.isEnabled = true
        if audioEngine.isRunning {
            recordImage.image = UIImage(named:"stopRecording")
        } else {
            recordImage.image = UIImage(named:"startRecording")
        }
        
    }
    
    

}

// These three blocks display the result of the classification model to the user. 
//
protocol GenderClassifierDelegate {
    func displayPredictionResult(identifier: String, confidence: Double)
}

extension RecordViewController: GenderClassifierDelegate {
    func displayPredictionResult(identifier: String, confidence: Double) {
        DispatchQueue.main.async {
            self.genderClassification.text = "\(identifier)"
            self.genderConfidence.text = "\(Double(round(100*confidence)/100))"
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
