#  ClearMind Design


## The Story of ClearMind 

### Motivation

This app was motivated by a moment during my first-year outdoors program trip with Emma Humphrey (CA) when I realized that I wished I could transcribe my conversations with other people to better remember and reference them. In addition, I had no experience using a server or cloud in high school. Putting these two together, my goal for myself at the beginning of CS50 was to eventually learn how to 1) create a project that transcribed my voice and 2) stored that information using Amazon Web Services (AWS) or some similar back-end. After many long nights, I am happy to push a project to GitHub that accomplishes those two aims. 


### Back-End: Amazon Web Services

App Development started with the back-end, Amazon Web Services. I knew that I wanted to have user authentication and data storage so I started by installing Cognito and S3 (which I would later leave in turn for the faster DynamoDB database). 

AWS for iOS development is relatively novel and rapidly changing, so there were no Youtube guides or stack overflow articles that really helped me out with the back-end set up. Instead, I navigated the internet without direction as I bounced from documentation to documentation and bug to bug. 

At first, I was skeptical of all of the random names that AWS seemed to be throwing at me, including "Ampliy," "AppSync," "DataStore," "Storage," "DynamoDB," "Mobile Hub," "Predictions," "Kinesis," "Pinpoint," "Analytics," "User Pools," and more. If I could do the project over again, I would spend longer at the beginning of the project understanding the variety of AWS services and which ones would work best for me. It turned out that [AWS Amplify] for iOS SDK, which is being phased out in favor of a more general Amplify Framework that is online but does not work with XCode (looking at the wrong documentation lost me many hours), provided most of the keys and infrastructure for my app. [AWS AppSync] ended up being the way for me to use GraphQL to store data in DynamoDB tables. Pinpoint let me track individual users and send push notifications after extensive provisioning profiling, certificate work, and another many hours of bugfixing. These are reflected in my podfile, which is viewable in vim by typing "vim Podfile" in the root project directory. I included User Authentification, Facebook Sign in, Analytics, Push Notifications, and DyanmoDB tables in the project because, again, they seemed fun and I had never worked with them or a back-end before. They took tens of hours to implement, starting long before the Hackathon and ending few days after, from downloading my first Cocoa pod to learning how to edit Podfile's to tracking down the code that spawned the original error messages on github.com because there was such little help on the Internet in the form of articles, videos, or stack overflows even. As a result, I ended up spending most of my time in the later stages of back-end development on the legacy iOS Amplify SDK documentation, which was light and often redirected to the Amplify javascript framework for React, but had enough help for me to make sense of the services. 

Going forward, I only have to create separate tables for distinct users, instead of having them all access a public table, which will be a fun way to continue exploring AWS. 

### Swift Models, Views, and Controllers 

[Directory]: As mentioned in the README.md, there are five view controllers with two models (voice transcription and classification) and a delegate file: 
- AppDelegate.swift:
- SceneDelegate.swift
- RecordViewController.swift
- HistoryViewController.swift
- ProfileViewController.swift
- SettingsViewController.swift
- ViewController.swift

[Views]: The View controllers are all fairly standard with table views (Record, History, Profile, Settings), stack views (Record), programmatically generated UI elements (Settings, Profile) and necessary functionality. 

[Models]: There are three models involved in my project, the 1) DynamoDB table using AWS and GraphQL, 2) a real-time speech-to-text sound analyzer, and 3) a real-time gender sound classification machine learning model using Core ML3. 

DyanmoDB tables were created by pushing schema.graphql models made using AWS Amplify API to the cloud. These tables are then manipulated by using the functions in API.swift. The History view controller makes the most use of these functions: it queries all, queries with a filter, updates the tables, adds to the tables, and deletes from the tables. GraphQL is built in part upon SQLite. 

The real-time speech-to-text sound analyzer uses the device's microphone to first record audio using the AudioEngine by collecting samples into an internal buffer. When the buffer is full, the audio engine then calls on the block. The SFSpeechAudioBufferRecognition request makes sure that there is speech in the live audio and recognitionTask() then begins transcribing the speech. Core ML3 makes it possible to fit the latest advances in deep learning to upgrade Apple's model with offline functionality, better punctuation, and likely better overall accuracy as well. 

The pre-trained Core ML 3 Model uses Apple's MLSoundClassifier model structure trained on 33 labeled input files. The model works with the same "Tap" as the above model so that they analyze real-time speech with the same buffer concurrntly. It then makes a prediction on every buffer as to whether the speaker is male or female and displays both the prediction and the confidence that the model has to the user. This utilizes frameworks that Apple only released publicly a few months ago after WWDC 2019, so it felt great to implement them into the app. Going forward, these models could be improved by combining them into possible one model or using Core ML3 to turn neural networks built using Keras for more advanced processes such as Name detection or sentiment anlayisis into .mlmodels that can be deployed locally on iOS devices. 

### Front-End: Swift User Interfaces (UI)

[Main TabBar Items]: After logging in, the app opens with the RecordViewController, where the recordButton is featured prominently in the middle with a sleek and simple design. Next in the tab bar, the HistoryViewController let people access their past records, so I put it next to the record tab. Finally, the profile lets the user configure their notification setting and log out. To spice up the page and make it more interesting, I created a large table view with container images and views full with shadows and cornered radii. The images in the Profile page should all be self explanatory: logging out has an image of a lock, settings has a picture of gears, and learn more has a picture of the GitHub figurine. 

[Main TabBar Logos]: The logo in the "TabBar" for the Record page is a brain and a gear because the program functions to enhance the user's brain by effectively improving their memory and solidifying their past. The logo for the History page is an hour glass to ominously remind the user about how time, and many of their conception of their mememories, is ticking away. Thus, the History tab's focus is on time by 1) showing past recordings and 2) connoting the uncertainty of both that past and future time. The logo for the Profile page resembles a non-gendered person because the User is likely a human who could be any gender. 

[Login View]: The login view features the logo and a consistent blue background. This styling is consistent with the rest of the app. 

[App Icon and Color]:  The icon for the App as a whole is a brain with a gear to represent the core functionality of the app: enhancing the user's memory by transcribing what was said and therefore crystallizing past memories. I chose this light blue color for much of the UI because of it has innocent and pure connotations that suggest the user should trust the app while also being somewhat ethereal and intriguingly mystic. 



## Screenshots

<p align="center">

<img src="/images/login.png" alt="Default Login Screen" width="300"/><img src="/images/record.png" alt="Default Login Screen" width="300"/>

<img src="/images/history.png" alt="Default Login Screen" width="300"/><img src="/images/profile.png" alt="Default Login Screen" width="300"/>

<img src="/images/edit.png" alt="Default Login Screen" width="300"/><img src="/images/search.png" alt="Default Login Screen" width="300"/>


</p>

## Built With 
*[Xcode]
*[Amazon Web Services]

## References
- [AWS Amplify iOS SDK] https://aws-amplify.github.io/docs/sdk/ios/start
- [AWS Amplify Framework] https://aws-amplify.github.io/docs/ios/start
- [AWS Management Console] https://console.aws.amazon.com/console/home?region=us-east-1
- [Sound Classification Core ML] https://heartbeat.fritz.ai/sound-classification-using-core-ml-3-and-create-ml-fc73ca20aff5
- [Apple Documentation Core ML] https://developer.apple.com/documentation/coreml
- [Apple Documentation Speech Recognition Permission] https://developer.apple.com/documentation/speech/asking_permission_to_use_speech_recognition
- [Apple Documentation Recognizing Speech] https://developer.apple.com/documentation/speech/recognizing_speech_in_live_audio- [Google Punctuationless Passages] https://sites.google.com/a/saintelizabeth.us/learningspecialist/home/passages-to-edit-for-capitalization-and-punctuation-practice
