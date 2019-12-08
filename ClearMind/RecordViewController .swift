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

class RecordViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    // Inititialzie the speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var textView : UITextView!
    
    var appSyncClient: AWSAppSyncClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appSyncClient = appDelegate.appSyncClient
        
        runMutation()
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

        audioEngine.prepare()
        try audioEngine.start()
        textView.text = "(Go ahead, I'm listening)"
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
            
            runMutation()
            print("tried to run mutation")
        } else {
            try! startRecording()
            recordButton.setTitle("Stop recording", for: [])
            
        }
    }
    
    func runMutation(){
        print("starting mutation")
        let mutationInput = CreateRecordingInput(content: "hello")
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
    
}
