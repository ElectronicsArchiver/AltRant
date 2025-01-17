//
//  CommentCell.swift
//  AltRant
//
//  Created by Omer Shamai on 12/7/20.
//

import UIKit
//import SwiftUI
import QuickLook
import SwiftRant
import SwiftHEXColors
//import ActiveLabel


class CommentCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    
    @IBOutlet weak var textStackView: UIStackView!
    @IBOutlet weak var userProfileImageView: RoundedImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userScoreLabel: PaddingLabel!
    @IBOutlet weak var userStackView: UIStackView!
    @IBOutlet weak var actionsStackView: UIStackView!
    
    @IBOutlet weak var bodyLabel: UITextView!
    @IBOutlet weak var supplementalImageView: UIImageView!
    @IBOutlet weak var reportModifyButton: UIButton!
    
    /**
     The `File` instance for a possible image.
     
     # See Also
        [File](x-source-tag://File)
     */
    var file: File?
    
    /**
     The data for the comment.
     
     # See Also
     [CommentModel](x-source-tag://CommentModel)
     */
    var commentContents: Comment!
    
    /**
     The parent view controller.
     
     - important: This technically can be any UIViewController, but it is advised to only put UITableViewControllers in this variable.
     */
    var parentTableViewController: UIViewController? = nil
    
    /**
     The parent table view.
     */
    var parentTableView: UITableView? = nil
    
    /**
     A pointer holding the data for the same comment in another table view.
     
     If the comment data was also represented somewhere else (for example, in another table view) and you want to sync the data between both instances of the same comment (for continuity's sake), set this property's value to your other instance's pointer.
     
     # See Also
     [CommentModel](x-source-tag://CommentModel)
     */
    //var commentInFeed: UnsafeMutablePointer<Comment>?
    
    var delegate: FeedDelegate?
    
    private var loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    //- commentInFeed: An [`UnsafeMutablePointer`]() pointer holding the data for the same comment in another table view. Optional.
    
    /**
     Configures the comment cell to show a loading ring.
     
     - returns: Nothing.
     */
    func configureLoading() {
        upvoteButton.isHidden = true
        scoreLabel.isHidden = true
        downvoteButton.isHidden = true
        textStackView.isHidden = true
        bodyLabel.isHidden = true
        supplementalImageView.isHidden = true
        
        contentView.addSubview(loadingIndicator)
        
        loadingIndicator.startAnimating()
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        //loadingIndicator.widthAnchor.constraint(equalToConstant: 20).isActive = true
        //loadingIndicator.heightAnchor.constraint(equalToConstant: 20).isActive = true
        loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        loadingIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -40).isActive = true
        loadingIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 40).isActive = true
        
        layoutIfNeeded()
        //loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 40).isActive = true
        
        //loadingIndicator.hidesWhenStopped = true
    }
    
    /**
     Configures the comment cell with the required data.
     
     - parameters:
        - model: The `CommentModel` full of the data given from the devRant API.
        - supplementalImage: If there is an image associated with the comment, this is the parameter that you need to set in order to give the cache URL for the image. Optional.
        - parentTableViewController: The table view controller that shows this cell. Optional.
        - parentTableView: The table view that shows this cell. Optional.
        - commentInFeed: An `UnsafeMutablePointer` that holds the address for the data for the same `CommentModel` in another table view. Optional.
        - allowedToPreview: A boolean value that tells the cell if it should allow special functionality, like previewing attached images and opening the comment's poster's profile page.
     
     - returns: Nothing.
     */
    func configure(with model: Comment, supplementalImage: File?, parentTableViewController: UIViewController?, parentTableView: UITableView?, allowedToPreview: Bool) {
        self.commentContents = model
        self.file = supplementalImage
        self.parentTableViewController = parentTableViewController
        self.parentTableView = parentTableView
        
        if loadingIndicator.isDescendant(of: contentView) {
            loadingIndicator.removeFromSuperview()
        }
        
        upvoteButton.isHidden = false
        scoreLabel.isHidden = false
        downvoteButton.isHidden = false
        textStackView.isHidden = false
        bodyLabel.isHidden = false
        supplementalImageView.isHidden = false
        
        upvoteButton.tintColor = (model.voteState == 1 ? UIColor(hexString: model.userAvatar.backgroundColor)! : UIColor.systemGray)
        //scoreLabel.text = String(commentContents!.score)
        scoreLabel.text = formatNumber(commentContents!.score)
        downvoteButton.tintColor = (model.voteState == -1 ? UIColor(hexString: model.userAvatar.backgroundColor)! : UIColor.systemGray)
        
        if supplementalImage == nil {
            supplementalImageView.isHidden = true
        } else {
            supplementalImageView.isHidden = false
            let resizeMultiplier = supplementalImage!.size!.width / bodyLabel.frame.size.width
            
            let finalWidth = supplementalImage!.size!.width / resizeMultiplier
            let finalHeight = supplementalImage!.size!.height / resizeMultiplier
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: finalWidth, height: finalHeight), false, resizeMultiplier)
            UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!.draw(in: CGRect(origin: .zero, size: CGSize(width: finalWidth, height: finalHeight)))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            supplementalImageView.image = newImage
        }
        
        upvoteButton.isEnabled = commentContents!.voteState != -2
        downvoteButton.isEnabled = commentContents!.voteState != -2
        
        bodyLabel.text = commentContents!.body
        
        /*if commentContents!.userAvatar.avatarImage == nil {
            userProfileImageView.image =  UIImage(color: UIColor(hexString: commentContents!.userAvatar.backgroundColor)!, size: CGSize(width: 45, height: 45))
        } else {
            let resourceURL = URL(string: "https://avatars.devrant.com/" + commentContents!.userAvatar.avatarImage!)!
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            var imageData: Data? = nil
            
            URLSession.shared.dataTask(with: resourceURL) { data, response, error in
                imageData = data ?? nil
                
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()
            userProfileImageView.image = UIImage(data: imageData ?? Data()) ?? nil
        }*/
        
        if let parentTableViewController = parentTableViewController as? RantViewController {
            Task {
                self.userProfileImageView.image = try? await parentTableViewController.userImageLoader.loadImage(withUserID: self.commentContents.userID)
            }
        } else if let parentTableViewController = parentTableViewController as? ProfileTableViewController {
            Task {
                self.userProfileImageView.image = try? await parentTableViewController.userImageLoader.loadImage(withUserID: self.commentContents.userID)
            }
        }
        
        usernameLabel.text = commentContents!.username
        
        if commentContents!.score < 0 {
            userScoreLabel.text = String(commentContents!.userScore)
        } else {
            userScoreLabel.text = "+\(commentContents!.userScore)"
        }
        
        userScoreLabel.backgroundColor = UIColor(hexString: commentContents!.userAvatar.backgroundColor)
        
        scoreLabel.text = String(commentContents!.score)
        
        if allowedToPreview {
            let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
            supplementalImageView.addGestureRecognizer(imageGestureRecognizer)
            
            let usernameGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUsernameTap(_:)))
            userStackView.addGestureRecognizer(usernameGestureRecognizer)
            
            if commentContents.userID == SwiftRant.shared.tokenFromKeychain!.authToken.userID && commentContents.username == SwiftRant.shared.usernameFromKeychain {
                reportModifyButton.setTitle("Modify", for: .normal)
                
                let actionsMenu = UIMenu(title: "", children: [
                    UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil")!, handler: { _ in
                        if Double(Date().timeIntervalSince1970) - Double(self.commentContents.createdTime) >= 300 {
                            let alert = UIAlertController(title: "Editing Disabled", message: "Rants and comments can only be edited for 5 mins (30 mins for devRant++ subscribers) after they are posted.", preferredStyle: .alert)
                            
                            alert.addAction(UIAlertAction(title: "Got it", style: .default, handler: nil))
                            
                            self.parentTableViewController?.present(alert, animated: true, completion: nil)
                        } else {
                            let composeVC = UIStoryboard(name: "ComposeViewController", bundle: nil).instantiateViewController(identifier: "ComposeViewController") as! UINavigationController
                            (composeVC.viewControllers.first as! ComposeViewController).commentID = self.commentContents.id
                            (composeVC.viewControllers.first as! ComposeViewController).isComment = true
                            (composeVC.viewControllers.first as! ComposeViewController).isEdit = true
                            (composeVC.viewControllers.first as! ComposeViewController).content = self.commentContents.body
                            
                            (composeVC.viewControllers.first as! ComposeViewController).viewControllerThatPresented = self.parentTableViewController
                            
                            composeVC.isModalInPresentation = true
                            
                            self.parentTableViewController!.present(composeVC, animated: true, completion: nil)
                        }
                    }),
                    
                    UIAction(title: "Delete", image: UIImage(systemName: "trash")!, handler: { _ in
                        let alert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete this comment?", preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in self.delete() }))
                        
                        self.parentTableViewController?.present(alert, animated: true, completion: nil)
                    })
                ])
                
                reportModifyButton.showsMenuAsPrimaryAction = true
                reportModifyButton.menu = actionsMenu
            } else {
                reportModifyButton.setTitle("Report", for: .normal)
            }
            
            if let links = commentContents.links {
                // We create the variables that we will use in the loop in order to avoid excessive RAM usage.
                
                /*let semiboldAttrString = NSMutableAttributedString(string: commentContents.body)
                let stringAsData = commentContents.body.data(using: .utf8)!
                
                var temporaryStringBytes = Data()
                var temporaryGenericUseString = ""
                
                var temporaryRange = NSRange(location: 0, length: 1)
                
                semiboldAttrString.addAttribute(.font, value: bodyLabel.font!, range: (commentContents.body as NSString).range(of: commentContents.body))
                semiboldAttrString.addAttribute(.foregroundColor, value: UIColor.label, range: (commentContents.body as NSString).range(of: commentContents.body))
                
                for i in links {
                    
                    if i.start == nil && i.end == nil {
                        temporaryRange = (commentContents.body as NSString).range(of: i.title)
                        
                        semiboldAttrString.addAttribute(.font, value: UIFont.systemFont(ofSize: bodyLabel.font!.pointSize, weight: .semibold), range: temporaryRange)
                        
                        if i.type == "mention" {
                            semiboldAttrString.addAttribute(.link, value: "mention://\(i.url)", range: temporaryRange)
                        } else {
                            semiboldAttrString.addAttribute(.link, value: i.url, range: temporaryRange)
                        }
                    } else {
                        // The devRant API returns offsets for links in byte offsets, not in normalized character offsets, so we need to get the raw bytes between the start offset (i.start) and end offset (i.end) and turn the entire thing to a String again, encoded in UTF-8.
                        
                        // Get the raw bytes in the given range from the devRant API
                        temporaryStringBytes = stringAsData[stringAsData.index(stringAsData.startIndex, offsetBy: i.start!)..<stringAsData.index(stringAsData.startIndex, offsetBy: i.end!)]
                        
                        // Turn the raw data into a String again
                        temporaryGenericUseString = String(data: temporaryStringBytes, encoding: .utf8)!
                        
                        // Get the range using the sanitized String that we just got from the raw data
                        temporaryRange = (commentContents.body as NSString).range(of: temporaryGenericUseString)
                        
                        // And use it to add our desired attributes
                        semiboldAttrString.addAttribute(.font, value: UIFont.systemFont(ofSize: bodyLabel.font!.pointSize, weight: .semibold), range: temporaryRange)
                        
                        if i.type == "mention" {
                            semiboldAttrString.addAttribute(.link, value: "mention://\(i.url)", range: temporaryRange)
                        } else {
                            semiboldAttrString.addAttribute(.link, value: i.url, range: temporaryRange)
                        }
                    }
                }
                
                bodyLabel.attributedText = semiboldAttrString*/
                
                if let parentTableViewController = parentTableViewController, let controller = parentTableViewController as? RantViewController {
                    bodyLabel.attributedText = controller.textsWithLinks[commentContents.id]
                }
                bodyLabel.isUserInteractionEnabled = true
                
                bodyLabel.delegate = self
            }
        }
        
        if !allowedToPreview {
            actionsStackView.isHidden = true
        }
    }
    
    func delete() {
        let originalColor = self.parentTableViewController?.navigationController?.navigationBar.tintColor
        
        self.parentTableViewController?.navigationController?.navigationBar.isUserInteractionEnabled = false
        self.parentTableViewController?.navigationController?.navigationBar.tintColor = UIColor.systemGray
        
        let originalTitle = self.parentTableViewController?.title
        
        self.parentTableViewController?.title = "Deleting your comment..."
        
        delegate?.didDeleteComment(withID: commentContents.id, cell: self)
        
        /*SwiftRant.shared.deleteComment(nil, commentID: commentContents.id) { error, success in
            if success {
                let typeCastedController = self.parentTableViewController as! RantViewController
                let commentIdx = typeCastedController.comments.firstIndex(where: {
                    $0.id == self.commentContents.id
                })!
                
                typeCastedController.comments.remove(at: commentIdx)
                typeCastedController.commentImages[self.commentContents.id] = nil
                
                DispatchQueue.main.async {
                    self.parentTableViewController?.title = originalTitle
                    self.parentTableViewController?.navigationController?.navigationBar.isUserInteractionEnabled = true
                    self.parentTableViewController?.navigationController?.navigationBar.tintColor = originalColor
                    
                    typeCastedController.tableView.deleteRows(at: [IndexPath(row: commentIdx, section: 1)], with: .fade)
                }
            } else {
                let failureAlertController = UIAlertController(title: "Error", message: error ?? "An unknown error has occurred while deleting the comment.", preferredStyle: .alert)
                
                failureAlertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                failureAlertController.addAction(UIAlertAction(title: "Retry", style: .destructive, handler: { _ in self.delete() }))
                
                DispatchQueue.main.async {
                    self.parentTableViewController?.title = originalTitle
                    self.parentTableViewController?.navigationController?.navigationBar.isUserInteractionEnabled = true
                    self.parentTableViewController?.navigationController?.navigationBar.tintColor = originalColor
                    
                    self.parentTableViewController?.present(failureAlertController, animated: true, completion: nil)
                }
            }
        }*/
        
        /*DispatchQueue.global(qos: .userInitiated).async {
            let success = APIRequest().deleteComment(commentID: self.commentContents.id)
            
            if success {
                let typeCastedController = self.parentTableViewController as! RantViewController
                let commentIdx = typeCastedController.comments.firstIndex(where: {
                    $0.uuid == self.commentContents.uuid
                })!
                
                typeCastedController.comments.remove(at: commentIdx)
                typeCastedController.commentImages[self.commentContents.id] = nil
                
                DispatchQueue.main.async {
                    self.parentTableViewController?.title = originalTitle
                    self.parentTableViewController?.navigationController?.navigationBar.isUserInteractionEnabled = true
                    self.parentTableViewController?.navigationController?.navigationBar.tintColor = originalColor
                    
                    typeCastedController.tableView.deleteRows(at: [IndexPath(row: commentIdx, section: 1)], with: .fade)
                    
                    
                }
            } else {
                let failureAlertController = UIAlertController(title: "Error", message: "Failed to delete comment. Please try again later.", preferredStyle: .alert)
                
                failureAlertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                failureAlertController.addAction(UIAlertAction(title: "Retry", style: .destructive, handler: { _ in self.delete() }))
                
                DispatchQueue.main.async {
                    self.parentTableViewController?.title = originalTitle
                    self.parentTableViewController?.navigationController?.navigationBar.isUserInteractionEnabled = true
                    self.parentTableViewController?.navigationController?.navigationBar.tintColor = originalColor
                    
                    self.parentTableViewController?.present(failureAlertController, animated: true, completion: nil)
                }
            }
        }*/
    }
    
    @IBAction func handleUpvote(_ sender: UIButton) {
        var vote: Int {
            switch self.commentContents!.voteState {
            case 0:
                return 1
                
            case 1:
                return 0
                
            default:
                return 1
            }
        }
        
        (delegate as? ProfileTableViewControllerDelegate)?.setVoteStateForComment(withID: commentContents!.id, voteState: vote)
        (delegate as? RantViewControllerDelegate)?.changeCommentVoteState(commentID: commentContents!.id, voteState: vote)
        
        (delegate as? ProfileTableViewControllerDelegate)?.setScoreForComment(withID: commentContents!.id, score: commentContents!.voteState == 1 ? commentContents!.score - 1 : commentContents!.score + vote)
        (delegate as? RantViewControllerDelegate)?.changeCommentScore(commentID: commentContents!.id, score: commentContents!.voteState == 1 ? commentContents!.score - 1 : commentContents!.score + vote)
        
        DispatchQueue.main.async {
            (self.delegate as? ProfileTableViewControllerDelegate)?.reloadData()
            (self.delegate as? RantViewControllerDelegate)?.reloadData()
        }
        
        delegate?.didVoteOnComment(withID: commentContents.id, vote: vote, cell: self)
        
        /*SwiftRant.shared.voteOnComment(nil, commentID: commentContents!.id, vote: vote) { error, updatedComment in
            if let updatedComment = updatedComment {
                if let commentInFeed = self.commentInFeed {
                    commentInFeed.pointee.voteState = vote
                    commentInFeed.pointee.score = updatedComment.score
                }
                
                if let idx = (self.parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent.firstIndex(where: {
                    $0.id == self.commentContents!.id
                }) {
                    (self.parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].voteState = updatedComment.voteState
                    (self.parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].score = updatedComment.score
                } else if let idx = (self.parentTableViewController as? RantViewController)?.comments.firstIndex(where: {
                    $0.id == self.commentContents!.id
                }) {
                    (self.parentTableViewController as? RantViewController)?.comments[idx].voteState = updatedComment.voteState
                    (self.parentTableViewController as? RantViewController)?.comments[idx].score = updatedComment.score
                }
                
                DispatchQueue.main.async {
                    self.parentTableView?.reloadData()
                }
            } else {
                if let parentTableViewController = self.parentTableViewController {
                    let alertController = UIAlertController(title: "Error", message: error ?? "An unknown error has occurred while voting on the comment.", preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self.handleUpvote(sender) }))
                    
                    DispatchQueue.main.async {
                        parentTableViewController.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }*/
        
        /*let success = APIRequest().voteOnComment(commentID: commentContents!.id, vote: vote)
        
        if success == nil {
            print("ERROR WHILE UPVOTING")
        } else {
            if let commentInFeed = self.commentInFeed {
                commentInFeed.pointee.voteState = vote
                commentInFeed.pointee.score = success!.comment.score
            }
            
            if let idx = (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent.firstIndex(where: {
                $0.uuid == self.commentContents!.uuid
            }) {
                (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].voteState = success!.comment.voteState
                (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].score = success!.comment.score
            } else if let idx = (parentTableViewController as? RantViewController)?.comments.firstIndex(where: {
                $0.uuid == self.commentContents!.uuid
            }) {
                (parentTableViewController as? RantViewController)?.comments[idx].voteState = success!.comment.voteState
                (parentTableViewController as? RantViewController)?.comments[idx].score = success!.comment.score
            }
            
            parentTableView?.reloadData()
        }*/
    }
    
    @IBAction func handleDownvote(_ sender: UIButton) {
        var vote: Int {
            switch self.commentContents!.voteState {
            case 0:
                return -1
                
            case -1:
                return 0
                
            default:
                return -1
            }
        }
        
        (delegate as? ProfileTableViewControllerDelegate)?.setVoteStateForComment(withID: commentContents!.id, voteState: vote)
        (delegate as? RantViewControllerDelegate)?.changeCommentVoteState(commentID: commentContents!.id, voteState: vote)
        
        (delegate as? ProfileTableViewControllerDelegate)?.setScoreForComment(withID: commentContents!.id, score: commentContents!.voteState == -1 ? commentContents!.score + 1 : commentContents!.score + vote)
        (delegate as? RantViewControllerDelegate)?.changeCommentScore(commentID: commentContents!.id, score: commentContents!.voteState == -1 ? commentContents!.score + 1 : commentContents!.score + vote)
        
        DispatchQueue.main.async {
            (self.delegate as? ProfileTableViewControllerDelegate)?.reloadData()
            (self.delegate as? RantViewControllerDelegate)?.reloadData()
        }
        
        delegate?.didVoteOnComment(withID: commentContents.id, vote: vote, cell: self)
        
        /*SwiftRant.shared.voteOnComment(nil, commentID: commentContents!.id, vote: vote) { error, updatedComment in
            if let updatedComment = updatedComment {
                if let commentInFeed = self.commentInFeed {
                    commentInFeed.pointee.voteState = vote
                    commentInFeed.pointee.score = updatedComment.score
                }
                
                if let idx = (self.parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent.firstIndex(where: {
                    $0.id == self.commentContents!.id
                }) {
                    (self.parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].voteState = updatedComment.voteState
                    (self.parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].score = updatedComment.score
                } else if let idx = (self.parentTableViewController as? RantViewController)?.comments.firstIndex(where: {
                    $0.id == self.commentContents!.id
                }) {
                    (self.parentTableViewController as? RantViewController)?.comments[idx].voteState = updatedComment.voteState
                    (self.parentTableViewController as? RantViewController)?.comments[idx].score = updatedComment.score
                }
                
                DispatchQueue.main.async {
                    self.parentTableView?.reloadData()
                }
            } else {
                if let parentTableViewController = self.parentTableViewController {
                    let alertController = UIAlertController(title: "Error", message: error ?? "An unknown error has occurred while voting on the comment.", preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self.handleDownvote(sender) }))
                    
                    DispatchQueue.main.async {
                        parentTableViewController.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }*/
        
        /*let success = APIRequest().voteOnComment(commentID: self.commentContents!.id, vote: vote)
        
        if success == nil {
            print("ERROR WHILE DOWNVOTING")
        } else {
            if let commentInFeed = self.commentInFeed {
                commentInFeed.pointee.voteState = vote
                commentInFeed.pointee.score = success!.comment.score
            }
            
            if let idx = (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent.firstIndex(where: {
                $0.uuid == self.commentContents!.uuid
            }) {
                (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].voteState = success!.comment.voteState
                (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].score = success!.comment.score
                
                parentTableView?.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .none)
            } else if let idx = (parentTableViewController as? RantViewController)?.comments.firstIndex(where: {
                $0.uuid == self.commentContents!.uuid
            }) {
                (parentTableViewController as? RantViewController)?.comments[idx].voteState = success!.comment.voteState
                (parentTableViewController as? RantViewController)?.comments[idx].score = success!.comment.score
                
                parentTableView?.reloadRows(at: [IndexPath(row: idx, section: 1)], with: .none)
            }
        }*/
    }
    
    @objc func handleImageTap(_ sender: UITapGestureRecognizer) {
        let quickLookViewController = QLPreviewController()
        quickLookViewController.modalPresentationStyle = .overFullScreen
        quickLookViewController.dataSource = (parentTableViewController as! RantViewController)
        quickLookViewController.delegate = (parentTableViewController as! RantViewController)
        (parentTableViewController as! RantViewController).tappedComment = self
        
        quickLookViewController.currentPreviewItemIndex = 0
        parentTableViewController?.present(quickLookViewController, animated: true)
    }
    
    @objc func handleUsernameTap(_ sender: UITapGestureRecognizer) {
        if let parentTableViewController = self.parentTableViewController {
            let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                return ProfileTableViewController(coder: coder, userID: self.commentContents.userID)
            })
            
            print(String(describing: type(of: parentTableViewController)))
            print(String(describing: type(of: self)))
            
            parentTableViewController.navigationController?.pushViewController(profileVC, animated: true)
        }
    }
    
    @IBAction func reply(_ sender: Any) {
        let composeVC = UIStoryboard(name: "ComposeViewController", bundle: nil).instantiateViewController(identifier: "ComposeViewController") as! UINavigationController
        
        (composeVC.viewControllers.first! as! ComposeViewController).content = "@\(commentContents.username) "
        (composeVC.viewControllers.first! as! ComposeViewController).rantID = commentContents.rantID
        (composeVC.viewControllers.first! as! ComposeViewController).isComment = true
        (composeVC.viewControllers.first! as! ComposeViewController).isEdit = false
        (composeVC.viewControllers.first! as! ComposeViewController).viewControllerThatPresented = parentTableViewController
        
        composeVC.isModalInPresentation = true
        parentTableViewController?.present(composeVC, animated: true, completion: nil)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if URL.absoluteString.hasPrefix("mention://") {
            if let parentTableViewController = self.parentTableViewController {
                let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                    return ProfileTableViewController(coder: coder, userID: Int(URL.absoluteString.components(separatedBy: "/").last!)!)
                })
                
                print(String(describing: type(of: parentTableViewController)))
                print(String(describing: type(of: self)))
                
                parentTableViewController.navigationController?.pushViewController(profileVC, animated: true)
            }
        } else {
            UIApplication.shared.open(URL)
        }
        return false
    }
    
    private func getImageResizeMultiplier(imageWidth: CGFloat, imageHeight: CGFloat, multiplier: Int) -> CGFloat {
        if imageWidth / CGFloat(multiplier) < 315 && imageHeight / CGFloat(multiplier) < 420 {
            return CGFloat(multiplier)
        } else {
            return getImageResizeMultiplier(imageWidth: imageWidth, imageHeight: imageHeight, multiplier: multiplier + 2)
        }
    }
    
    /*func getUserImageFromImageStore() -> UIImage {
        let semaphore = DispatchSemaphore(value: 0)
        var image = UIImage()
        
        Task {
            image = try! await (parentTableViewController as! RantViewController).userImageLoader.loadImage(withUserID: self.commentContents.userID)
        }
        
        semaphore.wait()
        return image
    }*/
}

func unsafeWaitFor(_ f: @escaping () async -> ()) {
    let sema = DispatchSemaphore(value: 0)
    Task {
        await f()
        sema.signal()
    }
    
    sema.wait()
}
