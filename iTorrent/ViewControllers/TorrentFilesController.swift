//
//  TorrentFilesController.swift
//  iTorrent
//
//  Created by  XITRIX on 16.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class TorrentFilesController : ThemedUIViewController {
    @IBOutlet weak var tableView: ThemedUITableView!
    
    var managerHash : String!
    var name : String!
	
	var files : [File] = []
	var notSortedFiles : [File] = []
	var downloadedFiles : [File] = []
	
	var showFolders : [String:Folder] = [:]
	var showFiles : [File] = []
	
	var root : String = ""
	
    var runUpdate = false
	
	var tableViewEditMode : Bool = false
	
	var defaultToolBarItems : [UIBarButtonItem]?
	lazy var editBarItems : [UIBarButtonItem] = {
		let res = [UIBarButtonItem(title: NSLocalizedString("All", comment: ""), style: .plain, target: self, action: #selector(shareAll)),
				   UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
				   UIBarButtonItem(title: NSLocalizedString("Share", comment: ""), style: .plain, target: self, action: nil),
				   UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
				   UIBarButtonItem(title: NSLocalizedString("Selected", comment: ""), style: .plain, target: self, action: #selector(shareSelected))]
		
		res[0].width = (NSLocalizedString("All", comment: "") as NSString).boundingRect(with: CGSize.zero, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 21)], context: nil).width
		res[4].width = (NSLocalizedString("Selected", comment: "") as NSString).boundingRect(with: CGSize.zero, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 21)], context: nil).width
		
		if (res[0].width < res[4].width) {
			res[0].width = res[4].width
		} else {
			res[4].width = res[0].width
		}
		return res
	}()
	
	@IBOutlet weak var selectButton: ThemedUITableView!
	
	override func themeUpdate() {
		super.themeUpdate()
        
		let theme = Themes.current()
		tableView.backgroundColor = theme.backgroundMain
		editBarItems[2].tintColor = theme.tertiaryText
	}
	
	deinit {
		print("Files DEINIT!!")
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		defaultToolBarItems = toolbarItems
		
		if (root.starts(with: "/")) { root.removeFirst() }
		
        if (root == "") {
            let back = UIBarButtonItem()
            back.title = "Root"
            navigationItem.backBarButtonItem = back
			
			initialize()
        } else {
			let urlRoot = URL(string: root.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)
			title = urlRoot?.lastPathComponent
			
			let titleView = FileManagerTitleView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
			titleView.title.text = title
			titleView.subTitle.text = urlRoot?.deletingLastPathComponent().path
			navigationItem.titleView = titleView
        }
		initFolder()
		update()
		
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = 82
		tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
        runUpdate = true
        DispatchQueue.global(qos: .background).async {
            while(self.runUpdate) {
				self.update()
                DispatchQueue.main.async {
                    for cell in self.tableView.visibleCells {
                        if let cell = cell as? FileCell {
							cell.file = self.tableViewEditMode ? self.downloadedFiles[cell.index] : self.showFiles[cell.index]
                            cell.update()
                        }
                    }
                }
                sleep(1)
            }
        }
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        runUpdate = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Manager.saveTorrents()
    }
	
	func initialize() {
		let localFiles = get_files_of_torrent_by_hash(managerHash)
		if localFiles.error == 1 {
			dismiss(animated: false)
			return
        }
		
        let size = Int(localFiles.size)
        
        for i in 0 ..< size {
            let file = File()
			
			let n = String(validatingUTF8: localFiles.files[i].file_name) ?? "ERROR"
			let name = URL(string: n.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!
			file.name = name.lastPathComponent
			file.path = name.deletingLastPathComponent().path == "." ? "" : name.deletingLastPathComponent().path
			file.size = localFiles.files[i].file_size
			file.isDownloading = localFiles.files[i].file_priority
			file.number = i
            file.pieces = Array(UnsafeBufferPointer(start: localFiles.files[i].pieces, count: Int(localFiles.files[i].num_pieces)))
			
			files.append(file)
			
			if (i == 0 && root == "" && n.starts(with: self.name + "/")) {
				root = self.name
			}
        }
		notSortedFiles = files
		files.sort{$0.name < $1.name}
	}
	
	func initFolder() {
		let rootPathParts = root.split(separator: "/")
		for file in files {
			if (file.path == root) {
				showFiles.append(file)
				continue
			}
			let filePathParts = file.path.split(separator: "/")
			if (file.path.starts(with: root + "/") && filePathParts.count > rootPathParts.count) {
				let folderName = String(filePathParts[rootPathParts.count])
				if (showFolders[folderName] == nil) {
					let folder = Folder()
					folder.name = folderName
					showFolders[folderName] = folder
				}
				let folder = showFolders[folderName]!
				print("\(file.path) : \(root)/\(folderName)")
				if (file.path.starts(with:("\(root)/\(folderName)"))) {
					folder.files.append(file)
				}
			}
		}
		
		for folder in showFolders.keys {
			var size : Int64 = 0
			for s in (showFolders[folder]?.files)! {
				size += s.size
			}
			showFolders[folder]?.size = size
		}
	}
	
	func update() {
		let localFiles = get_files_of_torrent_by_hash(managerHash)
		if localFiles.error == 1 {
			dismiss(animated: false)
			return
		}
		
		let size = Int(localFiles.size)

		for i in 0 ..< size {
			notSortedFiles[i].size = localFiles.files[i].file_size
			notSortedFiles[i].downloaded = localFiles.files[i].file_downloaded
            notSortedFiles[i].pieces = Array(UnsafeBufferPointer(start: localFiles.files[i].pieces, count: Int(localFiles.files[i].num_pieces)))
		}
	}
    
    @IBAction func deselectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
            if let cell = cell as? FileCell {
                cell.switcher.setOn(false, animated: true)
            }
		}
		for i in 0 ..< files.count {
			if (files[i].size != 0 && files[i].downloaded / files[i].size == 1) {
				files[i].isDownloading = 4
			} else {
				files[i].isDownloading = 0
			}
		}
		setFilesPriority()
    }
	
    @IBAction func selectAction(_ sender: UIBarButtonItem) {
		for cell in tableView.visibleCells {
            if let cell = cell as? FileCell {
                cell.switcher.setOn(true, animated: true)
            }
		}
		for i in 0 ..< files.count {
			files[i].isDownloading = 4
		}
		setFilesPriority()
    }
	
	func setFilesPriority() {
		var res : [Int32] = []
		for file in notSortedFiles {
			res.append(file.isDownloading)
		}
		set_torrent_files_priority(managerHash, UnsafeMutablePointer(mutating: res))
	}
	
	@IBAction func selectButtonItem(_ sender: UIBarButtonItem) {
		if (!tableView.isEditing) {
			tableView.setEditing(true, animated: true)
			tableViewEditMode = true
			
			navigationItem.setLeftBarButton(UIBarButtonItem(title: NSLocalizedString("Select All", comment: ""), style: .plain, target: self, action: #selector(selectAllOnEdit)), animated: true)
			navigationItem.rightBarButtonItem?.title = NSLocalizedString("Done", comment: "")
			navigationItem.rightBarButtonItem?.style = .done
			
			editBarItems[4].isEnabled = false
			setToolbarItems(editBarItems, animated: true)
		} else {
			tableView.setEditing(false, animated: true)
			tableViewEditMode = false
			
			navigationItem.setLeftBarButton(nil, animated: true)
			navigationItem.rightBarButtonItem?.title = NSLocalizedString("Select", comment: "")
			navigationItem.rightBarButtonItem?.style = .plain
			
			setToolbarItems(defaultToolBarItems, animated: true)
		}
		
		tableView.reloadSections([0], with: .automatic)
		for cell in tableView.visibleCells {
			if let cell = cell as? FileCell {
				cell.hideUI = tableViewEditMode
				cell.update()
			} else if let cell = cell as? FolderCell {
				cell.update()
			}
		}
	}
	
	@objc func selectAllOnEdit() {
		if (tableView.indexPathsForSelectedRows?.count ?? 0 > 0) {
			for indexPath in tableView.indexPathsForSelectedRows! {
				tableView.deselectRow(at: indexPath, animated: true)
			}
		} else {
			for i in 0 ..< downloadedFiles.count {
				tableView.selectRow(at: IndexPath(row: i, section: 0), animated: true, scrollPosition: .none)
			}
		}
		updateLeftEditSelectionButton()
	}
	
	func updateLeftEditSelectionButton() {
		if tableView.isEditing {
			if (tableView.indexPathsForSelectedRows?.count ?? 0 > 0) {
				navigationItem.leftBarButtonItem?.title = "\(NSLocalizedString("Deselect", comment: "")) (\(tableView.indexPathsForSelectedRows!.count))"
				editBarItems[4].isEnabled = true
			} else {
				navigationItem.leftBarButtonItem?.title = NSLocalizedString("Select All", comment: "")
				editBarItems[4].isEnabled = false
			}
		}
	}
	
	@objc func shareAll() {
		print(Manager.rootFolder + "/" + root)
		var path : NSURL
		if (root.isEmpty) {
			if let file = showFiles.first {
				path = NSURL(fileURLWithPath: Manager.rootFolder + "/" + file.path + "/" + file.name, isDirectory: false)
			} else { return }
		} else {
			path = NSURL(fileURLWithPath: Manager.rootFolder + "/" + root, isDirectory: true)
		}
		let shareController = ThemedUIActivityViewController(activityItems: [path], applicationActivities: nil)
		if (shareController.popoverPresentationController != nil) {
			shareController.popoverPresentationController?.barButtonItem = editBarItems[0]
			shareController.popoverPresentationController?.permittedArrowDirections = .any
		}
		UIApplication.shared.keyWindow?.rootViewController?.present(shareController, animated: true)
	}
	
	@objc func shareSelected() {
		var paths : [NSURL] = []
		for indexPath in tableView.indexPathsForSelectedRows! {
			if indexPath.row < showFolders.keys.count {
				let key = showFolders.keys.sorted()[indexPath.row]
				paths.append(NSURL(fileURLWithPath: Manager.rootFolder + "/" + root + "/" + showFolders[key]!.name, isDirectory: true))
			} else {
				let index = indexPath.row - showFolders.keys.count
				paths.append(NSURL(fileURLWithPath: Manager.rootFolder + "/" + downloadedFiles[index].path + "/" + downloadedFiles[index].name, isDirectory: false))
			}
		}
		let shareController = ThemedUIActivityViewController(activityItems: paths, applicationActivities: nil)
		if (shareController.popoverPresentationController != nil) {
			shareController.popoverPresentationController?.barButtonItem = editBarItems[4]
			shareController.popoverPresentationController?.permittedArrowDirections = .any
		}
		UIApplication.shared.keyWindow?.rootViewController?.present(shareController, animated: true)
	}
}

extension TorrentFilesController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableViewEditMode) {
            downloadedFiles = showFiles.filter({$0.downloaded == $0.size})
            return showFolders.keys.count + downloadedFiles.count
        }
        return showFolders.keys.count + showFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (tableViewEditMode) {
            if (indexPath.row < showFolders.keys.count) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath) as! FolderCell
                let key = showFolders.keys.sorted()[indexPath.row]
                cell.title.text = key
                cell.size.text = Utils.getSizeText(size: showFolders[key]!.size)
                cell.actionDelegate = self
                return cell
            } else {
                let index = indexPath.row - showFolders.keys.count
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FileCell
                cell.file = downloadedFiles[index]
                cell.index = index
                cell.hideUI = true
                cell.update()
                cell.switcher.setOn(downloadedFiles[index].isDownloading != 0, animated: false)
                cell.actionDelegate = self
                return cell
            }
        } else {
            if (indexPath.row < showFolders.keys.count) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath) as! FolderCell
                let key = showFolders.keys.sorted()[indexPath.row]
                cell.title.text = key
                cell.size.text = Utils.getSizeText(size: showFolders[key]!.size)
                cell.actionDelegate = self
                return cell
            } else {
                let index = indexPath.row - showFolders.keys.count
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FileCell
                cell.file = showFiles[index]
                cell.index = index
                cell.hideUI = false
                cell.update()
                cell.switcher.setOn(showFiles[index].isDownloading != 0, animated: false)
                cell.actionDelegate = self
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (tableViewEditMode) {
            return true
        }
        if (indexPath.row < showFolders.count ) {
            return false
        } else {
            let file = showFiles[indexPath.row - showFolders.count]
            if (file.downloaded == file.size) {
                return false
            }
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let title = NSLocalizedString("Priority", comment: "")
        let button = UITableViewRowAction(style: .default, title: title) { action, indexPath in
            let controller = ThemedUIAlertController(title: nil, message: NSLocalizedString("Priority", comment: ""), preferredStyle: .actionSheet)
            
            // "Normal"
            let max = UIAlertAction(title: NSLocalizedString("High", comment: ""), style: .default, handler: { _ in
                let index = indexPath.row - self.showFolders.count
                self.showFiles[index].isDownloading = 4
                (self.tableView.cellForRow(at: indexPath) as? FileCell)?.update()
                set_torrent_file_priority(self.managerHash, Int32(self.showFiles[index].number), 4)
            })
            let high = UIAlertAction(title: NSLocalizedString("Medium", comment: ""), style: .default, handler: { _ in
                let index = indexPath.row - self.showFolders.count
                self.showFiles[index].isDownloading = 3
                (self.tableView.cellForRow(at: indexPath) as? FileCell)?.update()
                set_torrent_file_priority(self.managerHash, Int32(self.showFiles[index].number), 3)
            })
            let norm = UIAlertAction(title: NSLocalizedString("Low", comment: ""), style: .default, handler: { _ in
                let index = indexPath.row - self.showFolders.count
                self.showFiles[index].isDownloading = 2
                (self.tableView.cellForRow(at: indexPath) as? FileCell)?.update()
                set_torrent_file_priority(self.managerHash, Int32(self.showFiles[index].number), 2)
            })
            //            let min = UIAlertAction(title: NSLocalizedString("Low", comment: ""), style: .default, handler: { _ in
            //                let index = indexPath.row - self.showFolders.count
            //                self.showFiles[indexPath.row - self.showFolders.count].isDownloading = 1
            //                (self.tableView.cellForRow(at: indexPath) as? FileCell)?.update()
            //                set_torrent_file_priority(self.managerHash, Int32(self.showFiles[index].number), 1)
            //            })
            
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
            
            controller.addAction(max)
            controller.addAction(high)
            controller.addAction(norm)
            //            controller.addAction(min)
            controller.addAction(cancel)
            
            if (controller.popoverPresentationController != nil) {
                controller.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                controller.popoverPresentationController?.sourceRect = (tableView.cellForRow(at: indexPath)?.bounds)!
                controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            }
            
            self.present(controller, animated: true)
        }
        button.backgroundColor = #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1)
        (tableView.cellForRow(at: indexPath) as? FileCell)?.update()
        return [button]
    }
}

extension TorrentFilesController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableViewEditMode) {
            updateLeftEditSelectionButton()
        } else {
            if (indexPath.row < showFolders.keys.count) {
                let controller = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "Files") as! TorrentFilesController
                controller.managerHash = managerHash
                controller.name = name
                controller.root = root + "/" + showFolders.keys.sorted()[indexPath.row]
                controller.notSortedFiles = notSortedFiles
                controller.files = files
                show(controller, sender: self)
            } else {
                let index = indexPath.row - showFolders.keys.count
                let file = showFiles[index]
                let percent = Float(file.downloaded) / Float(file.size) * 100
                if (percent < 100) {
                    let cell = tableView.cellForRow(at: indexPath) as! FileCell
                    cell.switcher.setOn(!cell.switcher.isOn, animated: true)
                    if (cell.actionDelegate != nil) {
                        cell.actionDelegate?.fileCellAction(cell.switcher, index: index)
                    }
                } else {
                    let cell = tableView.cellForRow(at: indexPath) as! FileCell
                    cell.shareAction(cell.shareButton)
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if (tableView.isEditing) {
            updateLeftEditSelectionButton()
        }
    }
}

extension TorrentFilesController: FolderCellActionDelegate {
    func folderCellAction(_ key: String, sender : UIButton) {
        let controller = ThemedUIAlertController(title: NSLocalizedString("Download content of folder", comment: ""), message: key, preferredStyle: .actionSheet)
        
        let download = UIAlertAction(title: NSLocalizedString("Download", comment: ""), style: .default) { alert in
            for i in self.showFolders[key]!.files {
                i.isDownloading = 4
            }
            self.setFilesPriority()
        }
        let notDownload = UIAlertAction(title: NSLocalizedString("Don't Download", comment: ""), style: .destructive) { alert in
            for i in self.showFolders[key]!.files {
                if (i.size != 0 && i.downloaded / i.size == 1) {
                    i.isDownloading = 4
                } else {
                    i.isDownloading = 0
                }
            }
            self.setFilesPriority()
        }
        let cancel = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
        
        controller.addAction(download)
        controller.addAction(notDownload)
        controller.addAction(cancel)
        
        if (controller.popoverPresentationController != nil) {
            controller.popoverPresentationController?.sourceView = sender;
            controller.popoverPresentationController?.sourceRect = sender.bounds;
            controller.popoverPresentationController?.permittedArrowDirections = .any;
        }
        
        self.present(controller, animated: true)
    }
}

extension TorrentFilesController: FileCellActionDelegate {
    func fileCellAction(_ sender: UISwitch, index: Int) {
        showFiles[index].isDownloading = sender.isOn ? 4 : 0
        set_torrent_file_priority(managerHash, Int32(showFiles[index].number), sender.isOn ? 4 : 0)
    }
}
