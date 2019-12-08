//
//  HistoryViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 12/8/19.
//  Copyright © 2019 Asher Noel. All rights reserved.
//
import AWSAppSync
import UIKit

class RecordingCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet var recordingText: UITextView!
    
    // The app's AppSyncClient, used to fetch initial comment data and subscribe to new comments
    var appSyncClient: AWSAppSyncClient?
   
    var recordingId: GraphQLID = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        appSyncClient = appDelegate.appSyncClient
    }
    
    func updateValues(recording: String?) {
        
        
        recordingText.delegate = self
        recordingText.text = recording
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        runUpdateRecording()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
    }
    
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
    
 
}

class HistoryViewController: UIViewController, UISearchBarDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!

    
    // MARK: - Variables
    var appSyncClient: AWSAppSyncClient?

    
    var nextToken: String?
    var fixedLimit: Int = 20 // predefined pagination size
    var isLoadInProgress: Bool = false
    var needUpdateList: Bool = false
    var lastOpenedIndex: Int = -1

    var recordingList: [ListRecordingsQuery.Data.ListRecording.Item?] = []

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self,
                                 action: #selector(handleRefresh(_:)),
                                 for: .valueChanged)

        return refreshControl
    }()

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        nextToken = nil
        fetchAllRecordingsUsingCachePolicy(.fetchIgnoringCacheData)
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

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        appSyncClient = appDelegate.appSyncClient

        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        tableView.refreshControl = refreshControl
        tableView.allowsSelection = false


        fetchAllRecordingsUsingCachePolicy(.returnCacheDataAndFetch)
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)
        
    }

    // MARK: - Queries
    func fetchAllRecordingsUsingCachePolicy(_ cachePolicy: CachePolicy) {
        if isLoadInProgress {
            return
        }

        isLoadInProgress = true

        refreshControl.beginRefreshing()
        
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

            self.tableView.reloadData()

            self.nextToken = result?.data?.listRecordings?.nextToken
            

            self.isLoadInProgress = false
        }
    }
    
    func fetchAllRecordingsUsingSearch(_ searchQuery: String) {
        
        if isLoadInProgress {
            return
        }
        
        print("hello")
        print(searchQuery)
        isLoadInProgress = true

        refreshControl.beginRefreshing()
        
        let listQuery = ListRecordingsQuery(filter: ModelRecordingFilterInput(content: ModelStringInput(contains: searchQuery)), limit: fixedLimit, nextToken: nextToken)
            
       
        appSyncClient?.fetch(query: listQuery) { result, error in
            self.refreshControl.endRefreshing()

            if let error = error {
                print("Error fetching data: \(error)")
                return
            }

            self.recordingList.removeAll()
            

            let existingKeys = Set(self.recordingList.compactMap { $0?.id })
            let newItems = result?
                .data?
                .listRecordings?
                .items?
                .compactMap { $0 }
                .filter { !existingKeys.contains($0.id) }

            self.recordingList.append(contentsOf: newItems ?? [])

            print(self.recordingList)
            print("reload")
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

    // click handlers
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        lastOpenedIndex = indexPath.row
//
//        guard let recording = recordingList[indexPath.row] else {
//            return
//        }
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        guard let controller = storyboard.instantiateViewController(withIdentifier: "RecordingDetailsViewController")
//            as? RecordingDetailsViewController else {
//                return
//        }
//        controller.event = recording.fragments.recording
//        navigationController?.pushViewController(controller, animated: true)
    //}
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {

        return 200.0 // You can set any other value, it's up to you
    }

    // pagination
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !isLoadInProgress,
            indexPath.row > recordingList.count - 2,
            nextToken?.count ?? 0 > 0 {
            fetchAllRecordingsUsingCachePolicy(.fetchIgnoringCacheData)
        }
    }
    
    // Reload the data in the table view remotely
    @objc func loadList(){
        //load data here
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
      // implement search here

        if searchText != "" {
            fetchAllRecordingsUsingSearch(searchText.lowercased())
        } else {
            fetchAllRecordingsUsingCachePolicy(.fetchIgnoringCacheData)
        }


    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.searchBar.endEditing(true)
    }


}


