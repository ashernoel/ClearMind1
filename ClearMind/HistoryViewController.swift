//
//  HistoryViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 12/8/19.
//  Copyright © 2019 Asher Noel. All rights reserved.
//

// The main function of this view controller and table view cell is to present PAST recordings and let them be 1) editable and 2) searchable!!

import AWSAppSync
import UIKit

// This specificies how each recording appears
//
class RecordingCell: UITableViewCell, UITextViewDelegate {
    
    // The text is a text view so that it is editable
    @IBOutlet var recordingText: UITextView!
    
    // The app's AppSyncClient, used to fetch initial comment data and subscribe to new comments
    var appSyncClient: AWSAppSyncClient?
   
    // The table view stores the ID so that it can mutate the recording
    var recordingId: GraphQLID = ""
    
    // This function makes sure that the cell connects to AWS
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        appSyncClient = appDelegate.appSyncClient
    }
    
    // This populates the cell with values from the table cell
    func updateValues(recording: String?) {
        
        createToolbar()
        recordingText.delegate = self
        recordingText.text = recording
    }
    
    // This mutates the recording with the EDITED information
    func runUpdateRecording(){
        appSyncClient?.perform(mutation: UpdateRecordingMutation(input: UpdateRecordingInput(id: recordingId, content: recordingText.text)))  { (result, error) in
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
    
    // This creates a toolbar and "Save" button when editing a recording
    func createToolbar()
    {
        // Create the toolbar
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        // Add the done button
        let doneButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(RecordingCell.dismissKeyboard))
         let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        
        // Adjust the colors and present the done button as a subjview
        doneButton.tintColor = UIColor(red:0.00, green:0.69, blue:1.00, alpha:1.0)
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        recordingText.inputAccessoryView = toolBar
    }
    
    // This updates the recording cell and there rest of the table view
    @objc func dismissKeyboard()
    {
        // Dismiss the keyboard
        recordingText.endEditing(true)
        
        // Update the table using a mutation
        runUpdateRecording()
    
    }
    
 
}

// This is the main view controller for the past recordings
//
class HistoryViewController: UIViewController, UISearchBarDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!

    
    // MARK: - Variables
    var appSyncClient: AWSAppSyncClient?

    // These variables ensure speed
    var nextToken: String?
    var fixedLimit: Int = 20 // predefined pagination size
    var isLoadInProgress: Bool = false
    var needUpdateList: Bool = false
    var lastOpenedIndex: Int = -1

    var recordingList: [ListRecordingsQuery.Data.ListRecording.Item?] = []

    // This function update the table view upon refreshing
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self,
                                 action: #selector(handleRefresh(_:)),
                                 for: .valueChanged)

        return refreshControl
    }()

    // This function always fetches new data from AWS before populating the table view.
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        nextToken = nil
        fetchAllRecordingsUsingCachePolicy(.returnCacheDataAndFetch)
    }

    // MARK: - Controller delegates
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // update list only if data source is changed programmatically
        if needUpdateList {
            needUpdateList = false
            nextToken = nil
            fetchAllRecordingsUsingCachePolicy(.returnCacheDataAndFetch)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // This is the standard code that syncs the class with AWS
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        appSyncClient = appDelegate.appSyncClient

        // Standard delegate assignment
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        tableView.refreshControl = refreshControl
        tableView.allowsSelection = false

        // We want all of teh data at first
        fetchAllRecordingsUsingCachePolicy(.returnCacheDataAndFetch)
            
    }

    // MARK: - Queries
    
    // The first function gets a list of all of the current recordings from AWS
    //
    func fetchAllRecordingsUsingCachePolicy(_ cachePolicy: CachePolicy) {
        if isLoadInProgress {
            return
        }

        isLoadInProgress = true

        refreshControl.beginRefreshing()
        
        // There is no filter on this query: it grabs all of the results
        let listQuery = ListRecordingsQuery(limit: fixedLimit, nextToken: nextToken)

        appSyncClient?.fetch(query: listQuery, cachePolicy: cachePolicy) { result, error in
            self.refreshControl.endRefreshing()

            if let error = error {
                print("Error fetching data: \(error)")
                return
            }

            // Remove existing records if we're either loading from cache, or loading fresh (e.g., from a refresh)
            if self.nextToken == nil, cachePolicy == .returnCacheDataAndFetch {
                self.recordingList.removeAll()
            }

            let existingKeys = Set(self.recordingList.compactMap { $0?.id })
            let newItems = result?
                .data?
                .listRecordings?
                .items?
                .compactMap { $0 }
                .filter { !existingKeys.contains($0.id) }

            self.recordingList.append(contentsOf: newItems ?? [])
            
            // Update data and the rest of the table
            self.tableView.reloadData()

            self.nextToken = result?.data?.listRecordings?.nextToken
            

            self.isLoadInProgress = false
        }
    }
    
    // This function works with the SEARCH BAR so that only certain recordings are displayed
    func fetchAllRecordingsUsingSearch(_ searchQuery: String) {
        
        if isLoadInProgress {
            return
        }
        
        print("hello")
        print(searchQuery)
        isLoadInProgress = true

        refreshControl.beginRefreshing()
        
        // This query checks to make sure the content contains the search Query
        let listQuery = ListRecordingsQuery(filter: ModelRecordingFilterInput(content: ModelStringInput(contains: searchQuery)), limit: fixedLimit, nextToken: nextToken)
            
       
        appSyncClient?.fetch(query: listQuery) { result, error in
            self.refreshControl.endRefreshing()

            if let error = error {
                print("Error fetching data: \(error)")
                return
            }

            // No matter what, get rid of all of the old recordings to make room for only the searched ones.
            self.recordingList.removeAll()
            

            let existingKeys = Set(self.recordingList.compactMap { $0?.id })
            let newItems = result?
                .data?
                .listRecordings?
                .items?
                .compactMap { $0 }
                .filter { !existingKeys.contains($0.id) }

            self.recordingList.append(contentsOf: newItems ?? [])

            // Update the rest of the table view.
            self.tableView.reloadData()

            self.nextToken = result?.data?.listRecordings?.nextToken
            

            self.isLoadInProgress = false
        }
    }

}

// MARK: - Table view delegates
extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recordingList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? RecordingCell else {
            return UITableViewCell()
        }

        guard let recording = recordingList[indexPath.row] else {
            return cell
        }

        cell.recordingId = recording.id
        cell.updateValues(recording: recording.content)
        
        return cell
    }

    // editing check
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    // editing action
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            guard let recordingId = recordingList[indexPath.row]?.id else {
                return
            }
            let deleteRecordingMutation = DeleteRecordingMutation(input: DeleteRecordingInput(id: recordingId))
            
            let optimisticUpdate: OptimisticResponseBlock = { transaction in
                do {
                    // Update our normalized local store immediately for a responsive UI.
                    try transaction?.update(query: ListRecordingsQuery()) { (data: inout ListRecordingsQuery.Data) in
                        // remove event from local cache.
                        let newState = data.listRecordings?.items?.filter { $0?.id != recordingId }
                        data.listRecordings?.items = newState
                    }
                } catch {
                    print("Error removing the object from cache with optimistic response.")
                }
            }

            appSyncClient?.perform(mutation: deleteRecordingMutation, optimisticUpdate: optimisticUpdate) { result, error in
                if let result = result {
                    print("Successful response for delete: \(result)")

                    // refresh updated list in main thread
                    self.recordingList.remove(at: indexPath.row)
                    self.tableView.reloadData()
                } else if let error = error {
                    print("Error response for delete: \(error)")
                }
            }
        }
    }

    // If the UITextView is multiple lines, then the table view should adjust its height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return UITableView.automaticDimension
    }
    
    // Default table view height
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {

        return 200.0 // You can set any other value, it's up to you
    }

    // Pagination
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !isLoadInProgress,
            indexPath.row > recordingList.count - 2,
            nextToken?.count ?? 0 > 0 {
            fetchAllRecordingsUsingCachePolicy(.fetchIgnoringCacheData)
        }
    }
    
    // Implement the search bar and check for the empty string case.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText != "" {
            fetchAllRecordingsUsingSearch(searchText.lowercased())
        } else {
            fetchAllRecordingsUsingCachePolicy(.fetchIgnoringCacheData)
        }


    }
    
    // Dismiss the search bar when done.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.searchBar.endEditing(true)
    }
    
}


